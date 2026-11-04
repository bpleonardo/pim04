using api.DTOs;
using api.Models;
using api.Services;
using api.Utilities;
using Microsoft.AspNetCore.Mvc;

namespace api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ServicosController(ServicosService service) : ControllerBase
    {
        private readonly ServicosService _service = service;

        // GET: /api/servicos
        [HttpGet]
        [ProducesResponseType(typeof(ApiResponse<Servico[]>), StatusCodes.Status200OK)]
        public async Task<ActionResult<ApiResponse<Servico[]>>> Get()
        {
            var servicos = await _service.GetAll();
            return Ok(ApiResponse.Ok(servicos));
        }

        // GET: /api/servicos/{id}
        [HttpGet("{id:guid}")]
        [ProducesResponseType(typeof(ApiResponse<Servico>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
        public async Task<ActionResult<ApiResponse<Servico>>> Get(Guid id)
        {
            var servico = await _service.GetOne(id);
            return Ok(ApiResponse.Ok(servico));
        }

        // POST: /api/servicos
        [HttpPost]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
        public async Task<ActionResult> Post([FromBody] ServicoCreateDTO dto)
        {
            await _service.CreateOne(dto);
            return NoContent();
        }

        // PUT: /api/servicos/{id}
        [HttpPut("{id:guid}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
        public async Task<ActionResult> Put(Guid id, [FromBody] ServicoCreateDTO dto)
        {
            await _service.ReplaceOne(id, dto);
            return NoContent();
        }

        // PATCH: /api/servicos/{id}
        [HttpPatch("{id:guid}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
        public async Task<ActionResult> Patch(Guid id, [FromBody] ServicoUpdateDTO dto)
        {
            await _service.UpdateOne(id, dto);
            return NoContent();
        }

        // DELETE: /api/servicos/{id}
        [HttpDelete("{id:guid}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
        [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status409Conflict)]
        public async Task<ActionResult> Delete(Guid id)
        {
            await _service.DeleteOne(id);
            return NoContent();
        }
    }
}
