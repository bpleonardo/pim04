using api.DTOs;
using api.Services;
using api.Utilities;
using Microsoft.AspNetCore.Mvc;

namespace api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DashboardController(DashboardService service) : ControllerBase
    {
        private readonly DashboardService _service = service;

        // GET: /api/dashboard
        [HttpGet]
        [ProducesResponseType(typeof(ApiResponse<DashboardDTO>), StatusCodes.Status200OK)]
        public async Task<ActionResult<ApiResponse<DashboardDTO>>> Get()
        {
            var dashboard = await _service.GetDashboard();
            return Ok(ApiResponse.Ok(dashboard));
        }
    }
}
