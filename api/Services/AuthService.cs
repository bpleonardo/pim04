using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using api.DTOs;
using api.Repositories;
using api.Utilities;
using Microsoft.IdentityModel.Tokens;

namespace api.Services
{
    public class AuthService(UsuariosRepository repo, IConfiguration config)
    {
        private readonly UsuariosRepository _repo = repo;
        private readonly IConfiguration _config = config;

        public async Task<Maybe<LoginResponse>> AuthenticateAsync(LoginRequest request)
        {
            var result = await _repo.GetByLoginAndPassword(request.Login, request.Senha);

            if (!result.HasValue)
            {
                return new Maybe<LoginResponse>(ErrorCodes.NotFound);
            }

            var (idFuncionario, nomeFuncionario, login) = result.Value;

            var token = GenerateJwtToken(idFuncionario, login, nomeFuncionario);

            var response = new LoginResponse
            {
                Token = token,
                User = new AuthUser
                {
                    Id = idFuncionario,
                    Nome = nomeFuncionario,
                    Login = login,
                }
            };

            return new Maybe<LoginResponse>(response);
        }

        private string GenerateJwtToken(Guid userId, string login, string nome)
        {
            var jwtKey = _config["Jwt:Key"] ?? "your-secret-key-change-in-production";
            var jwtIssuer = _config["Jwt:Issuer"] ?? "api";
            var jwtAudience = _config["Jwt:Audience"] ?? "client";
            var jwtExpirationMinutes = int.TryParse(_config["Jwt:ExpirationMinutes"], out var exp) ? exp : 60;

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
            var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var claims = new[]
            {
                new Claim(ClaimTypes.NameIdentifier, userId.ToString()),
                new Claim(ClaimTypes.Name, login),
                new Claim("full_name", nome),
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
