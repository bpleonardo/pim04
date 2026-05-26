using api.DTOs;
using api.Models;
using api.Services;
using api.Utilities;
using Microsoft.AspNetCore.Mvc;

namespace api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AgendamentosController(AgendamentosService service) : ControllerBase
    {
        private readonly AgendamentosService _service = service;

        // GET: /api/agendamentos
        [HttpGet]
        public async Task<ActionResult<ApiResponse<MinAgendamentoDTO[]>>> Get(
            [FromQuery] DateOnly? date
        )
        {
            var agendamentos = await _service.GetAll(date);
            return Ok(ApiResponse.Ok(agendamentos));
        }
    }
}
