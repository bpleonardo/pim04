using api.DTOs;
using api.Models;
using api.Repositories;
using api.Utilities;

namespace api.Services
{
    public class AgendamentosService(AgendamentosRepository repo)
    {
        private readonly AgendamentosRepository _repo = repo;

        public async Task<MinAgendamentoDTO[]> GetAll(DateOnly? date = null)
        {
            return await _repo.GetByDate(date ?? DateOnly.FromDateTime(DateTime.Now));
        }
    }
}
