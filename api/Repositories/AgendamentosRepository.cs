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
        public async Task<MinAgendamentoDTO[]> GetByDate(DateOnly date)
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
                        sr.Servico.Preco
                    ))
                    .ToArray(),
                new MinClienteDTO(a.Cliente.Nome, a.Cliente.Telefone ?? string.Empty),
                new MinFuncionarioDTO(a.Funcionario.Id, a.Funcionario.Nome)
            )).ToArray();
        }

        /// <summary>
        /// Checks if a time slot is available for a specific employee.
        /// </summary>
        public async Task<bool> IsSlotAvailable(Guid idFuncionario, DateTime dateTime)
        {
            var dateTimeUtc = dateTime.Kind == DateTimeKind.Unspecified
                ? DateTime.SpecifyKind(dateTime, DateTimeKind.Utc)
                : dateTime.ToUniversalTime();

            // Retorna true se não houver agendamento ativo no mesmo horário para o funcionário
            var isBusy = await _context.Agendamentos
                .AnyAsync(a =>
                    a.IdFuncionario == idFuncionario
                    && a.DataAgendamento == dateTimeUtc
                    && a.Status == "agendado"
                );

            return !isBusy;
        }

        /// <summary>
        /// Creates a new appointment and its associated services in a single transaction.
        /// </summary>
        public async Task<Guid> CreateOne(
            Guid idCliente,
            Guid idFuncionario,
            DateTime dataAgendamento,
            double total,
            Guid[] idServicos
        )
        {
            var servicos = await _context.Servicos
                .Where(s => idServicos.Contains(s.Id))
                .ToListAsync();

            // Valida se todos os serviços existem no banco
            if (servicos.Count != idServicos.Distinct().Count())
            {
                throw new ResourceNotFoundException("Um ou mais serviços informados não foram encontrados.");
            }

            var agendamentoId = Guid.NewGuid();
            var agendamento = new Agendamento
            {
                Id = agendamentoId,
                IdCliente = idCliente,
                IdFuncionario = idFuncionario,
                DataAgendamento = dataAgendamento.Kind == DateTimeKind.Unspecified
                    ? DateTime.SpecifyKind(dataAgendamento, DateTimeKind.Utc)
                    : dataAgendamento.ToUniversalTime(),
                Status = "agendado",
                ValorTotal = total,
            };

            foreach (var idServico in idServicos)
            {
                var servico = servicos.First(s => s.Id == idServico);
                agendamento.ServicosRealizados.Add(new ServicoRealizado
                {
                    IdAgendamento = agendamentoId,
                    IdServico = idServico,
                    Valor = servico.Preco,
                });
            }

            await _context.Agendamentos.AddAsync(agendamento);
            await _context.SaveChangesAsync();

            return agendamentoId;
        }

        /// <summary>
        /// Updates the status of an existing appointment. Returns false if not found.
        /// </summary>
        public async Task<bool> UpdateStatus(Guid agendamentoId, string novoStatus)
        {
            var agendamento = await _context.Agendamentos.FindAsync(agendamentoId);
            if (agendamento == null)
            {
                return false;
            }

            agendamento.Status = novoStatus;
            await _context.SaveChangesAsync();

            return true;
        }

        /// <summary>
        /// Retrieves a single appointment by identifier with all details, or null if not found.
        /// </summary>
        public async Task<MinAgendamentoDTO?> GetOne(Guid agendamentoId)
        {
            var a = await _context.Agendamentos
                .AsNoTracking()
                .Include(a => a.Cliente)
                .Include(a => a.Funcionario)
                .Include(a => a.ServicosRealizados)
                    .ThenInclude(sr => sr.Servico)
                .FirstOrDefaultAsync(a => a.Id == agendamentoId);

            if (a == null)
            {
                return null;
            }

            var servicos = a.ServicosRealizados
                .Select(sr => new ServicoDTO(
                    sr.Servico.Id,
                    sr.Servico.Nome,
                    sr.Servico.Descricao,
                    sr.Servico.Preco
                ))
                .ToArray();

            return new MinAgendamentoDTO(
                a.Id,
                a.DataAgendamento,
                a.Status,
                a.ValorTotal ?? 0,
                servicos,
                new MinClienteDTO(a.Cliente.Nome, a.Cliente.Telefone ?? string.Empty),
                new MinFuncionarioDTO(a.Funcionario.Id, a.Funcionario.Nome)
            );
        }
    }
}
