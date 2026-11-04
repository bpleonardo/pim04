using System.ComponentModel.DataAnnotations;

namespace api.DTOs
{
    public readonly struct MinAgendamentoDTO(
        Guid id,
        DateTime dataAgendamento,
        string status,
        double total,
        ServicoDTO[] servicos,
        MinClienteDTO cliente,
        MinFuncionarioDTO funcionario
    )
    {
        public Guid Id { get; init; } = id;
        public DateTime DataAgendamento { get; init; } = dataAgendamento;
        public string Status { get; init; } = status;
        public double Total { get; init; } = total;
        public ServicoDTO[] Servicos { get; init; } = servicos;
        public MinClienteDTO Cliente { get; init; } = cliente;
        public MinFuncionarioDTO Funcionario { get; init; } = funcionario;
    }

    /// <summary>
    /// Create a new appointment. Can include client info for auto-creation.
    /// </summary>
    public struct AgendamentoCreateDTO
    {
        [Required(ErrorMessage = "{0} é obrigatório!")]
        [MinLength(3, ErrorMessage = "{0} deve conter pelo menos {1} caracteres!")]
        public string NomeCliente { get; set; }

        [Required(ErrorMessage = "{0} é obrigatório!")]
        [RegularExpression(
            @"55\d{11}",
            ErrorMessage = "{0} deve conter 13 dígitos, incluindo o código do país '55'."
        )]
        public string TelefoneCliente { get; set; }

        [EmailAddress]
        public string? EmailCliente { get; set; }

        public string? ObservacoesCliente { get; set; }

        [Required]
        public Guid IdFuncionario { get; set; }

        [Required(ErrorMessage = "{0} é obrigatória!")]
        public DateTime DataAgendamento { get; set; }

        [Required(ErrorMessage = "Pelo menos um serviço é obrigatório!")]
        public Guid[]? IdServicos { get; set; }
    }

    public struct AgendamentoUpdateDTO
    {
        [Required]
        [RegularExpression(@"^(agendado|concluido|cancelado)$", ErrorMessage = "Status inválido.")]
        public string Status { get; set; }
    }

    public readonly struct AgendamentoResponseDTO
    {
        public Guid Id { get; init; }
        public string NomeCliente { get; init; }
        public string NomeFuncionario { get; init; }
        public DateTime DataAgendamento { get; init; }
        public string Status { get; init; }
        public double Total { get; init; }
        public string[] Servicos { get; init; }
    }
}
