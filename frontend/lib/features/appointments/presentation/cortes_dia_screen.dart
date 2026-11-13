import 'dart:async';
import 'package:flutter/material.dart';
import 'package:barbearia_frontend/app/routes/app_router.dart';
import 'package:barbearia_frontend/core/shop_time.dart';
import 'package:barbearia_frontend/core/network/api_client.dart';
import 'package:barbearia_frontend/features/appointments/data/appointment_repository.dart';
import 'package:barbearia_frontend/features/appointments/models/appointment.dart';
import 'package:barbearia_frontend/features/appointments/presentation/appointment_card.dart';
import 'package:barbearia_frontend/core/responsive/app_platform.dart';

class CortesDiaScreen extends StatefulWidget {
  const CortesDiaScreen({super.key, this.repository});
  final AppointmentRepository? repository;

  @override
  State<CortesDiaScreen> createState() => _CortesDiaScreenState();
}

class _CortesDiaScreenState extends State<CortesDiaScreen>
    with WidgetsBindingObserver {
  late final AppointmentRepository repo;
  late Future<DailyAgenda> future;
  Timer? _retryTimer;
  bool _loading = false;
  DateTime _selectedDate = shopTime(DateTime.now());
  String? completingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    repo = widget.repository ?? AppointmentRepository();
    future = _load();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refresh();
    } else {
      _retryTimer?.cancel();
    }
  }

  Future<DailyAgenda> _load() async {
    _loading = true;
    _retryTimer?.cancel();
    var shouldRetry = false;
    try {
      final agenda = await repo.loadDay(_selectedDate);
      shouldRetry = agenda.offline ||
          agenda.completions.containsValue(CompletionState.pending);
      return agenda;
    } on ApiException catch (error) {
      shouldRetry = error.retryable;
      rethrow;
    } finally {
      _loading = false;
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (mounted &&
          (lifecycle == null || lifecycle == AppLifecycleState.resumed) &&
          shouldRetry) {
        _retryTimer =
            Timer.periodic(const Duration(seconds: 30), (_) => refresh());
      }
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
    );
    if (date == null || !mounted || _loading || completingId != null) return;
    _selectedDate = date;
    await refresh();
  }

  Future<void> _createAppointment() async {
    final date =
        await Navigator.pushNamed<DateTime>(context, AppRouter.newAppointment);
    if (date == null || !mounted) return;
    _selectedDate = date;
    await refresh();
  }

  Future<void> refresh() async {
    if (_loading || completingId != null) return;
    setState(() {
      future = _load();
    });
    try {
      await future;
    } catch (_) {
      // O FutureBuilder apresenta a falha e oferece nova tentativa.
    }
  }

  Future<void> completeAppointment(Appointment appointment) async {
    if (_loading || completingId != null) return;
    setState(() => completingId = appointment.id);
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Concluir corte?'),
          content: Text(
              'Confirmar que o atendimento de ${appointment.clientName} foi concluído?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Voltar')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Confirmar conclusão')),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
      final result = await repo.complete(appointment.id);
      if (!mounted) return;
      setState(() {
        future = _load();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(switch (result) {
          CompletionState.sent => 'Corte concluído com sucesso.',
          CompletionState.pending =>
            'Conclusão salva no aparelho. Aguardando sincronização.',
          CompletionState.rejected =>
            'A API recusou a conclusão. Confira a agenda.',
        })),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Não foi possível concluir o corte. Atualize a lista e tente novamente.'),
        ));
      }
    } finally {
      if (mounted) setState(() => completingId = null);
    }
  }

  Widget appointmentCard(Appointment appointment, CompletionState? completion) {
    final canComplete = appointment.status == 'agendado' && completion == null;
    final status = switch (completion) {
      CompletionState.pending => 'Aguardando sincronização',
      CompletionState.sent => 'Concluído',
      CompletionState.rejected =>
        '${appointmentStatusLabel(appointment.status)} · Conclusão não sincronizada',
      null => appointmentStatusLabel(appointment.status),
    };
    return AppointmentCard(
      appointment: appointment,
      status: status,
      action: canComplete
          ? TextButton(
              onPressed: completingId != null
                  ? null
                  : () => completeAppointment(appointment),
              child: Text(completingId == appointment.id
                  ? 'Aguarde...'
                  : 'Concluir corte'),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: AppBar(
          title: const Text('Agendamentos'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          actions: [
            IconButton(
              onPressed: _loading || completingId != null ? null : _pickDate,
              tooltip: 'Selecionar data',
              icon: const Icon(Icons.calendar_month),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed:
              _loading || completingId != null ? null : _createAppointment,
          tooltip: 'Novo agendamento',
          child: const Icon(Icons.add),
        ),
        drawer: Drawer(
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('N&E', style: TextStyle(fontSize: 24)),
                ),
                ListTile(
                  selected: true,
                  title: const Text('Agendamentos'),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('Atualizar'),
                  onTap: () {
                    Navigator.pop(context);
                    refresh();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.content_cut),
                  title: const Text('Serviços'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.catalog);
                  },
                ),
                if (AppPlatform.native)
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Configurações'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRouter.settingsRoute);
                    },
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
          ),
        ),
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: FutureBuilder<DailyAgenda>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 40),
                        const SizedBox(height: 16),
                        const Text(
                            'Não foi possível carregar os agendamentos da data selecionada. Confira a conexão. Se a sessão expirou, saia e entre novamente.',
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                            onPressed: refresh,
                            child: const Text('Tentar novamente')),
                      ],
                    ));
              }
              final agenda = snapshot.data!;
              final appointments = [...agenda.appointments]..sort((a, b) {
                  final first = appointmentShopTime(a.scheduledAt);
                  final second = appointmentShopTime(b.scheduledAt);
                  if (first == null || second == null) {
                    return (first == null ? 1 : 0) - (second == null ? 1 : 0);
                  }
                  return first.compareTo(second);
                });
              final pendingCount = appointments
                  .where((a) =>
                      a.status == 'agendado' &&
                      !agenda.completions.containsKey(a.id))
                  .length;
              final completedCount = appointments
                  .where((a) =>
                      a.status == 'concluido' ||
                      agenda.completions[a.id] == CompletionState.sent)
                  .length;
              return RefreshIndicator(
                onRefresh: refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 88),
                  children: [
                    Text(ApiClient.user?.name ?? 'Barbeiro',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(shopDateLabel(_selectedDate)),
                    const SizedBox(height: 12),
                    Text(
                        '$pendingCount ${pendingCount == 1 ? 'pendente' : 'pendentes'} • $completedCount ${completedCount == 1 ? 'concluído' : 'concluídos'}'),
                    if (agenda.offline)
                      const Text('Sem conexão. Mostrando a agenda salva.'),
                    if (agenda.completions
                        .containsValue(CompletionState.pending))
                      const Text('Há conclusões aguardando sincronização.'),
                    if (agenda.completions
                        .containsValue(CompletionState.rejected))
                      const Text(
                          'Uma ou mais conclusões não foram aceitas. O status da agenda no servidor foi mantido.'),
                    const SizedBox(height: 22),
                    if (appointments.isEmpty)
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Column(children: [
                            Icon(Icons.event_available_outlined, size: 48),
                            SizedBox(height: 16),
                            Text('Nenhum agendamento para esta data.',
                                textAlign: TextAlign.center),
                            SizedBox(height: 8),
                            Text('Puxe para baixo para atualizar.',
                                textAlign: TextAlign.center),
                          ])),
                    for (final appointment in appointments)
                      appointmentCard(
                          appointment, agenda.completions[appointment.id]),
                  ],
                ),
              );
            },
          ),
        ))),
      );
}
