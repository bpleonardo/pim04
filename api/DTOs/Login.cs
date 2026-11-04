using System.ComponentModel.DataAnnotations;

namespace api.DTOs
{
    public struct LoginRequest
    {
        [Required(ErrorMessage = "{0} é obrigatório!")]
        [MinLength(3, ErrorMessage = "{0} deve conter pelo menos {1} caracteres!")]
        public string Login { get; set; }

        [Required(ErrorMessage = "{0} é obrigatória!")]
        [MinLength(6, ErrorMessage = "{0} deve conter pelo menos {1} caracteres!")]
        public string Senha { get; set; }
    }

    public readonly struct AuthUser
    {
        public Guid Id { get; init; }
        public string Nome { get; init; }
        public string Login { get; init; }
    }

    public readonly struct LoginResponse
    {
        public string Token { get; init; }
        public AuthUser User { get; init; }
    }
}
