using api.DTOs;
using api.Services;
using api.Utilities;
using Microsoft.AspNetCore.Mvc;

namespace api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
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

        [HttpPost("refresh")]
        public async Task<ActionResult<ApiResponse<LoginResponse>>> Refresh(RefreshRequest request) =>
            Ok(ApiResponse.Ok(await _authService.RefreshAsync(request.RefreshToken)));

        [HttpPost("logout")]
        public async Task<ActionResult> Logout(RefreshRequest request)
        {
            await _authService.LogoutAsync(request.RefreshToken);
            return NoContent();
        }
    }
}
