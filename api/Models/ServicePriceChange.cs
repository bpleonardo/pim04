using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace api.Models;

public class ServicePriceChange
{
    [Key]
    public long Id { get; set; }
    public Guid? ServiceId { get; set; }
    [ForeignKey(nameof(ServiceId))]
    [DeleteBehavior(DeleteBehavior.SetNull)]
    public Servico? Service { get; set; }
    [Required]
    public string ServiceName { get; set; } = string.Empty;
    [Precision(6, 2)]
    public double OldPrice { get; set; }
    [Precision(6, 2)]
    public double NewPrice { get; set; }
    public DateTime ChangedAt { get; set; }
}
