using api.DTOs;
using api.Services;
using api.Utilities;
using Microsoft.AspNetCore.Authorization;
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

        [Authorize]
        [HttpPost]
        public async Task<ActionResult> Post([FromBody] FuncionarioCreateDTO dto)
        {
            await _service.CreateOne(dto);
            return NoContent();
        }

        [Authorize]
        [HttpPut("{id:guid}")]
        public async Task<ActionResult> Put(Guid id, [FromBody] FuncionarioCreateDTO dto)
        {
            await _service.UpdateOne(id, dto);
            return NoContent();
        }

        [Authorize]
        [HttpDelete("{id:guid}")]
        public async Task<ActionResult> Delete(Guid id)
        {
            var isDeleted = await _service.DeleteOne(id);
            return Ok(ApiResponse.Ok(new { isDeleted }));
        }
    }
}
