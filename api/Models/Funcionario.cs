using System.ComponentModel.DataAnnotations;
using Microsoft.EntityFrameworkCore;

namespace api.Models
{
    /// <summary>
    /// Represents an employee entity in the database.
    /// </summary>
    [Index(nameof(CPF), IsUnique = true)]
    [Index(nameof(Email), IsUnique = true)]
    public class Funcionario : Pessoa
    {
        [Required]
        [MinLength(5)]
        public string Endereco { get; set; } = string.Empty;

        // Navegação 1:1 para a conta de usuário
        public Usuario? Usuario { get; set; }

        // Navegação para a lista de agendamentos atribuídos ao funcionário
        public ICollection<Agendamento> Agendamentos { get; set; } = [];

        public Funcionario(
            Guid? id,
            string nome,
            string? telefone,
            string cpf,
            string email,
            string endereco
        )
            : base(id, nome, telefone, cpf, email)
        {
            Endereco = endereco;
        }

        // Construtor protegido para materialização pelo EF Core
        protected Funcionario() { }
    }
}
