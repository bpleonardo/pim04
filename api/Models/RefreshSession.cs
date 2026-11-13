namespace api.Models;

public class RefreshSession
{
    [System.ComponentModel.DataAnnotations.Key]
    public Guid Jti { get; init; }
    public Guid EmployeeId { get; init; }
    [System.ComponentModel.DataAnnotations.Schema.ForeignKey(nameof(EmployeeId))]
    public Usuario User { get; init; } = null!;
    public DateTime ExpiresAt { get; init; }
}
