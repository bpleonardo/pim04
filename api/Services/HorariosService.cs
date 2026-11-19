using api.DTOs;
using api.Exceptions;
using api.Repositories;
using System.Security.Claims;

namespace api.Services
{
    public class HorariosService(HorariosRepository repo)
    {
        private readonly HorariosRepository _repo = repo;

        public Task<DisponibilidadeDTO> GetDisponibilidade(Guid employeeId) =>
            _repo.GetDisponibilidade(employeeId);

        public async Task SaveDisponibilidade(
            Guid employeeId,
            DisponibilidadeDTO availability
        )
        {
            Validate(availability);
            await _repo.SaveDisponibilidade(employeeId, availability);
        }

        private static void Validate(DisponibilidadeDTO availability)
        {
            foreach (var day in availability.Dias)
            {
                var ordered = day.Intervalos.OrderBy(item => item.Inicio).ToArray();
                for (var index = 0; index < ordered.Length; index++)
                {
                    if (ordered[index].Fim <= ordered[index].Inicio)
                        throw new ValidationException(
                            "O horário final deve ser posterior ao inicial.",
                            "INVALID_AVAILABILITY"
                        );
                    if (index > 0 && ordered[index - 1].Fim > ordered[index].Inicio)
                        throw new ValidationException(
                            "Os intervalos de um dia não podem se sobrepor.",
                            "INVALID_AVAILABILITY"
                        );
                }
            }
        }

        /// <summary>
        /// Retrieves available slots for the given date, validating that the date is between today and the next 14 days.
        /// </summary>
        public async Task<List<HorarioDTO>> GetHorariosDisponiveis(
            DateOnly date,
            Guid? employeeId = null
        )
        {
            var timeZone = TimeZoneInfo.FindSystemTimeZoneById("America/Sao_Paulo");
            var today = DateOnly.FromDateTime(TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, timeZone));

            if (date < today)
            {
                throw new ValidationException("A data deve ser hoje ou no futuro.", "INVALID_DATE");
            }

            if (date > today.AddDays(14))
            {
                throw new ValidationException("A data deve estar dentro dos próximos 14 dias.", "INVALID_DATE");
            }

            // TODO: Configurar horário de funcionamento.
            return await _repo.GetHorariosDisponiveis(
                date,
                new TimeOnly(9, 0),
                new TimeOnly(18, 0),
                employeeId
            );
        }
    }
}
