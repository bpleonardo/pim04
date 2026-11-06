import 'package:flutter/material.dart';
import 'package:barbearia_frontend/app/routes/app_router.dart';
import 'package:barbearia_frontend/features/auth/models/user.dart';
import 'package:barbearia_frontend/core/network/barbershop_api.dart';
import 'package:barbearia_frontend/core/network/api_client.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final form = GlobalKey<FormState>();
  final login = TextEditingController(), password = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    login.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final result =
          await BarbershopApi().login(login.text.trim(), password.text);
      final user = User.fromJson(Map<String, dynamic>.from(result['user']));
      ApiClient.token = result['token'] as String;
      ApiClient.user = user;
      if (mounted) Navigator.pushReplacementNamed(context, AppRouter.home);
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
                            controller: password,
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
                                onPressed: busy ? null : signIn,
                                child: Text(busy ? 'Entrando...' : 'Entrar'))),
                      ]))))));
}
