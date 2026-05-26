namespace api.DTOs
{
    public readonly struct MinFuncionarioDTO(Guid id, string nome)
    {
        public Guid Id { get; init; } = id;
        public string Nome { get; init; } = nome;
    }
}
