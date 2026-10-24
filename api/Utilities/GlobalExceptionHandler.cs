using api.Exceptions;
using Microsoft.AspNetCore.Diagnostics;

namespace api.Utilities
{
    /// <summary>
    /// Global exception handler that intercepts unhandled exceptions, maps them to standard HTTP status codes,
    /// logs internal details, and formats the response according to the API error contract.
    /// </summary>
    public class GlobalExceptionHandler(ILogger<GlobalExceptionHandler> logger) : IExceptionHandler
    {
        private readonly ILogger<GlobalExceptionHandler> _logger = logger;

        public async ValueTask<bool> TryHandleAsync(
            HttpContext httpContext,
            Exception exception,
            CancellationToken cancellationToken
        )
        {
            if (httpContext.Response.HasStarted)
            {
                _logger.LogWarning(exception, "A resposta HTTP já foi iniciada; não é possível tratar a exceção globalmente.");
                return false;
            }

            int statusCode;
            string code;
            string message;

            if (exception is AppException appEx)
            {
                statusCode = appEx.StatusCode;
                code = appEx.Code;
                message = appEx.Message;

                _logger.LogWarning("Exceção da aplicação tratada: {Code} ({StatusCode}) - {Message}", code, statusCode, message);
            }
            else if (exception is BadHttpRequestException badRequestEx)
            {
                statusCode = StatusCodes.Status400BadRequest;
                code = "VALIDATION_ERROR";
                message = badRequestEx.Message;

                _logger.LogWarning(badRequestEx, "Exceção de requisição HTTP inválida tratada.");
            }
            else
            {
                statusCode = StatusCodes.Status500InternalServerError;
                code = "INTERNAL_SERVER_ERROR";
                message = "Ocorreu um erro interno no servidor.";

                // Registra o erro completo com stack trace internamente, sem expor ao consumidor
                _logger.LogError(exception, "Exceção não tratada capturada no servidor.");
            }

            httpContext.Response.Clear();
            httpContext.Response.StatusCode = statusCode;
            httpContext.Response.ContentType = "application/json";

            var response = new ErrorResponse(code, message);
            await httpContext.Response.WriteAsJsonAsync(response, cancellationToken);

            return true;
        }
    }
}
