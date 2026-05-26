using api.DTOs;
using api.Utilities;
using Npgsql;

namespace api.Repositories
{
    public class FuncionariosRepository(NpgsqlDataSource ds)
    {
        private readonly NpgsqlDataSource _ds = ds;

        public async Task<FuncionarioDTO[]> GetAll()
        {
            var funcionarios = new List<FuncionarioDTO>();

            await using var connection = await _ds.OpenConnectionAsync();

            await using var command = new NpgsqlCommand(
                @"
                SELECT id, nome, COALESCE(telefone, ''), cpf, email, endereco 
                FROM tb_funcionario
                ORDER BY nome
                ",
                connection
            );

            await using var reader = await command.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                funcionarios.Add(
                    new FuncionarioDTO(
                        reader.GetGuid(0),
                        reader.GetString(1),
                        reader.GetString(2),
                        reader.IsDBNull(3) ? null : reader.GetString(3),
                        reader.IsDBNull(4) ? null : reader.GetString(4),
                        reader.GetString(5)
                    )
                );
            }

            return [.. funcionarios];
        }

        public async Task<Maybe<FuncionarioDTO>> GetOne(Guid id)
        {
            await using var connection = await _ds.OpenConnectionAsync();

            await using var command = new NpgsqlCommand(
                @"
                SELECT id, nome, COALESCE(telefone, ''), cpf, email, endereco 
                FROM tb_funcionario
                WHERE id = $1
                ",
                connection
            );
            command.Parameters.AddWithValue(id);

            await using var reader = await command.ExecuteReaderAsync();

            if (await reader.ReadAsync())
            {
                return new Maybe<FuncionarioDTO>(
                    new FuncionarioDTO(
                        reader.GetGuid(0),
                        reader.GetString(1),
                        reader.GetString(2),
                        reader.IsDBNull(3) ? null : reader.GetString(3),
                        reader.IsDBNull(4) ? null : reader.GetString(4),
                        reader.GetString(5)
                    )
                );
            }

            return new Maybe<FuncionarioDTO>(ErrorCodes.NotFound);
        }

        public async Task<bool> CreateOne(FuncionarioDTO dto)
        {
            await using var connection = await _ds.OpenConnectionAsync();

            await using var command = new NpgsqlCommand(
                @"
                INSERT INTO tb_funcionario (id, nome, telefone, cpf, email, endereco)
                VALUES ($1, $2, $3, $4, $5, $6)
                ",
                connection
            );

            command.Parameters.AddWithValue(dto.Id);
            command.Parameters.AddWithValue(dto.Nome);
            command.Parameters.AddWithValue((object?)dto.Telefone ?? DBNull.Value);
            command.Parameters.AddWithValue((object?)dto.CPF ?? DBNull.Value);
            command.Parameters.AddWithValue((object?)dto.Email ?? DBNull.Value);
            command.Parameters.AddWithValue(dto.Endereco);

            await command.ExecuteNonQueryAsync();
            return true;
        }
    }
}
