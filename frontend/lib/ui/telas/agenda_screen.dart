import 'package:flutter/material.dart';
import '../../models/agendamento.dart';
import '../../data/repositories/agendamento_repository.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});
  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final repo = AgendamentoRepository();
  late Future<List<Agendamento>> future;
  @override
  void initState() {
    super.initState();
    recarregar();
  }

  void recarregar() {
    future = repo.listar();
  }

  Future<void> atualizar(Agendamento a, String status) async {
    try {
      await repo.alterarStatus(a.id, status);
      if (mounted) setState(recarregar);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Agenda'), actions: [
        IconButton(
            onPressed: () => setState(recarregar),
            icon: const Icon(Icons.refresh))
      ]),
      body: FutureBuilder<List<Agendamento>>(
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
                        title: Text('${a.nomeCliente} • ${a.nomeFuncionario}'),
                        subtitle: Text(
                            '${a.dataAgendamento} • ${a.status} • R\$ ${a.total.toStringAsFixed(2)}'),
                        trailing: PopupMenuButton<String>(
                            onSelected: (v) => atualizar(a, v),
                            itemBuilder: (_) => [
                                  const PopupMenuItem(
                                      value: 'agendado',
                                      child: Text('Agendado')),
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
