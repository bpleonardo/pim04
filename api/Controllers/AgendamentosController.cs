using api.DTOs;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
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

        [HttpGet]
        public async Task<ActionResult> Get(
            [FromQuery] DateOnly? date,
            [FromQuery] bool mine = false
        )
        {
            Guid? employeeId = null;
            if (mine)
            {
                if (!Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var ownerId))
                    return Unauthorized();
                employeeId = ownerId;
            }

            return Ok(ApiResponse.Ok(await _service.GetAll(date, employeeId)));
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
            return StatusCode(StatusCodes.Status201Created, ApiResponse.Ok(result));
        }

        // PATCH: /api/agendamentos/{id}
        [Authorize]
        [HttpPatch("{id:guid}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
        public async Task<ActionResult> Patch(Guid id, [FromBody] AgendamentoUpdateDTO dto)
        {
            if (!Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var employeeId))
                return Unauthorized();

            await _service.UpdateStatus(id, dto.Status, employeeId);
            return NoContent();
        }
    }
}
