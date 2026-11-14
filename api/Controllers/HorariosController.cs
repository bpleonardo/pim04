using api.DTOs;
using api.Services;
using api.Utilities;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class HorariosController(HorariosService horariosService) : ControllerBase
    {
        private readonly HorariosService _service = horariosService;

        // GET: /api/horarios?date=2026-05-26
        [HttpGet]
        [ProducesResponseType(typeof(ApiResponse<List<HorarioDTO>>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
        public async Task<ActionResult<ApiResponse<List<HorarioDTO>>>> GetHorarios(
            [FromQuery(Name = "date"), BindRequired] DateOnly date,
            [FromQuery] Guid? employeeId
        )
        {
            var horarios = await _service.GetHorariosDisponiveis(date, employeeId);
            return Ok(ApiResponse.Ok(horarios));
        }

        [Authorize]
        [HttpGet("me")]
        public async Task<ActionResult<ApiResponse<DisponibilidadeDTO>>> GetMine()
        {
            return Ok(ApiResponse.Ok(await _service.GetDisponibilidade(EmployeeId())));
        }

        [Authorize]
        [HttpPut("me")]
        public async Task<ActionResult> SaveMine([FromBody] DisponibilidadeDTO availability)
        {
            await _service.SaveDisponibilidade(EmployeeId(), availability);
            return NoContent();
        }

        private Guid EmployeeId()
        {
            var value = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(value, out var employeeId)
                ? employeeId
                : throw new UnauthorizedAccessException("Funcionário autenticado inválido.");
        }
    }
}
