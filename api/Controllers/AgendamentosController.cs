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
        public async Task<ActionResult<ApiResponse<MinAgendamentoDTO[]>>> Get(
            [FromQuery] DateOnly? date
        )
        {
            var agendamentos = await _service.GetAll(date);
            return Ok(ApiResponse.Ok(agendamentos));
        }

        // POST: /api/agendamentos
        [HttpPost]
        [ProducesResponseType(typeof(ApiResponse<AgendamentoResponseDTO>), StatusCodes.Status201Created)]
        [ProducesResponseType(typeof(ApiResponse<EmptyResponse>), StatusCodes.Status400BadRequest)]
        public async Task<ActionResult<ApiResponse<AgendamentoResponseDTO>>> Post(
            [FromBody] AgendamentoCreateDTO dto
        )
        {
            var result = await _service.CreateOne(dto);

            if (!result.HasValue)
            {
                return BadRequest(
                    ApiResponse.Fail<AgendamentoResponseDTO>(
                        new ApiError("CREATE_FAILED", "Erro ao criar agendamento. Horário indisponível ou serviço não encontrado.")
                    )
                );
            }

            return CreatedAtAction(nameof(Get), new { }, ApiResponse.Ok(result.Value));
        }

        // PATCH: /api/agendamentos/{id}
        [HttpPatch("{id:guid}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(typeof(ApiResponse<EmptyResponse>), StatusCodes.Status400BadRequest)]
        public async Task<ActionResult> Patch(
            Guid id,
            [FromBody] AgendamentoUpdateDTO dto
        )
        {
            var result = await _service.UpdateStatus(id, dto.Status);

            if (!result.HasValue)
            {
                return BadRequest(
                    ApiResponse.Fail<EmptyResponse>(
                        new ApiError("UPDATE_FAILED", "Agendamento não encontrado ou status inválido.")
                    )
                );
            }

            return NoContent();
        }
    }
}
