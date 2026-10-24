using api.DTOs;
using api.Exceptions;
using api.Models;
using api.Repositories;

namespace api.Services
{
    public class AgendamentosService(
        AgendamentosRepository agendamentosRepo,
        ClientesRepository clientesRepo,
        ServicosRepository servicosRepo,
        HorariosRepository horariosRepo
    )
    {
        private readonly AgendamentosRepository _agendamentosRepo = agendamentosRepo;
        private readonly ClientesRepository _clientesRepo = clientesRepo;
        private readonly ServicosRepository _servicosRepo = servicosRepo;
        private readonly HorariosRepository _horariosRepo = horariosRepo;

        /// <summary>
        /// Retrieves all appointments for the specified date (or today if null).
        /// </summary>
        public async Task<MinAgendamentoDTO[]> GetAll(DateOnly? date = null)
        {
            return await _agendamentosRepo.GetByDate(date ?? DateOnly.FromDateTime(DateTime.Now));
        }

        /// <summary>
        /// Creates a new appointment with auto-created client if needed, or throws ConflictException/ResourceNotFoundException.
        /// </summary>
        public async Task<AgendamentoResponseDTO> CreateOne(AgendamentoCreateDTO dto)
        {
            // 1. Validate slot availability
            var isAvailable = await _agendamentosRepo.IsSlotAvailable(dto.IdFuncionario, dto.DataAgendamento);
            if (!isAvailable)
            {
                throw new ConflictException("Horário indisponível para o funcionário informado.");
            }

            // 2. Find or create cliente
            Guid idCliente;
            var clienteExistente = await _clientesRepo.CheckCPF(string.Empty);
            // Por enquanto sempre cria um novo cliente
            {
                var novoCliente = new Cliente(
                    null,
                    dto.NomeCliente,
                    dto.TelefoneCliente,
                    null,
                    dto.EmailCliente,
                    null
                );

                await _clientesRepo.CreateOne(
                    new ClienteDTO(
                        novoCliente.Id,
                        novoCliente.Nome,
                        novoCliente.Telefone,
                        novoCliente.CPF,
                        novoCliente.Email,
                        novoCliente.DtNascimento.HasValue
                            ? novoCliente.DtNascimento.Value.ToDateTime(new TimeOnly(0, 0))
                            : null
                    )
                );

                idCliente = novoCliente.Id;
            }

            // 3. Calculate total from services
            var servicosList = new List<ServicoDTO>();
            double total = 0;

            foreach (var idServico in dto.IdServicos ?? [])
            {
                var servico = await _servicosRepo.GetOne(idServico);
                if (servico is null)
                {
                    throw new ResourceNotFoundException($"Serviço com ID '{idServico}' não encontrado.");
                }

                servicosList.Add(servico.Value);
                total += servico.Value.Preco;
            }

            // 4. Create agendamento
            var agendamentoId = await _agendamentosRepo.CreateOne(
                idCliente,
                dto.IdFuncionario,
                dto.DataAgendamento,
                total,
                dto.IdServicos ?? []
            );

            // 5. Fetch created agendamento and return
            var agendamento = await _agendamentosRepo.GetOne(agendamentoId);

            if (agendamento is null)
            {
                throw new ResourceNotFoundException("Agendamento não encontrado.");
            }

            var appt = agendamento.Value;
            return new AgendamentoResponseDTO
            {
                Id = appt.Id,
                NomeCliente = appt.Cliente.Nome,
                NomeFuncionario = appt.Funcionario.Nome,
                DataAgendamento = appt.DataAgendamento,
                Status = appt.Status,
                Total = appt.Total,
                Servicos = appt.Servicos.Select(s => s.Nome).ToArray(),
            };
        }

        /// <summary>
        /// Updates appointment status or throws ValidationException/ResourceNotFoundException.
        /// </summary>
        public async Task UpdateStatus(Guid agendamentoId, string novoStatus)
        {
            var validStatuses = new[] { "agendado", "concluido", "cancelado" };
            if (!validStatuses.Contains(novoStatus))
            {
                throw new ValidationException("Status inválido. Use: agendado, concluido ou cancelado.");
            }

            var updated = await _agendamentosRepo.UpdateStatus(agendamentoId, novoStatus);
            if (!updated)
            {
                throw new ResourceNotFoundException("Agendamento não encontrado.");
            }
        }
    }
}
