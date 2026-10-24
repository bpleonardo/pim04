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
        [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
        public async Task<ActionResult<ApiResponse<FinanceiroDTO>>> Get(
            [FromQuery] string periodo = "hoje",
            [FromQuery] DateOnly? dataInicio = null,
            [FromQuery] DateOnly? dataFim = null
        )
        {
            var financeiro = await _service.GetFinanceiro(periodo, dataInicio, dataFim);
            return Ok(ApiResponse.Ok(financeiro));
        }
    }
}
