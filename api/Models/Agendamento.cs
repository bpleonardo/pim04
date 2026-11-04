using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using api.Utilities;
using Microsoft.EntityFrameworkCore;

namespace api.Models
{
    /// <summary>
    /// Represents an appointment entity in the database.
    /// </summary>
    public class Agendamento
    {
        [Key]
        [Guid]
        public Guid Id { get; init; }

        [Required]
        [Guid]
        public Guid IdCliente { get; set; }

        [ForeignKey(nameof(IdCliente))]
        [DeleteBehavior(DeleteBehavior.Restrict)]
        public Cliente Cliente { get; set; } = null!;

        [Required]
        [Guid]
        public Guid IdFuncionario { get; set; }

        [ForeignKey(nameof(IdFuncionario))]
        [DeleteBehavior(DeleteBehavior.Restrict)]
        public Funcionario Funcionario { get; set; } = null!;

        [Required]
        [DateTime]
        public DateTime DataAgendamento { get; set; }

        [DateTime(AllowFuture = false, NotBefore = "DataAgendamento")]
        public DateTime? DataConclusao { get; set; }

        [Required]
        [MaxLength(9)]
        [AllowedValues("agendado", "concluido", "cancelado")]
        public string Status { get; set; } = string.Empty;

        [Precision(6, 2)]
        [Range(0.01, 9999.99)]
        public double? ValorTotal { get; set; }

        // Navegação para a lista de serviços associados a este agendamento
        public ICollection<ServicoRealizado> ServicosRealizados { get; set; } =
            new List<ServicoRealizado>();

        public Agendamento(
            Guid id,
            Cliente cliente,
            Funcionario funcionario,
            DateTime dataAgendamento,
            DateTime? dataConclusao,
            string status,
            double? valorTotal
        )
        {
            Id = id;
            Cliente = cliente;
            Funcionario = funcionario;
            DataAgendamento = dataAgendamento;
            DataConclusao = dataConclusao;
            Status = status;
            ValorTotal = valorTotal;
        }

        // Construtor público para materialização pelo EF Core
        public Agendamento() { }
    }
}
