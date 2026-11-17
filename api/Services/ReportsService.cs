using api.DTOs;
using api.Repositories;
using api.Exceptions;

namespace api.Services;

public class ReportsService(ReportsRepository repository)
{
    public Task<DailyReportDTO> GetDaily(DateOnly date, Guid? employeeId) =>
        repository.GetDaily(date, employeeId);
    public Task<PeriodReportDTO> GetPeriod(DateOnly date, string period, Guid? employeeId)
    {
        var start = period switch
        {
            "daily" => date,
            "weekly" => date.AddDays(-(((int)date.DayOfWeek + 6) % 7)),
            "monthly" => new DateOnly(date.Year, date.Month, 1),
            _ => throw new ValidationException("Período inválido. Use daily, weekly ou monthly.", "INVALID_PERIOD"),
        };
        return repository.GetPeriod(start, date, employeeId);
    }
}
