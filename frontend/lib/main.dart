import 'package:flutter/material.dart';
import 'package:barbearia_frontend/core/barbershop_theme.dart';
import 'package:barbearia_frontend/core/routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BarbershopApp());
}

class BarbershopApp extends StatelessWidget {
  const BarbershopApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Barbearia',
        debugShowCheckedModeBanner: false,
        theme: BarbershopTheme.theme,
        initialRoute: Routes.login,
        routes: Routes.routes,
      );
}
