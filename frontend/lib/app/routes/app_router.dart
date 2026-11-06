import 'package:flutter/material.dart';
import 'package:barbearia_frontend/core/responsive/app_platform.dart';
import 'package:barbearia_frontend/features/appointments/presentation/cortes_dia_screen.dart';
import 'package:barbearia_frontend/features/auth/presentation/login_page.dart';
import 'package:barbearia_frontend/features/home/presentation/home_screen.dart';
import 'package:barbearia_frontend/features/catalog/presentation/catalogo_screen.dart';
import 'package:barbearia_frontend/features/appointments/presentation/agendamento_screen.dart';
import 'package:barbearia_frontend/features/appointments/presentation/agenda_screen.dart';
import 'package:barbearia_frontend/features/dashboard/presentation/dashboard_screen.dart';

class AppRouter {
  static const login = '/login';
  static const home = '/home';
  static const catalog = '/servicos';
  static const newAppointment = '/agendar';
  static const agenda = '/agenda';
  static const dashboard = '/dashboard';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final page = switch (settings.name) {
      '/' || login => const LoginPage(),
      home => AppPlatform.mobile ? const CortesDiaScreen() : const HomeScreen(),
      catalog =>
        AppPlatform.mobile ? const CortesDiaScreen() : const CatalogoScreen(),
      newAppointment => AppPlatform.mobile
          ? const CortesDiaScreen()
          : const AgendamentoScreen(),
      agenda =>
        AppPlatform.mobile ? const CortesDiaScreen() : const AgendaScreen(),
      dashboard =>
        AppPlatform.mobile ? const CortesDiaScreen() : const DashboardScreen(),
      _ => const Scaffold(body: Center(child: Text('Página não encontrada'))),
    };
    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }
}
