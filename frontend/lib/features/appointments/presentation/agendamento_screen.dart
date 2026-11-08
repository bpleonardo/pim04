import 'package:flutter/material.dart';
import 'package:barbearia_frontend/core/shop_time.dart';
import 'package:barbearia_frontend/core/network/barbershop_api.dart';
import 'package:barbearia_frontend/features/catalog/models/service.dart';
import 'package:barbearia_frontend/features/employees/models/employee.dart';

class AgendamentoScreen extends StatefulWidget {
  const AgendamentoScreen({super.key});
  @override
  State<AgendamentoScreen> createState() => _AgendamentoScreenState();
}

class _AgendamentoScreenState extends State<AgendamentoScreen> {
  final api = BarbershopApi();
  final form = GlobalKey<FormState>();
  final name = TextEditingController(), phone = TextEditingController();
  late Future<void> loading;
  List<Service> services = [];
  List<Employee> employees = [];
  String? serviceId, employeeId, slot;
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
        serviceId == null ||
        employeeId == null ||
        slot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Selecione serviço, barbeiro e horário')));
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
          services: [serviceId!]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agendamento confirmado pela API')));
        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Novo agendamento')),
      body: FutureBuilder<void>(
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
                                  decoration: const InputDecoration(
                                      labelText: 'Nome do cliente'),
                                  validator: (v) => (v ?? '').trim().length < 3
                                      ? 'Nome obrigatório'
                                      : null),
                              const SizedBox(height: 16),
                              TextFormField(
                                  controller: phone,
                                  decoration: const InputDecoration(
                                      labelText:
                                          'Telefone (55 + DDD + número)'),
                                  keyboardType: TextInputType.phone,
                                  validator: (v) => RegExp(r'^55\d{11}$')
                                          .hasMatch(v ?? '')
                                      ? null
                                      : 'Informe 13 dígitos começando por 55'),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                  initialValue: serviceId,
                                  decoration: const InputDecoration(
                                      labelText: 'Serviço'),
                                  items: [
                                    for (final x in services)
                                      DropdownMenuItem(
                                          value: x.id, child: Text(x.name))
                                  ],
                                  onChanged: (v) =>
                                      setState(() => serviceId = v)),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                  initialValue: employeeId,
                                  decoration: const InputDecoration(
                                      labelText: 'Barbeiro'),
                                  items: [
                                    for (final x in employees)
                                      DropdownMenuItem(
                                          value: x.id, child: Text(x.name))
                                  ],
                                  onChanged: (v) =>
                                      setState(() => employeeId = v)),
                              const SizedBox(height: 16),
                              ListTile(
                                  title: Text(
                                      'Data: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                                  trailing: const Icon(Icons.calendar_month),
                                  onTap: busy
                                      ? null
                                      : () async {
                                          final firstDate =
                                              shopTime(DateTime.now());
                                          final d = await showDatePicker(
                                              context: context,
                                              initialDate: selectedDate
                                                      .isBefore(firstDate)
                                                  ? firstDate
                                                  : selectedDate,
                                              firstDate: firstDate,
                                              lastDate: firstDate.add(
                                                  const Duration(days: 14)));
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
                                                    .showSnackBar(SnackBar(
                                                        content: Text('$e')));
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
                                  decoration: const InputDecoration(
                                      labelText: 'Horário'),
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
                                  child: Text(busy
                                      ? 'Aguarde...'
                                      : 'Confirmar agendamento')),
                            ]))));
          }));
}
