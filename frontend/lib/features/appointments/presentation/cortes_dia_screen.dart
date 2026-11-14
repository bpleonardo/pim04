import 'package:barbearia_frontend/app/theme/app_theme.dart';
import 'dart:async';
import 'package:barbearia_frontend/features/appointments/data/offline_booking_repository.dart';
import 'package:barbearia_frontend/features/appointments/presentation/agendamento_screen.dart';
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
    if (widget.repository == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _probeAndRefresh());
    }
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
      _probeAndRefresh();
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
          agenda.completions.containsValue(CompletionState.pending) ||
          agenda.pending.any((p) => !p.rejected);
      return agenda;
    } on ApiException catch (error) {
      shouldRetry = error.retryable;
      rethrow;
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      } else {
        _loading = false;
      }
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (mounted &&
          (lifecycle == null || lifecycle == AppLifecycleState.resumed) &&
          shouldRetry) {
        _retryTimer = Timer.periodic(
            const Duration(seconds: 30), (_) => _probeAndRefresh());
      }
    }
  }

  Future<void> _probeAndRefresh() async {
    if (!mounted || _loading || completingId != null) return;
    if (ApiClient.connectionUnavailable && !await ApiClient.probeConnection()) {
      return;
    }
    if (mounted) await refresh();
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

  Future<void> editAppointment(Appointment appointment,
      {PendingAppointment? conflict}) async {
    try {
      var draft = appointment;
      var recreate = false;
      if (conflict != null) {
        final id = await repo.bookings.remoteId(conflict.entityId);
        if (id.startsWith('local:')) {
          recreate = true;
        } else {
          final server = await repo.api.appointment(id);
          if (!mounted) return;
          final mutations = (await repo.bookings.pending())
              .where((p) => p.entityId == conflict.entityId)
              .toList();
          final statusOnly =
              mutations.isNotEmpty && mutations.last.kind == 'status';
          if (!mounted) return;
          final apply = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                    title: const Text('Revisar conflito'),
                    content: Text(
                        'Servidor: ${shopDateLabel(appointmentShopTime(server.scheduledAt)!)} às ${shopClockLabel(appointmentShopTime(server.scheduledAt)!)}; status ${appointmentStatusLabel(server.status)}. Cliente: ${server.clientName}; serviços: ${server.services.join(', ')}. ${statusOnly ? 'Ao confirmar, somente o status local (${appointmentStatusLabel(appointment.status)}) será reaplicado; os outros dados do servidor serão mantidos.' : 'Sua edição local será aberta para revisão. Nada será sobrescrito automaticamente.'}'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Voltar')),
                      FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(statusOnly
                              ? 'Reaplicar status'
                              : 'Revisar edição'))
                    ],
                  ));
          if (apply != true || !mounted) return;
          if (statusOnly) {
            final preview = Appointment.fromJson(server.toJson()
              ..['status'] = appointment.status
              ..['revision'] = server.revision + 1);
            await repo.bookings.enqueue(
                'status',
                preview,
                {
                  'status': appointment.status,
                  'expectedRevision': server.revision
                },
                replacingConflict: conflict.entityId);
            if (mounted) await refresh();
            return;
          }
          draft = Appointment.fromJson(appointment.toJson()
            ..['id'] = id
            ..['revision'] = server.revision);
        }
      }
      if (!mounted) return;
      final date = await Navigator.push<DateTime>(
          context,
          MaterialPageRoute(
              builder: (_) => AgendamentoScreen(
                  forCurrentEmployee: true,
                  appointment: draft,
                  conflictEntityId: conflict?.entityId,
                  recreate: recreate)));
      if (date != null && mounted) {
        _selectedDate = date;
        await refresh();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Não foi possível abrir a edição: $error')));
      }
    }
  }

  Future<void> changeStatus(Appointment appointment, String status) async {
    if (_loading || completingId != null) return;
    setState(() => completingId = appointment.id);
    try {
      await repo.changeStatus(appointment, status);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) {
        setState(() => completingId = null);
        await refresh();
      }
    }
  }

  Future<void> discard(PendingAppointment conflict) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Descartar alteração local?'),
              content: const Text(
                  'O cadastro que está no servidor será mantido. As alterações locais deste agendamento serão removidas.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Voltar')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Descartar'))
              ],
            ));
    if (confirmed != true) return;
    await repo.bookings.discardConflict(conflict.entityId);
    if (mounted) await refresh();
  }

  Widget appointmentCard(Appointment appointment, CompletionState? completion,
      {PendingAppointment? pending}) {
    final canComplete = appointment.status == 'agendado' && completion == null;
    final status = pending != null
        ? (pending.rejected
            ? 'Conflito: ${pending.error}'
            : 'Alteração local · aguardando sincronização')
        : switch (completion) {
            CompletionState.pending => 'Aguardando sincronização',
            CompletionState.sent => 'Concluído',
            CompletionState.rejected =>
              '${appointmentStatusLabel(appointment.status)} · Conclusão não sincronizada',
            null => appointmentStatusLabel(appointment.status),
          };
    return AppointmentCard(
      appointment: appointment,
      status: status,
      action: pending?.rejected == true
          ? Wrap(children: [
              TextButton(
                  onPressed: () =>
                      editAppointment(appointment, conflict: pending),
                  child: const Text('Resolver')),
              IconButton(
                  tooltip: 'Descartar alteração local',
                  onPressed: () => discard(pending!),
                  icon: const Icon(Icons.delete_outline)),
            ])
          : Wrap(children: [
              if (canComplete)
                TextButton(
                    onPressed: completingId != null
                        ? null
                        : () => completeAppointment(appointment),
                    child: Text(completingId == appointment.id
                        ? 'Aguarde...'
                        : 'Concluir corte')),
              if (appointment.status == 'agendado')
                IconButton(
                    tooltip: 'Editar agendamento',
                    onPressed: completingId != null
                        ? null
                        : () => editAppointment(appointment),
                    icon: const Icon(Icons.edit_outlined)),
              PopupMenuButton<String>(
                  tooltip: 'Alterar status',
                  onSelected: (status) => changeStatus(appointment, status),
                  itemBuilder: (_) => [
                        for (final status in [
                          'agendado',
                          'concluido',
                          'cancelado'
                        ])
                          if (status != appointment.status)
                            PopupMenuItem(
                                value: status,
                                child: Text(appointmentStatusLabel(status)))
                      ])
            ]),
    );
  }

  PendingAppointment? _pendingFor(List<PendingAppointment> items, String id) {
    final matching = items.where((p) => p.entityId == id).toList();
    if (matching.isEmpty) return null;
    final rejected = matching.where((p) => p.rejected);
    return rejected.isEmpty ? matching.last : rejected.first;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        appBar: AppBar(
          title: const Text('Agendamentos'),
          actions: [
            const ThemeToggleButton(),
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
                    _probeAndRefresh();
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
                ListTile(
                    leading: const Icon(Icons.analytics_outlined),
                    title: const Text('Indicadores'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRouter.dashboard);
                    }),
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
                  onTap: () async {
                    try {
                      await ApiClient.logout();
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Não foi possível sair. $error')),
                        );
                      }
                      return;
                    }
                    if (!context.mounted) return;
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
                            onPressed: _probeAndRefresh,
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
                onRefresh: _probeAndRefresh,
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
                    if (agenda.pending.isNotEmpty)
                      ExpansionTile(
                          title: Text(
                              '${agenda.pending.length} alterações locais'),
                          subtitle: const Text(
                              'A confirmação depende da API. Toque para ver as datas e conflitos.'),
                          children: [
                            for (final p in agenda.pending)
                              ListTile(
                                  leading: Icon(p.rejected
                                      ? Icons.error_outline
                                      : Icons.cloud_upload_outlined),
                                  title: Text(p.appointment.clientName),
                                  subtitle: Text(
                                      '${shopDateLabel(appointmentShopTime(p.appointment.scheduledAt)!)} · ${p.error ?? 'Aguardando sincronização'}'),
                                  onTap: () {
                                    _selectedDate = appointmentShopTime(
                                        p.appointment.scheduledAt)!;
                                    refresh();
                                  })
                          ]),
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
                          appointment, agenda.completions[appointment.id],
                          pending: _pendingFor(agenda.pending, appointment.id)),
                  ],
                ),
              );
            },
          ),
        ))),
      );
}
