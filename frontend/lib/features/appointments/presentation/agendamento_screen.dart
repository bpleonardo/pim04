import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:barbearia_frontend/core/storage/app_database.dart';
import 'package:barbearia_frontend/features/appointments/data/offline_booking_repository.dart';
import 'package:barbearia_frontend/features/appointments/models/appointment.dart';

import 'package:barbearia_frontend/core/network/api_client.dart';
import 'package:barbearia_frontend/app/routes/app_router.dart';
import 'package:barbearia_frontend/core/shop_time.dart';
import 'package:barbearia_frontend/core/network/barbershop_api.dart';
import 'package:barbearia_frontend/features/catalog/models/service.dart';
import 'package:barbearia_frontend/features/employees/models/employee.dart';
import 'package:barbearia_frontend/app/layout/desktop_layout.dart';

class AgendamentoScreen extends StatefulWidget {
  const AgendamentoScreen(
      {super.key,
      this.api,
      this.embedded = false,
      this.forCurrentEmployee = false,
      this.appointment,
      this.conflictEntityId,
      this.recreate = false,
      this.offlineRepository});

  final OfflineBookingRepository? offlineRepository;
  final Appointment? appointment;
  final String? conflictEntityId;
  final bool recreate;
  final BarbershopApi? api;
  final bool embedded;
  final bool forCurrentEmployee;

  @override
  State<AgendamentoScreen> createState() => _AgendamentoScreenState();
}

class _AgendamentoScreenState extends State<AgendamentoScreen> {
  late final api = widget.api ?? BarbershopApi();
  late final OfflineBookingRepository? offlineRepo = widget.offlineRepository ??
      (AppDatabase.available && widget.forCurrentEmployee
          ? OfflineBookingRepository(api: api)
          : null);
  final form = GlobalKey<FormState>();
  final name = TextEditingController(), phone = TextEditingController();
  late Future<void> loading;
  List<Service> services = [];
  List<Employee> employees = [];
  final selectedServiceIds = <String>{};
  String? employeeId, slot;
  DateTime selectedDate = shopTime(DateTime.now());
  List<Map<String, dynamic>> timeSlots = [];
  bool busy = false;
  String? _bookingKey, _bookingNonce;
  @override
  void initState() {
    super.initState();
    final existing = widget.appointment;
    if (existing != null) {
      name.text = existing.clientName;
      phone.text = existing.phone;
      selectedServiceIds.addAll(existing.serviceIds);
      final day = appointmentShopTime(existing.scheduledAt);
      if (day != null) selectedDate = day;
    }
    loading = load();
  }

  Future<void> load() async {
    if (widget.forCurrentEmployee) {
      final user = ApiClient.user;
      if (user == null || ApiClient.token == null) {
        throw const ApiException('Entre novamente para agendar.', 401);
      }
      employeeId = user.id;
      employees = [Employee(id: user.id, name: user.name)];
    } else {
      employees = await api.employees();
    }
    services = (await (offlineRepo?.services() ?? api.services()))
        .where((service) => service.enabled)
        .toList();
    selectedServiceIds
        .removeWhere((id) => !services.any((service) => service.id == id));
    await loadTimeSlots();
  }

  Future<void> loadTimeSlots() async {
    final original = widget.appointment == null
        ? null
        : appointmentShopTime(widget.appointment!.scheduledAt);
    final sameDay = original != null &&
        original.year == selectedDate.year &&
        original.month == selectedDate.month &&
        original.day == selectedDate.day;
    final originalSlot = sameDay ? shopClockLabel(original) : null;
    if (sameDay &&
        !shopSlotToUtc(original, original.hour, original.minute)
            .isAfter(DateTime.now().toUtc())) {
      timeSlots = [
        {'slot': originalSlot, 'available': true}
      ];
      slot = originalSlot;
      return;
    }
    timeSlots =
        await (offlineRepo?.slots(selectedDate) ?? api.timeSlots(selectedDate));
    slot = originalSlot;
    if (originalSlot != null) {
      timeSlots = [
        for (final entry in timeSlots)
          if (entry['slot'] != slot) entry,
        {'slot': slot, 'available': true}
      ];
      timeSlots
          .sort((a, b) => a['slot'].toString().compareTo(b['slot'].toString()));
    }
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> confirm() async {
    if (busy) return;
    if (!form.currentState!.validate() ||
        selectedServiceIds.isEmpty ||
        employeeId == null ||
        slot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Selecione pelo menos um serviço, o barbeiro e o horário')));
      return;
    }
    setState(() => busy = true);
    try {
      final selectedSlot = slot!;
      final parts = RegExp(r'\d{1,2}:\d{2}').firstMatch(selectedSlot);
      if (parts == null) throw Exception('Horário inválido: $selectedSlot');
      final hm = parts.group(0)!.split(':');
      final scheduledAt =
          shopSlotToUtc(selectedDate, int.parse(hm[0]), int.parse(hm[1]));
      final services = selectedServiceIds.toList()..sort();
      final key = jsonEncode([
        ApiClient.baseUrl,
        name.text.trim(),
        phone.text.trim(),
        employeeId,
        scheduledAt.toIso8601String(),
        services,
      ]);
      if (_bookingKey != key) {
        _bookingKey = key;
        _bookingNonce = ApiClient.newNonce();
      }
      final original = widget.appointment;
      final unchangedTime = original != null &&
          !widget.recreate &&
          DateTime.parse(original.scheduledAt).toUtc() == scheduledAt;
      if (!unchangedTime && !scheduledAt.isAfter(DateTime.now().toUtc())) {
        throw const ApiException('Escolha um horário futuro.');
      }
      final booking = <String, dynamic>{
        'nomeCliente': name.text.trim(),
        'telefoneCliente': phone.text.trim(),
        'idFuncionario': employeeId!,
        'dataAgendamento': scheduledAt.toIso8601String(),
        'idServicos': services,
      };
      final repository = offlineRepo;
      var pending = false;
      if (repository != null) {
        booking['recordedAt'] = DateTime.now().toUtc().toIso8601String();
        final existing = widget.appointment;
        final creating = existing == null || widget.recreate;
        final id = creating ? 'local:$_bookingNonce' : existing.id;
        final selected =
            this.services.where((s) => services.contains(s.id)).toList();
        final preview = Appointment(
            id: id,
            scheduledAt: scheduledAt.toIso8601String(),
            status: 'agendado',
            clientName: name.text.trim(),
            phone: phone.text.trim(),
            employeeName: ApiClient.user!.name,
            employeeId: employeeId!,
            total: selected.fold(0.0, (sum, service) => sum + service.price),
            services: selected.map((s) => s.name).toList(),
            serviceIds: services,
            revision: creating ? 0 : existing.revision + 1);
        await repository.enqueue(
            creating ? 'create' : 'edit',
            preview,
            creating
                ? {...booking, 'clientRequestId': _bookingNonce}
                : {'booking': booking, 'expectedRevision': existing.revision},
            replacingConflict: widget.conflictEntityId);
        pending = (await repository.pending()).any((p) => p.entityId == id);
      } else {
        await api.createAppointment(
            name: name.text.trim(),
            phone: phone.text.trim(),
            employeeId: employeeId!,
            scheduledAt: scheduledAt,
            services: services,
            nonce: _bookingNonce);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(pending
                ? 'Salvo no aparelho. Aguarda sincronização; confira possíveis conflitos na agenda.'
                : 'Agendamento confirmado pela API')));
        if (widget.embedded) {
          DesktopLayout.of(context).open(AppRouter.home);
        } else {
          Navigator.pop(context, selectedDate);
        }
      }
    } catch (e) {
      if (e is ApiException && !e.retryable) _bookingKey = null;
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget buildContent() => FutureBuilder<void>(
        future: loading,
        builder: (context, s) {
          if (s.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (s.hasError) return Center(child: Text('Erro: ${s.error}'));
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Form(
                key: form,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (offlineRepo?.offline == true)
                      const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text(
                              'Sem conexão. Serviços salvos e horários previstos. A API confirmará disponibilidade e preços ao sincronizar.')),
                    TextFormField(
                        controller: name,
                        decoration:
                            const InputDecoration(labelText: 'Nome do cliente'),
                        validator: (v) => (v ?? '').trim().length < 3
                            ? 'Nome obrigatório'
                            : null),
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: phone,
                        decoration: const InputDecoration(
                            labelText: 'Telefone (55 + DDD + número)'),
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            RegExp(r'^55\d{11}$').hasMatch(v ?? '')
                                ? null
                                : 'Informe 13 dígitos começando por 55'),
                    const SizedBox(height: 16),
                    Text('Serviços',
                        style: Theme.of(context).textTheme.titleSmall),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final service in services)
                          FilterChip(
                            label: Text(service.name),
                            selected: selectedServiceIds.contains(service.id),
                            onSelected: busy
                                ? null
                                : (selected) => setState(() {
                                      if (selected) {
                                        selectedServiceIds.add(service.id);
                                      } else {
                                        selectedServiceIds.remove(service.id);
                                      }
                                    }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                        initialValue: employeeId,
                        decoration:
                            const InputDecoration(labelText: 'Barbeiro'),
                        items: [
                          for (final x in employees)
                            DropdownMenuItem(value: x.id, child: Text(x.name))
                        ],
                        onChanged: widget.forCurrentEmployee || busy
                            ? null
                            : (v) => setState(() => employeeId = v)),
                    const SizedBox(height: 16),
                    ListTile(
                        title: Text(
                            'Data: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                        trailing: const Icon(Icons.calendar_month),
                        onTap: busy
                            ? null
                            : () async {
                                final firstDate = shopTime(DateTime.now());
                                final d = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        selectedDate.isBefore(firstDate)
                                            ? firstDate
                                            : selectedDate,
                                    firstDate: firstDate,
                                    lastDate: firstDate
                                        .add(const Duration(days: 14)));
                                if (!context.mounted) return;
                                if (d != null) {
                                  setState(() {
                                    busy = true;
                                    selectedDate = d;
                                    slot = null;
                                    timeSlots = [];
                                  });
                                  try {
                                    await loadTimeSlots();
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                              SnackBar(content: Text('$e')));
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => busy = false);
                                    }
                                  }
                                }
                              }),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                        key: ValueKey(selectedDate),
                        initialValue: slot,
                        decoration: const InputDecoration(labelText: 'Horário'),
                        items: [
                          for (final h in timeSlots)
                            if (h['available'] == true)
                              DropdownMenuItem(
                                  value: h['slot'].toString(),
                                  child: Text('${h['slot']}'))
                        ],
                        onChanged: (v) => setState(() => slot = v)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: busy ? null : confirm,
                        child: Text(
                            busy ? 'Aguarde...' : 'Confirmar agendamento')),
                  ],
                ),
              ),
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) => widget.embedded
      ? buildContent()
      : Scaffold(
          appBar: AppBar(
              title: Text(widget.appointment == null
                  ? 'Novo agendamento'
                  : 'Editar agendamento')),
          body: buildContent(),
        );
}
