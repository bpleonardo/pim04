import 'dart:async';
import 'package:flutter/material.dart';
import 'package:barbearia_frontend/core/routes.dart';
import 'package:barbearia_frontend/data/api/api_client.dart';
import 'package:barbearia_frontend/data/repositories/appointment_repository.dart';
import 'package:barbearia_frontend/models/appointment.dart';

class DailyAppointmentsScreen extends StatefulWidget {
  const DailyAppointmentsScreen({super.key, this.repository});
  final AppointmentRepository? repository;

  @override
  State<DailyAppointmentsScreen> createState() =>
      _DailyAppointmentsScreenState();
}

class _DailyAppointmentsScreenState extends State<DailyAppointmentsScreen>
    with WidgetsBindingObserver {
  late final AppointmentRepository repo;
  late Future<DailyAgenda> future;
  Timer? _retryTimer;
  bool _loading = false;
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
    try {
      final agenda = await repo.loadToday();
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (mounted &&
          (lifecycle == null || lifecycle == AppLifecycleState.resumed) &&
          agenda.completions.containsValue(CompletionState.pending)) {
        _retryTimer = Timer(const Duration(seconds: 30), refresh);
      }
      return agenda;
    } finally {
      _loading = false;
    }
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

  String formatTime(Appointment appointment) {
    final scheduledAt = DateTime.tryParse(appointment.scheduledAt);
    if (scheduledAt == null) return 'Horário não informado';
    final local = AppointmentRepository.shopTime(scheduledAt);
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String get dateLabel {
    final today = AppointmentRepository.shopTime(DateTime.now());
    const weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return '${weekdays[today.weekday - 1]}, ${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}';
  }

  Widget appointmentCard(Appointment appointment, CompletionState? completion) {
    final canComplete = appointment.status == 'agendado' && completion == null;
    final status = switch (completion) {
      CompletionState.pending => 'Aguardando sincronização',
      CompletionState.sent => 'Concluído',
      CompletionState.rejected => 'Sincronização recusada',
      null => switch (appointment.status) {
          'concluido' => 'Concluído',
          'cancelado' => 'Cancelado',
          'agendado' => 'Agendado',
          _ => appointment.status,
        },
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF303030)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Text(appointment.clientName,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w600))),
            const SizedBox(width: 12),
            Text(formatTime(appointment),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Text(appointment.services.isEmpty
              ? 'Atendimento'
              : appointment.services.join(' • ')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: Text(
                    'R\$ ${appointment.total.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(fontWeight: FontWeight.w600))),
            Flexible(child: Text(status, textAlign: TextAlign.end)),
          ]),
          if (canComplete) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: completingId != null
                  ? null
                  : () => completeAppointment(appointment),
              icon: const Icon(Icons.check),
              label: Text(completingId == appointment.id
                  ? 'Aguarde...'
                  : 'Concluir corte'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Cortes de hoje'),
          actions: [
            IconButton(
                tooltip: 'Atualizar',
                onPressed: refresh,
                icon: const Icon(Icons.refresh)),
            IconButton(
                tooltip: 'Sair',
                onPressed: () {
                  ApiClient.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, Routes.login, (_) => false);
                },
                icon: const Icon(Icons.logout)),
          ],
        ),
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: FutureBuilder<DailyAgenda>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done &&
                  !snapshot.hasData) {
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
                            'Não foi possível carregar os cortes de hoje. Confira a conexão. Se a sessão expirou, saia e entre novamente.',
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                            onPressed: refresh,
                            child: const Text('Tentar novamente')),
                      ],
                    ));
              }
              final agenda = snapshot.data!;
              final appointments = [...agenda.appointments]
                ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
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
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(ApiClient.user?.name ?? 'Barbeiro',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(dateLabel),
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
                          'A API recusou uma ou mais conclusões. Confira a agenda com a barbearia.'),
                    const SizedBox(height: 22),
                    if (appointments.isEmpty)
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Column(children: [
                            Icon(Icons.event_available_outlined, size: 48),
                            SizedBox(height: 16),
                            Text('Nenhum corte para você hoje.',
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
