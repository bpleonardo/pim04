using api.Data;
using api.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

var options = new DbContextOptionsBuilder<AppDbContext>()
    .UseNpgsql("Host=localhost;Database=unused;Username=unused;Password=unused").Options;
using var context = new AppDbContext(options);
if (context.Database.HasPendingModelChanges())
{
    var current = context.GetService<Microsoft.EntityFrameworkCore.Metadata.IDesignTimeModel>().Model;
    var snapshot = context.GetService<IMigrationsAssembly>().ModelSnapshot!.Model;
    var initialized = context.GetService<Microsoft.EntityFrameworkCore.Infrastructure.IModelRuntimeInitializer>().Initialize(snapshot);
    var difference = context.GetService<IMigrationsModelDiffer>().GetDifferences(initialized.GetRelationalModel(), current.GetRelationalModel());
    foreach (var operation in difference) Console.WriteLine(System.Text.Json.JsonSerializer.Serialize(operation, operation.GetType()));
    throw new Exception("O snapshot de migração não corresponde ao modelo atual.");
}
var migrations = context.Database.GetMigrations().ToArray();
if (!migrations.Contains("20261113120000_AddOfflineAppointments"))
    throw new Exception("Migração de sincronização não encontrada.");
var sql = context.GetService<IMigrator>().GenerateScript(
    "20261113000000_AddRefreshSessions", "20261113120000_AddOfflineAppointments");
foreach (var column in new[] { "Revision", "ClientRequestId", "RequestHash", "LastMutationId" })
    if (!sql.Contains(column)) throw new Exception($"Coluna ausente: {column}");
var model = context.Model.FindEntityType(typeof(Agendamento))!;
if (!model.FindProperty(nameof(Agendamento.Revision))!.IsConcurrencyToken)
    throw new Exception("Revisão deve participar da verificação de concorrência.");
if (!model.GetIndexes().Any(i => i.IsUnique && i.Properties.SingleOrDefault()?.Name == nameof(Agendamento.ClientRequestId)))
    throw new Exception("Identificador de criação deve ser único.");
Console.WriteLine("Contrato offline, controle de versão e migração validados sem conexão com banco de produção.");

var now = DateTime.UtcNow;
var recorded = api.Services.AgendamentosService.BookingReferenceTime(new api.DTOs.AgendamentoCreateDTO { RecordedAt = now.AddHours(-2) });
if (recorded >= now) throw new Exception("Registro offline deve conservar a hora de criação.");
try
{
    api.Services.AgendamentosService.BookingReferenceTime(new api.DTOs.AgendamentoCreateDTO { RecordedAt = now.AddDays(-8) });
    throw new Exception("Registros fora da janela offline não devem ser aceitos.");
}
catch (api.Exceptions.ValidationException) { }
var controller = new api.Controllers.AgendamentosController(null!)
{
    ControllerContext = new Microsoft.AspNetCore.Mvc.ControllerContext { HttpContext = new Microsoft.AspNetCore.Http.DefaultHttpContext() }
};
var denied = await controller.Post(new api.DTOs.AgendamentoCreateDTO { RecordedAt = now, IdFuncionario = Guid.NewGuid(), ClientRequestId = new string('a', 32) });
if (denied.Result is not Microsoft.AspNetCore.Mvc.UnauthorizedResult)
    throw new Exception("Registro offline não deve permitir criação anônima retroativa.");
Console.WriteLine("Janela de registro offline e proteção de criação autenticada validadas.");
