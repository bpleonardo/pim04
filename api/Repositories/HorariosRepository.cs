using api.DTOs;
using api.Utilities;
using Npgsql;

namespace api.Repositories
{
    public class HorariosRepository(NpgsqlDataSource ds)
    {
        private readonly NpgsqlDataSource _ds = ds;

        public async Task<List<HorarioDTO>> GetHorariosDisponiveis(
            DateOnly date,
            TimeOnly startTime,
            TimeOnly endTime
        )
        {
            var horarios = new List<HorarioDTO>();

            await using var connection = await _ds.OpenConnectionAsync();

            await using var command = new NpgsqlCommand(
                Queries.GET_HORARIOS_DISPONIVEIS,
                connection
            );
            command.Parameters.AddWithValue("start_date", date.ToDateTime(startTime));
            command.Parameters.AddWithValue("end_date", date.ToDateTime(endTime));
            command.Parameters.AddWithValue("date", date);

            await using var reader = await command.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                var slot = reader.GetString(0);
                var available = reader.GetBoolean(1);

                horarios.Add(new HorarioDTO(slot, available));
            }

            return horarios;
        }
    }
}
