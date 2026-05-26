using api.DTOs;
using api.Models;
using api.Repositories;
using api.Utilities;

namespace api.Services
{
    public class FuncionariosService(FuncionariosRepository repo)
    {
        private readonly FuncionariosRepository _repo = repo;

        public async Task<FuncionarioDTO[]> GetAll()
        {
            return await _repo.GetAll();
        }

        public async Task<FuncionarioDTO?> GetOne(Guid id)
        {
            var result = await _repo.GetOne(id);

            if (!result.HasValue)
            {
                return null;
            }

            return result.Value;
        }

        public async Task<Maybe<bool>> CreateOne(FuncionarioCreateDTO dto)
        {
            var newFuncionario = new Funcionario(
                null,
                dto.Nome,
                dto.Telefone,
                dto.CPF,
                dto.Email,
                dto.Endereco
            );

            var created = await _repo.CreateOne(
                new FuncionarioDTO(
                    newFuncionario.Id,
                    newFuncionario.Nome,
                    newFuncionario.Telefone,
                    newFuncionario.CPF,
                    newFuncionario.Email,
                    newFuncionario.Endereco
                )
            );

            if (created)
            {
                return new Maybe<bool>(true);
            }

            // TODO: Better error handling
            throw new Exception("Erro ao criar funcionário.");
        }
    }
}
