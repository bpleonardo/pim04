import 'package:flutter/material.dart';
import '../../data/api/barbearia_api.dart';
import '../../models/servico.dart';
import '../../models/funcionario.dart';

class AgendamentoScreen extends StatefulWidget {
  const AgendamentoScreen({super.key});
  @override
  State<AgendamentoScreen> createState() => _AgendamentoScreenState();
}

class _AgendamentoScreenState extends State<AgendamentoScreen> {
  final api = BarbeariaApi();
  final form = GlobalKey<FormState>();
  final nome = TextEditingController(), telefone = TextEditingController();
  late Future<void> carregamento;
  List<Servico> servicos = [];
  List<Funcionario> funcionarios = [];
  String? servicoId, funcionarioId, slot;
  DateTime dia = DateTime.now();
  List<Map<String, dynamic>> horarios = [];
  bool busy = false;
  @override
  void initState() {
    super.initState();
    carregamento = carregar();
  }

  Future<void> carregar() async {
    servicos = await api.servicos();
    funcionarios = await api.funcionarios();
    await buscarHorarios();
  }

  Future<void> buscarHorarios() async {
    horarios = await api.horarios(dia);
    slot = null;
  }

  @override
  void dispose() {
    nome.dispose();
    telefone.dispose();
    super.dispose();
  }

  Future<void> confirmar() async {
    if (!form.currentState!.validate() ||
        servicoId == null ||
        funcionarioId == null ||
        slot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Selecione serviço, barbeiro e horário')));
      return;
    }
    setState(() => busy = true);
    try {
      final horario = slot!;
      final parts = RegExp(r'\d{1,2}:\d{2}').firstMatch(horario);
      if (parts == null) throw Exception('Horário inválido: $horario');
      final hm = parts.group(0)!.split(':');
      final data = DateTime(
          dia.year, dia.month, dia.day, int.parse(hm[0]), int.parse(hm[1]));
      await api.criar(
          nome: nome.text.trim(),
          telefone: telefone.text.trim(),
          funcionarioId: funcionarioId!,
          data: data,
          servicos: [servicoId!]);
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
          future: carregamento,
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
                                  controller: nome,
                                  decoration: const InputDecoration(
                                      labelText: 'Nome do cliente'),
                                  validator: (v) => (v ?? '').trim().length < 3
                                      ? 'Nome obrigatório'
                                      : null),
                              TextFormField(
                                  controller: telefone,
                                  decoration: const InputDecoration(
                                      labelText:
                                          'Telefone (55 + DDD + número)'),
                                  keyboardType: TextInputType.phone,
                                  validator: (v) => RegExp(r'^55\d{11}$')
                                          .hasMatch(v ?? '')
                                      ? null
                                      : 'Informe 13 dígitos começando por 55'),
                              DropdownButtonFormField<String>(
                                  initialValue: servicoId,
                                  decoration: const InputDecoration(
                                      labelText: 'Serviço'),
                                  items: [
                                    for (final x in servicos)
                                      DropdownMenuItem(
                                          value: x.id, child: Text(x.nome))
                                  ],
                                  onChanged: (v) =>
                                      setState(() => servicoId = v)),
                              DropdownButtonFormField<String>(
                                  initialValue: funcionarioId,
                                  decoration: const InputDecoration(
                                      labelText: 'Barbeiro'),
                                  items: [
                                    for (final x in funcionarios)
                                      DropdownMenuItem(
                                          value: x.id, child: Text(x.nome))
                                  ],
                                  onChanged: (v) =>
                                      setState(() => funcionarioId = v)),
                              ListTile(
                                  title: Text(
                                      'Data: ${dia.day}/${dia.month}/${dia.year}'),
                                  trailing: const Icon(Icons.calendar_month),
                                  onTap: () async {
                                    final d = await showDatePicker(
                                        context: context,
                                        initialDate: dia,
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now()
                                            .add(const Duration(days: 14)));
                                    if (!context.mounted) return;
                                    if (d != null) {
                                      setState(() => busy = true);
                                      try {
                                        dia = d;
                                        await buscarHorarios();
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
                              DropdownButtonFormField<String>(
                                  key: ValueKey(dia),
                                  initialValue: slot,
                                  decoration: const InputDecoration(
                                      labelText: 'Horário'),
                                  items: [
                                    for (final h in horarios)
                                      if (h['available'] == true)
                                        DropdownMenuItem(
                                            value: h['slot'].toString(),
                                            child: Text('${h['slot']}'))
                                  ],
                                  onChanged: (v) => setState(() => slot = v)),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                  onPressed: busy ? null : confirmar,
                                  child: Text(busy
                                      ? 'Aguarde...'
                                      : 'Confirmar agendamento')),
                            ]))));
          }));
}
