using api.DTOs;
using api.Repositories;

namespace api.Services
{
    public class HorariosService(HorariosRepository repo)
    {
        private readonly HorariosRepository _repo = repo;

        public async Task<List<HorarioDTO>> GetHorariosDisponiveis(DateOnly date)
        {
            // TODO: Configurar horário de funcionamento.
            return await _repo.GetHorariosDisponiveis(
                date,
                new TimeOnly(9, 0),
                new TimeOnly(18, 0)
            );
        }
    }
}
