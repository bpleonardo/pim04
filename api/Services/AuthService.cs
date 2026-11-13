using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using api.DTOs;
using api.Data;
using api.Models;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;
using System.Text;
using api.Exceptions;
using api.Repositories;
using Microsoft.IdentityModel.Tokens;

namespace api.Services
{
    public class AuthService(UsuariosRepository repo, IConfiguration config, SymmetricSecurityKey signingKey, AppDbContext db)
    {
        private readonly UsuariosRepository _repo = repo;
        private readonly IConfiguration _config = config;

        /// <summary>
        /// Authenticates a user with login and password, returning authentication response or throwing UnauthorizedException.
        /// </summary>
        public async Task<LoginResponse> AuthenticateAsync(LoginRequest request)
        {
            var result =
                await _repo.GetByLoginAndPassword(request.Login, request.Senha)
                ?? throw new UnauthorizedException(
                    "Login ou senha inválidos.",
                    "INVALID_CREDENTIALS"
                );

            var (employeeId, employeeName, login) = result;

            var response = Issue(employeeId, login, employeeName);
            await db.SaveChangesAsync();
            return response;
        }

        public async Task<LoginResponse> RefreshAsync(string token)
        {
            var id = ReadRefreshId(token);
            await using var transaction = await db.Database.BeginTransactionAsync();
            var session = await db.RefreshSessions.AsNoTracking()
                .Include(item => item.User.Funcionario)
                .SingleOrDefaultAsync(item => item.Jti == id && item.ExpiresAt > DateTime.UtcNow);
            if (session == null || await Revoke(id) != 1) throw InvalidRefresh();

            var response = Issue(session.EmployeeId, session.User.Login, session.User.Funcionario.Nome);
            await db.SaveChangesAsync();
            await transaction.CommitAsync();
            return response;
        }

        public async Task LogoutAsync(string token) => await Revoke(ReadRefreshId(token));

        private Task<int> Revoke(Guid id) =>
            db.RefreshSessions.Where(item => item.Jti == id).ExecuteDeleteAsync();

        private string Issuer => _config["Jwt:Issuer"] ?? "api";

        private SymmetricSecurityKey RefreshKey => new(HMACSHA256.HashData(
            signingKey.Key, Encoding.UTF8.GetBytes("barbershop-refresh-token")));

        private static UnauthorizedException InvalidRefresh() =>
            new("Sessão expirada. Entre novamente.", "INVALID_REFRESH_TOKEN");

        private Guid ReadRefreshId(string token)
        {
            try
            {
                var handler = new JwtSecurityTokenHandler { MapInboundClaims = false };
                var principal = handler.ValidateToken(token, new TokenValidationParameters
                {
                    IssuerSigningKey = RefreshKey,
                    ValidateIssuerSigningKey = true,
                    ValidIssuer = Issuer,
                    ValidAudience = Issuer,
                    ClockSkew = TimeSpan.Zero,
                    ValidAlgorithms = [SecurityAlgorithms.HmacSha256],
                }, out _);
                return Guid.TryParse(principal.FindFirstValue(JwtRegisteredClaimNames.Jti), out var id)
                    ? id : throw InvalidRefresh();
            }
            catch (Exception ex) when (ex is SecurityTokenException or ArgumentException)
            {
                throw InvalidRefresh();
            }
        }

        private LoginResponse Issue(Guid employeeId, string login, string name)
        {
            var now = DateTime.UtcNow;
            var id = Guid.NewGuid();
            var expiration = now.AddDays(7);
            db.RefreshSessions.Add(new RefreshSession { Jti = id, EmployeeId = employeeId, ExpiresAt = expiration });
            var refresh = new JwtSecurityToken(
                issuer: Issuer, audience: Issuer,
                claims: [
                    new Claim(JwtRegisteredClaimNames.Jti, id.ToString()),
                    new Claim(JwtRegisteredClaimNames.Iat, EpochTime.GetIntDate(now).ToString(), ClaimValueTypes.Integer64),
                ],
                notBefore: now, expires: expiration,
                signingCredentials: new SigningCredentials(RefreshKey, SecurityAlgorithms.HmacSha256));
            return new LoginResponse
            {
                Token = GenerateJwtToken(employeeId, login, name),
                RefreshToken = new JwtSecurityTokenHandler().WriteToken(refresh),
                User = new AuthUser { Id = employeeId, Nome = name, Login = login },
            };
        }

        private string GenerateJwtToken(Guid userId, string login, string name)
        {
            var jwtIssuer = _config["Jwt:Issuer"] ?? "api";
            var jwtAudience = _config["Jwt:Audience"] ?? "client";
            var jwtExpirationMinutes = int.TryParse(_config["Jwt:ExpirationMinutes"], out var exp)
                ? exp
                : 60;

            var credentials = new SigningCredentials(signingKey, SecurityAlgorithms.HmacSha256);

            var claims = new[]
            {
                new Claim(ClaimTypes.NameIdentifier, userId.ToString()),
                new Claim(ClaimTypes.Name, login),
                new Claim("full_name", name),
                new Claim(ClaimTypes.Role, "staff"),
            };

            var token = new JwtSecurityToken(
                issuer: jwtIssuer,
                audience: jwtAudience,
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(jwtExpirationMinutes),
                signingCredentials: credentials
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}
