using api.DTOs;
using api.Utilities;
using Npgsql;

namespace api.Repositories
{
    public class UsuariosRepository(NpgsqlDataSource ds)
    {
        private readonly NpgsqlDataSource _ds = ds;

        /// <summary>
        /// Find user by login and verify password (plain text for now; should use BCrypt in production).
        /// Returns usuario with id_funcionario and associated funcionario data.
        /// </summary>
        public async Task<Maybe<(Guid IdFuncionario, string NomeFuncionario, string Login)>> GetByLoginAndPassword(
            string login,
            string senha
        )
        {
            await using var connection = await _ds.OpenConnectionAsync();

            await using var command = new NpgsqlCommand(
                @"
                SELECT u.id_funcionario, f.nome, u.login
                FROM tb_usuario u
                INNER JOIN tb_funcionario f ON u.id_funcionario = f.id
                WHERE u.login = $1 AND u.senha = $2
                LIMIT 1
                ",
                connection
            );
            command.Parameters.AddWithValue(login);
            command.Parameters.AddWithValue(senha);

            await using var reader = await command.ExecuteReaderAsync();

            if (await reader.ReadAsync())
            {
                var idFuncionario = reader.GetGuid(0);
                var nomeFuncionario = reader.GetString(1);
                var loginResult = reader.GetString(2);

                return new Maybe<(Guid, string, string)>((idFuncionario, nomeFuncionario, loginResult));
            }

            return new Maybe<(Guid, string, string)>(ErrorCodes.NotFound);
        }
    }
}
