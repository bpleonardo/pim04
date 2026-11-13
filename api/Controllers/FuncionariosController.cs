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
        [ProducesResponseType(typeof(ApiResponse<FuncionarioDTO[]>), StatusCodes.Status200OK)]
        public async Task<ActionResult<ApiResponse<FuncionarioDTO[]>>> Get()
        {
            var funcionarios = await _service.GetAll();
            return Ok(ApiResponse.Ok(funcionarios));
        }
    }
}
