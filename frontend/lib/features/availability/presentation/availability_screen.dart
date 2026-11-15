import 'package:flutter/material.dart';
import 'package:barbearia_frontend/core/network/barbershop_api.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key, this.embedded = false, this.api});
  final BarbershopApi? api;
  final bool embedded;

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  late final _api = widget.api ?? BarbershopApi();
  late final Future<List<_Day>> _days = _load();
  bool _busy = false;

  Future<List<_Day>> _load() async {
    final response = await _api.myAvailability();
    final source = (response['data'] ?? response) as Map<String, dynamic>;
    final configured = <int, List<_Interval>>{};
    for (final item in (source['dias'] as List? ?? const [])) {
      final day = Map<String, dynamic>.from(item as Map);
      configured[day['diaSemana'] as int] = [
        for (final interval in (day['intervalos'] as List? ?? const []))
          _Interval.fromJson(Map<String, dynamic>.from(interval as Map)),
      ];
    }
    return List.generate(
      7,
      (index) => _Day(index, List.of(configured[index] ?? const [])),
    );
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final days = await _days;
      await _api.saveAvailability({
        'dias': [
          for (final day in days)
            if (day.intervals.isNotEmpty)
              {
                'diaSemana': day.weekday,
                'intervalos': [
                  for (final interval in day.intervals)
                    {'inicio': interval.start, 'fim': interval.end},
                ],
              },
        ],
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Disponibilidade salva.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível salvar: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addInterval(_Day day) async {
    final start = TextEditingController(text: '09:00');
    final end = TextEditingController(text: '18:00');
    if (_busy) return;
    final form = GlobalKey<FormState>();
    final result = await showDialog<_Interval>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Horário de ${day.name}'),
        content: Form(
            key: form,
            child: Row(children: [
              Expanded(
                  child: TextFormField(
                      validator: (value) => RegExp(r'^([01]\d|2[0-3]):[0-5]\d$')
                              .hasMatch(value ?? '')
                          ? null
                          : 'Use HH:mm',
                      controller: start,
                      decoration: const InputDecoration(labelText: 'Início'))),
              const SizedBox(width: 12),
              Expanded(
                  child: TextFormField(
                      validator: (_) {
                        final interval = _Interval(start.text, end.text);
                        if (!_valid(interval)) {
                          return 'Informe um fim posterior ao início';
                        }
                        if (day.intervals.any((other) =>
                            interval.start.compareTo(other.end) < 0 &&
                            interval.end.compareTo(other.start) > 0)) {
                          return 'Este intervalo sobrepõe outro';
                        }
                        return null;
                      },
                      controller: end,
                      decoration: const InputDecoration(labelText: 'Fim'))),
            ])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, _Interval(start.text, end.text));
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    if (!mounted || result == null) return;
    setState(() => day.intervals.add(result));
  }

  bool _valid(_Interval interval) {
    final pattern = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
    int toMinutes(String value) =>
        int.parse(value.substring(0, 2)) * 60 + int.parse(value.substring(3));
    return pattern.hasMatch(interval.start) &&
        pattern.hasMatch(interval.end) &&
        toMinutes(interval.start) < toMinutes(interval.end);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<_Day>>(
        future: _days,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return snapshot.hasError
                ? Center(child: Text('Erro: ${snapshot.error}'))
                : const Center(child: CircularProgressIndicator());
          }
          return Column(children: [
            if (_busy) const LinearProgressIndicator(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final day in snapshot.data!)
                    Card(
                      child: ExpansionTile(
                        title: Text(day.name),
                        subtitle: Text(day.intervals.isEmpty
                            ? 'Sem disponibilidade'
                            : day.intervals
                                .map((item) => '${item.start}–${item.end}')
                                .join(', ')),
                        children: [
                          for (final interval in day.intervals)
                            ListTile(
                              title: Text('${interval.start}–${interval.end}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: _busy
                                    ? null
                                    : () => setState(
                                        () => day.intervals.remove(interval)),
                              ),
                            ),
                          TextButton.icon(
                            onPressed: _busy ? null : () => _addInterval(day),
                            icon: const Icon(Icons.add),
                            label: const Text('Adicionar intervalo'),
                          ),
                        ],
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: _busy ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Salvar disponibilidade'),
                  ),
                ],
              ),
            ),
          ]);
        },
      );
}

class _Day {
  _Day(this.weekday, this.intervals);
  final int weekday;
  final List<_Interval> intervals;
  String get name => const [
        'Domingo',
        'Segunda',
        'Terça',
        'Quarta',
        'Quinta',
        'Sexta',
        'Sábado'
      ][weekday];
}

class _Interval {
  _Interval(this.start, this.end);
  final String start;
  final String end;
  factory _Interval.fromJson(Map<String, dynamic> json) => _Interval(
        (json['inicio'] as String).substring(0, 5),
        (json['fim'] as String).substring(0, 5),
      );
}
