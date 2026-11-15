using Microsoft.EntityFrameworkCore.Migrations;

namespace api.Migrations;

public partial class AddDailyAppointmentSummary : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql("""
            CREATE PROCEDURE public.daily_appointment_summary(
                IN report_date date,
                IN employee_id uuid,
                OUT completed_revenue numeric,
                OUT completed_count bigint,
                OUT pending_revenue numeric,
                OUT active_count bigint,
                OUT service_counts jsonb
            )
            LANGUAGE plpgsql AS $report$
            BEGIN
                IF report_date IS NULL THEN
                    RAISE EXCEPTION 'Report date is required' USING ERRCODE = '22004';
                END IF;

                WITH selected AS (
                    SELECT "Id", "Status", round(COALESCE("ValorTotal", 0)::numeric, 2) AS total
                    FROM public."Agendamentos"
                    WHERE "DataAgendamento" >= (report_date::timestamp AT TIME ZONE 'America/Sao_Paulo')
                      AND "DataAgendamento" < ((report_date + 1)::timestamp AT TIME ZONE 'America/Sao_Paulo')
                      AND (employee_id IS NULL OR "IdFuncionario" = employee_id)
                      AND "Status" IN ('agendado', 'concluido')
                ), ranked AS (
                    SELECT CASE WHEN s."Ativo" THEN s."Nome" ELSE s."Nome" || ' (desabilitado)' END AS service_name,
                        count(*) AS occurrences
                    FROM selected a
                    JOIN public."ServicosRealizados" sr ON sr."IdAgendamento" = a."Id"
                    JOIN public."Servicos" s ON s."Id" = sr."IdServico"
                    GROUP BY 1
                )
                SELECT COALESCE(sum(total) FILTER (WHERE "Status" = 'concluido'), 0),
                    count(*) FILTER (WHERE "Status" = 'concluido'),
                    COALESCE(sum(total) FILTER (WHERE "Status" = 'agendado'), 0),
                    count(*),
                    (SELECT COALESCE(jsonb_object_agg(service_name, occurrences), '{}'::jsonb) FROM ranked)
                INTO completed_revenue, completed_count, pending_revenue, active_count, service_counts
                FROM selected;
            END;
            $report$;
            """);
    }

    protected override void Down(MigrationBuilder migrationBuilder) =>
        migrationBuilder.Sql("DROP PROCEDURE public.daily_appointment_summary(date, uuid);");
}
