using api.DTOs;
using api.Services;
using api.Utilities;
using Microsoft.AspNetCore.Mvc;

namespace api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class FinanceiroController(FinanceiroService service) : ControllerBase
    {
        private readonly FinanceiroService _service = service;

        // GET: /api/financeiro?periodo=hoje|semana|mes|personalizado&dataInicio=2026-05-20&dataFim=2026-05-26
        [HttpGet]
        [ProducesResponseType(typeof(ApiResponse<FinanceiroDTO>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<EmptyResponse>), StatusCodes.Status400BadRequest)]
        public async Task<ActionResult<ApiResponse<FinanceiroDTO>>> Get(
            [FromQuery] string periodo = "hoje",
            [FromQuery] DateOnly? dataInicio = null,
            [FromQuery] DateOnly? dataFim = null
        )
        {
            var validPeriodos = new[] { "hoje", "semana", "mes", "personalizado" };
            if (!validPeriodos.Contains(periodo))
            {
                return BadRequest(
                    ApiResponse.Fail<FinanceiroDTO>(
                        new ApiError("INVALID_PERIOD", "Período inválido. Use: hoje, semana, mes, personalizado")
                    )
                );
            }

            if (periodo == "personalizado" && (!dataInicio.HasValue || !dataFim.HasValue))
            {
                return BadRequest(
                    ApiResponse.Fail<FinanceiroDTO>(
                        new ApiError("MISSING_DATES", "Para período personalizado, forneça dataInicio e dataFim")
                    )
                );
            }

            var financeiro = await _service.GetFinanceiro(periodo, dataInicio, dataFim);
            return Ok(ApiResponse.Ok(financeiro));
        }
    }
}
