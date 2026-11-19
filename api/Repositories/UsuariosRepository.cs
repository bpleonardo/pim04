using api.Data;
using api.Models;
using api.Utilities;
using Microsoft.EntityFrameworkCore;

namespace api.Repositories
{
    public class UsuariosRepository(AppDbContext context)
    {
        public async Task<Usuario?> GetByLoginAndPassword(string login, string password)
        {
            var user = await context.Usuarios.Include(item => item.Funcionario)
                .SingleOrDefaultAsync(item => item.Login == login && !item.Funcionario.IsDeleted);
            return user != null && AccountPassword.Verify(user, password) ? user : null;
        }
    }
}
