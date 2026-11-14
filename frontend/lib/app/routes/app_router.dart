import 'package:flutter/material.dart';
import 'package:barbearia_frontend/app/layout/desktop_layout.dart';
import 'package:barbearia_frontend/core/responsive/app_platform.dart';
import 'package:barbearia_frontend/features/appointments/presentation/cortes_dia_screen.dart';
import 'package:barbearia_frontend/features/auth/presentation/login_page.dart';
import 'package:barbearia_frontend/features/catalog/presentation/catalogo_screen.dart';
import 'package:barbearia_frontend/features/appointments/presentation/agendamento_screen.dart';
import 'package:barbearia_frontend/features/appointments/presentation/agenda_screen.dart';
import 'package:barbearia_frontend/features/dashboard/presentation/dashboard_screen.dart';
import 'package:barbearia_frontend/features/settings/presentation/api_settings_screen.dart';

class AppRouter {
  static const login = '/login';
  static const home = '/home';
  static const catalog = '/servicos';
  static const newAppointment = '/agendar';
  static const agenda = '/agenda';
  static const dashboard = '/dashboard';
  static const settingsRoute = '/configuracoes';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    if (!AppPlatform.mobile &&
        settings.name != '/' &&
        settings.name != login &&
        settings.name != home) {
      return _SmoothPageRoute<void>(
        builder: (_) => DesktopLayout(
          initialRoute: settings.name!,
          initialContent: desktopPage(settings.name),
        ),
        settings: settings,
      );
    }
    if (settings.name == newAppointment) {
      return _SmoothPageRoute<DateTime>(
        builder: (_) => const AgendamentoScreen(forCurrentEmployee: true),
        settings: settings,
      );
    }
    final page = switch (settings.name) {
      '/' || login => const LoginPage(),
      home ||
      agenda =>
        AppPlatform.mobile ? const CortesDiaScreen() : const AgendaScreen(),
      catalog => AppPlatform.mobile
          ? const CatalogoScreen()
          : DesktopLayout(
              initialRoute: catalog,
              initialContent: const CatalogoScreen(),
            ),
      dashboard => AppPlatform.mobile
          ? const DashboardScreen()
          : DesktopLayout(
              initialRoute: dashboard,
              initialContent: const DashboardScreen(),
            ),
      settingsRoute => AppPlatform.mobile
          ? const ApiSettingsScreen()
          : DesktopLayout(
              initialRoute: settingsRoute,
              initialContent: const ApiSettingsScreen(embedded: true),
            ),
      _ => const Scaffold(body: Center(child: Text('Página não encontrada'))),
    };
    return _SmoothPageRoute<void>(
      builder: (_) => page,
      settings: settings,
    );
  }

  static Widget desktopPage(String? name) => switch (name) {
        home || agenda => const AgendaScreen(embedded: true),
        catalog => const CatalogoScreen(embedded: true),
        newAppointment => const AgendamentoScreen(embedded: true),
        dashboard => const DashboardScreen(embedded: true),
        settingsRoute => const ApiSettingsScreen(embedded: true),
        _ => const Scaffold(
            body: Center(child: Text('Página não encontrada')),
          ),
      };
}

class _SmoothPageRoute<T> extends MaterialPageRoute<T> {
  _SmoothPageRoute({
    required super.builder,
    super.settings,
  });

  @override
  Duration get transitionDuration =>
      AppPlatform.mobile ? const Duration(milliseconds: 150) : Duration.zero;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (!AppPlatform.mobile ||
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false)) {
      return child;
    }
    final offset = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: SlideTransition(position: animation.drive(offset), child: child),
    );
  }
}
