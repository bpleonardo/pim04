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

        // GET: /api/funcionarios/{id}
        [HttpGet("{id:guid}")]
        [ProducesResponseType(typeof(ApiResponse<FuncionarioDTO>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
        public async Task<ActionResult<ApiResponse<FuncionarioDTO>>> Get(Guid id)
        {
            var funcionario = await _service.GetOne(id);
            return Ok(ApiResponse.Ok(funcionario));
        }

        // POST: /api/funcionarios
        [HttpPost]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        public async Task<ActionResult> Post([FromBody] FuncionarioCreateDTO dto)
        {
            await _service.CreateOne(dto);
            return NoContent();
        }
    }
}
