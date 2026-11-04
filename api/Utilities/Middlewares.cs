using System.Text.Json;
using StackExchange.Redis;

namespace api.Utilities
{
    public class NonceMiddleware(RequestDelegate next, ConnectionMultiplexer redis)
    {
        private static readonly string[] ALLOWED_METHODS = ["POST", "PUT", "PATCH", "DELETE"];
        private static readonly string[] EXCLUDED_HEADERS =
        [
            "Content-Type",
            "Server",
            "Content-Length",
            "Transfer-Encoding",
            "Connection",
            "Keep-Alive",
            "Upgrade",
            "Proxy-Authenticate",
            "Proxy-Authorization",
            "TE",
            "Trailer",
        ];

        private readonly RequestDelegate _next = next;
        private readonly IDatabase _redisDb = redis.GetDatabase();

        private static bool ShouldCache(int statusCode)
        {
            return statusCode switch
            {
                >= 200 and < 300 => true,

                301 => true,
                308 => true,

                400 => true,
                405 => true,
                409 => true,
                410 => true,
                _ => false,
            };
        }

        public async Task InvokeAsync(HttpContext context)
        {
            if (ALLOWED_METHODS.Contains(context.Request.Method))
            {
                var headerNonce = context.Request.Headers["Nonce"].ToString();

                var nonceKey =
                    $"nonce:{context.Request.Method}:{context.Request.Path}:{headerNonce}";

                RedisValue cached = await _redisDb.StringGetAsync(nonceKey);

                if (
                    cached.HasValue
                    && JsonSerializer.Deserialize<Response>((string)cached!)
                        is Response cachedResponse
                )
                {
                    context.Response.StatusCode = cachedResponse.StatusCode;
                    context.Response.ContentType = cachedResponse.ContentType;

                    foreach (var header in cachedResponse.Headers)
                    {
                        if (!EXCLUDED_HEADERS.Contains(header.Key))
                        {
                            context.Response.Headers[header.Key] = header.Value;
                        }
                    }

                    if (cachedResponse.Body != null)
                    {
                        await context.Response.WriteAsync(cachedResponse.Body);
                    }
                    await context.Response.CompleteAsync();
                }
                else
                {
                    var originalBodyStream = context.Response.Body;

                    try
                    {
                        using var memStream = new MemoryStream();
                        context.Response.Body = memStream;

                        await _next.Invoke(context);

                        memStream.Seek(0, SeekOrigin.Begin);

                        var responseBody = await new StreamReader(memStream).ReadToEndAsync();

                        memStream.Seek(0, SeekOrigin.Begin);
                        await memStream.CopyToAsync(originalBodyStream);
                        context.Response.Body = originalBodyStream;

                        if (ShouldCache(context.Response.StatusCode))
                        {
                            var response = new Response(
                                statusCode: context.Response.StatusCode,
                                body: responseBody,
                                contentType: context.Response.ContentType
                            );

                            foreach (var header in context.Response.Headers)
                            {
                                if (!EXCLUDED_HEADERS.Contains(header.Key) && header.Value.Count > 0)
                                {
                                    response.Headers[header.Key] = header.Value!;
                                }
                            }

                            await _redisDb.StringSetAsync(
                                nonceKey,
                                JsonSerializer.Serialize(response),
                                TimeSpan.FromMinutes(10)
                            );
                        }
                    }
                    finally
                    {
                        context.Response.Body = originalBodyStream;
                    }
                }
            }
            else
            {
                await _next(context);
            }
        }
    }
}
