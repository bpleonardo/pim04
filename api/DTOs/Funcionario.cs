using System.ComponentModel.DataAnnotations;

namespace api.DTOs
{
    public readonly struct MinFuncionarioDTO(Guid id, string nome)
    {
        public Guid Id { get; init; } = id;
        public string Nome { get; init; } = nome;
    }

    public struct FuncionarioDTO(
        Guid id,
        string nome,
        string telefone,
        string? cpf,
        string? email,
        string endereco
    )
    {
        public Guid Id { get; init; } = id;
        public string Nome { get; set; } = nome;
        public string Telefone { get; set; } = telefone;
        public string? CPF { get; set; } = cpf;
        public string? Email { get; set; } = email;
        public string Endereco { get; set; } = endereco;
    }

    public struct FuncionarioCreateDTO(
        string nome,
        string telefone,
        string? cpf,
        string? email,
        string endereco
    )
    {
        [Required(ErrorMessage = "{0} é obrigatório!")]
        [MinLength(3, ErrorMessage = "{0} deve conter pelo menos {1} caracteres!")]
        public string Nome { get; set; } = nome;

        [Required(ErrorMessage = "{0} é obrigatório!")]
        [RegularExpression(
            @"55\d{11}",
            ErrorMessage = "{0} deve conter 13 dígitos, incluindo o código do país '55'."
        )]
        public string Telefone { get; set; } = telefone;

        [RegularExpression(@"^\d{11}$", ErrorMessage = "CPF deve conter 11 dígitos")]
        public string? CPF { get; set; } = cpf;

        [EmailAddress]
        public string? Email { get; set; } = email;

        [Required(ErrorMessage = "{0} é obrigatório!")]
        [MinLength(5, ErrorMessage = "{0} deve conter pelo menos {1} caracteres!")]
        public string Endereco { get; set; } = endereco;
    }
}
