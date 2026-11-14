import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

  void _refresh() {
    final dashboard = _load();
    setState(() {
      _dashboard = dashboard;
    });
  }

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
        if (_repository.offline)
          const Text(
              'Sem conexão. Indicadores calculados com os dados salvos; podem estar desatualizados.'),
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 240,
                width: double.infinity,
                child: CustomPaint(
                  painter: _RevenueChart(
                    realizedByDay,
                    peak,
                    theme.colorScheme,
                    _currency,
                    Directionality.of(context),
                  ),
                ),
              ),
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

class _RevenueChart extends CustomPainter {
  _RevenueChart(
      this.revenue, this.peak, this.colors, this.currency, this.direction);

  final Map<DateTime, double> revenue;
  final double peak;
  final ColorScheme colors;
  final String Function(double) currency;
  final TextDirection direction;

  TextPainter _label(String text) => TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(color: colors.onSurface, fontSize: 12),
        ),
        textDirection: direction,
      )..layout();

  String _date(DateTime date) => '${date.day}/${date.month}';

  @override
  void paint(Canvas canvas, Size size) {
    final labels = [
      for (var step = 0; step <= 4; step++) _label(currency(peak * step / 4)),
    ];
    final left = labels.fold(
            0.0, (width, label) => label.width > width ? label.width : width) +
        12;
    final right = size.width - 20;
    final bottom = size.height - 24;
    const top = 12.0;
    if (right <= left || bottom <= top) return;

    final grid = Paint()..color = colors.outlineVariant;
    for (var step = 0; step < labels.length; step++) {
      final y = bottom - (bottom - top) * step / 4;
      final label = labels[step];
      label.paint(canvas, Offset(left - label.width - 8, y - label.height / 2));
      canvas.drawLine(Offset(left, y), Offset(right, y), grid);
    }

    final entries = revenue.entries.toList();
    final line = Path();
    final dots = <Offset>[];
    final last = entries.length - 1;
    final labelInterval =
        ((last * 48) / (right - left)).ceil().clamp(1, entries.length);
    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      final x =
          last == 0 ? (left + right) / 2 : left + (right - left) * index / last;
      final y = bottom - (bottom - top) * (entry.value / peak).clamp(0.0, 1.0);
      if (index == 0) {
        line.moveTo(x, y);
      } else {
        line.lineTo(x, y);
      }
      dots.add(Offset(x, y));
      if (index == last ||
          (index % labelInterval == 0 && last - index >= labelInterval)) {
        final label = _label(_date(entry.key));
        label.paint(canvas, Offset(x - label.width / 2, bottom + 7));
      }
    }

    final stroke = Paint()
      ..color = colors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(line, stroke);
    final marker = Paint()..color = colors.primary;
    for (final point in dots) {
      canvas.drawCircle(point, entries.length > 15 ? 2 : 3.5, marker);
    }
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder => (size) => [
        CustomPainterSemantics(
          rect: Offset.zero & size,
          properties: SemanticsProperties(
            label: revenue.entries
                .map((entry) => '${_date(entry.key)}: ${currency(entry.value)}')
                .join(', '),
            textDirection: direction,
          ),
        ),
      ];

  @override
  bool shouldRebuildSemantics(covariant _RevenueChart oldDelegate) =>
      shouldRepaint(oldDelegate);

  @override
  bool shouldRepaint(covariant _RevenueChart oldDelegate) =>
      oldDelegate.revenue != revenue ||
      oldDelegate.colors != colors ||
      oldDelegate.direction != direction;
}
