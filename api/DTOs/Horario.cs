namespace api.DTOs
{
    public readonly struct HorarioDTO(string slot, bool available)
    {
        public string Slot { get; init; } = slot;
        public bool Available { get; init; } = available;
    }
}
