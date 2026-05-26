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

        [HttpGet]
        public async Task<ActionResult<ApiResponse<List<HorarioDTO>>>> GetHorarios(
            [FromQuery(Name = "date"), BindRequired] DateOnly date
        )
        {
            if (date < DateOnly.FromDateTime(DateTime.Now))
            {
                return BadRequest(
                    ApiResponse.Fail<List<HorarioDTO>>(
                        new ApiError("INVALID_DATE", "A data deve ser hoje ou no futuro.")
                    )
                );
            }
            else if (date > DateOnly.FromDateTime(DateTime.Now).AddDays(14))
            {
                return BadRequest(
                    ApiResponse.Fail<List<HorarioDTO>>(
                        new ApiError(
                            "INVALID_DATE",
                            "A data deve estar dentro dos próximos 14 dias."
                        )
                    )
                );
            }

            var horarios = await _service.GetHorariosDisponiveis(date);
            return Ok(ApiResponse.Ok(horarios));
        }
    }
}
