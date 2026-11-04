import 'package:flutter/material.dart';
import '../../core/rotas.dart';
import '../../data/api/barbearia_api.dart';
import '../../data/api/api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final form = GlobalKey<FormState>();
  final login = TextEditingController(), senha = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    login.dispose();
    senha.dispose();
    super.dispose();
  }

  Future<void> entrar() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final result = await BarbeariaApi().login(login.text.trim(), senha.text);
      ApiClient.token = result['token'] as String;
      if (mounted) Navigator.pushReplacementNamed(context, Rotas.home);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                      key: form,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.content_cut, size: 52),
                        const SizedBox(height: 16),
                        const Text('Barbearia',
                            style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        TextFormField(
                            controller: login,
                            decoration: const InputDecoration(
                                labelText: 'Login',
                                border: OutlineInputBorder()),
                            validator: (v) => (v == null || v.trim().length < 3)
                                ? 'Informe seu login'
                                : null),
                        const SizedBox(height: 12),
                        TextFormField(
                            controller: senha,
                            obscureText: true,
                            decoration: const InputDecoration(
                                labelText: 'Senha',
                                border: OutlineInputBorder()),
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Informe sua senha'
                                : null),
                        const SizedBox(height: 20),
                        SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                                onPressed: busy ? null : entrar,
                                child: Text(busy ? 'Entrando...' : 'Entrar'))),
                      ]))))));
}
