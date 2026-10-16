using api.Models;
using Microsoft.EntityFrameworkCore;

namespace api.Data
{
    /// <summary>
    /// Provides initial test seed data for development builds, equivalent to resources/database/test_seed.sql.
    /// </summary>
    public static class DevSeeder
    {
        private static readonly Guid SeedCheckClienteId = Guid.Parse(
            "a3f1c9d2-6b4e-4f8a-9d1c-2e7b5a0f3c11"
        );

        public static void Seed(AppDbContext context)
        {
            if (context.Clientes.Any(c => c.Id == SeedCheckClienteId))
            {
                return;
            }

            context.AddRange(GetSeedEntities());
            context.SaveChanges();
        }

        public static async Task SeedAsync(
            AppDbContext context,
            CancellationToken cancellationToken = default
        )
        {
            if (await context.Clientes.AnyAsync(c => c.Id == SeedCheckClienteId, cancellationToken))
            {
                return;
            }

            await context.AddRangeAsync(GetSeedEntities(), cancellationToken);
            await context.SaveChangesAsync(cancellationToken);
        }

        private static object[] GetSeedEntities()
        {
            // Clientes
            var clientes = new[]
            {
                new Cliente(
                    id: Guid.Parse("a3f1c9d2-6b4e-4f8a-9d1c-2e7b5a0f3c11"),
                    nome: "João Silva",
                    telefone: "11999990001",
                    cpf: "12345678901",
                    email: "joao.silva@email.com",
                    dtNascimento: new DateOnly(1990, 5, 10)
                ),
                new Cliente(
                    id: Guid.Parse("b7e2d4a1-9c3f-4a6b-8e2d-1f0c7b5a9d22"),
                    nome: "Maria Souza",
                    telefone: "11999990002",
                    cpf: "12345678902",
                    email: "maria.souza@email.com",
                    dtNascimento: new DateOnly(1988, 11, 22)
                ),
                new Cliente(
                    id: Guid.Parse("c1d3e5f7-2a4b-4c6d-9e1f-3b5a7c9d0e33"),
                    nome: "Pedro Lima",
                    telefone: "11999990003",
                    cpf: "12345678903",
                    email: "pedro.lima@email.com",
                    dtNascimento: new DateOnly(1995, 2, 14)
                ),
            };

            // Funcionários
            var funcionarios = new[]
            {
                new Funcionario(
                    id: Guid.Parse("d4a6c8e0-1b3d-4f5a-9c2e-7b0d1f3a5c44"),
                    nome: "Ana Costa",
                    telefone: "11999990004",
                    cpf: "98765432101",
                    email: "ana.costa@empresa.com",
                    endereco: "Rua A, 100"
                ),
                new Funcionario(
                    id: Guid.Parse("e5b7d9f1-2c4e-4a6b-8d3f-0c1e2a4b6d55"),
                    nome: "Bruno Alves",
                    telefone: "11999990005",
                    cpf: "98765432102",
                    email: "bruno.alves@empresa.com",
                    endereco: "Rua B, 200"
                ),
            };

            // Serviços
            var servicos = new[]
            {
                new Servico(
                    id: Guid.Parse("f6c8e0a2-3d5f-4b7c-9e4a-1d2f3b5c7e66"),
                    nome: "Corte de Cabelo",
                    descricao: "Corte masculino/feminino",
                    preco: 50.00
                ),
                new Servico(
                    id: Guid.Parse("07d9f1b3-4e6a-4c8d-8f5b-2e3a4c6d8f77"),
                    nome: "Barba",
                    descricao: "Aparar e modelar barba",
                    preco: 35.00
                ),
                new Servico(
                    id: Guid.Parse("18e0a2c4-5f7b-4d9e-9a6c-3f4b5d7e9a88"),
                    nome: "Hidratação",
                    descricao: "Tratamento capilar",
                    preco: 80.00
                ),
            };

            // Usuários (1:1 com funcionário)
            var usuarios = new[]
            {
                new Usuario(
                    idFuncionario: Guid.Parse("d4a6c8e0-1b3d-4f5a-9c2e-7b0d1f3a5c44"),
                    login: "ana.costa",
                    senha: "senha_teste_ana"
                ),
                new Usuario(
                    idFuncionario: Guid.Parse("e5b7d9f1-2c4e-4a6b-8d3f-0c1e2a4b6d55"),
                    login: "bruno.alves",
                    senha: "senha_teste_bruno"
                ),
            };

            // Agendamentos
            var agendamentos = new[]
            {
                new Agendamento
                {
                    Id = Guid.Parse("29f1b3d5-6a8c-4e0f-8b7d-4a5c6e8f0b99"),
                    IdCliente = Guid.Parse("a3f1c9d2-6b4e-4f8a-9d1c-2e7b5a0f3c11"),
                    IdFuncionario = Guid.Parse("d4a6c8e0-1b3d-4f5a-9c2e-7b0d1f3a5c44"),
                    DataAgendamento = DateTime.SpecifyKind(
                        DateTime.Parse("2026-04-28 10:00:00"),
                        DateTimeKind.Utc
                    ),
                    DataConclusao = DateTime.SpecifyKind(
                        DateTime.Parse("2026-04-28 11:00:00"),
                        DateTimeKind.Utc
                    ),
                    Status = "concluido",
                    ValorTotal = 85.00,
                },
                new Agendamento
                {
                    Id = Guid.Parse("3af2c4e6-7b9d-4f1a-9c8e-5b6d7f9a1caa"),
                    IdCliente = Guid.Parse("b7e2d4a1-9c3f-4a6b-8e2d-1f0c7b5a9d22"),
                    IdFuncionario = Guid.Parse("e5b7d9f1-2c4e-4a6b-8d3f-0c1e2a4b6d55"),
                    DataAgendamento = DateTime.SpecifyKind(
                        DateTime.Parse("2026-04-29 14:00:00"),
                        DateTimeKind.Utc
                    ),
                    DataConclusao = null,
                    Status = "agendado",
                    ValorTotal = 50.00,
                },
                new Agendamento
                {
                    Id = Guid.Parse("4bf3d5f7-8c0e-4a2b-8d9f-6c7e8a0b2dbb"),
                    IdCliente = Guid.Parse("c1d3e5f7-2a4b-4c6d-9e1f-3b5a7c9d0e33"),
                    IdFuncionario = Guid.Parse("d4a6c8e0-1b3d-4f5a-9c2e-7b0d1f3a5c44"),
                    DataAgendamento = DateTime.SpecifyKind(
                        DateTime.Parse("2026-04-30 09:30:00"),
                        DateTimeKind.Utc
                    ),
                    DataConclusao = null,
                    Status = "cancelado",
                    ValorTotal = null,
                },
            };

            // Serviços realizados (N:N entre agendamento e serviço)
            var servicosRealizados = new[]
            {
                new ServicoRealizado
                {
                    IdAgendamento = Guid.Parse("29f1b3d5-6a8c-4e0f-8b7d-4a5c6e8f0b99"),
                    IdServico = Guid.Parse("f6c8e0a2-3d5f-4b7c-9e4a-1d2f3b5c7e66"),
                    Valor = 50.00,
                },
                new ServicoRealizado
                {
                    IdAgendamento = Guid.Parse("29f1b3d5-6a8c-4e0f-8b7d-4a5c6e8f0b99"),
                    IdServico = Guid.Parse("07d9f1b3-4e6a-4c8d-8f5b-2e3a4c6d8f77"),
                    Valor = 35.00,
                },
                new ServicoRealizado
                {
                    IdAgendamento = Guid.Parse("3af2c4e6-7b9d-4f1a-9c8e-5b6d7f9a1caa"),
                    IdServico = Guid.Parse("f6c8e0a2-3d5f-4b7c-9e4a-1d2f3b5c7e66"),
                    Valor = 50.00,
                },
            };

            return
            [
                .. clientes,
                .. funcionarios,
                .. servicos,
                .. usuarios,
                .. agendamentos,
                .. servicosRealizados,
            ];
        }
    }
}
