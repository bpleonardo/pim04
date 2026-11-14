using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

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

        public async Task<MinAgendamentoDTO> GetOne(Guid id, Guid? employeeId)
        {
            return await _appointments.GetOne(id, employeeId)
                ?? throw new ResourceNotFoundException("Agendamento não encontrado.");
        }

        /// <summary>
        /// Creates a new appointment with auto-created client if needed, or throws ConflictException/ResourceNotFoundException.
        /// </summary>
        public async Task<AgendamentoResponseDTO> CreateOne(AgendamentoCreateDTO dto)
        {
            var requestHash = CreateRequestHash(dto);
            if (
                dto.ClientRequestId is not null
                && await _appointments.FindRequest(dto.ClientRequestId) is { } previous
            )
            {
                if (previous.RequestHash != requestHash)
                    throw new ConflictException(
                        "Identificador de sincronização já utilizado com outros dados."
                    );
                return ToResponse(await GetOne(previous.Id, null));
            }
            var scheduledAtUtc = ToUtc(dto.DataAgendamento);
            if (scheduledAtUtc <= BookingReferenceTime(dto))
            {
                throw new ValidationException("Escolha um horário futuro para o agendamento.");
            }

            if (
                dto.IdServicos is not { Length: > 0 }
                || dto.IdServicos.Distinct().Count() != dto.IdServicos.Length
            )
                throw new ValidationException("Selecione pelo menos um serviço, sem repetições.");
            if (!await _appointments.IsSlotAvailable(dto.IdFuncionario, scheduledAtUtc))
            {
                throw new ConflictException("Horário indisponível para o funcionário informado.");
            }

            await ValidateServices(dto.IdServicos!);

            var client = await CreateClient(dto);

            var appointmentId = await _appointments.CreateOne(
                client.Id,
                dto.IdFuncionario,
                scheduledAtUtc,
                dto.IdServicos ?? [],
                dto.ClientRequestId,
                requestHash
            );

            var createdAppointment =
                await _appointments.GetOne(appointmentId)
                ?? throw new ResourceNotFoundException("Agendamento não encontrado.");

            return ToResponse(createdAppointment);
        }

        private static string CreateRequestHash(AgendamentoCreateDTO dto) =>
            Convert.ToHexString(
                SHA256.HashData(Encoding.UTF8.GetBytes(JsonSerializer.Serialize(dto)))
            );

        private static DateTime ToUtc(DateTime value) =>
            value.Kind == DateTimeKind.Unspecified
                ? DateTime.SpecifyKind(value, DateTimeKind.Utc)
                : value.ToUniversalTime();

        private async Task ValidateServices(Guid[] serviceIds)
        {
            foreach (var serviceId in serviceIds)
            {
                var service =
                    await _services.GetOne(serviceId)
                    ?? throw new ResourceNotFoundException(
                        $"Serviço com ID '{serviceId}' não encontrado."
                    );

                if (!service.Ativo)
                    throw new ConflictException($"O serviço '{service.Nome}' está desabilitado.");
            }
        }

        private async Task<Cliente> CreateClient(AgendamentoCreateDTO dto)
        {
            var client = new Cliente(
                null,
                dto.NomeCliente,
                dto.TelefoneCliente,
                null,
                dto.EmailCliente,
                null
            );
            await _clients.CreateOne(
                new ClienteDTO(client.Id, client.Nome, client.Telefone ?? string.Empty, client.CPF, client.Email, null)
            );
            return client;
        }

        public static DateTime BookingReferenceTime(AgendamentoCreateDTO dto)
        {
            var now = DateTime.UtcNow;
            if (dto.RecordedAt is not { } recorded)
                return now;
            recorded = ToUtc(recorded);
            if (recorded > now.AddMinutes(5) || recorded < now.AddDays(-7))
                throw new ValidationException(
                    "A data de registro offline deve estar nos últimos sete dias. Confira o relógio do aparelho."
                );
            return recorded;
        }

        private static AgendamentoResponseDTO ToResponse(MinAgendamentoDTO appointment) =>
            new()
            {
                Id = appointment.Id,
                Revision = appointment.Revision,
                TelefoneCliente = appointment.Cliente.Telefone,
                ServiceIds = appointment.Servicos.Select(s => s.Id).ToArray(),
                NomeCliente = appointment.Cliente.Nome,
                NomeFuncionario = appointment.Funcionario.Nome,
                DataAgendamento = appointment.DataAgendamento,
                Status = appointment.Status,
                Total = appointment.Total,
                Servicos = appointment.Servicos.Select(s => s.Nome).ToArray(),
            };

        public async Task<MinAgendamentoDTO> Edit(
            Guid id,
            Guid employeeId,
            AgendamentoEditDTO dto,
            string? mutationId
        )
        {
            await _appointments.Edit(id, employeeId, dto, mutationId);
            return await GetOne(id, employeeId);
        }

        /// <summary>
        /// Updates appointment status or throws ValidationException/ResourceNotFoundException.
        /// </summary>
        public async Task UpdateStatus(
            Guid appointmentId,
            string status,
            Guid employeeId,
            long? expectedRevision = null,
            string? mutationId = null
        )
        {
            var validStatuses = new[] { "agendado", "concluido", "cancelado" };
            if (!validStatuses.Contains(status))
            {
                throw new ValidationException(
                    "Status inválido. Use: agendado, concluido ou cancelado."
                );
            }

            var updated = await _appointments.UpdateStatus(
                appointmentId,
                status,
                employeeId,
                expectedRevision,
                mutationId
            );
            if (updated)
                return;

            var appointment = await GetOne(appointmentId, employeeId);
            if (expectedRevision.HasValue && appointment.Revision != expectedRevision.Value)
                throw new ConflictException(
                    "O agendamento foi alterado no servidor. Confira o status atual."
                );
            if (appointment.Status != status)
                throw new ConflictException(
                    "O status atual do agendamento não permite essa alteração."
                );
        }
    }
}
