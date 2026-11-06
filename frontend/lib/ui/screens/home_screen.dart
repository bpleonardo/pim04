import 'package:flutter/material.dart';
import 'package:barbearia_frontend/core/routes.dart';
import 'package:barbearia_frontend/data/api/api_client.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Barbearia'), actions: [
        IconButton(
            onPressed: () {
              ApiClient.signOut();
              Navigator.pushNamedAndRemoveUntil(
                  context, Routes.login, (_) => false);
            },
            icon: const Icon(Icons.logout))
      ]),
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: ListView(padding: const EdgeInsets.all(20), children: [
                for (final item in [
                  ('Serviços', Routes.catalog),
                  ('Novo agendamento', Routes.newAppointment),
                  ('Agenda', Routes.agenda),
                  ('Dashboard', Routes.dashboard)
                ])
                  Card(
                      child: ListTile(
                          title: Text(item.$1),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pushNamed(context, item.$2))),
              ]))));
}
