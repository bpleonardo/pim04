using System.Text;
using api.Data;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
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

            builder.Services.AddScoped<Repositories.HorariosRepository>();
            builder.Services.AddScoped<Services.HorariosService>();

            builder.Services.AddScoped<Repositories.AgendamentosRepository>();
            builder.Services.AddScoped<Services.AgendamentosService>();

            builder.Services.AddScoped<Repositories.UsuariosRepository>();
            builder.Services.AddScoped<Services.AuthService>();

            builder.Services.AddScoped<Repositories.FuncionariosRepository>();
            builder.Services.AddScoped<Services.FuncionariosService>();


            // O Flutter Web usa uma porta local variável durante o desenvolvimento.
            if (builder.Environment.IsDevelopment())
            {
                builder.Services.AddCors(options =>
                    options.AddPolicy(
                        "FlutterLocal",
                        policy =>
                            policy
                                .SetIsOriginAllowed(origin =>
                                    Uri.TryCreate(origin, UriKind.Absolute, out var uri)
                                    && uri.IsLoopback
                                    && (uri.Scheme == "http" || uri.Scheme == "https")
                                )
                                .AllowAnyHeader()
                                .WithExposedHeaders("Access-Token-Expired")
                                .AllowAnyMethod()
                    )
                );
            }

            var jwtSecret = Environment.GetEnvironmentVariable("JWT_KEY");
            if (string.IsNullOrWhiteSpace(jwtSecret) || Encoding.UTF8.GetByteCount(jwtSecret) < 32)
                throw new InvalidOperationException("JWT_KEY must contain at least 32 bytes.");

            var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret));
            builder.Services.AddSingleton(signingKey);
            builder
                .Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
                .AddJwtBearer(options =>
                {
                    options.Events = new JwtBearerEvents
                    {
                        OnChallenge = context =>
                        {
                            if (context.AuthenticateFailure is SecurityTokenExpiredException)
                                context.Response.Headers["Access-Token-Expired"] = "true";
                            return Task.CompletedTask;
                        },
                    };
                    options.TokenValidationParameters = new TokenValidationParameters
                    {
                        ValidateIssuerSigningKey = true,
                        IssuerSigningKey = signingKey,
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
            builder.Services.AddExceptionHandler<Utilities.GlobalExceptionHandler>();
            builder.Services.AddProblemDetails();

            builder
                .Services.AddControllers()
                .ConfigureApiBehaviorOptions(options =>
                {
                    options.InvalidModelStateResponseFactory = context =>
                    {
                        var errors = context
                            .ModelState.Where(e => e.Value?.Errors.Count > 0)
                            .SelectMany(e => e.Value!.Errors.Select(x => x.ErrorMessage))
                            .Where(msg => !string.IsNullOrWhiteSpace(msg))
                            .ToList();

                        var message =
                            errors.Count > 0
                                ? string.Join("; ", errors)
                                : "Dados de requisição inválidos.";

                        var errorResponse = new Utilities.ErrorResponse(
                            "VALIDATION_ERROR",
                            message
                        );
                        return new Microsoft.AspNetCore.Mvc.BadRequestObjectResult(errorResponse);
                    };
                });

            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen();

            // Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
            builder.Services.AddOpenApi();

            var app = builder.Build();

            app.UseExceptionHandler();

            using (var scope = app.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                await db.Database.MigrateAsync();
            }

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

            app.UseWhen(
                context => context.Request.Headers.ContainsKey("Nonce")
                    && !context.Request.Path.StartsWithSegments("/api/login", StringComparison.OrdinalIgnoreCase),
                appBuilder =>
                {
                    appBuilder.UseMiddleware<Utilities.NonceMiddleware>();
                }
            );


            app.MapGet("/api/ping", () => Results.Ok(new { status = "ok" }));
            app.MapControllers();

            await app.RunAsync();
        }
    }
}
