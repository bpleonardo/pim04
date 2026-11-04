import 'package:flutter/material.dart';
import '../../data/api/barbearia_api.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: FutureBuilder<Map<String, dynamic>>(
          future: BarbeariaApi().dashboard(),
          builder: (context, s) {
            if (s.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (s.hasError) return Center(child: Text('Erro: ${s.error}'));
            final indicadores = (s.data?['indicadores'] as List?) ?? [];
            return ListView(padding: const EdgeInsets.all(16), children: [
              for (final i in indicadores)
                Card(
                    child: ListTile(
                        title: Text('${i['label']}'),
                        subtitle: Text('${i['note'] ?? ''}'),
                        trailing: Text('${i['value']}')))
            ]);
          }));
}
