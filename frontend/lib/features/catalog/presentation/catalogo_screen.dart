import 'package:flutter/material.dart';
import 'package:barbearia_frontend/features/catalog/data/service_repository.dart';
import 'package:barbearia_frontend/features/catalog/models/service.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  late Future<List<Service>> future;

  @override
  void initState() {
    super.initState();
    future = ServiceRepository().list();
  }

  Widget buildContent() => FutureBuilder<List<Service>>(
        future: future,
        builder: (context, s) {
          if (s.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (s.hasError) return Center(child: Text('Erro: ${s.error}'));
          final list = s.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('Nenhum serviço cadastrado'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final x in list)
                Card(
                  child: ListTile(
                    title: Text(x.name),
                    subtitle: Text(x.description ?? ''),
                    trailing: Text('R\$ ${x.price.toStringAsFixed(2)}'),
                  ),
                ),
            ],
          );
        },
      );

  @override
  Widget build(BuildContext context) => widget.embedded
      ? buildContent()
      : Scaffold(
          appBar: AppBar(title: const Text('Serviços')),
          body: buildContent(),
        );
}
