using api.Data;
using api.DTOs;
using Microsoft.EntityFrameworkCore;

namespace api.Repositories
{
    /// <summary>
    /// Repository for scheduling availability and time slot calculations using Entity Framework Core.
    /// </summary>
    public class HorariosRepository(AppDbContext context)
    {
        private readonly AppDbContext _context = context;

        /// <summary>
        /// Retrieves available 30-minute time slots for a given date and operating hour range.
        /// </summary>
        public async Task<List<HorarioDTO>> GetHorariosDisponiveis(
            DateOnly date,
            TimeOnly startTime,
            TimeOnly endTime
        )
        {
            // Determina a janela do dia no fuso horário de São Paulo
            var tz = TimeZoneInfo.FindSystemTimeZoneById("America/Sao_Paulo");
            var startLocal = date.ToDateTime(new TimeOnly(0, 0, 0), DateTimeKind.Unspecified);
            var startUtc = TimeZoneInfo.ConvertTimeToUtc(startLocal, tz);
            var endUtc = startUtc.AddDays(1);

            // Contagem total de funcionários cadastrados
            var totalFuncionarios = await _context.Funcionarios.CountAsync();

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

            var horarios = new List<HorarioDTO>();
            var current = startTime;

            while (current <= endTime)
            {
                var slotStr = current.ToString("HH:mm");
                var slotLocal = date.ToDateTime(current, DateTimeKind.Unspecified);
                var slotUtc = TimeZoneInfo.ConvertTimeToUtc(slotLocal, tz);

                // Slot está disponível se pelo menos um funcionário não estiver com agendamento ativo
                var busyCount = busyAppointments
                    .Where(a => a.DataAgendamento == slotUtc)
                    .Select(a => a.IdFuncionario)
                    .Distinct()
                    .Count();

                var isAvailable = totalFuncionarios > 0 && busyCount < totalFuncionarios;

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
