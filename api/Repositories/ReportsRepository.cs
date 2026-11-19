using System.Data;
using System.Text.Json;
using api.Data;
using api.DTOs;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using Npgsql;
using NpgsqlTypes;

namespace api.Repositories;

public class ReportsRepository(AppDbContext context)
{
    public async Task<PeriodReportDTO> GetPeriod(DateOnly start, DateOnly end, Guid? employeeId)
    {
        var connection = (NpgsqlConnection)context.Database.GetDbConnection();
        var openedHere = connection.State != ConnectionState.Open;
        if (openedHere) await context.Database.OpenConnectionAsync();
        try
        {
            await using var command = connection.CreateCommand();
            command.Transaction = context.Database.CurrentTransaction?.GetDbTransaction() as NpgsqlTransaction;
            command.CommandText = """
                WITH selected AS (
                    SELECT "Id", "Status", round(COALESCE("ValorTotal", 0)::numeric, 2) AS total,
                        ("DataAgendamento" AT TIME ZONE 'America/Sao_Paulo')::date AS day
                    FROM public."Agendamentos"
                    WHERE "DataAgendamento" >= (@start::date::timestamp AT TIME ZONE 'America/Sao_Paulo')
                      AND "DataAgendamento" < ((@end::date + 1)::timestamp AT TIME ZONE 'America/Sao_Paulo')
                      AND (@employee::uuid IS NULL OR "IdFuncionario" = @employee)
                      AND "Status" IN ('agendado', 'concluido')
                ), ranked AS (
                    SELECT CASE WHEN s."Ativo" THEN s."Nome" ELSE s."Nome" || ' (desabilitado)' END AS name,
                        count(*) AS occurrences
                    FROM selected a
                    JOIN public."ServicosRealizados" sr ON sr."IdAgendamento" = a."Id"
                    JOIN public."Servicos" s ON s."Id" = sr."IdServico"
                    GROUP BY 1
                ), revenue AS (
                    SELECT day, sum(total) AS total FROM selected WHERE "Status" = 'concluido' GROUP BY day
                )
                SELECT jsonb_build_object(
                    'startDate', @start::date, 'endDate', @end::date,
                    'summary', jsonb_build_object(
                        'date', @end::date,
                        'completedRevenue', COALESCE(sum(total) FILTER (WHERE "Status" = 'concluido'), 0),
                        'completedCount', count(*) FILTER (WHERE "Status" = 'concluido'),
                        'pendingRevenue', COALESCE(sum(total) FILTER (WHERE "Status" = 'agendado'), 0),
                        'activeCount', count(*),
                        'serviceCounts', (SELECT COALESCE(jsonb_object_agg(name, occurrences), '{}'::jsonb) FROM ranked)),
                    'revenueByDay', (SELECT jsonb_agg(jsonb_build_object('date', d::date, 'revenue', COALESCE(r.total, 0)) ORDER BY d)
                        FROM generate_series(@start::date::timestamp, @end::date::timestamp, interval '1 day') d
                        LEFT JOIN revenue r ON r.day = d::date))
                FROM selected;
                """;
            command.Parameters.AddWithValue("start", NpgsqlDbType.Date, start);
            command.Parameters.AddWithValue("end", NpgsqlDbType.Date, end);
            command.Parameters.AddWithValue("employee", NpgsqlDbType.Uuid, (object?)employeeId ?? DBNull.Value);
            var json = (string)(await command.ExecuteScalarAsync())!;
            return JsonSerializer.Deserialize<PeriodReportDTO>(json, new JsonSerializerOptions(JsonSerializerDefaults.Web))!;
        }
        finally
        {
            if (openedHere) await context.Database.CloseConnectionAsync();
        }
    }

    public async Task<DailyReportDTO> GetDaily(DateOnly date, Guid? employeeId)
    {
        var connection = (NpgsqlConnection)context.Database.GetDbConnection();
        var openedHere = connection.State != ConnectionState.Open;
        if (openedHere) await context.Database.OpenConnectionAsync();
        try
        {
            await using var command = connection.CreateCommand();
            command.Transaction = context.Database.CurrentTransaction?.GetDbTransaction() as NpgsqlTransaction;
            command.CommandText = "CALL daily_appointment_summary(@day, @employee, NULL, NULL, NULL, NULL, NULL)";
            command.Parameters.AddWithValue("day", NpgsqlDbType.Date, date);
            command.Parameters.AddWithValue("employee", NpgsqlDbType.Uuid, (object?)employeeId ?? DBNull.Value);
            await using var reader = await command.ExecuteReaderAsync();
            await reader.ReadAsync();
            return new DailyReportDTO(date,
                reader.GetDecimal(0), reader.GetInt64(1), reader.GetDecimal(2), reader.GetInt64(3),
                JsonSerializer.Deserialize<Dictionary<string, long>>(reader.GetString(4))!);
        }
        finally
        {
            if (openedHere) await context.Database.CloseConnectionAsync();
        }
    }
}
