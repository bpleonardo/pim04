import 'package:flutter/material.dart';
import 'package:barbearia_frontend/core/app_platform.dart';
import 'package:barbearia_frontend/ui/screens/daily_appointments_screen.dart';
import 'package:barbearia_frontend/ui/screens/login_screen.dart';
import 'package:barbearia_frontend/ui/screens/home_screen.dart';
import 'package:barbearia_frontend/ui/screens/catalog_screen.dart';
import 'package:barbearia_frontend/ui/screens/new_appointment_screen.dart';
import 'package:barbearia_frontend/ui/screens/appointment_list_screen.dart';
import 'package:barbearia_frontend/ui/screens/dashboard_screen.dart';

class Routes {
  static const login = '/';
  static const home = '/home';
  static const catalog = '/servicos';
  static const newAppointment = '/agendar';
  static const agenda = '/agenda';
  static const dashboard = '/dashboard';
  static Map<String, WidgetBuilder> get routes {
    if (AppPlatform.mobile) {
      return {
        login: (_) => const LoginScreen(),
        for (final route in [home, catalog, newAppointment, agenda, dashboard])
          route: (_) => const DailyAppointmentsScreen(),
      };
    }
    return {
      login: (_) => const LoginScreen(),
      home: (_) => const HomeScreen(),
      catalog: (_) => const CatalogScreen(),
      newAppointment: (_) => const NewAppointmentScreen(),
      agenda: (_) => const AppointmentListScreen(),
      dashboard: (_) => const DashboardScreen(),
    };
  }
}
