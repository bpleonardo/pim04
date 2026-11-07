import 'package:flutter/material.dart';
import 'package:barbearia_frontend/core/shop_time.dart';
import 'package:barbearia_frontend/core/network/api_client.dart';
import 'package:barbearia_frontend/features/appointments/models/appointment.dart';
import 'package:barbearia_frontend/features/appointments/data/appointment_repository.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});
  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final repo = AppointmentRepository();
  late Future<List<Appointment>> future;
  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() {
    future = repo.list();
  }

  Future<void> changeStatus(Appointment a, String status) async {
    try {
      await repo.updateStatus(a.id, status);
      if (mounted) setState(reload);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  String formatSchedule(String value) {
    final local = appointmentShopTime(value);
    if (local == null) return value;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month}/${local.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Agenda'), actions: [
        IconButton(
            onPressed: () => setState(reload), icon: const Icon(Icons.refresh))
      ]),
      body: FutureBuilder<List<Appointment>>(
          future: future,
          builder: (context, s) {
            if (s.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (s.hasError) return Center(child: Text('Erro: ${s.error}'));
            final list = s.data ?? [];
            if (list.isEmpty) {
              return const Center(child: Text('Sem agendamentos'));
            }
            return ListView(children: [
              for (final a in list)
                Card(
                    child: ListTile(
                        title: Text('${a.clientName} • ${a.employeeName}'),
                        subtitle: Text(
                            '${formatSchedule(a.scheduledAt)} • ${a.status} • R\$ ${a.total.toStringAsFixed(2)}'),
                        trailing: ApiClient.user?.id != a.employeeId
                            ? null
                            : PopupMenuButton<String>(
                                onSelected: (v) => changeStatus(a, v),
                                itemBuilder: (_) => [
                                      const PopupMenuItem(
                                          value: 'agendado',
                                          child: Text('Agendado')),
                                      if (a.status != 'cancelado')
                                        const PopupMenuItem(
                                            value: 'concluido',
                                            child: Text('Concluído')),
                                      const PopupMenuItem(
                                          value: 'cancelado',
                                          child: Text('Cancelado'))
                                    ])))
            ]);
          }));
}
