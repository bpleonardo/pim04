namespace api.DTOs;

public record DailyRevenueDTO(DateOnly Date, decimal Revenue);
public record PeriodReportDTO(DateOnly StartDate, DateOnly EndDate,
    DailyReportDTO Summary, DailyRevenueDTO[] RevenueByDay);
