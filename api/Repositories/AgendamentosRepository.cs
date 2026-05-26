using api.DTOs;
using api.Utilities;
using Npgsql;

namespace api.Repositories
{
    public class AgendamentosRepository(NpgsqlDataSource ds)
    {
        private readonly NpgsqlDataSource _ds = ds;

        private async Task<ServicoDTO[]> GetServicosByAgendamentoId(Guid agendamentoId)
        {
            var servicos = new List<ServicoDTO>();

            await using var connection = await _ds.OpenConnectionAsync();

            await using var command = new NpgsqlCommand(
                Queries.QUERY_SERVICOS_BY_AGENDAMENTO,
                connection
            );
            command.Parameters.AddWithValue(agendamentoId);

            await using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                var id = reader.GetGuid(0);
                var nome = reader.GetString(1);
                var descricao = reader.IsDBNull(2) ? null : reader.GetString(2);
                var preco = reader.GetDouble(3);

                servicos.Add(new ServicoDTO(id, nome, descricao, preco));
            }
            return [.. servicos];
        }

        public async Task<MinAgendamentoDTO[]> GetByDate(DateOnly date)
        {
            var agendamentos = new List<MinAgendamentoDTO>();

            await using var connection = await _ds.OpenConnectionAsync();

            await using var command = new NpgsqlCommand(
                Queries.QUERY_AGENDAMENTOS_BY_DATE,
                connection
            );
            command.Parameters.AddWithValue(date);

            await using var reader = await command.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                var id = reader.GetGuid(0);
                var data = reader.GetDateTime(1);
                var status = reader.GetString(2);
                var total = reader.GetDouble(3);
                var nomeCliente = reader.GetString(4);
                var telefoneCliente = reader.GetString(5);
                var idFuncionario = reader.GetGuid(6);
                var nomeFuncionario = reader.GetString(7);

                var servicos = await GetServicosByAgendamentoId(id);

                agendamentos.Add(
                    new MinAgendamentoDTO(
                        id,
                        data,
                        status,
                        total,
                        servicos,
                        new MinClienteDTO(nomeCliente, telefoneCliente),
                        new MinFuncionarioDTO(idFuncionario, nomeFuncionario)
                    )
                );
            }

            return [.. agendamentos];
        }

        /// <summary>
        /// Check if a given horário slot is available for a specific funcionário on a given date.
        /// </summary>
        public async Task<bool> IsSlotAvailable(Guid idFuncionario, DateTime dateTime)
        {
            await using var connection = await _ds.OpenConnectionAsync();

            // Convert to Brazilian time for comparison
            await using var command = new NpgsqlCommand(
                @"
                SELECT COUNT(*) FROM tb_agendamento
                WHERE id_funcionario = $1
                AND (dt_agendamento AT TIME ZONE 'America/Sao_Paulo')::date = $2::date
                AND to_char(dt_agendamento AT TIME ZONE 'America/Sao_Paulo', 'HH24:MI') = $3
                AND status = 'agendado'
                ",
                connection
            );

            command.Parameters.AddWithValue(idFuncionario);
            command.Parameters.AddWithValue(dateTime.Date);
            command.Parameters.AddWithValue(dateTime.ToString("HH:mm"));

            var result = (long?)await command.ExecuteScalarAsync();
            return result.HasValue && result.Value == 0;
        }

        /// <summary>
        /// Create a new appointment and related service records.
        /// </summary>
        public async Task<Maybe<Guid>> CreateOne(
            Guid idCliente,
            Guid idFuncionario,
            DateTime dataAgendamento,
            double total,
            Guid[] idServicos
        )
        {
            await using var connection = await _ds.OpenConnectionAsync();
            await using var transaction = await connection.BeginTransactionAsync();

            try
            {
                var agendamentoId = Guid.NewGuid();

                // Insert agendamento
                await using var cmdAgendamento = new NpgsqlCommand(
                    @"
                    INSERT INTO tb_agendamento (id, id_cliente, id_funcionario, dt_agendamento, status, total)
                    VALUES ($1, $2, $3, $4, 'agendado', $5)
                    ",
                    connection,
                    transaction
                );
                cmdAgendamento.Parameters.AddWithValue(agendamentoId);
                cmdAgendamento.Parameters.AddWithValue(idCliente);
                cmdAgendamento.Parameters.AddWithValue(idFuncionario);
                cmdAgendamento.Parameters.AddWithValue(dataAgendamento);
                cmdAgendamento.Parameters.AddWithValue(total);

                await cmdAgendamento.ExecuteNonQueryAsync();

                // Insert servicos_realizados for each service
                foreach (var idServico in idServicos)
                {
                    // Get service price
                    await using var cmdGetPrice = new NpgsqlCommand(
                        "SELECT valor FROM tb_servico WHERE id = $1",
                        connection,
                        transaction
                    );
                    cmdGetPrice.Parameters.AddWithValue(idServico);

                    var preco = await cmdGetPrice.ExecuteScalarAsync() as decimal?;
                    if (!preco.HasValue)
                        throw new Exception($"Serviço não encontrado: {idServico}");

                    await using var cmdServico = new NpgsqlCommand(
                        @"
                        INSERT INTO tb_servico_realizado (id_agendamento, id_servico, valor)
                        VALUES ($1, $2, $3)
                        ",
                        connection,
                        transaction
                    );
                    cmdServico.Parameters.AddWithValue(agendamentoId);
                    cmdServico.Parameters.AddWithValue(idServico);
                    cmdServico.Parameters.AddWithValue((double)preco.Value);

                    await cmdServico.ExecuteNonQueryAsync();
                }

                await transaction.CommitAsync();
                return new Maybe<Guid>(agendamentoId);
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return new Maybe<Guid>(ErrorCodes.NotFound);
            }
        }

        /// <summary>
        /// Update appointment status.
        /// </summary>
        public async Task<Maybe<bool>> UpdateStatus(Guid agendamentoId, string novoStatus)
        {
            await using var connection = await _ds.OpenConnectionAsync();

            await using var command = new NpgsqlCommand(
                @"
                UPDATE tb_agendamento 
                SET status = $2
                WHERE id = $1
                ",
                connection
            );
            command.Parameters.AddWithValue(agendamentoId);
            command.Parameters.AddWithValue(novoStatus);

            var affectedRows = await command.ExecuteNonQueryAsync();

            if (affectedRows == 0)
                return new Maybe<bool>(ErrorCodes.NotFound);

            return new Maybe<bool>(true);
        }

        /// <summary>
        /// Get a single appointment by ID with all details.
        /// </summary>
        public async Task<Maybe<MinAgendamentoDTO>> GetOne(Guid agendamentoId)
        {
            await using var connection = await _ds.OpenConnectionAsync();

            await using var command = new NpgsqlCommand(
                @"
                SELECT
                    a.id,
                    a.dt_agendamento,
                    a.status,
                    a.total,
                    c.nome AS cliente_nome,
                    c.telefone AS cliente_telefone,
                    f.id AS funcionario_id,
                    f.nome AS funcionario_nome
                FROM tb_agendamento a
                INNER JOIN tb_cliente c ON a.id_cliente = c.id
                INNER JOIN tb_funcionario f ON a.id_funcionario = f.id
                WHERE a.id = $1
                ",
                connection
            );
            command.Parameters.AddWithValue(agendamentoId);

            await using var reader = await command.ExecuteReaderAsync();

            if (await reader.ReadAsync())
            {
                var id = reader.GetGuid(0);
                var data = reader.GetDateTime(1);
                var status = reader.GetString(2);
                var total = reader.GetDouble(3);
                var nomeCliente = reader.GetString(4);
                var telefoneCliente = reader.GetString(5);
                var idFuncionario = reader.GetGuid(6);
                var nomeFuncionario = reader.GetString(7);

                var servicos = await GetServicosByAgendamentoId(id);

                return new Maybe<MinAgendamentoDTO>(
                    new MinAgendamentoDTO(
                        id,
                        data,
                        status,
                        total,
                        servicos,
                        new MinClienteDTO(nomeCliente, telefoneCliente),
                        new MinFuncionarioDTO(idFuncionario, nomeFuncionario)
                    )
                );
            }

            return new Maybe<MinAgendamentoDTO>(ErrorCodes.NotFound);
        }
    }
}
