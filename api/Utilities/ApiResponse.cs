using System.Text.Json.Serialization;

namespace api.Utilities
{
    public static class ApiResponse
    {
        /// <summary>
        /// Creates a successful API response with the provided data.
        /// This is only here to avoid having to write the generic type parameter when returning a successful response.
        /// </summary>
        public static ApiResponse<T> Ok<T>(T data) => new(Success: true, Data: data);
    }

    public sealed record EmptyResponse();

    public sealed record ApiResponse<T>(
        [property: JsonPropertyName("success")] bool Success,
        [property: JsonPropertyName("data")] T? Data
    );

    /// <summary>
    /// Standard error response contract for all handled API errors.
    /// </summary>
    public sealed record ErrorResponse(
        [property: JsonPropertyName("code")] string Code,
        [property: JsonPropertyName("error")] string Error,
        [property: JsonPropertyName("success")] bool Success = false
    );
}
