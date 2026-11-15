namespace api.DTOs;

public record DailyReportDTO(
    DateOnly Date,
    decimal CompletedRevenue,
    long CompletedCount,
    decimal PendingRevenue,
    long ActiveCount,
    Dictionary<string, long> ServiceCounts
);
