import 'package:flutter/material.dart';
import 'core/tema.dart';
import 'core/rotas.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BarbeariaApp());
}

class BarbeariaApp extends StatelessWidget {
  const BarbeariaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Barbearia',
        debugShowCheckedModeBanner: false,
        theme: TemaApp.tema,
        initialRoute: Rotas.login,
        routes: Rotas.routes,
      );
}
