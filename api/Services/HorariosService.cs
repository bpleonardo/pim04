using api.DTOs;
using api.Exceptions;
using api.Repositories;

namespace api.Services
{
    public class HorariosService(HorariosRepository repo)
    {
        private readonly HorariosRepository _repo = repo;

        /// <summary>
        /// Retrieves available slots for the given date, validating that the date is between today and the next 14 days.
        /// </summary>
        public async Task<List<HorarioDTO>> GetHorariosDisponiveis(DateOnly date)
        {
            var today = DateOnly.FromDateTime(DateTime.Now);

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
                new TimeOnly(18, 0)
            );
        }
    }
}
