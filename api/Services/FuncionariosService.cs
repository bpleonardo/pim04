using api.DTOs;
using api.Exceptions;
using api.Models;
using api.Repositories;

namespace api.Services
{
    public class FuncionariosService(FuncionariosRepository repo)
    {
        private readonly FuncionariosRepository _repo = repo;

        /// <summary>
        /// Retrieves all employees.
        /// </summary>
        public async Task<FuncionarioDTO[]> GetAll()
        {
            return await _repo.GetAll();
        }

        public Task<FuncionarioPublicoDTO[]> GetPublic() => _repo.GetPublic();

        public async Task CreateOne(FuncionarioCreateDTO dto)
        {
            var employee = new Funcionario(
                null,
                dto.Nome,
                dto.Telefone,
                dto.CPF ?? string.Empty,
                dto.Email ?? string.Empty,
                dto.Endereco
            );
            await _repo.CreateOne(new FuncionarioDTO(
                employee.Id, employee.Nome, employee.Telefone ?? string.Empty, employee.CPF,
                employee.Email, employee.Endereco));
        }

        /// <summary>
        /// Retrieves a single employee by id or throws ResourceNotFoundException.
        /// </summary>
        public async Task<FuncionarioDTO> GetOne(Guid id)
        {
            return await _repo.GetOne(id)
                ?? throw new ResourceNotFoundException("Funcionário não encontrado.");
        }

        /// <summary>
        /// Creates a new employee.
        /// </summary>
        public async Task UpdateOne(Guid id, FuncionarioCreateDTO dto)
        {
            if (!await _repo.UpdateOne(id, dto))
                throw new ResourceNotFoundException("Funcionário não encontrado ou já excluído.");
        }

        public async Task<bool> DeleteOne(Guid id)
        {
            var wasSoftDeleted = await _repo.DeleteOne(id);
            if (wasSoftDeleted is null)
                throw new ResourceNotFoundException("Funcionário não encontrado ou já excluído.");
            return wasSoftDeleted.Value;
        }
    }
}
