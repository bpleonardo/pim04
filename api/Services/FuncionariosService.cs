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

        /// <summary>
        /// Retrieves a single employee by id or throws ResourceNotFoundException.
        /// </summary>
        public async Task<FuncionarioDTO> GetOne(Guid id)
        {
            var funcionario = await _repo.GetOne(id);

            if (funcionario is null)
            {
                throw new ResourceNotFoundException("Funcionário não encontrado.");
            }

            return funcionario.Value;
        }

        /// <summary>
        /// Creates a new employee.
        /// </summary>
        public async Task CreateOne(FuncionarioCreateDTO dto)
        {
            var newFuncionario = new Funcionario(
                null,
                dto.Nome,
                dto.Telefone,
                dto.CPF,
                dto.Email,
                dto.Endereco
            );

            await _repo.CreateOne(
                new FuncionarioDTO(
                    newFuncionario.Id,
                    newFuncionario.Nome,
                    newFuncionario.Telefone,
                    newFuncionario.CPF,
                    newFuncionario.Email,
                    newFuncionario.Endereco
                )
            );
        }
    }
}
