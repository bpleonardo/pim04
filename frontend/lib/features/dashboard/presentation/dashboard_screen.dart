import 'package:flutter/material.dart';
import 'package:barbearia_frontend/core/network/barbershop_api.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: FutureBuilder<Map<String, dynamic>>(
          future: BarbershopApi().dashboard(),
          builder: (context, s) {
            if (s.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (s.hasError) return Center(child: Text('Erro: ${s.error}'));
            final indicators = (s.data?['indicadores'] as List?) ?? [];
            return ListView(padding: const EdgeInsets.all(16), children: [
              for (final i in indicators)
                Card(
                    child: ListTile(
                        title: Text('${i['label']}'),
                        subtitle: Text('${i['note'] ?? ''}'),
                        trailing: Text('${i['value']}')))
            ]);
          }));
}
