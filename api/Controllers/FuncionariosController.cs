using api.DTOs;
using api.Services;
using api.Utilities;
using Microsoft.AspNetCore.Mvc;

namespace api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class FuncionariosController(FuncionariosService service) : ControllerBase
    {
        private readonly FuncionariosService _service = service;

        // GET: /api/funcionarios
        [HttpGet]
        [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
        public async Task<ActionResult<ApiResponse<object>>> Get()
        {
            object funcionarios = User.Identity?.IsAuthenticated == true
                ? await _service.GetAll()
                : await _service.GetPublic();
            return Ok(ApiResponse.Ok(funcionarios));
        }
    }
}
