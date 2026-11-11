import 'package:flutter/material.dart';
import 'package:barbearia_frontend/app/routes/app_router.dart';
import 'package:barbearia_frontend/core/shop_time.dart';
import 'package:barbearia_frontend/core/network/barbershop_api.dart';
import 'package:barbearia_frontend/features/catalog/models/service.dart';
import 'package:barbearia_frontend/features/employees/models/employee.dart';
import 'package:barbearia_frontend/app/layout/desktop_layout.dart';

class AgendamentoScreen extends StatefulWidget {
  const AgendamentoScreen({super.key, this.api, this.embedded = false});

  final BarbershopApi? api;
  final bool embedded;

  @override
  State<AgendamentoScreen> createState() => _AgendamentoScreenState();
}

class _AgendamentoScreenState extends State<AgendamentoScreen> {
  late final api = widget.api ?? BarbershopApi();
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
  @override
  void initState() {
    super.initState();
    loading = load();
  }

  Future<void> load() async {
    services = await api.services();
    employees = await api.employees();
    await loadTimeSlots();
  }

  Future<void> loadTimeSlots() async {
    timeSlots = await api.timeSlots(selectedDate);
    slot = null;
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
      await api.createAppointment(
          name: name.text.trim(),
          phone: phone.text.trim(),
          employeeId: employeeId!,
          scheduledAt: scheduledAt,
          services: selectedServiceIds.toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agendamento confirmado pela API')));
        if (widget.embedded) {
          DesktopLayout.of(context).open(AppRouter.home);
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
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
                        onChanged: (v) => setState(() => employeeId = v)),
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
          appBar: AppBar(title: const Text('Novo agendamento')),
          body: buildContent(),
        );
}
