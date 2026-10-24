using System.ComponentModel.DataAnnotations;
using api.Utilities;
using Microsoft.EntityFrameworkCore;

namespace api.Models
{
    /// <summary>
    /// Represents a service entity in the database.
    /// </summary>
    [Index(nameof(Nome), IsUnique = true)]
    public class Servico
    {
        [Key]
        [Guid]
        public Guid Id { get; init; }

        [Required]
        [MinLength(3)]
        public string Nome { get; set; } = string.Empty;

        [MinLength(5)]
        public string? Descricao { get; set; }

        [Required]
        [Precision(6, 2)]
        [Range(0.01, 9999.99)]
        public double Preco { get; set; }

        // Navegação para a tabela intermediária de serviços prestados
        public ICollection<ServicoRealizado> ServicosRealizados { get; set; } = [];

        public Servico(Guid? id, string nome, string? descricao, double preco)
        {
            Id = id ?? Guid.NewGuid();
            Nome = nome;
            Descricao = descricao;
            Preco = preco;
        }

        // Construtor protegido para materialização pelo EF Core
        protected Servico() { }
    }
}
