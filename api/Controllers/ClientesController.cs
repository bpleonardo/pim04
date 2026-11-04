using api.DTOs;
using api.Models;
using api.Services;
using api.Utilities;
using Microsoft.AspNetCore.Mvc;

namespace api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ClientesController(ClientesService service) : ControllerBase
    {
        private readonly ClientesService _service = service;

        // GET: /api/clientes
        [HttpGet]
        [ProducesResponseType(typeof(ApiResponse<Cliente[]>), StatusCodes.Status200OK)]
        public async Task<ActionResult<ApiResponse<Cliente[]>>> Get()
        {
            var clientes = await _service.GetAll();
            return Ok(ApiResponse.Ok(clientes));
        }

        // GET: /api/clientes/{id}
        [HttpGet("{id:guid}")]
        [ProducesResponseType(typeof(ApiResponse<Cliente>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
        public async Task<ActionResult<ApiResponse<Cliente>>> Get(Guid id)
        {
            var cliente = await _service.GetOne(id);
            return Ok(ApiResponse.Ok(cliente));
        }

        [HttpPost]
        [ProducesResponseType(typeof(ApiResponse<EmptyResponse>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status409Conflict)]
        public async Task<ActionResult<ApiResponse<EmptyResponse>>> Post(
            [FromBody] ClienteCreateDTO dto
        )
        {
            await _service.CreateOne(dto);
            return CreatedAtAction(nameof(Get), new { }, ApiResponse.Ok(new EmptyResponse()));
        }

        // PUT /api/clientes/3fa85f64-5717-4562-b3fc-2c963f66afa6
        [HttpPut("{id}")]
        public void Put(Guid id, [FromBody] string value) { }

        // PATCH /api/clientes/3fa85f64-5717-4562-b3fc-2c963f66afa6
        [HttpPatch("{id}")]
        public void Patch(Guid id, [FromBody] string value) { }

        // DELETE /api/clientes/3fa85f64-5717-4562-b3fc-2c963f66afa6
        [HttpDelete("{id}")]
        public void Delete(Guid id) { }
    }
}
