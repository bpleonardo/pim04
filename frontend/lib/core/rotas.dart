import 'package:flutter/material.dart';
import 'plataforma.dart';
import '../ui/telas/cortes_dia_screen.dart';
import '../ui/telas/login_screen.dart';
import '../ui/telas/home_screen.dart';
import '../ui/telas/catalogo_screen.dart';
import '../ui/telas/agendamento_screen.dart';
import '../ui/telas/agenda_screen.dart';
import '../ui/telas/dashboard_screen.dart';

class Rotas {
  static const login = '/';
  static const home = '/home';
  static const catalogo = '/servicos';
  static const novo = '/agendar';
  static const agenda = '/agenda';
  static const dashboard = '/dashboard';
  static Map<String, WidgetBuilder> get routes {
    if (Plataforma.mobile) {
      return {
        login: (_) => const LoginScreen(),
        for (final rota in [home, catalogo, novo, agenda, dashboard])
          rota: (_) => const CortesDiaScreen(),
      };
    }
    return {
      login: (_) => const LoginScreen(),
      home: (_) => const HomeScreen(),
      catalogo: (_) => const CatalogoScreen(),
      novo: (_) => const AgendamentoScreen(),
      agenda: (_) => const AgendaScreen(),
      dashboard: (_) => const DashboardScreen(),
    };
  }
}
