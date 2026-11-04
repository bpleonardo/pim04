using api.Data;
using api.DTOs;
using api.Models;
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
                    f.Endereco
                ))
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
                    funcionario.Endereco
                );
            }

            return null;
        }

        /// <summary>
        /// Creates a new employee.
        /// </summary>
        public async Task<bool> CreateOne(FuncionarioDTO dto)
        {
            var entity = new Funcionario(
                dto.Id,
                dto.Nome,
                dto.Telefone,
                dto.CPF ?? string.Empty,
                dto.Email ?? string.Empty,
                dto.Endereco
            );

            await _context.Funcionarios.AddAsync(entity);
            await _context.SaveChangesAsync();

            return true;
        }
    }
}
