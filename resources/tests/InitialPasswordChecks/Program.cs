using System.ComponentModel.DataAnnotations;
using System.Text;
using api.Data;
using api.DTOs;
using api.Exceptions;
using api.Models;
using api.Repositories;
using api.Services;
using api.Utilities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using Npgsql;

static void Check(bool condition, string message)
{
    if (!condition) throw new Exception(message);
}
static async Task Reject(Func<Task> action, string code)
{
    try { await action(); }
    catch (AppException error) when (error.Code == code) { return; }
    throw new Exception($"Expected rejection: {code}");
}
var connection = Environment.GetEnvironmentVariable("PIM_TEST_DB_CONNECTION")
    ?? throw new Exception("Defina PIM_TEST_DB_CONNECTION para um banco PostgreSQL descartável.");
Check(new NpgsqlConnectionStringBuilder(connection).Database?.StartsWith("pim_auth_test_", StringComparison.Ordinal) == true,
    "Use somente um banco descartável com prefixo pim_auth_test_.");
var options = new DbContextOptionsBuilder<AppDbContext>().UseNpgsql(connection).Options;
AppDbContext Open() => new(options);
AuthService Auth(AppDbContext db) => new(new UsuariosRepository(db), new ConfigurationBuilder().Build(),
    new SymmetricSecurityKey(Encoding.UTF8.GetBytes("test-only-auth-key-at-least-32-bytes-long")), db);
var login = $"test.{Guid.NewGuid():N}";
var duplicateName = $"Duplicate {login}";
FuncionarioCreateDTO Employee(string name) => new(name, "5511000000000", null, $"{Guid.NewGuid():N}@test.invalid", "Endereço fictício")
    { Login = login, InitialPassword = "initial password" };
await using var context = Open();
await context.Database.MigrateAsync();
Check(!context.Database.HasPendingModelChanges(), "Migration snapshot differs from model.");
try
{
    var employees = new FuncionariosService(new FuncionariosRepository(context));
    await employees.CreateOne(Employee("Funcionário de teste"));
    var user = await context.Usuarios.AsNoTracking().SingleAsync(item => item.Login == login);
    Check(user.PasswordExpired && user.Senha != "initial password" && AccountPassword.Verify(user, "initial password"),
        "Registration must atomically persist the account with a hashed, expired password.");
    var id = user.IdFuncionario;
    await using (var duplicate = Open())
    {
        await Reject(() => new FuncionariosService(new FuncionariosRepository(duplicate)).CreateOne(Employee(duplicateName)), "LOGIN_ALREADY_EXISTS");
    }
    Check(!await context.Funcionarios.AnyAsync(item => item.Nome == duplicateName), "Duplicate login left an orphan employee.");
    await using (var request = Open())
    {
        await Reject(async () => await Auth(request).AuthenticateAsync(new LoginRequest { Login = login, Senha = "wrong password" }), "INVALID_CREDENTIALS");
        await Reject(async () => await Auth(request).AuthenticateAsync(new LoginRequest { Login = login, Senha = "initial password" }), "PASSWORD_CHANGE_REQUIRED");
    }
    Check(!await context.RefreshSessions.AnyAsync(item => item.EmployeeId == id), "Initial login issued a token session.");
    await using (var request = Open())
        await Reject(() => Auth(request).SetInitialPasswordAsync(new InitialPasswordRequest
            { Login = login, Senha = "wrong password", NewPassword = "chosen password" }), "INVALID_CREDENTIALS");
    await using (var request = Open())
        await Reject(() => Auth(request).SetInitialPasswordAsync(new InitialPasswordRequest
            { Login = login, Senha = "initial password", NewPassword = "initial password" }), "VALIDATION_ERROR");
    var shortRequest = new InitialPasswordRequest { Login = login, Senha = "initial password", NewPassword = "short" };
    Check(!Validator.TryValidateObject(shortRequest,
        new ValidationContext(shortRequest), new List<ValidationResult>(), true), "Short password accepted by request validation.");
    // Duas requisições concorrentes não podem substituir a senha uma da outra.
    async Task<bool> Change(string password)
    {
        await using var request = Open();
        try {
            await Auth(request).SetInitialPasswordAsync(new InitialPasswordRequest
                { Login = login, Senha = "initial password", NewPassword = password });
            return true;
        } catch (AppException error) when (error is UnauthorizedException or ConflictException) { return false; }
    }
    var changes = await Task.WhenAll(Change("chosen password one"), Change("chosen password two"));
    Check(changes.Count(item => item) == 1, "Concurrent initial-password requests both succeeded.");
    var chosen = changes[0] ? "chosen password one" : "chosen password two";
    context.ChangeTracker.Clear();
    user = await context.Usuarios.AsNoTracking().SingleAsync(item => item.Login == login);
    Check(!user.PasswordExpired && AccountPassword.Verify(user, chosen), "New password not persisted.");
    Check(!await context.RefreshSessions.AnyAsync(item => item.EmployeeId == id), "Password endpoint should not issue tokens.");
    await using (var request = Open())
        await Reject(async () => await Auth(request).AuthenticateAsync(new LoginRequest { Login = login, Senha = "initial password" }), "INVALID_CREDENTIALS");
    LoginResponse session;
    await using (var request = Open())
        session = await Auth(request).AuthenticateAsync(new LoginRequest { Login = login, Senha = chosen });
    Check(!string.IsNullOrEmpty(session.Token) && !string.IsNullOrEmpty(session.RefreshToken), "New password cannot log in.");
    await using (var request = Open())
        await Reject(() => Auth(request).SetInitialPasswordAsync(new InitialPasswordRequest
            { Login = login, Senha = chosen, NewPassword = "another password" }), "CONFLICT");
    // A renovação também precisa respeitar o bloqueio no servidor.
    await context.Usuarios.Where(item => item.Login == login).ExecuteUpdateAsync(setters => setters.SetProperty(item => item.PasswordExpired, true));
    await using (var request = Open())
        await Reject(async () => await Auth(request).RefreshAsync(session.RefreshToken), "INVALID_REFRESH_TOKEN");
    await context.Usuarios.Where(item => item.Login == login).ExecuteUpdateAsync(setters => setters.SetProperty(item => item.PasswordExpired, false));
    await using (var request = Open()) {
        var refreshed = await Auth(request).RefreshAsync(session.RefreshToken);
        Check(!string.IsNullOrEmpty(refreshed.Token), "Regular refresh failed.");
    }
    // As contas antigas continuam válidas e passam a armazenar hash após o login.
    await context.Usuarios.Where(item => item.Login == login).ExecuteUpdateAsync(setters => setters.SetProperty(item => item.Senha, "legacy password"));
    await using (var request = Open())
        await Auth(request).AuthenticateAsync(new LoginRequest { Login = login, Senha = "legacy password" });
    user = await context.Usuarios.AsNoTracking().SingleAsync(item => item.Login == login);
    Check(user.Senha != "legacy password" && AccountPassword.Verify(user, "legacy password"), "Legacy password migration failed.");
    Console.WriteLine("PASS: registration, atomicity, first-login restriction, password validation, concurrency, persistence, refresh blocking and legacy compatibility.");
}
finally
{
    var ids = context.Usuarios.Where(item => item.Login == login).Select(item => item.IdFuncionario);
    await context.Funcionarios.Where(item => ids.Contains(item.Id) || item.Nome == duplicateName).ExecuteDeleteAsync();
}
