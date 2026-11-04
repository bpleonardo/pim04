import 'package:flutter/material.dart';
import '../../data/repositories/servico_repository.dart';
import '../../models/servico.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});
  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  late Future<List<Servico>> future;
  @override
  void initState() {
    super.initState();
    future = ServicoRepository().listar();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Serviços')),
      body: FutureBuilder<List<Servico>>(
          future: future,
          builder: (context, s) {
            if (s.connectionState != ConnectionState.done)
              return const Center(child: CircularProgressIndicator());
            if (s.hasError) return Center(child: Text('Erro: ${s.error}'));
            final list = s.data ?? [];
            if (list.isEmpty)
              return const Center(child: Text('Nenhum serviço cadastrado'));
            return ListView(children: [
              for (final x in list)
                ListTile(
                    title: Text(x.nome),
                    subtitle: Text(x.descricao ?? ''),
                    trailing: Text('R\$ ${x.preco.toStringAsFixed(2)}'))
            ]);
          }));
}
