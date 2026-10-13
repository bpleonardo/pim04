import 'package:flutter/material.dart';
import '../../features/auth/presentation/login_page.dart';

class AppRouter {
  static const login = '/login';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute<void>(
          builder: (_) => const LoginPage(),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Página não encontrada')),
          ),
        );
    }
  }
}
