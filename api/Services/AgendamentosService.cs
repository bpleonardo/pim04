using api.DTOs;
using api.Models;
using api.Repositories;
using api.Utilities;

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

        public async Task<MinAgendamentoDTO[]> GetAll(DateOnly? date = null)
        {
            return await _agendamentosRepo.GetByDate(date ?? DateOnly.FromDateTime(DateTime.Now));
        }

        /// <summary>
        /// Create a new appointment with auto-creating cliente if needed.
        /// </summary>
        public async Task<Maybe<AgendamentoResponseDTO>> CreateOne(AgendamentoCreateDTO dto)
        {
            // 1. Validate slot availability
            var isAvailable = await _agendamentosRepo.IsSlotAvailable(dto.IdFuncionario, dto.DataAgendamento);
            if (!isAvailable)
            {
                return new Maybe<AgendamentoResponseDTO>(ErrorCodes.NotFound);
            }

            // 2. Find or create cliente
            Guid idCliente;
            var clienteExistente = await _clientesRepo.CheckCPF(string.Empty);
            // For now, always create a new cliente (in future, could search by telefone)
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
                if (!servico.HasValue)
                {
                    return new Maybe<AgendamentoResponseDTO>(ErrorCodes.NotFound);
                }

                servicosList.Add(servico.Value);
                total += servico.Value.Preco;
            }

            // 4. Create agendamento
            var agendamentoResult = await _agendamentosRepo.CreateOne(
                idCliente,
                dto.IdFuncionario,
                dto.DataAgendamento,
                total,
                dto.IdServicos ?? []
            );

            if (!agendamentoResult.HasValue)
            {
                return new Maybe<AgendamentoResponseDTO>(ErrorCodes.NotFound);
            }

            // 5. Fetch created agendamento and return
            var agendamento = await _agendamentosRepo.GetOne(agendamentoResult.Value);

            if (!agendamento.HasValue)
            {
                return new Maybe<AgendamentoResponseDTO>(ErrorCodes.NotFound);
            }

            var appt = agendamento.Value;
            var response = new AgendamentoResponseDTO
            {
                Id = appt.Id,
                NomeCliente = appt.Cliente.Nome,
                NomeFuncionario = appt.Funcionario.Nome,
                DataAgendamento = appt.DataAgendamento,
                Status = appt.Status,
                Total = appt.Total,
                Servicos = appt.Servicos.Select(s => s.Nome).ToArray(),
            };

            return new Maybe<AgendamentoResponseDTO>(response);
        }

        /// <summary>
        /// Update appointment status (agendado → concluido/cancelado).
        /// </summary>
        public async Task<Maybe<bool>> UpdateStatus(Guid agendamentoId, string novoStatus)
        {
            var validStatuses = new[] { "agendado", "concluido", "cancelado" };
            if (!validStatuses.Contains(novoStatus))
            {
                return new Maybe<bool>(ErrorCodes.NotFound);
            }

            return await _agendamentosRepo.UpdateStatus(agendamentoId, novoStatus);
        }
    }
}
