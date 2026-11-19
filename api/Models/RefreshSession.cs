using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace api.Models
{
    public class RefreshSession
    {
        [Key]
        public Guid Jti { get; init; }
        public Guid EmployeeId { get; init; }

        [ForeignKey(nameof(EmployeeId))]
        public Usuario User { get; init; } = null!;
        public DateTime ExpiresAt { get; init; }
    }
}
