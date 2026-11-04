import 'package:flutter/material.dart';
import '../../core/rotas.dart';
import '../../data/api/api_client.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Barbearia'), actions: [
        IconButton(
            onPressed: () {
              ApiClient.sair();
              Navigator.pushNamedAndRemoveUntil(
                  context, Rotas.login, (_) => false);
            },
            icon: const Icon(Icons.logout))
      ]),
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: ListView(padding: const EdgeInsets.all(20), children: [
                for (final item in [
                  ('Serviços', Rotas.catalogo),
                  ('Novo agendamento', Rotas.novo),
                  ('Agenda', Rotas.agenda),
                  ('Dashboard', Rotas.dashboard)
                ])
                  Card(
                      child: ListTile(
                          title: Text(item.$1),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pushNamed(context, item.$2))),
              ]))));
}
