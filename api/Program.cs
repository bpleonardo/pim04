using api.Data;
using Microsoft.EntityFrameworkCore;
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

            // Registro do DbContext do Entity Framework Core com provedor PostgreSQL
            builder.Services.AddDbContext<AppDbContext>(options =>
            {
                options.UseNpgsql(dbConnString);
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

            builder.Services.AddScoped<Repositories.AgendamentosRepository>();
            builder.Services.AddScoped<Services.AgendamentosService>();

            builder.Services.AddScoped<Repositories.UsuariosRepository>();
            builder.Services.AddScoped<Services.AuthService>();

            builder.Services.AddScoped<Repositories.FuncionariosRepository>();
            builder.Services.AddScoped<Services.FuncionariosService>();

            builder.Services.AddScoped<Services.DashboardService>();
            builder.Services.AddScoped<Services.FinanceiroService>();

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
