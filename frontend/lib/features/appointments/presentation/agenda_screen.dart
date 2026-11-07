import 'package:flutter/material.dart';
import 'package:barbearia_frontend/app/routes/app_router.dart';
import 'package:barbearia_frontend/core/network/api_client.dart';
import 'package:barbearia_frontend/core/shop_time.dart';
import 'package:barbearia_frontend/features/appointments/data/appointment_repository.dart';
import 'package:barbearia_frontend/features/appointments/models/appointment.dart';
import 'package:barbearia_frontend/features/appointments/presentation/appointment_card.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key, this.repository});

  final AppointmentRepository? repository;

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  late final AppointmentRepository repo;
  late Future<List<Appointment>> future;
  DateTime selectedDate = shopTime(DateTime.now());

  @override
  void initState() {
    super.initState();
    repo = widget.repository ?? AppointmentRepository();
    future = repo.list(date: selectedDate);
  }

  Future<void> refresh() async {
    setState(() {
      future = repo.list(date: selectedDate);
    });
    try {
      await future;
    } catch (_) {
      // A tela apresenta o erro pelo FutureBuilder.
    }
  }

  void selectDate(DateTime date) {
    setState(() {
      selectedDate = date;
      future = repo.list(date: date);
    });
  }

  void stepDate(int days) {
    selectDate(DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day + days,
    ));
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
    );
    if (mounted && date != null) selectDate(date);
  }

  Future<void> createAppointment() async {
    await Navigator.pushNamed(context, AppRouter.newAppointment);
    if (mounted) await refresh();
  }

  Future<void> changeStatus(Appointment appointment, String status) async {
    try {
      await repo.updateStatus(appointment.id, status);
      if (mounted) await refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Widget navigation({bool drawer = false}) {
    void open(String route) {
      if (drawer) Navigator.pop(context);
      Navigator.pushNamed(context, route);
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('N&E',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                ListTile(
                  selected: true,
                  selectedTileColor: const Color(0xFFE9E9E9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  title: const Text('Agendamentos'),
                  onTap: () {
                    if (drawer) Navigator.pop(context);
                  },
                ),
                ListTile(
                    title: const Text('Serviços'),
                    onTap: () => open(AppRouter.catalog)),
                ListTile(
                    title: const Text('Dashboard'),
                    onTap: () => open(AppRouter.dashboard)),
                ListTile(
                    title: const Text('Atualizar'),
                    onTap: () {
                      if (drawer) Navigator.pop(context);
                      refresh();
                    }),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: () {
              ApiClient.signOut();
              Navigator.pushNamedAndRemoveUntil(
                  context, AppRouter.login, (_) => false);
            },
          ),
        ],
      ),
    );
  }

  Widget dateBar() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF303030)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
                child: Text(shopDateLabel(selectedDate),
                    style: Theme.of(context).textTheme.titleMedium)),
            IconButton(
                tooltip: 'Dia anterior',
                onPressed: () => stepDate(-1),
                icon: const Icon(Icons.chevron_left)),
            OutlinedButton(
                onPressed: pickDate, child: const Text('Selecionar')),
            IconButton(
                tooltip: 'Próximo dia',
                onPressed: () => stepDate(1),
                icon: const Icon(Icons.chevron_right)),
          ],
        ),
      );

  Widget appointments() => FutureBuilder<List<Appointment>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Erro: ${snapshot.error}', textAlign: TextAlign.center),
                TextButton(
                    onPressed: refresh, child: const Text('Tentar novamente')),
              ],
            ));
          }
          final items = snapshot.data ?? [];
          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 14, bottom: 84),
              children: [
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(child: Text('Sem agendamentos')),
                  ),
                for (final item in items)
                  AppointmentCard(
                    appointment: item,
                    status: appointmentStatusLabel(item.status),
                    showEmployee: true,
                    action: ApiClient.user?.id != item.employeeId
                        ? null
                        : PopupMenuButton<String>(
                            tooltip: 'Alterar status',
                            onSelected: (value) => changeStatus(item, value),
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                  value: 'agendado', child: Text('Agendado')),
                              if (item.status != 'cancelado')
                                const PopupMenuItem(
                                    value: 'concluido',
                                    child: Text('Concluído')),
                              const PopupMenuItem(
                                  value: 'cancelado', child: Text('Cancelado')),
                            ],
                          ),
                  ),
              ],
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          return Scaffold(
            backgroundColor: const Color(0xFFF7F7F7),
            appBar: wide
                ? null
                : AppBar(
                    title: const Text('Agendamentos'),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
            drawer: wide ? null : Drawer(child: navigation(drawer: true)),
            floatingActionButton: FloatingActionButton(
              tooltip: 'Novo agendamento',
              backgroundColor: const Color(0xFFE9EDF0),
              foregroundColor: Colors.black,
              shape: const CircleBorder(
                side: BorderSide(color: Color(0xFF303030)),
              ),
              elevation: 0,
              hoverElevation: 0,
              focusElevation: 0,
              highlightElevation: 0,
              onPressed: createAppointment,
              child: const Icon(Icons.add),
            ),
            body: SafeArea(
                child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  if (wide) ...[
                    SizedBox(
                      width: 216,
                      child: Material(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Color(0xFF303030)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: navigation(),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                      child: Column(
                    children: [
                      dateBar(),
                      Expanded(child: appointments()),
                    ],
                  )),
                ],
              ),
            )),
          );
        },
      );
}
