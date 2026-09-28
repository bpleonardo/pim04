using System.ComponentModel.DataAnnotations;
using api.Utilities;

namespace api.Models
{
    /// <summary>
    /// Abstract base model representing a person.
    /// </summary>
    public abstract class Pessoa
    {
        [Key]
        [Guid]
        public Guid Id { get; init; }

        [Required]
        [MinLength(3, ErrorMessage = "{0} deve conter pelo menos {1} caracteres!")]
        public string Nome { get; set; } = string.Empty;

        [MaxLength(13)]
        [RegularExpression(
            @"55\d{11}",
            ErrorMessage = "{0} deve conter 13 dígitos, incluindo o código do país '55'."
        )]
        public string? Telefone { get; set; }

        [MaxLength(11)]
        [CPF(AllowPunctuation = false)]
        public string? CPF { get; set; }

        [EmailAddress]
        public string? Email { get; set; }

        public Pessoa(Guid? id, string nome, string? telefone, string? cpf, string? email)
        {
            Id = id ?? Guid.NewGuid();
            Nome = nome;
            Telefone = telefone;
            CPF = cpf;
            Email = email;
        }

        // Construtor protegido para materialização pelo EF Core
        protected Pessoa() { }
    }
}
