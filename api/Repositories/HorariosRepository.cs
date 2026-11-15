using api.Data;
using api.DTOs;
using api.Models;
using Microsoft.EntityFrameworkCore;

namespace api.Repositories
{
    /// <summary>
    /// Repository for scheduling availability and time slot calculations using Entity Framework Core.
    /// </summary>
    public class HorariosRepository(AppDbContext context)
    {
        private readonly AppDbContext _context = context;

        public async Task<DisponibilidadeDTO> GetDisponibilidade(Guid employeeId)
        {
            var intervals = await _context.FuncionarioDisponibilidades
                .AsNoTracking()
                .Where(item => item.IdFuncionario == employeeId)
                .OrderBy(item => item.DiaSemana)
                .ThenBy(item => item.Inicio)
                .ToListAsync();

            return new DisponibilidadeDTO(
                intervals.GroupBy(item => item.DiaSemana)
                    .Select(group => new DiaDisponibilidadeDTO(
                        group.Key,
                        group.Select(item => new IntervaloDisponibilidadeDTO(
                            item.Inicio,
                            item.Fim
                        )).ToList()
                    )).ToList()
            );
        }

        public async Task SaveDisponibilidade(
            Guid employeeId,
            DisponibilidadeDTO availability
        )
        {
            var current = await _context.FuncionarioDisponibilidades
                .Where(item => item.IdFuncionario == employeeId)
                .ToListAsync();
            _context.FuncionarioDisponibilidades.RemoveRange(current);

            var rows = availability.Dias.SelectMany(day => day.Intervalos.Select(interval =>
                new FuncionarioDisponibilidade
                {
                    Id = Guid.NewGuid(),
                    IdFuncionario = employeeId,
                    DiaSemana = day.DiaSemana,
                    Inicio = interval.Inicio,
                    Fim = interval.Fim,
                }));
            await _context.FuncionarioDisponibilidades.AddRangeAsync(rows);
            await _context.SaveChangesAsync();
        }

        /// <summary>
        /// Retrieves available 30-minute time slots for a given date and operating hour range.
        /// </summary>
        public async Task<List<HorarioDTO>> GetHorariosDisponiveis(
            DateOnly date,
            TimeOnly startTime,
            TimeOnly endTime,
            Guid? employeeId = null
        )
        {
            // Determina a janela do dia no fuso horário de São Paulo
            var tz = TimeZoneInfo.FindSystemTimeZoneById("America/Sao_Paulo");
            var startLocal = date.ToDateTime(new TimeOnly(0, 0, 0), DateTimeKind.Unspecified);
            var startUtc = TimeZoneInfo.ConvertTimeToUtc(startLocal, tz);
            var endUtc = startUtc.AddDays(1);

            var employeeIds = await _context.Funcionarios
                .Where(item => !item.IsDeleted && (!employeeId.HasValue || item.Id == employeeId.Value))
                .Select(item => item.Id)
                .ToListAsync();
            var configuredIntervals = await _context.FuncionarioDisponibilidades
                .AsNoTracking()
                .Where(item => employeeIds.Contains(item.IdFuncionario) && item.DiaSemana == (int)date.DayOfWeek)
                .ToListAsync();

            // Obtém agendamentos do dia para conferir funcionários ocupados em cada slot
            var busyAppointments = await _context.Agendamentos
                .AsNoTracking()
                .Where(a =>
                    a.Status == "agendado"
                    && a.DataAgendamento >= startUtc
                    && a.DataAgendamento < endUtc
                )
                .Select(a => new { a.IdFuncionario, a.DataAgendamento })
                .ToListAsync();

            var utcNow = DateTime.UtcNow;
            var horarios = new List<HorarioDTO>();
            var current = startTime;

            while (current <= endTime)
            {
                var slotStr = current.ToString("HH:mm");
                var slotLocal = date.ToDateTime(current, DateTimeKind.Unspecified);
                var slotUtc = TimeZoneInfo.ConvertTimeToUtc(slotLocal, tz);

                // A disponibilidade e a ocupação precisam corresponder ao mesmo funcionário.
                var isAvailable = slotUtc > utcNow && employeeIds.Any(id =>
                    configuredIntervals.Any(interval => interval.IdFuncionario == id
                        && current >= interval.Inicio && current < interval.Fim)
                    && !busyAppointments.Any(appointment =>
                        appointment.IdFuncionario == id && appointment.DataAgendamento == slotUtc));

                horarios.Add(new HorarioDTO(slotStr, isAvailable));

                if (current == TimeOnly.MaxValue || current.AddMinutes(30) < current)
                {
                    break;
                }
                current = current.AddMinutes(30);
            }

            return horarios;
        }
    }
}
