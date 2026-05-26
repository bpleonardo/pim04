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
        [ProducesResponseType(typeof(ApiResponse<FuncionarioDTO>), StatusCodes.Status404NotFound)]
        public async Task<ActionResult<ApiResponse<FuncionarioDTO>>> Get(Guid id)
        {
            var funcionario = await _service.GetOne(id);

            if (funcionario is null)
                return NotFound(
                    ApiResponse.Fail<FuncionarioDTO>(
                        new ApiError("NOT_FOUND", "Funcionário não encontrado.")
                    )
                );

            return Ok(ApiResponse.Ok(funcionario.Value));
        }

        // POST: /api/funcionarios
        [HttpPost]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(typeof(ApiResponse<EmptyResponse>), StatusCodes.Status400BadRequest)]
        public async Task<ActionResult<ApiResponse<EmptyResponse>>> Post(
            [FromBody] FuncionarioCreateDTO dto
        )
        {
            var result = await _service.CreateOne(dto);

            if (!result.HasValue)
            {
                return BadRequest(
                    ApiResponse.Fail<EmptyResponse>(
                        new ApiError("CREATE_FAILED", "Erro ao criar funcionário.")
                    )
                );
            }

            return NoContent();
        }
    }
}
