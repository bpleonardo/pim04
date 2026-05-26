namespace api.DTOs
{
    public readonly struct ServicoBreakdownDTO
    {
        public string Nome { get; init; }
        public string Valor { get; init; }
        public int Percentual { get; init; }
    }

    public readonly struct TransacaoDTO
    {
        public string Data { get; init; }
        public string Cliente { get; init; }
        public string Servico { get; init; }
        public string Valor { get; init; }
    }

    public readonly struct FinanceiroDTO
    {
        public IndicadorDTO[] Indicadores { get; init; }
        public ServicoBreakdownDTO[] Barras { get; init; }
        public TransacaoDTO[] Transacoes { get; init; }
        public string Total { get; init; }
    }
}
