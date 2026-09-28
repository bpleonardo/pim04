using api.Models;
using Microsoft.EntityFrameworkCore;

namespace api.Data
{
    /// <summary>
    /// Database context for the application using Entity Framework Core.
    /// </summary>
    public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
    {
        public DbSet<Cliente> Clientes => Set<Cliente>();
        public DbSet<Funcionario> Funcionarios => Set<Funcionario>();
        public DbSet<Usuario> Usuarios => Set<Usuario>();
        public DbSet<Servico> Servicos => Set<Servico>();
        public DbSet<Agendamento> Agendamentos => Set<Agendamento>();
        public DbSet<ServicoRealizado> ServicosRealizados => Set<ServicoRealizado>();
    }
}
