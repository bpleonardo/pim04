using api.Data;
using api.DTOs;
using api.Models;
using api.Exceptions;
using api.Utilities;
using Npgsql;
using Microsoft.EntityFrameworkCore;

namespace api.Repositories
{
    /// <summary>
    /// Repository for employee data operations using Entity Framework Core.
    /// </summary>
    public class FuncionariosRepository(AppDbContext context)
    {
        private readonly AppDbContext _context = context;

        /// <summary>
        /// Retrieves all employees ordered by name.
        /// </summary>
        public async Task<FuncionarioDTO[]> GetAll()
        {
            // Ordena por nome conforme contrato do repositório original
            return await _context.Funcionarios
                .AsNoTracking()
                .OrderBy(f => f.Nome)
                .Select(f => new FuncionarioDTO(
                    f.Id,
                    f.Nome,
                    f.Telefone ?? string.Empty,
                    f.CPF,
                    f.Email,
                    f.Endereco,
                    f.IsDeleted
                ))
                .ToArrayAsync();
        }

        public async Task<FuncionarioPublicoDTO[]> GetPublic()
        {
            return await _context.Funcionarios
                .AsNoTracking()
                .OrderBy(f => f.Nome)
                .Select(f => new FuncionarioPublicoDTO(f.Id, f.Nome, f.IsDeleted))
                .ToArrayAsync();
        }

        /// <summary>
        /// Retrieves an employee by their unique identifier or null if not found.
        /// </summary>
        public async Task<FuncionarioDTO?> GetOne(Guid id)
        {
            var funcionario = await _context.Funcionarios
                .AsNoTracking()
                .FirstOrDefaultAsync(f => f.Id == id);

            if (funcionario != null)
            {
                return new FuncionarioDTO(
                    funcionario.Id,
                    funcionario.Nome,
                    funcionario.Telefone ?? string.Empty,
                    funcionario.CPF,
                    funcionario.Email,
                    funcionario.Endereco,
                    funcionario.IsDeleted
                );
            }

            return null;
        }

        /// <summary>
        /// Creates a new employee.
        /// </summary>
        public async Task<bool> CreateOne(FuncionarioDTO dto, string login, string initialPassword)
        {
            var entity = new Funcionario(
                dto.Id,
                dto.Nome,
                dto.Telefone,
                dto.CPF,
                dto.Email,
                dto.Endereco ?? string.Empty
            );

            var user = new Usuario(entity.Id, login, string.Empty) { PasswordExpired = true, Funcionario = entity };
            user.Senha = AccountPassword.Hash(user, initialPassword);
            _context.Usuarios.Add(user);
            try
            {
                // Funcionário e credenciais são persistidos na mesma transação do SaveChanges.
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException error) when (error.InnerException is PostgresException
                { SqlState: PostgresErrorCodes.UniqueViolation, ConstraintName: "IX_Usuarios_Login" })
            {
                throw new ConflictException("Esse login já está em uso. Escolha outro.", "LOGIN_ALREADY_EXISTS");
            }

            return true;
        }

        public async Task<bool> UpdateOne(Guid id, FuncionarioCreateDTO dto)
        {
            var employee = await _context.Funcionarios.FindAsync(id);
            if (employee is null || employee.IsDeleted)
                return false;

            employee.Nome = dto.Nome;
            employee.Telefone = dto.Telefone;
            employee.CPF = dto.CPF;
            employee.Email = dto.Email;
            employee.Endereco = dto.Endereco;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool?> DeleteOne(Guid id)
        {
            await using var transaction = await _context.Database.BeginTransactionAsync();
            var employee = await _context.Funcionarios
                .Include(item => item.Agendamentos)
                .Include(item => item.Usuario)
                .SingleOrDefaultAsync(item => item.Id == id);
            if (employee is null || employee.IsDeleted)
                return null;

            if (employee.Agendamentos.Count == 0)
            {
                _context.Funcionarios.Remove(employee);
            }
            else
            {
                employee.Telefone = null;
                employee.CPF = null;
                employee.Email = null;
                employee.Endereco = null;
                employee.IsDeleted = true;
                if (employee.Usuario is not null)
                    _context.Usuarios.Remove(employee.Usuario);
            }

            await _context.SaveChangesAsync();
            await transaction.CommitAsync();
            return employee.IsDeleted;
        }
    }
}
