using api.DTOs;
using api.Services;
using api.Utilities;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;

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
            [FromQuery(Name = "date"), BindRequired] DateOnly date
        )
        {
            var horarios = await _service.GetHorariosDisponiveis(date);
            return Ok(ApiResponse.Ok(horarios));
        }
    }
}
