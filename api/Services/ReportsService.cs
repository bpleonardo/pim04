using api.DTOs;
using api.Repositories;

namespace api.Services;

public class ReportsService(ReportsRepository repository)
{
    public Task<DailyReportDTO> GetDaily(DateOnly date, Guid? employeeId) =>
        repository.GetDaily(date, employeeId);
}
