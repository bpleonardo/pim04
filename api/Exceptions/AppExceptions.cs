namespace api.Exceptions
{
    /// <summary>
    /// Base class for all custom application domain exceptions.
    /// </summary>
    public abstract class AppException : Exception
    {
        /// <summary>
        /// HTTP status code associated with the exception.
        /// </summary>
        public int StatusCode { get; }

        /// <summary>
        /// Machine-readable error code in UPPER_SNAKE_CASE.
        /// </summary>
        public string Code { get; }

        protected AppException(string message, int statusCode, string code) : base(message)
        {
            StatusCode = statusCode;
            Code = code;
        }
    }

    /// <summary>
    /// Exception thrown when a requested resource is not found (HTTP 404).
    /// </summary>
    public class ResourceNotFoundException : AppException
    {
        public ResourceNotFoundException(string message = "Recurso não encontrado.", string code = "NOT_FOUND")
            : base(message, 404, code)
        {
        }
    }

    /// <summary>
    /// Exception thrown when request data or input validation fails (HTTP 400).
    /// </summary>
    public class ValidationException : AppException
    {
        public ValidationException(string message = "Dados de requisição inválidos.", string code = "VALIDATION_ERROR")
            : base(message, 400, code)
        {
        }
    }

    /// <summary>
    /// Exception thrown when authentication fails or credentials are required (HTTP 401).
    /// </summary>
    public class UnauthorizedException : AppException
    {
        public UnauthorizedException(string message = "Não autorizado.", string code = "UNAUTHORIZED")
            : base(message, 401, code)
        {
        }
    }

    /// <summary>
    /// Exception thrown when access to a resource is forbidden (HTTP 403).
    /// </summary>
    public class ForbiddenException : AppException
    {
        public ForbiddenException(string message = "Acesso proibido.", string code = "FORBIDDEN")
            : base(message, 403, code)
        {
        }
    }

    /// <summary>
    /// Exception thrown when an operation conflicts with the current resource state (HTTP 409).
    /// </summary>
    public class ConflictException : AppException
    {
        public ConflictException(string message = "Conflito com o estado atual do recurso.", string code = "CONFLICT")
            : base(message, 409, code)
        {
        }
    }

    /// <summary>
    /// Exception thrown when a business rule or invariant is violated (HTTP 422).
    /// </summary>
    public class BusinessRuleException : AppException
    {
        public BusinessRuleException(string message = "Regra de negócio violada.", string code = "BUSINESS_RULE_ERROR")
            : base(message, 422, code)
        {
        }
    }
}
