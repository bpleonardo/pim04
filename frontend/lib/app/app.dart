import 'package:flutter/material.dart';
import 'package:barbearia_frontend/core/network/api_client.dart';
import 'package:barbearia_frontend/app/routes/app_router.dart';
import 'package:barbearia_frontend/app/theme/app_theme.dart';

class BarbershopApp extends StatelessWidget {
  const BarbershopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.mode,
      builder: (context, mode, _) => MaterialApp(
        title: 'Barbearia',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        initialRoute: ApiClient.user == null ? AppRouter.login : AppRouter.home,
        onGenerateRoute: AppRouter.onGenerateRoute,
        onGenerateInitialRoutes: (name) => [
          AppRouter.onGenerateRoute(RouteSettings(name: name)),
        ],
      ),
    );
  }
}
