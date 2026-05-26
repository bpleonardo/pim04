using System.ComponentModel.DataAnnotations;
using api.Utilities;

namespace api.Models
{
    public class Usuario
    {
        [Required]
        [Guid]
        public Guid IdFuncionario { get; set; }

        [Required]
        [MinLength(3)]
        public string Login { get; set; }

        [Required]
        [MinLength(6)]
        public string Senha { get; set; }

        public Usuario(Guid idFuncionario, string login, string senha)
        {
            IdFuncionario = idFuncionario;
            Login = login;
            Senha = senha;
        }
    }
}
