using api.Data;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.EntityFrameworkCore;
using StackExchange.Redis;
using static api.Utilities.Functions;

namespace api
{
    public class Program
    {
        public static async Task Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            var dbConnString = GetDbConnectionString(builder);

            // Registro do DbContext do Entity Framework Core com provedor PostgreSQL
            builder.Services.AddDbContext<AppDbContext>(options =>
            {
                options.UseNpgsql(dbConnString);

                if (builder.Environment.IsDevelopment())
                {
                    options
                        .UseSeeding((context, _) => DevSeeder.Seed((AppDbContext)context))
                        .UseAsyncSeeding(
                            (context, _, ct) => DevSeeder.SeedAsync((AppDbContext)context, ct)
                        );
                }
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

            // O Flutter Web usa uma porta local variável durante o desenvolvimento.
            if (builder.Environment.IsDevelopment())
            {
                builder.Services.AddCors(options =>
                    options.AddPolicy("FlutterLocal", policy =>
                        policy
                            .SetIsOriginAllowed(origin =>
                                Uri.TryCreate(origin, UriKind.Absolute, out var uri)
                                && uri.IsLoopback
                                && (uri.Scheme == "http" || uri.Scheme == "https"))
                            .AllowAnyHeader()
                            .AllowAnyMethod()));
            }

            builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
                .AddJwtBearer(options =>
                {
                    options.TokenValidationParameters = new TokenValidationParameters
                    {
                        ValidateIssuerSigningKey = true,
                        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(
                            builder.Configuration["Jwt:Key"] ?? "your-secret-key-change-in-production")),
                        ValidateIssuer = true,
                        ValidIssuer = builder.Configuration["Jwt:Issuer"] ?? "api",
                        ValidateAudience = true,
                        ValidAudience = builder.Configuration["Jwt:Audience"] ?? "client",
                        ValidateLifetime = true,
                        ClockSkew = TimeSpan.Zero,
                        ValidAlgorithms = [SecurityAlgorithms.HmacSha256],
                    };
                });
            builder.Services.AddAuthorization();
            builder.Services.AddControllers();

            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen();

            // Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
            builder.Services.AddOpenApi();

            var app = builder.Build();

            using (var scope = app.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                await db.Database.MigrateAsync();
            }

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

            if (app.Environment.IsDevelopment())
            {
                app.UseCors("FlutterLocal");
            }

            app.UseAuthentication();
            app.UseAuthorization();

            app.MapControllers();

            await app.RunAsync();
        }
    }
}
