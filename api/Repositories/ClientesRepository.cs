using api.Data;
using api.DTOs;
using api.Models;
using api.Utilities;
using Microsoft.EntityFrameworkCore;

namespace api.Repositories
{
    /// <summary>
    /// Repository for client data operations using Entity Framework Core.
    /// </summary>
    public class ClientesRepository(AppDbContext context)
    {
        private readonly AppDbContext _context = context;

        /// <summary>
        /// Retrieves all clients.
        /// </summary>
        public async Task<ClienteDTO[]> GetAll()
        {
            // Consulta todos os clientes sem rastreamento para otimizar leitura
            return await _context.Clientes
                .AsNoTracking()
                .Select(c => new ClienteDTO(
                    c.Id,
                    c.Nome,
                    c.Telefone ?? string.Empty,
                    c.CPF,
                    c.Email,
                    c.DtNascimento.HasValue
                        ? c.DtNascimento.Value.ToDateTime(TimeOnly.MinValue)
                        : null
                ))
                .ToArrayAsync();
        }

        /// <summary>
        /// Retrieves a client by its unique identifier.
        /// </summary>
        public async Task<Maybe<ClienteDTO>> GetOne(Guid id)
        {
            var cliente = await _context.Clientes
                .AsNoTracking()
                .FirstOrDefaultAsync(c => c.Id == id);

            if (cliente != null)
            {
                return new Maybe<ClienteDTO>(
                    new ClienteDTO(
                        cliente.Id,
                        cliente.Nome,
                        cliente.Telefone ?? string.Empty,
                        cliente.CPF,
                        cliente.Email,
                        cliente.DtNascimento.HasValue
                            ? cliente.DtNascimento.Value.ToDateTime(TimeOnly.MinValue)
                            : null
                    )
                );
            }

            return new Maybe<ClienteDTO>(ErrorCodes.NotFound);
        }

        /// <summary>
        /// Creates a new client in the database.
        /// </summary>
        public async Task<bool> CreateOne(ClienteDTO dto)
        {
            var entity = new Cliente(
                dto.Id,
                dto.Nome,
                dto.Telefone,
                dto.CPF,
                dto.Email,
                dto.DtNascimento.HasValue
                    ? DateOnly.FromDateTime(dto.DtNascimento.Value)
                    : null
            );

            await _context.Clientes.AddAsync(entity);
            await _context.SaveChangesAsync();

            return true;
        }

        /// <summary>
        /// Checks whether a client with the specified CPF already exists.
        /// </summary>
        public async Task<bool> CheckCPF(string cpf)
        {
            // Retorna true se houver qualquer cliente com o CPF informado
            return await _context.Clientes.AnyAsync(c => c.CPF == cpf);
        }
    }
}
