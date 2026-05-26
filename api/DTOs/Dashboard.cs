namespace api.DTOs
{
    public readonly struct IndicadorDTO
    {
        public string Label { get; init; }
        public string Value { get; init; }
        public string Note { get; init; }
        public bool Highlight { get; init; }
    }

    public readonly struct DashboardDTO
    {
        public IndicadorDTO[] Indicadores { get; init; }
        public string CurrentDate { get; init; }
        public string Status { get; init; } // "ok" | "warning" | "critical"
    }
}
