using api.Controllers;
using api.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Hosting.Server;
using Microsoft.AspNetCore.Hosting.Server.Features;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using api.Data;
using api.Models;
using api.Repositories;
using Microsoft.EntityFrameworkCore;
using Npgsql;

static void Check(bool condition, string message) { if (!condition) throw new Exception(message); }
var connection = Environment.GetEnvironmentVariable("PIM_TEST_DB_CONNECTION") ?? throw new Exception("Use um banco descartável.");
Check(new NpgsqlConnectionStringBuilder(connection).Database?.StartsWith("pim_review_test_", StringComparison.Ordinal) == true,
    "Use somente banco descartável com prefixo pim_review_test_.");
await using var db = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().UseNpgsql(connection).Options);
await db.Database.MigrateAsync();
await using var tx = await db.Database.BeginTransactionAsync();
var day = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(1));
var employee = new Funcionario(null, "Profissional ocupado", null, null, null, "Endereço fictício");
var free = new Funcionario(null, "Profissional livre", null, null, null, "Endereço fictício");
var unconfigured = new Funcionario(null, "Sem disponibilidade", null, null, null, "Endereço fictício");
var deleted = new Funcionario(null, "Excluído", null, null, null, "Endereço fictício") { IsDeleted = true };
var client = new Cliente(null, "Cliente fictício", "5511000000000", null, null, null);
db.AddRange(employee, free, unconfigured, deleted, client);
foreach (var person in new[] { employee, free, deleted })
    db.FuncionarioDisponibilidades.Add(new FuncionarioDisponibilidade {
        Id = Guid.NewGuid(), IdFuncionario = person.Id, DiaSemana = (int)day.DayOfWeek,
        Inicio = new TimeOnly(9, 0), Fim = new TimeOnly(12, 0),
    });
var timezone = TimeZoneInfo.FindSystemTimeZoneById("America/Sao_Paulo");
var at = TimeZoneInfo.ConvertTimeToUtc(day.ToDateTime(new TimeOnly(10, 0)), timezone);
db.Agendamentos.Add(new Agendamento { Id = Guid.NewGuid(), IdCliente = client.Id, IdFuncionario = employee.Id,
    DataAgendamento = at, Status = "agendado", ValorTotal = 0 });
await db.SaveChangesAsync();
var repo = new HorariosRepository(db);
async Task<bool> Available(Guid? id, string slot) => (await repo.GetHorariosDisponiveis(day, new TimeOnly(9, 0), new TimeOnly(18, 0), id)).Single(item => item.Slot == slot).Available;
Check(!await Available(employee.Id, "10:00"), "O profissional ocupado apareceu livre.");
Check(await Available(free.Id, "10:00"), "Um agendamento bloqueou outro profissional.");
Check(await Available(null, "10:00"), "A consulta geral não encontrou o profissional livre.");
Check(!await Available(null, "13:00"), "A consulta geral ignorou os intervalos configurados.");
Check(!await Available(unconfigured.Id, "10:00"), "Funcionário sem disponibilidade apareceu livre.");
Check(!await Available(deleted.Id, "10:00"), "Funcionário excluído apareceu livre.");
Check(!await Available(Guid.NewGuid(), "10:00"), "Funcionário inexistente apareceu livre.");
// A agenda contém dados pessoais e só deve ser consultada após autenticação.
var builder = WebApplication.CreateBuilder();
builder.Logging.ClearProviders();
builder.WebHost.UseUrls("http://127.0.0.1:0");
builder.Services.AddControllers().AddApplicationPart(typeof(AgendamentosController).Assembly);
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer();
builder.Services.AddAuthorization();
builder.Services.AddSingleton(new AgendamentosService(new AgendamentosRepository(db), new ClientesRepository(db), new ServicosRepository(db)));
await using (var app = builder.Build()) {
    app.UseAuthentication();
    app.UseAuthorization();
    app.MapControllers();
    await app.StartAsync();
    var address = app.Services.GetRequiredService<IServer>().Features.Get<IServerAddressesFeature>()!.Addresses.Single();
    using var http = new HttpClient();
    var response = await http.GetAsync($"{address}/api/agendamentos");
    Check(response.StatusCode == System.Net.HttpStatusCode.Unauthorized, "Consulta anônima expôs a agenda.");
    await app.StopAsync();
}
await tx.RollbackAsync();
Console.WriteLine("PASS: ocupação por funcionário, disponibilidade geral, intervalos, exclusão e funcionário inexistente.");
