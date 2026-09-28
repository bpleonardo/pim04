using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace api.Models
{
    /// <summary>
    /// Represents a service performed in an appointment (join entity).
    /// </summary>
    [PrimaryKey(nameof(IdServico), nameof(IdAgendamento))]
    public class ServicoRealizado
    {
        public Guid IdAgendamento { get; set; }

        [ForeignKey(nameof(IdAgendamento))]
        [DeleteBehavior(DeleteBehavior.Cascade)]
        public Agendamento Agendamento { get; set; } = null!;

        public Guid IdServico { get; set; }

        [ForeignKey(nameof(IdServico))]
        [DeleteBehavior(DeleteBehavior.Restrict)]
        public Servico Servico { get; set; } = null!;

        [Precision(6, 2)]
        public double Valor { get; set; }
    }
}
