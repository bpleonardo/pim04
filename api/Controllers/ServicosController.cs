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
        [ProducesResponseType(typeof(ApiResponse<Servico>), StatusCodes.Status404NotFound)]
        public async Task<ActionResult<ApiResponse<Servico>>> Get(Guid id)
        {
            var servico = await _service.GetOne(id);

            if (servico == null)
            {
                return NotFound(
                    ApiResponse.Fail<Servico>(new ApiError("NOT_FOUND", "Serviço não encontrado."))
                );
            }

            return Ok(ApiResponse.Ok(servico));
        }

        // POST: /api/servicos
        [HttpPost]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
        public async Task<ActionResult> Post([FromBody] ServicoCreateDTO dto)
        {
            var created = await _service.CreateOne(dto);

            if (!created)
            {
                return BadRequest(
                    ApiResponse.Fail<object>(
                        new ApiError("CREATE_FAILED", "Erro ao criar o serviço.")
                    )
                );
            }

            return NoContent();
        }

        // PUT: /api/servicos/{id}
        [HttpPut("{id:guid}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
        public async Task<ActionResult> Put(Guid id, [FromBody] ServicoCreateDTO dto)
        {
            var updated = await _service.ReplaceOne(id, dto);

            if (!updated)
            {
                return BadRequest(
                    ApiResponse.Fail<object>(
                        new ApiError("REPLACE_FAILED", "Erro ao atualizar o serviço.")
                    )
                );
            }

            return NoContent();
        }

        // PATCH: /api/servicos/{id}
        [HttpPatch("{id:guid}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
        public async Task<ActionResult> Patch(Guid id, [FromBody] ServicoUpdateDTO dto)
        {
            var updated = await _service.UpdateOne(id, dto);

            if (updated.HasValue)
            {
                return NoContent();
            }

            if (updated.HasError)
            {
                return updated.Error switch
                {
                    ErrorCodes.NotFound => NotFound(
                        ApiResponse.Fail<object>(
                            new ApiError("NOT_FOUND", "Serviço não encontrado.")
                        )
                    ),
                    _ => StatusCode(
                        500,
                        ApiResponse.Fail<object>(
                            new ApiError("UNKNOWN_ERROR", "Erro desconhecido.")
                        )
                    ),
                };
            }

            return BadRequest(
                ApiResponse.Fail<object>(
                    new ApiError("UPDATE_FAILED", "Erro ao atualizar o serviço.")
                )
            );
        }

        // DELETE: /api/servicos/{id}
        [HttpDelete("{id:guid}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
        public async Task<ActionResult> Delete(Guid id)
        {
            var result = await _service.DeleteOne(id);

            if (result.HasError)
            {
                return result.Error switch
                {
                    ErrorCodes.NotFound => NotFound(
                        ApiResponse.Fail<object>(
                            new ApiError("NOT_FOUND", "Serviço não encontrado.")
                        )
                    ),
                    ErrorCodes.CantModify => Conflict(
                        ApiResponse.Fail<object>(
                            new ApiError("CANT_MODIFY", "Não é possível modificar este recurso.")
                        )
                    ),
                    _ => StatusCode(
                        500,
                        ApiResponse.Fail<object>(
                            new ApiError("UNKNOWN_ERROR", "Erro desconhecido.")
                        )
                    ),
                };
            }

            return NoContent();
        }
    }
}
