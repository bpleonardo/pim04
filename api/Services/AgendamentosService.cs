using api.DTOs;
using api.Exceptions;
using api.Models;
using api.Repositories;

namespace api.Services
{
    public class AgendamentosService(
        AgendamentosRepository appointmentRepository,
        ClientesRepository clientRepository,
        ServicosRepository serviceRepository
    )
    {
        private readonly AgendamentosRepository _appointments = appointmentRepository;
        private readonly ClientesRepository _clients = clientRepository;
        private readonly ServicosRepository _services = serviceRepository;

        public Task<MinAgendamentoDTO[]> GetAll(DateOnly? date, Guid? employeeId)
        {
            var timeZone = TimeZoneInfo.FindSystemTimeZoneById("America/Sao_Paulo");
            var localNow = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, timeZone);
            return _appointments.GetByDate(date ?? DateOnly.FromDateTime(localNow), employeeId);
        }

        public async Task<MinAgendamentoDTO> GetOne(Guid id, Guid? employeeId) =>
            await _appointments.GetOne(id, employeeId)
            ?? throw new ResourceNotFoundException("Agendamento não encontrado.");

        /// <summary>
        /// Creates a new appointment with auto-created client if needed, or throws ConflictException/ResourceNotFoundException.
        /// </summary>
        public async Task<AgendamentoResponseDTO> CreateOne(AgendamentoCreateDTO dto)
        {
            var scheduledAtUtc = dto.DataAgendamento.Kind == DateTimeKind.Unspecified
                ? DateTime.SpecifyKind(dto.DataAgendamento, DateTimeKind.Utc)
                : dto.DataAgendamento.ToUniversalTime();
            if (scheduledAtUtc <= DateTime.UtcNow)
            {
                throw new ValidationException("Escolha um horário futuro para o agendamento.");
            }

            // 1. Validate slot availability
            var isAvailable = await _appointments.IsSlotAvailable(
                dto.IdFuncionario,
                scheduledAtUtc
            );
            if (!isAvailable)
            {
                throw new ConflictException("Horário indisponível para o funcionário informado.");
            }

            // 2. Find or create cliente
            Guid clientId;
            var existingClient = await _clients.CheckCPF(string.Empty);
            // Por enquanto sempre cria um novo cliente
            {
                var newClient = new Cliente(
                    null,
                    dto.NomeCliente,
                    dto.TelefoneCliente,
                    null,
                    dto.EmailCliente,
                    null
                );

                await _clients.CreateOne(
                    new ClienteDTO(
                        newClient.Id,
                        newClient.Nome,
                        newClient.Telefone ?? string.Empty,
                        newClient.CPF,
                        newClient.Email,
                        newClient.DtNascimento.HasValue
                            ? newClient.DtNascimento.Value.ToDateTime(new TimeOnly(0, 0))
                            : null
                    )
                );

                clientId = newClient.Id;
            }

            // 3. Calculate total from services
            var selectedServices = new List<ServicoDTO>();
            double total = 0;

            foreach (var serviceId in dto.IdServicos ?? [])
            {
                var service =
                    await _services.GetOne(serviceId)
                    ?? throw new ResourceNotFoundException(
                        $"Serviço com ID '{serviceId}' não encontrado."
                    );

                if (!service.Ativo)
                    throw new ConflictException($"O serviço '{service.Nome}' está desabilitado.");

                selectedServices.Add(service);
                total += service.Preco;
            }

            // 4. Create appointment
            var appointmentId = await _appointments.CreateOne(
                clientId,
                dto.IdFuncionario,
                scheduledAtUtc,
                total,
                dto.IdServicos ?? []
            );

            // 5. Fetch created appointment and return
            var createdAppointment =
                await _appointments.GetOne(appointmentId)
                ?? throw new ResourceNotFoundException("Agendamento não encontrado.");

            return new AgendamentoResponseDTO
            {
                Id = createdAppointment.Id,
                NomeCliente = createdAppointment.Cliente.Nome,
                NomeFuncionario = createdAppointment.Funcionario.Nome,
                DataAgendamento = createdAppointment.DataAgendamento,
                Status = createdAppointment.Status,
                Total = createdAppointment.Total,
                Servicos = createdAppointment.Servicos.Select(s => s.Nome).ToArray(),
            };
        }

        /// <summary>
        /// Updates appointment status or throws ValidationException/ResourceNotFoundException.
        /// </summary>
        public async Task UpdateStatus(Guid appointmentId, string status, Guid employeeId)
        {
            var validStatuses = new[] { "agendado", "concluido", "cancelado" };
            if (!validStatuses.Contains(status))
            {
                throw new ValidationException(
                    "Status inválido. Use: agendado, concluido ou cancelado."
                );
            }

            var updated = await _appointments.UpdateStatus(appointmentId, status, employeeId);
            if (updated) return;

            var appointment = await GetOne(appointmentId, employeeId);
            if (appointment.Status != status)
                throw new ConflictException("O status atual do agendamento não permite essa alteração.");
        }
    }
}
