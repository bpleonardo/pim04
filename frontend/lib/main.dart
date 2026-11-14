import 'package:flutter/material.dart';
import 'package:barbearia_frontend/app/app.dart';
import 'package:barbearia_frontend/core/network/api_client.dart';
import 'package:barbearia_frontend/core/config/api_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.initialize();
  await ApiClient.restoreSession();
  runApp(const BarbershopApp());
}
