using api.Data;
using api.DTOs;
using api.Models;
using api.Utilities;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace api.Repositories
{
    /// <summary>
    /// Repository for service data operations using Entity Framework Core.
    /// </summary>
    public class ServicosRepository(AppDbContext context)
    {
        private readonly AppDbContext _context = context;

        /// <summary>
        /// Retrieves all services.
        /// </summary>
        public async Task<ServicoDTO[]> GetAll()
        {
            return await _context.Servicos
                .AsNoTracking()
                .Select(s => new ServicoDTO(s.Id, s.Nome, s.Descricao, s.Preco))
                .ToArrayAsync();
        }

        /// <summary>
        /// Retrieves a service by its unique identifier.
        /// </summary>
        public async Task<Maybe<ServicoDTO>> GetOne(Guid id)
        {
            var servico = await _context.Servicos
                .AsNoTracking()
                .FirstOrDefaultAsync(s => s.Id == id);

            if (servico != null)
            {
                return new Maybe<ServicoDTO>(
                    new ServicoDTO(servico.Id, servico.Nome, servico.Descricao, servico.Preco)
                );
            }

            return new Maybe<ServicoDTO>(ErrorCodes.NotFound);
        }

        /// <summary>
        /// Deletes a service by its unique identifier.
        /// </summary>
        public async Task<Maybe<bool>> DeleteOne(Guid id)
        {
            var servico = await _context.Servicos.FindAsync(id);
            if (servico == null)
            {
                return new Maybe<bool>(ErrorCodes.NotFound);
            }

            try
            {
                _context.Servicos.Remove(servico);
                await _context.SaveChangesAsync();
                return new Maybe<bool>(true);
            }
            catch (DbUpdateException ex) when (ex.InnerException is PostgresException pex && (pex.SqlState == "23001" || pex.SqlState == "23503"))
            {
                // restrict_violation / foreign_key_violation: O serviço está sendo referenciado por um agendamento.
                return new Maybe<bool>(ErrorCodes.CantModify);
            }
        }

        /// <summary>
        /// Creates a new service.
        /// </summary>
        public async Task<bool> CreateOne(ServicoDTO dto)
        {
            var entity = new Servico(dto.Id, dto.Nome, dto.Descricao, dto.Preco);

            await _context.Servicos.AddAsync(entity);
            await _context.SaveChangesAsync();

            return true;
        }

        /// <summary>
        /// Updates an existing service, optionally performing an upsert if requested.
        /// </summary>
        public async Task<bool> UpdateOne(ServicoDTO dto, bool upsert = false)
        {
            var existing = await _context.Servicos.FindAsync(dto.Id);

            if (existing != null)
            {
                existing.Nome = dto.Nome;
                existing.Descricao = dto.Descricao;
                existing.Preco = dto.Preco;

                await _context.SaveChangesAsync();
                return true;
            }

            if (upsert)
            {
                var newEntity = new Servico(dto.Id, dto.Nome, dto.Descricao, dto.Preco);
                await _context.Servicos.AddAsync(newEntity);
                await _context.SaveChangesAsync();
                return true;
            }

            return false;
        }
    }
}
