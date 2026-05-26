using Npgsql;
using StackExchange.Redis;
using static api.Utilities.Functions;

namespace api
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            var dbConnString = GetDbConnectionString(builder);

            builder.Services.AddSingleton(sp =>
            {
                return NpgsqlDataSource.Create(dbConnString);
            });

            builder.Services.AddSingleton(sp =>
            {
                return ConnectionMultiplexer.Connect(GetRedisConnectionString(builder));
            });

            builder.Services.AddScoped<Repositories.ServicosRepository>();
            builder.Services.AddScoped<Services.ServicosService>();

            builder.Services.AddScoped<Repositories.ClientesRepository>();
            builder.Services.AddScoped<Services.ClientesService>();

            builder.Services.AddScoped<Repositories.HorariosRepository>();
            builder.Services.AddScoped<Services.HorariosService>();

            builder.Services.AddControllers();

            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen();

            // Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
            builder.Services.AddOpenApi();

            var app = builder.Build();

            app.UseWhen(
                context => context.Request.Headers.ContainsKey("Nonce"),
                appBuilder =>
                {
                    appBuilder.UseMiddleware<Utilities.NonceMiddleware>();
                }
            );

            // Configure the HTTP request pipeline.
            if (app.Environment.IsDevelopment())
            {
                app.MapOpenApi();
                app.UseSwagger();
                app.UseSwaggerUI();
            }

            app.UseAuthorization();

            app.MapControllers();

            app.Run();
        }
    }
}
