using api.Data;
using api.DTOs;
using api.Models;
using api.Repositories;
using api.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql;

static void Check(bool condition, string message)
{
    if (!condition) throw new Exception(message);
}
var connection = Environment.GetEnvironmentVariable("PIM_TEST_DB_CONNECTION")
    ?? throw new Exception("Defina PIM_TEST_DB_CONNECTION para um banco PostgreSQL descartável.");
var settings = new NpgsqlConnectionStringBuilder(connection);
Check(settings.Database?.StartsWith("pim_routines_test_", StringComparison.Ordinal) == true,
    "O verificador aceita somente bancos descartáveis com prefixo pim_routines_test_.");
var options = new DbContextOptionsBuilder<AppDbContext>().UseNpgsql(connection).Options;
await using var context = new AppDbContext(options);
Check(!context.Database.HasPendingModelChanges(), "Modelo e snapshot de migração divergentes.");
await context.Database.MigrateAsync();
Check(!(await context.Database.GetPendingMigrationsAsync()).Any(), "Há migrações pendentes.");

await using (var transaction = await context.Database.BeginTransactionAsync())
{
    var service = new Servico(null, "Corte para auditoria", "Serviço fictício de teste", 35);
    context.Servicos.Add(service);
    await context.SaveChangesAsync();
    var services = new ServicosService(new ServicosRepository(context));
    Check((await services.GetPriceHistory(service.Id)).Length == 0, "Inserção não deve gerar histórico de alteração.");
    await services.ReplaceOne(service.Id, new ServicoCreateDTO { Nome = service.Nome, Descricao = service.Descricao, Preco = 45 });
    var history = await services.GetPriceHistory(service.Id);
    Check(history.Length == 1 && history[0].OldPrice == 35 && history[0].NewPrice == 45,
        "Trigger deve registrar o preço anterior e o novo preço.");
    Check(history[0].ChangedAt.Kind == DateTimeKind.Utc, "Data de auditoria deve ser UTC.");
    await context.Database.ExecuteSqlInterpolatedAsync($"UPDATE \"Servicos\" SET \"Preco\" = \"Preco\", \"Nome\" = 'Auditoria renomeada' WHERE \"Id\" = {service.Id}");
    Check((await services.GetPriceHistory(service.Id)).Length == 1, "Preço inalterado/renomeação não deve duplicar histórico.");
    await transaction.CreateSavepointAsync("audit_rollback");
    await context.Database.ExecuteSqlInterpolatedAsync($"UPDATE \"Servicos\" SET \"Preco\" = 60 WHERE \"Id\" = {service.Id}");
    Check((await services.GetPriceHistory(service.Id)).Length == 2, "Atualização SQL direta também deve disparar a trigger.");
    await transaction.RollbackToSavepointAsync("audit_rollback");
    Check((await services.GetPriceHistory(service.Id)).Length == 1, "Rollback deve desfazer também o histórico.");
    await services.DeleteOne(service.Id);
    var archived = await context.ServicePriceChanges.AsNoTracking().SingleAsync();
    Check(archived.ServiceId == null && archived.ServiceName == "Corte para auditoria",
        "Excluir serviço sem atendimentos deve preservar o histórico e o nome registrado.");

    var employee = new Funcionario(null, "Profissional Um", null, null!, "one@pim.test", "Endereço fictício");
    var other = new Funcionario(null, "Profissional Dois", null, null!, "two@pim.test", "Endereço fictício");
    var client = new Cliente(null, "Cliente de teste", "5511000000000", null, null, null);
    var hair = new Servico(null, "Cabelo do relatório", "Descrição fictícia", 30);
    var beard = new Servico(null, "Barba do relatório", "Descrição fictícia", 20);
    context.AddRange(employee, other, client, hair, beard);
    await context.SaveChangesAsync();
    void Add(DateTime at, string status, double? total, Funcionario owner, params Servico[] bookedServices)
    {
        var appointment = new Agendamento { Id = Guid.NewGuid(), IdCliente = client.Id, IdFuncionario = owner.Id,
            DataAgendamento = at, Status = status, ValorTotal = total };
        foreach (var item in bookedServices)
            appointment.ServicosRealizados.Add(new ServicoRealizado { IdAgendamento = appointment.Id, IdServico = item.Id, Valor = item.Preco });
        context.Agendamentos.Add(appointment);
    }
    Add(new DateTime(2026, 11, 15, 3, 0, 0, DateTimeKind.Utc), "concluido", 50, employee, hair, beard);
    Add(new DateTime(2026, 11, 16, 2, 59, 0, DateTimeKind.Utc), "agendado", 30, employee, hair);
    Add(new DateTime(2026, 11, 15, 18, 0, 0, DateTimeKind.Utc), "cancelado", 999, employee, hair);
    Add(new DateTime(2026, 11, 15, 2, 59, 0, DateTimeKind.Utc), "concluido", 300, employee, hair);
    Add(new DateTime(2026, 11, 16, 3, 0, 0, DateTimeKind.Utc), "concluido", 400, employee, hair);
    Add(new DateTime(2026, 11, 15, 12, 0, 0, DateTimeKind.Utc), "concluido", 20, other, beard);
    Add(new DateTime(2026, 11, 12, 12, 0, 0, DateTimeKind.Utc), "concluido", null, employee);
    await context.SaveChangesAsync();
    var reports = new ReportsService(new ReportsRepository(context));
    var date = new DateOnly(2026, 11, 15);
    var all = await reports.GetDaily(date, null);
    Check(all.CompletedRevenue == 70 && all.CompletedCount == 2 && all.PendingRevenue == 30 && all.ActiveCount == 3,
        "Procedure deve separar concluídos, pendentes e cancelados e respeitar os limites do dia em São Paulo.");
    Check(all.ServiceCounts[hair.Nome] == 2 && all.ServiceCounts[beard.Nome] == 2,
        "Múltiplos serviços não podem duplicar faturamento/atendimentos.");
    var mine = await reports.GetDaily(date, employee.Id);
    Check(mine.CompletedRevenue == 50 && mine.CompletedCount == 1 && mine.ActiveCount == 2, "Filtro de funcionário incorreto.");
    var empty = await reports.GetDaily(date, Guid.NewGuid());
    Check(empty.CompletedRevenue == 0 && empty.CompletedCount == 0 && empty.ActiveCount == 0 && empty.ServiceCounts.Count == 0,
        "Resumo sem atendimentos deve devolver zeros e ranking vazio.");
    var legacy = await reports.GetDaily(new DateOnly(2026, 11, 12), null);
    Check(legacy.CompletedRevenue == 0 && legacy.CompletedCount == 1, "Valor nulo legado deve ser tratado como zero.");
    await services.ReplaceOne(hair.Id, new ServicoCreateDTO { Nome = hair.Nome, Descricao = hair.Descricao, Preco = 90 });
    Check((await reports.GetDaily(date, null)).CompletedRevenue == 70, "Alterar preço do catálogo não pode recalcular vendas históricas.");
    await context.Servicos.Where(item => item.Id == beard.Id).ExecuteUpdateAsync(update => update.SetProperty(item => item.Ativo, false));
    Check((await reports.GetDaily(date, null)).ServiceCounts.ContainsKey(beard.Nome + " (desabilitado)"), "Ranking deve identificar serviço desabilitado.");
    await transaction.RollbackAsync();
}
context.ChangeTracker.Clear();
var migrator = context.GetService<IMigrator>();
await migrator.MigrateAsync("20261114130000_AddEmployeeAvailability");
await migrator.MigrateAsync();
Console.WriteLine("Trigger, procedure, repositórios, isolamento por funcionário, fuso horário e migrações Up/Down validados no PostgreSQL.");
