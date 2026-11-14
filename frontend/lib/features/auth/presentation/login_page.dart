import 'package:barbearia_frontend/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:barbearia_frontend/features/appointments/data/appointment_repository.dart';
import 'package:barbearia_frontend/core/shop_time.dart';
import 'package:barbearia_frontend/app/routes/app_router.dart';
import 'package:barbearia_frontend/core/network/barbershop_api.dart';
import 'package:barbearia_frontend/core/network/api_client.dart';
import 'package:barbearia_frontend/core/config/api_config_dialog.dart';
import 'package:barbearia_frontend/core/responsive/app_platform.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final form = GlobalKey<FormState>();
  final login = TextEditingController(), password = TextEditingController();
  bool busy = false;
  bool showPassword = false;
  @override
  void dispose() {
    login.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final result =
          await BarbershopApi().login(login.text.trim(), password.text);
      await ApiClient.startSession(result);
      if (AppPlatform.mobile) {
        try {
          final repository = AppointmentRepository();
          await repository.loadDay(shopTime(DateTime.now()));
          if (!await repository.bookings.prepared()) {
            throw const ApiException('Preparação offline incompleta.');
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'Login salvo. Não foi possível preparar todos os dados offline; atualize a agenda com internet.')));
          }
        }
      }
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
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(14));
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 4,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ThemeToggleButton(),
                  if (AppPlatform.native)
                    IconButton(
                      tooltip: 'Configurar API',
                      onPressed: () => showApiConfigDialog(context),
                      icon: const Icon(Icons.settings_outlined),
                    ),
                ],
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Form(
                    key: form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Login',
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: login,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                              labelText: 'Usuário', border: border),
                          validator: (value) => (value ?? '').trim().length < 3
                              ? 'Informe seu login'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: password,
                          obscureText: !showPassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => signIn(),
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            border: border,
                            suffixIcon: IconButton(
                              tooltip: showPassword
                                  ? 'Ocultar senha'
                                  : 'Mostrar senha',
                              onPressed: () =>
                                  setState(() => showPassword = !showPassword),
                              icon: Icon(showPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                            ),
                          ),
                          validator: (value) => (value ?? '').length < 6
                              ? 'Informe sua senha'
                              : null,
                        ),
                        const SizedBox(height: 26),
                        SizedBox(
                          width: 180,
                          child: OutlinedButton(
                            onPressed: busy ? null : signIn,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(busy ? 'Entrando...' : 'Entrar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
