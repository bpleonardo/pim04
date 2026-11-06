import 'package:flutter/material.dart';
import 'package:barbearia_frontend/features/catalog/data/service_repository.dart';
import 'package:barbearia_frontend/features/catalog/models/service.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late Future<List<Service>> future;
  @override
  void initState() {
    super.initState();
    future = ServiceRepository().list();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Serviços')),
      body: FutureBuilder<List<Service>>(
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
            return ListView(children: [
              for (final x in list)
                ListTile(
                    title: Text(x.name),
                    subtitle: Text(x.description ?? ''),
                    trailing: Text('R\$ ${x.price.toStringAsFixed(2)}'))
            ]);
          }));
}
