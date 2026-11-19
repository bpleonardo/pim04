using api.Models;
using Microsoft.AspNetCore.Identity;
using System.Security.Cryptography;
using System.Text;

namespace api.Utilities;

public static class AccountPassword
{
    private const string Prefix = "identity:";
    private static readonly PasswordHasher<Usuario> Hasher = new();

    public static string Hash(Usuario user, string password) => Prefix + Hasher.HashPassword(user, password);

    public static bool Verify(Usuario user, string password)
    {
        if (user.Senha.StartsWith(Prefix, StringComparison.Ordinal))
            return Hasher.VerifyHashedPassword(user, user.Senha[Prefix.Length..], password)
                != PasswordVerificationResult.Failed;

        // Compatibilidade com as contas legadas; as novas senhas são sempre armazenadas como hash.
        return CryptographicOperations.FixedTimeEquals(
            SHA256.HashData(Encoding.UTF8.GetBytes(user.Senha)),
            SHA256.HashData(Encoding.UTF8.GetBytes(password)));
    }
}
