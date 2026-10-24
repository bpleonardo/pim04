using api.DTOs;
using api.Exceptions;
using api.Models;
using api.Repositories;

namespace api.Services
{
    public class ServicosService(ServicosRepository repo)
    {
        private readonly ServicosRepository _repo = repo;

        /// <summary>
        /// Retrieves all services.
        /// </summary>
        public async Task<Servico[]> GetAll()
        {
            var dbServicos = await _repo.GetAll();

            return [.. dbServicos.Select(s => new Servico(s.Id, s.Nome, s.Descricao, s.Preco))];
        }

        /// <summary>
        /// Retrieves a single service by id or throws ResourceNotFoundException.
        /// </summary>
        public async Task<Servico> GetOne(Guid id)
        {
            var result = await _repo.GetOne(id);

            if (result is null)
            {
                throw new ResourceNotFoundException("Serviço não encontrado.");
            }

            var service = result.Value;

            return new Servico(service.Id, service.Nome, service.Descricao, service.Preco);
        }

        /// <summary>
        /// Deletes a service by id or throws ResourceNotFoundException/ConflictException.
        /// </summary>
        public async Task DeleteOne(Guid id)
        {
            await _repo.DeleteOne(id);
        }

        /// <summary>
        /// Creates a new service.
        /// </summary>
        public async Task CreateOne(ServicoCreateDTO dto)
        {
            var newServico = new Servico(null, dto.Nome, dto.Descricao, dto.Preco);

            await _repo.CreateOne(
                new ServicoDTO(
                    newServico.Id,
                    newServico.Nome,
                    newServico.Descricao,
                    newServico.Preco
                )
            );
        }

        /// <summary>
        /// Updates fields of an existing service or throws ResourceNotFoundException.
        /// </summary>
        public async Task UpdateOne(Guid id, ServicoUpdateDTO dto)
        {
            var existingResult = await _repo.GetOne(id);

            if (existingResult is null)
            {
                throw new ResourceNotFoundException("Serviço não encontrado.");
            }

            var existing = existingResult.Value;

            var updatedServico = new ServicoDTO(
                id,
                dto.Nome ?? existing.Nome,
                dto.Descricao ?? existing.Descricao,
                dto.Preco ?? existing.Preco
            );

            var updateResult = await _repo.UpdateOne(updatedServico);

            if (!updateResult)
            {
                throw new ResourceNotFoundException("Serviço não encontrado.");
            }
        }

        /// <summary>
        /// Replaces an existing service or throws ResourceNotFoundException.
        /// </summary>
        public async Task ReplaceOne(Guid id, ServicoCreateDTO dto)
        {
            var updated = await _repo.UpdateOne(
                new ServicoDTO(id, dto.Nome, dto.Descricao, dto.Preco)
            );

            if (!updated)
            {
                throw new ResourceNotFoundException("Serviço não encontrado.");
            }
        }
    }
}
