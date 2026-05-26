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
    }
}
