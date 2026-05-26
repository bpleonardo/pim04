using api.DTOs;
using api.Repositories;

namespace api.Services
{
    public class FinanceiroService(AgendamentosRepository agendamentosRepo)
    {
        private readonly AgendamentosRepository _agendamentosRepo = agendamentosRepo;

        public async Task<FinanceiroDTO> GetFinanceiro(string periodo, DateOnly? dataInicio = null, DateOnly? dataFim = null)
        {
            var appointments = periodo switch
            {
                "hoje" => await _agendamentosRepo.GetByDate(DateOnly.FromDateTime(DateTime.Now)),
                "semana" => await GetAppointmentsByWeek(),
                "mes" => await GetAppointmentsByMonth(),
                "personalizado" when dataInicio.HasValue && dataFim.HasValue => 
                    await GetAppointmentsByRange(dataInicio.Value, dataFim.Value),
                _ => []
            };

            var validAppointments = appointments.Where(a => a.Status != "cancelado").ToArray();
            var revenue = validAppointments.Sum(a => a.Total);
            var appointmentCount = validAppointments.Length;

            // Calculate service breakdown from appointments' services
            var serviceBreakdown = new Dictionary<string, double>();
            foreach (var appt in validAppointments)
            {
                foreach (var service in appt.Servicos)
                {
                    if (!serviceBreakdown.ContainsKey(service.Nome))
                        serviceBreakdown[service.Nome] = 0;
                    
                    serviceBreakdown[service.Nome] += service.Preco;
                }
            }

            var totalRevenue = serviceBreakdown.Values.Sum();
            var barras = serviceBreakdown
                .OrderByDescending(x => x.Value)
                .Select(x => new ServicoBreakdownDTO
                {
                    Nome = x.Key,
                    Valor = x.Value.ToString("C2"),
                    Percentual = totalRevenue > 0 ? (int)((x.Value / totalRevenue) * 100) : 0
                })
                .ToArray();

            // Create transactions list
            var transacoes = validAppointments
                .SelectMany(appt => appt.Servicos.Select(svc => new TransacaoDTO
                {
                    Data = appt.DataAgendamento.ToString("dd/MM/yyyy"),
                    Cliente = appt.Cliente.Nome,
                    Servico = svc.Nome,
                    Valor = svc.Preco.ToString("C2")
                }))
                .OrderByDescending(t => t.Data)
                .ToArray();

            // Create indicators
            var avgTicket = appointmentCount > 0 ? revenue / appointmentCount : 0;
            var indic1 = new IndicadorDTO
            {
                Label = "Faturamento total",
                Value = revenue.ToString("C2"),
                Note = "Destaque do período",
                Highlight = true
            };

            var indic2 = new IndicadorDTO
            {
                Label = "Total de atendimentos",
                Value = appointmentCount.ToString(),
                Note = appointmentCount > 0 ? $"Média de {(double)appointmentCount / (periodo == "semana" ? 7 : periodo == "mes" ? 30 : 1):F1} por dia" : "Sem dados",
                Highlight = false
            };

            var indic3 = new IndicadorDTO
            {
                Label = "Ticket médio",
                Value = avgTicket.ToString("C2"),
                Note = avgTicket > 0 ? "Cálculo atual" : "Sem dados",
                Highlight = false
            };

            return new FinanceiroDTO
            {
                Indicadores = [indic1, indic2, indic3],
                Barras = barras,
                Transacoes = transacoes,
                Total = revenue.ToString("C2")
            };
        }

        private async Task<MinAgendamentoDTO[]> GetAppointmentsByWeek()
        {
            var today = DateOnly.FromDateTime(DateTime.Now);
            var appointments = new List<MinAgendamentoDTO>();

            for (int i = 0; i < 7; i++)
            {
                var date = today.AddDays(-i);
                var daily = await _agendamentosRepo.GetByDate(date);
                appointments.AddRange(daily);
            }

            return appointments.ToArray();
        }

        private async Task<MinAgendamentoDTO[]> GetAppointmentsByMonth()
        {
            var today = DateOnly.FromDateTime(DateTime.Now);
            var appointments = new List<MinAgendamentoDTO>();

            for (int i = 0; i < 30; i++)
            {
                var date = today.AddDays(-i);
                var daily = await _agendamentosRepo.GetByDate(date);
                appointments.AddRange(daily);
            }

            return appointments.ToArray();
        }

        private async Task<MinAgendamentoDTO[]> GetAppointmentsByRange(DateOnly start, DateOnly end)
        {
            var appointments = new List<MinAgendamentoDTO>();
            var current = start;

            while (current <= end)
            {
                var daily = await _agendamentosRepo.GetByDate(current);
                appointments.AddRange(daily);
                current = current.AddDays(1);
            }

            return appointments.ToArray();
        }
    }
}
