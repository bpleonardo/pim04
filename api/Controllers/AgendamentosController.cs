using System.Security.Claims;
using api.DTOs;
using api.Services;
using api.Utilities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AgendamentosController(AgendamentosService service) : ControllerBase
    {
        private readonly AgendamentosService _service = service;

        private string? MutationId()
        {
            var nonce = Request.Headers["Nonce"].ToString();
            return nonce.Length == 32 && nonce.All(Uri.IsHexDigit) ? nonce : null;
        }

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
                {
                    return Unauthorized();
                }
                employeeId = ownerId;
            }

            return Ok(ApiResponse.Ok(await _service.GetAll(date, employeeId)));
        }

        [Authorize]
        [HttpGet("{id:guid}")]
        public async Task<ActionResult> GetOne(Guid id)
        {
            if (!Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var employeeId))
            {
                return Unauthorized();
            }
            return Ok(ApiResponse.Ok(await _service.GetOne(id, employeeId)));
        }

        [Authorize]
        [HttpPut("{id:guid}")]
        public async Task<ActionResult> Put(Guid id, [FromBody] AgendamentoEditDTO dto)
        {
            if (!Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var employeeId))
            {
                return Unauthorized();
            }
            return Ok(ApiResponse.Ok(await _service.Edit(id, employeeId, dto, MutationId())));
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
            if (
                (dto.RecordedAt.HasValue || dto.ClientRequestId is not null)
                && (
                    !Guid.TryParse(
                        User.FindFirstValue(ClaimTypes.NameIdentifier),
                        out var employeeId
                    )
                    || employeeId != dto.IdFuncionario
                )
            )
                return Unauthorized();
            var result = await _service.CreateOne(dto);
            return StatusCode(StatusCodes.Status201Created, ApiResponse.Ok(result));
        }

        // PATCH: /api/agendamentos/{id}
        [Authorize]
        [HttpPatch("{id:guid}")]
        [ProducesResponseType(typeof(ApiResponse<MinAgendamentoDTO>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
        public async Task<ActionResult> Patch(Guid id, [FromBody] AgendamentoUpdateDTO dto)
        {
            if (!Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var employeeId))
                return Unauthorized();

            await _service.UpdateStatus(
                id,
                dto.Status,
                employeeId,
                dto.ExpectedRevision,
                MutationId()
            );
            return Ok(ApiResponse.Ok(await _service.GetOne(id, employeeId)));
        }
    }
}
