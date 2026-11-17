# Trigger de preços e procedure do dashboard

## O que foi implementado

A trigger `service_price_changed`, no PostgreSQL, registra mudanças reais em `Servicos.Preco`. Ela chama a função de trigger `record_service_price_change` e grava em `ServicePriceChanges`:

- Serviço e nome no momento da alteração.
- Preço anterior e preço novo.
- Data/hora da alteração, em `timestamptz`.

Inserir um serviço, alterar somente o nome ou salvar novamente o mesmo preço não gera uma mudança de preço. A auditoria participa da mesma transação: se a alteração for desfeita, seu histórico também será desfeito. O histórico começa quando a migração é aplicada; não reconstrói mudanças anteriores.

No painel Web/desktop, abra **Serviços** e use o ícone de histórico ao lado do serviço. O aplicativo exibe os valores em reais e a data/hora de São Paulo. A consulta exige login e conexão.

A exclusão de serviços vinculados a atendimentos continua bloqueada pela regra existente. Se um serviço sem atendimentos for excluído, seus registros de auditoria permanecem com o nome e os preços, e ServiceId fica nulo. A consulta global desses registros pode ser feita no banco; o painel mostra o histórico dos serviços ainda presentes no catálogo.

A procedure `daily_appointment_summary` recebe a data da agenda e um funcionário opcional. Retorna faturamento realizado, quantidade de concluídos, faturamento pendente, total de atendimentos ativos e contagem por serviço. Esses campos preservam as informações que o dashboard já apresentava. A procedure é chamada com **CALL**; não é uma função usada em SELECT.

Os limites do dia são calculados no fuso America/Sao_Paulo. O faturamento utiliza o valor registrado em cada agendamento, sem recalcular atendimentos antigos com o preço atual do catálogo. Cancelados ficam fora dos totais e do ranking; concluídos e agendados entram no total de ativos. Cada atendimento conta uma vez, mesmo com vários serviços. Serviços desabilitados são identificados no ranking. Dias sem registros devolvem zeros e ranking vazio.

O dashboard Web/desktop passa a receber esses resumos da API, mantendo o gráfico, os períodos, o ticket médio e o ranking. O mobile compartilha a tela e conserva o suporte offline: usa resumos já salvos ou converte o cache anterior de agendamentos, com aviso de dados desatualizados. O histórico de preços não acrescenta uma nova dependência offline móvel.

## Rotas

- GET `/api/servicos/{id}/price-history`: histórico de preços do serviço; requer autenticação.
- GET `/api/reports/daily?date=2026-11-15`: resumo geral do dia; requer autenticação.
- GET `/api/reports/daily?date=2026-11-15&mine=true`: resumo apenas do funcionário autenticado. O identificador é extraído do JWT, não recebido livremente do cliente.

## Arquivos principais

- `Models/ServicePriceChange.cs`: entidade do histórico.
- `Migrations/*_AddServicePriceHistory.cs`: tabela, função e trigger, com reversão.
- `Migrations/*_AddDailyAppointmentSummary.cs`: procedure, com reversão.
- `Repositories/ServicosRepository.cs` e `Services/ServicosService.cs`: consulta do histórico.
- `Repositories/ReportsRepository.cs`: chamada parametrizada à procedure.
- `Services/ReportsService.cs` e `Controllers/ReportsController.cs`: fluxo do relatório na arquitetura em camadas.
- `../frontend/lib/features/catalog/presentation/catalogo_screen.dart`: consulta visual do histórico.
- `../frontend/lib/features/dashboard/presentation/dashboard_screen.dart`: consumo dos resumos.

Também foram corrigidos os metadados de descoberta das migrações recentes de funcionários e disponibilidade e a relação ausente no snapshot. Os atributos do modelo foram alinhados à estrutura que essas migrações já definiam: endereço anulável e índice composto da disponibilidade. Assim, a migração do histórico não altera esses dados nem troca seus índices.

## Aplicar

Na raiz, execute `task start:api` para reconstruir a API de desenvolvimento. A inicialização aplica as migrações pendentes. Reinicie a execução do Flutter para carregar o painel atualizado. Para publicar pelo Nginx, recompile o painel com `task build:web` antes de iniciar a composição de produção configurada no projeto.

## Conferir no pgAdmin ou psql

Consulta somente de leitura:

```sql
SELECT "ServiceName", "OldPrice", "NewPrice", "ChangedAt", "ServiceId"
FROM public."ServicePriceChanges"
ORDER BY "ChangedAt" DESC, "Id" DESC
LIMIT 20;
```

Resumo geral para uma data de exemplo:

```sql
CALL public.daily_appointment_summary('2026-11-15', NULL, NULL, NULL, NULL, NULL, NULL);
```

Os dois primeiros argumentos são data e funcionário opcional. Os cinco NULL seguintes correspondem aos parâmetros de saída exigidos por CALL. Para filtrar diretamente no banco, substitua o segundo argumento pelo UUID de um funcionário de teste. Pela API, use mine=true.

## Testes automatizados

`resources/tests/DatabaseRoutinesChecks` verifica o código real em PostgreSQL. Por proteção, aceita somente um banco descartável cujo nome comece com `pim_routines_test_`. Ele aplica e reverte migrações; nunca use conexão de produção.

Configure PIM_TEST_DB_CONNECTION apontando para esse ambiente isolado e execute, na raiz:

```powershell
dotnet run --project resources/tests/DatabaseRoutinesChecks
```

Os cenários cobrem inserção sem auditoria, mudança real, SQL direto, preço inalterado, renomeação, rollback, preservação do histórico na exclusão, múltiplos serviços, cancelamentos, filtro por funcionário, dia vazio, valor legado nulo, limites do fuso horário, preço histórico e migrações Up/Down. Os registros de teste são revertidos ao final.

No frontend, execute `flutter analyze` e `flutter test`. Os testes também verificam a tela de histórico, os valores do dashboard, o botão de atualização e a conversão dos dados legados offline.

Referências técnicas: [CREATE TRIGGER](https://www.postgresql.org/docs/current/sql-createtrigger.html), [funções de trigger](https://www.postgresql.org/docs/current/plpgsql-trigger.html) e [CREATE PROCEDURE](https://www.postgresql.org/docs/current/sql-createprocedure.html), na documentação oficial do PostgreSQL.

## Relatórios por período

O dashboard utiliza `GET /api/reports?date=2026-11-16&period=weekly&mine=true`.
Os valores aceitos de `period` são `daily`, `weekly` e `monthly`; `date` é obrigatório.
A semana começa na segunda-feira e o mês no dia 1, ambos até a data informada,
preservando o comportamento dos seletores. `mine=true` restringe ao funcionário
identificado pelo JWT; sem essa flag, o painel consulta todos os funcionários.

A resposta inclui `startDate`, `endDate`, `summary` (totais e ranking calculados
pela API) e `revenueByDay` (série para o gráfico, incluindo dias com receita zero).
Uma consulta SQL agrega o período inteiro, sem um loop de chamadas diárias.
Valores históricos, cancelamentos, serviços desabilitados e os limites de dias
no fuso de São Paulo seguem as regras do resumo diário. A rota autenticada
`/api/reports/daily` e a procedure existente continuam disponíveis por compatibilidade.
Não é necessária uma nova migração para esse endpoint.

No mobile, cada período consultado online fica no SQLite. Sem conexão, o app lê
esse cache; se necessário, também consegue montar o período a partir dos resumos
diários legados já salvos, sem emitir requisições por dia. Os testes em
`DatabaseRoutinesChecks`, `period_reports_test.dart` e `offline_booking_test.dart`
cobrem os totais, os limites dos períodos e a quantidade de chamadas.

Ao consultar a agenda histórica, a preparação do cache de novos agendamentos
usa uma data dentro da janela de horários válida (hoje até 14 dias), em vez de
consultar horários disponíveis no passado. A API continua aceitando a consulta
de agendamentos antigos e recusando novos horários em datas passadas.
