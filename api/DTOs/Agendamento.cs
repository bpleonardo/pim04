namespace api.DTOs
{
    public readonly struct MinAgendamentoDTO(
        Guid id,
        DateTime dataAgendamento,
        string status,
        double total,
        ServicoDTO[] servicos,
        MinClienteDTO cliente,
        MinFuncionarioDTO funcionario
    )
    {
        public Guid Id { get; init; } = id;
        public DateTime DataAgendamento { get; init; } = dataAgendamento;
        public string Status { get; init; } = status;
        public double Total { get; init; } = total;
        public ServicoDTO[] Servicos { get; init; } = servicos;
        public MinClienteDTO Cliente { get; init; } = cliente;
        public MinFuncionarioDTO Funcionario { get; init; } = funcionario;
    }
}
