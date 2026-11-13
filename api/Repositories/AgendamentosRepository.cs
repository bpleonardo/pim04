using api.Data;
using api.DTOs;
using api.Exceptions;
using api.Models;
using Microsoft.EntityFrameworkCore;

namespace api.Repositories
{
    /// <summary>
    /// Repository for appointment data operations using Entity Framework Core.
    /// </summary>
    public class AgendamentosRepository(AppDbContext context)
    {
        private readonly AppDbContext _context = context;

        /// <summary>
        /// Retrieves all appointments for a given date in the America/Sao_Paulo timezone.
        /// </summary>
        public async Task<MinAgendamentoDTO[]> GetByDate(DateOnly date, Guid? employeeId = null)
        {
            // Converte a data local de São Paulo para o intervalo correspondente em UTC
            var tz = TimeZoneInfo.FindSystemTimeZoneById("America/Sao_Paulo");
            var startLocal = date.ToDateTime(new TimeOnly(0, 0, 0), DateTimeKind.Unspecified);
            var startUtc = TimeZoneInfo.ConvertTimeToUtc(startLocal, tz);
            var endUtc = startUtc.AddDays(1);

            // Carrega agendamentos e relacionamentos em uma única consulta, eliminando o problema de N+1
            var appointments = await _context.Agendamentos
                .AsNoTracking()
                .Include(a => a.Cliente)
                .Include(a => a.Funcionario)
                .Include(a => a.ServicosRealizados)
                    .ThenInclude(sr => sr.Servico)
                .Where(a => a.DataAgendamento >= startUtc && a.DataAgendamento < endUtc)
                .Where(a => !employeeId.HasValue || a.IdFuncionario == employeeId.Value)
                .OrderBy(a => a.DataAgendamento)
                .ToListAsync();

            return appointments.Select(a => new MinAgendamentoDTO(
                a.Id,
                a.DataAgendamento,
                a.Status,
                a.ValorTotal ?? 0,
                a.ServicosRealizados
                    .Select(sr => new ServicoDTO(
                        sr.Servico.Id,
                        sr.Servico.Nome,
                        sr.Servico.Descricao,
                        sr.Servico.Preco,
                        sr.Servico.Ativo
                    ))
                    .ToArray(),
                new MinClienteDTO(a.Cliente.Nome, a.Cliente.Telefone ?? string.Empty),
                new MinFuncionarioDTO(a.Funcionario.Id, a.Funcionario.Nome)
            )).ToArray();
        }

        public async Task<bool> IsSlotAvailable(Guid employeeId, DateTime dateTime)
        {
            var dateTimeUtc = dateTime.Kind == DateTimeKind.Unspecified
                ? DateTime.SpecifyKind(dateTime, DateTimeKind.Utc)
                : dateTime.ToUniversalTime();

            // Retorna true se não houver agendamento ativo no mesmo horário para o funcionário
            var isBusy = await _context.Agendamentos
                .AnyAsync(a =>
                    a.IdFuncionario == employeeId
                    && a.DataAgendamento == dateTimeUtc
                    && a.Status == "agendado"
                );

            return !isBusy;
        }

        /// <summary>
        /// Creates a new appointment and its associated services in a single transaction.
        /// </summary>
        public async Task<Guid> CreateOne(
            Guid clientId,
            Guid employeeId,
            DateTime scheduledAt,
            double total,
            Guid[] serviceIds
        )
        {
            await using var transaction = await _context.Database.BeginTransactionAsync();
            // Mantém o estado dos serviços estável até gravar o agendamento.
            var services = await _context.Servicos
                .FromSql($"SELECT * FROM \"Servicos\" WHERE \"Id\" = ANY ({serviceIds}) ORDER BY \"Id\" FOR SHARE")
                .AsNoTracking()
                .ToListAsync();

            // Valida se todos os serviços existem no banco
            if (services.Count != serviceIds.Distinct().Count())
            {
                throw new ResourceNotFoundException("Um ou mais serviços informados não foram encontrados.");
            }

            if (services.Any(service => !service.Ativo))
            {
                throw new ConflictException("Um dos serviços selecionados está desabilitado.");
            }

            var appointmentId = Guid.NewGuid();
            var appointment = new Agendamento
            {
                Id = appointmentId,
                IdCliente = clientId,
                IdFuncionario = employeeId,
                DataAgendamento = scheduledAt.Kind == DateTimeKind.Unspecified
                    ? DateTime.SpecifyKind(scheduledAt, DateTimeKind.Utc)
                    : scheduledAt.ToUniversalTime(),
                Status = "agendado",
                ValorTotal = total,
            };

            foreach (var serviceId in serviceIds)
            {
                var service = services.First(s => s.Id == serviceId);
                appointment.ServicosRealizados.Add(new ServicoRealizado
                {
                    IdAgendamento = appointmentId,
                    IdServico = serviceId,
                    Valor = service.Preco,
                });
            }

            await _context.Agendamentos.AddAsync(appointment);
            await _context.SaveChangesAsync();
            await transaction.CommitAsync();

            return appointmentId;
        }

        /// <summary>
        /// Updates the status of an existing appointment. Returns false if not found.
        /// </summary>
        public async Task<bool> UpdateStatus(Guid id, string status, Guid employeeId)
        {
            var appointments = _context.Agendamentos.Where(a =>
                a.Id == id && a.IdFuncionario == employeeId && a.Status != status);
            if (status == "concluido")
                appointments = appointments.Where(a => a.Status == "agendado");

            DateTime? completedAt = status == "concluido" ? DateTime.UtcNow : null;
            var changed = await appointments.ExecuteUpdateAsync(update => update
                .SetProperty(a => a.Status, status)
                .SetProperty(a => a.DataConclusao, completedAt));
            return changed == 1;
        }

        /// <summary>
        /// Retrieves a single appointment by identifier with all details, or null if not found.
        /// </summary>
        public async Task<MinAgendamentoDTO?> GetOne(Guid appointmentId, Guid? employeeId = null)
        {
            var a = await _context.Agendamentos
                .AsNoTracking()
                .Include(a => a.Cliente)
                .Include(a => a.Funcionario)
                .Include(a => a.ServicosRealizados)
                    .ThenInclude(sr => sr.Servico)
                .FirstOrDefaultAsync(a => a.Id == appointmentId && (!employeeId.HasValue || a.IdFuncionario == employeeId.Value));

            if (a == null)
            {
                return null;
            }

            var services = a.ServicosRealizados
                .Select(sr => new ServicoDTO(
                    sr.Servico.Id,
                    sr.Servico.Nome,
                    sr.Servico.Descricao,
                    sr.Servico.Preco,
                        sr.Servico.Ativo
                ))
                .ToArray();

            return new MinAgendamentoDTO(
                a.Id,
                a.DataAgendamento,
                a.Status,
                a.ValorTotal ?? 0,
                services,
                new MinClienteDTO(a.Cliente.Nome, a.Cliente.Telefone ?? string.Empty),
                new MinFuncionarioDTO(a.Funcionario.Id, a.Funcionario.Nome)
            );
        }
    }
}
