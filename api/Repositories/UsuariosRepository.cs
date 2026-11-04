using api.Data;
using Microsoft.EntityFrameworkCore;

namespace api.Repositories
{
    /// <summary>
    /// Repository for user credentials and authentication operations using Entity Framework Core.
    /// </summary>
    public class UsuariosRepository(AppDbContext context)
    {
        private readonly AppDbContext _context = context;

        /// <summary>
        /// Finds a user by login and password, returning employee data if verified or null if not found.
        /// </summary>
        public async Task<(Guid IdFuncionario, string NomeFuncionario, string Login)?> GetByLoginAndPassword(
            string login,
            string senha
        )
        {
            // Busca o usuário e os dados do funcionário associado em uma única consulta
            var user = await _context.Usuarios
                .AsNoTracking()
                .Include(u => u.Funcionario)
                .Where(u => u.Login == login && u.Senha == senha)
                .Select(u => new
                {
                    u.IdFuncionario,
                    NomeFuncionario = u.Funcionario.Nome,
                    u.Login
                })
                .FirstOrDefaultAsync();

            if (user != null)
            {
                return (user.IdFuncionario, user.NomeFuncionario, user.Login);
            }

            return null;
        }
    }
}
