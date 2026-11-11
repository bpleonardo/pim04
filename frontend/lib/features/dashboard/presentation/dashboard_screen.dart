import 'package:flutter/material.dart';
import 'package:barbearia_frontend/core/shop_time.dart';
import 'package:barbearia_frontend/features/appointments/data/appointment_repository.dart';
import 'package:barbearia_frontend/features/appointments/models/appointment.dart';

enum _Period { today, week, month }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repository = AppointmentRepository();
  var _period = _Period.today;
  late var _dashboard = _load();

  Future<Map<DateTime, List<Appointment>>> _load() async {
    final today = shopTime(DateTime.now());
    final start = switch (_period) {
      _Period.today => today.day,
      _Period.week => today.day - today.weekday + 1,
      _Period.month => 1,
    };
    final days = [
      for (var day = start; day <= today.day; day++)
        DateTime.utc(today.year, today.month, day),
    ];

    final results = <DateTime, List<Appointment>>{};
    // A API devolve um dia por chamada. Limita as consultas simultâneas.
    for (var offset = 0; offset < days.length; offset += 7) {
      final batch = await Future.wait(days.skip(offset).take(7).map(
            (day) async => MapEntry(day, await _repository.list(date: day)),
          ));
      results.addEntries(batch);
    }
    return results;
  }

  void _refresh() => setState(() => _dashboard = _load());

  String _currency(double value) {
    final cents = (value.abs() * 100).round();
    final whole = (cents ~/ 100)
        .toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    final decimals = (cents % 100).toString().padLeft(2, '0');
    final sign = value < 0 ? '-' : '';
    return '${sign}R\$ $whole,$decimals';
  }

  Widget _summary(Map<DateTime, List<Appointment>> agenda) {
    final theme = Theme.of(context);
    final realizedByDay = <DateTime, double>{};
    final serviceCounts = <String, int>{};
    var realized = 0.0;
    var pending = 0.0;
    var completedCount = 0;
    var activeCount = 0;
    for (final entry in agenda.entries) {
      var dailyRealized = 0.0;
      for (final appointment in entry.value) {
        if (appointment.status == 'cancelado') continue;
        activeCount++;
        if (appointment.status == 'concluido') {
          dailyRealized += appointment.total;
          completedCount++;
        } else {
          pending += appointment.total;
        }
        for (final service in appointment.services.toSet()) {
          serviceCounts.update(service, (count) => count + 1,
              ifAbsent: () => 1);
        }
      }
      realized += dailyRealized;
      realizedByDay[entry.key] = dailyRealized;
    }

    final ranking = serviceCounts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    final peak = realizedByDay.values
        .fold(0.0, (max, value) => value > max ? value : max);
    final metrics = [
      (
        'Faturamento previsto',
        _currency(realized + pending),
        'Concluídos e pendentes'
      ),
      ('Faturamento realizado', _currency(realized), 'Atendimentos concluídos'),
      ('Atendimentos', '$activeCount', '$completedCount concluídos'),
      (
        'Ticket médio',
        _currency(completedCount == 0 ? 0 : realized / completedCount),
        'Por atendimento concluído'
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            '${shopDateLabel(agenda.keys.first)} até ${shopDateLabel(agenda.keys.last)}'),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth >= 700 ? 2 : 1;
          return Wrap(
            spacing: 12,
            children: [
              for (final (label, value, note) in metrics)
                SizedBox(
                  width: (constraints.maxWidth - 12 * (columns - 1)) / columns,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: theme.textTheme.titleMedium),
                          Text(value, style: theme.textTheme.headlineMedium),
                          Text(note),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
        const SizedBox(height: 12),
        Text('Faturamento realizado por dia',
            style: theme.textTheme.titleMedium),
        if (peak == 0)
          const Text('Sem faturamento realizado no período.')
        else
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final entry in realizedByDay.entries)
                  Expanded(
                    child: Tooltip(
                      message:
                          '${shopDateLabel(entry.key)} · ${_currency(entry.value)}',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height:
                                  108 * (entry.value / peak).clamp(0.0, 1.0) +
                                      2,
                              color: theme.colorScheme.primary,
                            ),
                            if (realizedByDay.length <= 7 ||
                                entry.key == agenda.keys.first ||
                                entry.key.day % 5 == 0 ||
                                entry.key == agenda.keys.last)
                              Text('${entry.key.day}',
                                  style: theme.textTheme.labelSmall)
                            else
                              const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        Text('Serviços mais agendados', style: theme.textTheme.titleMedium),
        if (ranking.isEmpty) const Text('Sem serviços no período.'),
        for (final service in ranking.take(5))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(service.key),
            trailing: Text('${service.value}'),
          ),
      ],
    );
  }

  Widget _content() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Resumo de atendimentos',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              IconButton(
                onPressed: _refresh,
                tooltip: 'Atualizar dashboard',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final (period, label) in [
                (_Period.today, 'Hoje'),
                (_Period.week, 'Esta semana'),
                (_Period.month, 'Este mês'),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: _period == period,
                  onSelected: (selected) {
                    if (!selected) return;
                    setState(() {
                      _period = period;
                      _dashboard = _load();
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder(
            future: _dashboard,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return OutlinedButton(
                  onPressed: _refresh,
                  child: const Text('Falha ao carregar. Tentar novamente'),
                );
              }
              return _summary(snapshot.data!);
            },
          ),
        ],
      );

  @override
  Widget build(BuildContext context) => widget.embedded
      ? _content()
      : Scaffold(
          appBar: AppBar(title: const Text('Dashboard')),
          body: _content(),
        );
}
