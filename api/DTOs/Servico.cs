using System.ComponentModel.DataAnnotations;

namespace api.DTOs
{
    public readonly struct ServicoDTO(Guid id, string nome, string? descricao, double preco, bool ativo = true, bool vinculado = false)
    {
        public bool Ativo { get; init; } = ativo;
        public bool Vinculado { get; init; } = vinculado;
        public Guid Id { get; init; } = id;
        public string Nome { get; init; } = nome;
        public string? Descricao { get; init; } = descricao;
        public double Preco { get; init; } = preco;
    }

    public struct ServicoCreateDTO
    {
        [Required(ErrorMessage = "{0} é obrigatório!")]
        [MinLength(3, ErrorMessage = "{0} deve conter pelo menos {1} caracteres!")]
        public string Nome { get; set; }

        [MinLength(5, ErrorMessage = "{0} deve conter pelo menos {1} caracteres!")]
        public string? Descricao { get; set; }

        [Required(ErrorMessage = "{0} é obrigatório!")]
        [Range(0.01, 9999.99, ErrorMessage = "{0} deve ser um valor positivo!")]
        public double Preco { get; set; }
    }

    public struct ServicoUpdateDTO
    {
        public bool? Ativo { get; set; }

        [MinLength(3, ErrorMessage = "{0} deve conter pelo menos {1} caracteres!")]
        public string? Nome { get; set; }

        [MinLength(5, ErrorMessage = "{0} deve conter pelo menos {1} caracteres!")]
        public string? Descricao { get; set; }

        [Range(0.01, 9999.99, ErrorMessage = "{0} deve ser um valor positivo!")]
        public double? Preco { get; set; }
    }
}
