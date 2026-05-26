namespace api.Utilities
{
    public static class Functions
    {
        public static string GetDbConnectionString(WebApplicationBuilder builder)
        {
            var fromEnv = Environment.GetEnvironmentVariable("DB_CONNECTION_STRING");
            if (!string.IsNullOrEmpty(fromEnv))
            {
                return fromEnv;
            }

            return builder.Configuration.GetConnectionString("DefaultConnection")
                ?? throw new InvalidOperationException(
                    "Connection string 'DefaultConnection' not found."
                );
        }

        public static string GetRedisConnectionString(WebApplicationBuilder builder)
        {
            var fromEnv = Environment.GetEnvironmentVariable("REDIS_CONNECTION_STRING");
            if (!string.IsNullOrEmpty(fromEnv))
            {
                return fromEnv;
            }

            return builder.Configuration.GetConnectionString("RedisConnection")
                ?? throw new InvalidOperationException(
                    "Connection string 'RedisConnection' not found."
                );
        }
    }
}
