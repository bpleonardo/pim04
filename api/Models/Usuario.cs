using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using api.Utilities;
using Microsoft.EntityFrameworkCore;

namespace api.Models
{
    /// <summary>
    /// Represents an application user account tied to an employee.
    /// </summary>
    [Index(nameof(Login), IsUnique = true)]
    public class Usuario
    {
        [Key]
        [Guid]
        public Guid IdFuncionario { get; set; }

        [Required]
        [MinLength(3)]
        public string Login { get; set; } = string.Empty;

        [Required]
        [MinLength(6)]
        public string Senha { get; set; } = string.Empty;

        // Navegação 1:1 para o funcionário titular com exclusão em cascata
        [ForeignKey(nameof(IdFuncionario))]
        [DeleteBehavior(DeleteBehavior.Cascade)]
        public Funcionario Funcionario { get; set; } = null!;

        public Usuario(Guid idFuncionario, string login, string senha)
        {
            IdFuncionario = idFuncionario;
            Login = login;
            Senha = senha;
        }

        // Construtor protegido para materialização pelo EF Core
        protected Usuario() { }
    }
}
