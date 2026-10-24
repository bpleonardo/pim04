using api.DTOs;
using api.Exceptions;
using api.Models;
using api.Repositories;

namespace api.Services
{
    public class ClientesService(ClientesRepository repo)
    {
        private readonly ClientesRepository _repo = repo;

        /// <summary>
        /// Retrieves all clients.
        /// </summary>
        public async Task<Cliente[]> GetAll()
        {
            var dbClientes = await _repo.GetAll();

            return
            [
                .. dbClientes.Select(c => new Cliente(
                    c.Id,
                    c.Nome,
                    c.Telefone,
                    c.Email,
                    c.CPF,
                    c.DtNascimento.HasValue ? DateOnly.FromDateTime(c.DtNascimento.Value) : null
                )),
            ];
        }

        /// <summary>
        /// Retrieves a single client by id or throws ResourceNotFoundException.
        /// </summary>
        public async Task<Cliente> GetOne(Guid id)
        {
            var result = await _repo.GetOne(id);

            if (result is null)
            {
                throw new ResourceNotFoundException("Cliente não encontrado.");
            }

            var c = result.Value;

            return new Cliente(
                c.Id,
                c.Nome,
                c.Telefone,
                c.Email,
                c.CPF,
                c.DtNascimento.HasValue ? DateOnly.FromDateTime(c.DtNascimento.Value) : null
            );
        }

        /// <summary>
        /// Creates a new client, throwing ConflictException if CPF already exists.
        /// </summary>
        public async Task CreateOne(ClienteCreateDTO dto)
        {
            if (!string.IsNullOrEmpty(dto.CPF))
            {
                var cpfExists = await _repo.CheckCPF(dto.CPF);

                if (cpfExists)
                {
                    throw new ConflictException("Já existe um cliente com este CPF.", "ALREADY_EXISTS");
                }
            }

            var newCliente = new Cliente(
                null,
                dto.Nome,
                dto.Telefone,
                dto.CPF,
                dto.Email,
                dto.DtNascimento
            );

            await _repo.CreateOne(
                new ClienteDTO(
                    newCliente.Id,
                    newCliente.Nome,
                    newCliente.Telefone,
                    newCliente.CPF,
                    newCliente.Email,
                    newCliente.DtNascimento.HasValue
                        ? newCliente.DtNascimento.Value.ToDateTime(new TimeOnly(0, 0))
                        : null
                )
            );
        }
    }
}
