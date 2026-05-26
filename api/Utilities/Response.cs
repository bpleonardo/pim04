namespace api.Utilities
{
    public class Response(int statusCode, string? body, string? contentType = "application/json")
    {
        public string? Body { get; init; } = body;
        public int StatusCode { get; init; } = statusCode;
        public string? ContentType { get; init; } = contentType;
        public Dictionary<string, string[]> Headers { get; init; } = [];
    }
}
