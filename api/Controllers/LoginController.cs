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
        [ProducesResponseType(typeof(ApiResponse<EmptyResponse>), StatusCodes.Status401Unauthorized)]
        public async Task<ActionResult<ApiResponse<LoginResponse>>> Post([FromBody] LoginRequest request)
        {
            var result = await _authService.AuthenticateAsync(request);

            if (!result.HasValue)
            {
                return Unauthorized(
                    ApiResponse.Fail<LoginResponse>(
                        new ApiError("INVALID_CREDENTIALS", "Login ou senha inválidos.")
                    )
                );
            }

            var loginResponse = result.Value;
            return Ok(ApiResponse.Ok(loginResponse));
        }
    }
}
