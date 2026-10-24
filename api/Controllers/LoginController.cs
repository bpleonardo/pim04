using api.DTOs;
using api.Services;
using api.Utilities;
using Microsoft.AspNetCore.Mvc;

namespace api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class LoginController(AuthService authService) : ControllerBase
    {
        private readonly AuthService _authService = authService;

        // POST: /api/login
        [HttpPost]
        [ProducesResponseType(typeof(ApiResponse<LoginResponse>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status401Unauthorized)]
        public async Task<ActionResult<ApiResponse<LoginResponse>>> Post([FromBody] LoginRequest request)
        {
            var loginResponse = await _authService.AuthenticateAsync(request);
            return Ok(ApiResponse.Ok(loginResponse));
        }
    }
}
