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
