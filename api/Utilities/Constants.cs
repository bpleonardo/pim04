namespace api.Utilities
{
    public static class Queries
    {
        #region Queries de Serviços
        public const string GET_ALL_SERVICOS = "SELECT id, nome, descricao, valor FROM tb_servico";
        public const string GET_SERVICO_BY_ID =
            "SELECT id, nome, descricao, valor FROM tb_servico WHERE id = $1";
        public const string DELETE_SERVICO_BY_ID = "DELETE FROM tb_servico WHERE id = $1";
        public const string INSERT_SERVICO =
            "INSERT INTO tb_servico (id, nome, descricao, valor) VALUES ($1, $2, $3, $4)";
        public const string UPDATE_SERVICO_UPSERT =
            @"INSERT INTO tb_servico (id, nome, descricao, valor)
            VALUES ($1, $2, $3, $4)
            ON CONFLICT (id) DO UPDATE
            SET
                nome = EXCLUDED.nome,
                descricao = EXCLUDED.descricao,
                valor = EXCLUDED.valor
            WHERE
                nome IS DISTINCT FROM EXCLUDED.nome
                OR descricao IS DISTINCT FROM EXCLUDED.descricao
                OR valor IS DISTINCT FROM EXCLUDED.valor";
        public const string UPDATE_SERVICO =
            @"
            UPDATE tb_servico SET nome=$2, descricao=$3, valor=$4
            WHERE id = $1
            AND (
                nome IS DISTINCT FROM $2
                OR descricao IS DISTINCT FROM $3
                OR valor IS DISTINCT FROM $4
            )";
        #endregion

        #region Queries de Clientes
        public const string GET_ALL_CLIENTES =
            "SELECT id, nome, telefone, email, cpf, dt_nasc FROM tb_cliente";

        public const string GET_CLIENTE_BY_ID =
            "SELECT id, nome, telefone, email, cpf, dt_nasc FROM tb_cliente WHERE id = $1";
        public const string INSERT_CLIENTE =
            "INSERT INTO tb_cliente (id, nome, telefone, email, cpf, dt_nasc) VALUES ($1, $2, $3, $4, $5, $6)";
        public const string QUERY_CPF = "SELECT COUNT(*) FROM tb_cliente WHERE cpf = $1";
        #endregion

        #region Horarios Disponíveis
        public const string GET_HORARIOS_DISPONIVEIS =
            @"
            WITH
                slots AS (
                    SELECT
                        generate_series(
                            @start_date::timestamptz,
                            @end_date::timestamptz,
                            INTERVAL '30 minutes'
                        ) AS slot_utc
                ),
                funcionarios AS (
                    SELECT id AS funcionario_id FROM tb_funcionario
                )
            SELECT
                to_char(slot_utc AT TIME ZONE 'America/Sao_Paulo', 'HH24:MI') AS hora,
                EXISTS (
                    SELECT 1
                    FROM funcionarios f
                    WHERE NOT EXISTS (
                        SELECT 1
                        FROM tb_agendamento a
                        WHERE a.id_funcionario = f.funcionario_id
                        AND (a.dt_agendamento AT TIME ZONE 'America/Sao_Paulo')::date = @date::date
                        AND to_char(a.dt_agendamento AT TIME ZONE 'America/Sao_Paulo', 'HH24:MI') = to_char(slot_utc AT TIME ZONE 'America/Sao_Paulo', 'HH24:MI')
                        AND a.status = 'agendado'
                    )
                ) AS disponivel
            FROM slots
            ORDER BY hora;";
        #endregion

        #region Queries de Agendamento
        public const string QUERY_AGENDAMENTOS_BY_DATE =
            @"
            SELECT
                a.id AS id_agendamento,
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
            WHERE (a.dt_agendamento AT TIME ZONE 'America/Sao_Paulo')::date = $1::date
            ORDER BY a.dt_agendamento;
            ";

        public const string QUERY_SERVICOS_BY_AGENDAMENTO =
            @"
            SELECT
                s.id,
                s.nome,
                s.descricao,
                s.valor
            FROM tb_servico_realizado sr
            INNER JOIN tb_servico s ON sr.id_servico = s.id
            WHERE sr.id_agendamento = $1;
            ";
        #endregion
    }
}
