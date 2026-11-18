-- Semente de teste a fim de desenvolvimento.
-- Não deverá ser utilizada em produção, e deverá ser mantida apenas como referência.
BEGIN;

TRUNCATE TABLE
    "ServicePriceChanges",
    "RefreshSessions",
    "FuncionarioDisponibilidades",
    "ServicosRealizados",
    "Usuarios",
    "Agendamentos",
    "Servicos",
    "Funcionarios",
    "Clientes"
CASCADE;

-- Clientes
INSERT INTO "Clientes" ("Id", "Nome", "Telefone", "Email", "CPF", "DtNascimento") VALUES
('a3f1c9d2-6b4e-4f8a-9d1c-2e7b5a0f3c11', 'João Silva',  '11999990001', 'joao.silva@email.com',  '12345678901', '1990-05-10'),
('b7e2d4a1-9c3f-4a6b-8e2d-1f0c7b5a9d22', 'Maria Souza', '11999990002', 'maria.souza@email.com', '12345678902', '1988-11-22'),
('c1d3e5f7-2a4b-4c6d-9e1f-3b5a7c9d0e33', 'Pedro Lima',  '11999990003', 'pedro.lima@email.com',  '12345678903', '1995-02-14');

-- Funcionários
INSERT INTO "Funcionarios" ("Id", "Nome", "Telefone", "CPF", "Email", "Endereco", "IsDeleted") VALUES
('d4a6c8e0-1b3d-4f5a-9c2e-7b0d1f3a5c44', 'Ana Costa',   '11999990004', '98765432101', 'ana.costa@empresa.com',   'Rua A, 100', false),
('e5b7d9f1-2c4e-4a6b-8d3f-0c1e2a4b6d55', 'Bruno Alves', '11999990005', '98765432102', 'bruno.alves@empresa.com', 'Rua B, 200', false);

-- Serviços
INSERT INTO "Servicos" ("Id", "Nome", "Descricao", "Preco", "Ativo") VALUES
('f6c8e0a2-3d5f-4b7c-9e4a-1d2f3b5c7e66', 'Corte de Cabelo', 'Corte masculino/feminino', 50.00, true),
('07d9f1b3-4e6a-4c8d-8f5b-2e3a4c6d8f77', 'Barba',           'Aparar e modelar barba',    35.00, true),
('18e0a2c4-5f7b-4d9e-9a6c-3f4b5d7e9a88', 'Hidratação',      'Tratamento capilar',        80.00, false);

-- Agendamentos
INSERT INTO "Agendamentos" ("Id", "IdCliente", "IdFuncionario", "DataAgendamento", "DataConclusao", "Status", "ValorTotal", "ClientRequestId", "LastMutationId", "RequestHash", "Revision") VALUES
('29f1b3d5-6a8c-4e0f-8b7d-4a5c6e8f0b99', 'a3f1c9d2-6b4e-4f8a-9d1c-2e7b5a0f3c11', 'd4a6c8e0-1b3d-4f5a-9c2e-7b0d1f3a5c44', '2026-04-28 10:00:00+00', '2026-04-28 11:00:00+00', 'concluido', 85.00, 'seed-complete-001', 'seed-mutation-001', NULL, 1),
('3af2c4e6-7b9d-4f1a-9c8e-5b6d7f9a1caa', 'b7e2d4a1-9c3f-4a6b-8e2d-1f0c7b5a9d22', 'e5b7d9f1-2c4e-4a6b-8d3f-0c1e2a4b6d55', '2026-04-29 14:00:00+00', NULL,                         'agendado',  50.00, 'seed-scheduled-002', 'seed-mutation-002', NULL, 1),
('4bf3d5f7-8c0e-4a2b-8d9f-6c7e8a0b2dbb', 'c1d3e5f7-2a4b-4c6d-9e1f-3b5a7c9d0e33', 'd4a6c8e0-1b3d-4f5a-9c2e-7b0d1f3a5c44', '2026-04-30 09:30:00+00', NULL,                         'cancelado', NULL,  'seed-canceled-003', 'seed-mutation-003', NULL, 1);

-- Usuários (1:1 com funcionário)
INSERT INTO "Usuarios" ("IdFuncionario", "Login", "Senha", "password_expired") VALUES
('d4a6c8e0-1b3d-4f5a-9c2e-7b0d1f3a5c44', 'ana.costa',   'senha_teste_ana',   false),
('e5b7d9f1-2c4e-4a6b-8d3f-0c1e2a4b6d55', 'bruno.alves', 'senha_teste_bruno', false);

-- Disponibilidade semanal dos funcionários
INSERT INTO "FuncionarioDisponibilidades" ("Id", "IdFuncionario", "DiaSemana", "Inicio", "Fim") VALUES
('50b4d5e6-7c8a-4f90-8d1e-2a3b4c5d6e71', 'd4a6c8e0-1b3d-4f5a-9c2e-7b0d1f3a5c44', 1, '09:00:00', '18:00:00'),
('61c5e6f7-8d9b-4a01-9e2f-3b4c5d6e7f82', 'd4a6c8e0-1b3d-4f5a-9c2e-7b0d1f3a5c44', 2, '09:00:00', '18:00:00'),
('72d6f7a8-9e0c-4b12-8f30-4c5d6e7f8093', 'e5b7d9f1-2c4e-4a6b-8d3f-0c1e2a4b6d55', 3, '10:00:00', '19:00:00');

-- Sessões de refresh de teste
INSERT INTO "RefreshSessions" ("Jti", "EmployeeId", "ExpiresAt") VALUES
('83e7a8b9-0f1d-4c23-9a41-5d6e7f8091a4', 'd4a6c8e0-1b3d-4f5a-9c2e-7b0d1f3a5c44', '2027-12-31 23:59:59+00');

-- Histórico de alteração de preços
INSERT INTO "ServicePriceChanges" ("ServiceId", "ServiceName", "OldPrice", "NewPrice", "ChangedAt") VALUES
('f6c8e0a2-3d5f-4b7c-9e4a-1d2f3b5c7e66', 'Corte de Cabelo', 45.00, 50.00, '2026-04-01 12:00:00+00');

-- Serviços realizados (N:N entre agendamento e serviço)
INSERT INTO "ServicosRealizados" ("IdAgendamento", "IdServico", "Valor") VALUES
('29f1b3d5-6a8c-4e0f-8b7d-4a5c6e8f0b99', 'f6c8e0a2-3d5f-4b7c-9e4a-1d2f3b5c7e66', 50.00), -- corte
('29f1b3d5-6a8c-4e0f-8b7d-4a5c6e8f0b99', '07d9f1b3-4e6a-4c8d-8f5b-2e3a4c6d8f77', 35.00), -- barba
('3af2c4e6-7b9d-4f1a-9c8e-5b6d7f9a1caa', 'f6c8e0a2-3d5f-4b7c-9e4a-1d2f3b5c7e66', 50.00); -- corte

COMMIT;
