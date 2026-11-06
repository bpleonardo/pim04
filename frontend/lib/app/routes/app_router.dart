import 'package:flutter/material.dart';
import 'package:barbearia_frontend/core/responsive/app_platform.dart';
import 'package:barbearia_frontend/features/appointments/presentation/daily_appointments_screen.dart';
import 'package:barbearia_frontend/features/auth/presentation/login_page.dart';
import 'package:barbearia_frontend/features/home/presentation/home_screen.dart';
import 'package:barbearia_frontend/features/catalog/presentation/catalog_screen.dart';
import 'package:barbearia_frontend/features/appointments/presentation/new_appointment_screen.dart';
import 'package:barbearia_frontend/features/appointments/presentation/appointment_list_screen.dart';
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
      home => AppPlatform.mobile
          ? const DailyAppointmentsScreen()
          : const HomeScreen(),
      catalog => AppPlatform.mobile
          ? const DailyAppointmentsScreen()
          : const CatalogScreen(),
      newAppointment => AppPlatform.mobile
          ? const DailyAppointmentsScreen()
          : const NewAppointmentScreen(),
      agenda => AppPlatform.mobile
          ? const DailyAppointmentsScreen()
          : const AppointmentListScreen(),
      dashboard => AppPlatform.mobile
          ? const DailyAppointmentsScreen()
          : const DashboardScreen(),
      _ => const Scaffold(body: Center(child: Text('Página não encontrada'))),
    };
    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }
}
