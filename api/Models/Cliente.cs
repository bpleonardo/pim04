using System.ComponentModel.DataAnnotations.Schema;
using api.Utilities;
using Microsoft.EntityFrameworkCore;

namespace api.Models
{
    /// <summary>
    /// Represents a client entity in the database.
    /// </summary>
    [Index(nameof(CPF), IsUnique = true)]
    public class Cliente : Pessoa
    {
        [Column(TypeName = "date")]
        [BirthDate(MaximumAge = 120)]
        public DateOnly? DtNascimento { get; set; }

        // Navegação para a lista de agendamentos do cliente
        public ICollection<Agendamento> Agendamentos { get; set; } = [];

        public Cliente(
            Guid? id,
            string nome,
            string telefone,
            string? cpf,
            string? email,
            DateOnly? dtNascimento
        )
            : base(id, nome, telefone, cpf, email)
        {
            DtNascimento = dtNascimento;
        }

        // Construtor protegido para materialização pelo EF Core
        protected Cliente() { }
    }
}
