using System.ComponentModel.DataAnnotations;
using api.Utilities;

namespace api.DTOs
{
    public readonly struct MinClienteDTO(string nome, string telefone)
    {
        public string Nome { get; init; } = nome;
        public string Telefone { get; init; } = telefone;
    }

    public struct ClienteDTO(
        Guid id,
        string nome,
        string telefone,
        string? cpf,
        string? email,
        DateTime? dtNascimento
    )
    {
        public Guid Id { get; init; } = id;
        public string Nome { get; set; } = nome;
        public string Telefone { get; set; } = telefone;
        public string? CPF { get; set; } = cpf;
        public string? Email { get; set; } = email;
        public DateTime? DtNascimento { get; set; } = dtNascimento;
    }

    public struct ClienteCreateDTO(
        string nome,
        string telefone,
        string? cpf,
        string? email,
        DateOnly? dtNascimento
    )
    {
        [Required]
        [MinLength(3, ErrorMessage = "{0} deve conter pelo menos {1} caracteres!")]
        public string Nome { get; set; } = nome;

        [Required]
        [RegularExpression(
            @"55\d{11}",
            ErrorMessage = "{0} deve conter 13 dígitos, incluindo o código do país '55'."
        )]
        public string Telefone { get; set; } = telefone;

        [CPF(AllowPunctuation = false)]
        [RegularExpression(@"\d{11}")]
        public string? CPF { get; set; } = cpf;

        [EmailAddress]
        public string? Email { get; set; } = email;

        [BirthDate(MaximumAge = 120)]
        public DateOnly? DtNascimento { get; set; } = dtNascimento;
    }
}
