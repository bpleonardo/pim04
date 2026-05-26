using api.DTOs;
using api.Repositories;

namespace api.Services
{
    public class DashboardService(AgendamentosRepository agendamentosRepo)
    {
        private readonly AgendamentosRepository _agendamentosRepo = agendamentosRepo;

        public async Task<DashboardDTO> GetDashboard()
        {
            var today = DateOnly.FromDateTime(DateTime.Now);
            var agendamentos = await _agendamentosRepo.GetByDate(today);

            var totalAppointments = agendamentos.Length;
            var pendingAppointments = agendamentos.Count(a => a.Status == "agendado");
            var revenue = agendamentos
                .Where(a => a.Status != "cancelado")
                .Sum(a => a.Total);

            var indic1 = new IndicadorDTO
            {
                Label = "Faturamento total",
                Value = revenue.ToString("C2"),
                Note = totalAppointments > 0 ? "Destaque do dia" : "Sem agendamentos",
                Highlight = true
            };

            var indic2 = new IndicadorDTO
            {
                Label = "Total de atendimentos",
                Value = totalAppointments.ToString(),
                Note = pendingAppointments > 0 
                    ? $"{pendingAppointments} agendamentos pendentes" 
                    : "Todos concluídos",
                Highlight = false
            };

            var avgTicket = totalAppointments > 0 ? revenue / totalAppointments : 0;
            var indic3 = new IndicadorDTO
            {
                Label = "Ticket médio",
                Value = avgTicket.ToString("C2"),
                Note = avgTicket > 0 ? "Cálculo em tempo real" : "Sem dados",
                Highlight = false
            };

            return new DashboardDTO
            {
                Indicadores = [indic1, indic2, indic3],
                CurrentDate = DateTime.Now.ToLongDateString(),
                Status = revenue > 500 ? "ok" : (revenue > 0 ? "warning" : "critical")
            };
        }
    }
}
