using api.DTOs;
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

        // GET: /api/agendamentos?date=2026-05-26
        [HttpGet]
        [ProducesResponseType(typeof(ApiResponse<MinAgendamentoDTO[]>), StatusCodes.Status200OK)]
        public async Task<ActionResult<ApiResponse<MinAgendamentoDTO[]>>> Get(
            [FromQuery] DateOnly? date
        )
        {
            var agendamentos = await _service.GetAll(date);
            return Ok(ApiResponse.Ok(agendamentos));
        }

        // POST: /api/agendamentos
        [HttpPost]
        [ProducesResponseType(
            typeof(ApiResponse<AgendamentoResponseDTO>),
            StatusCodes.Status201Created
        )]
        [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
        [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status409Conflict)]
        public async Task<ActionResult<ApiResponse<AgendamentoResponseDTO>>> Post(
            [FromBody] AgendamentoCreateDTO dto
        )
        {
            var result = await _service.CreateOne(dto);
            return CreatedAtAction(nameof(Get), new { }, ApiResponse.Ok(result));
        }

        // PATCH: /api/agendamentos/{id}
        [HttpPatch("{id:guid}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
        public async Task<ActionResult> Patch(Guid id, [FromBody] AgendamentoUpdateDTO dto)
        {
            await _service.UpdateStatus(id, dto.Status);
            return NoContent();
        }
    }
}
