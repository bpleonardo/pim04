using System.Security.Claims;
using api.DTOs;
using api.Services;
using api.Utilities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;

namespace api.Controllers;

[Authorize]
[ApiController]
[Route("api/reports")]
public class ReportsController(ReportsService service) : ControllerBase
{
    [HttpGet("daily")]
    public async Task<ActionResult<ApiResponse<DailyReportDTO>>> GetDaily(
        [FromQuery, BindRequired] DateOnly date, [FromQuery] bool mine = false)
    {
        Guid? employeeId = null;
        if (mine)
        {
            if (!Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id)) return Unauthorized();
            employeeId = id;
        }
        return Ok(ApiResponse.Ok(await service.GetDaily(date, employeeId)));
    }
}
