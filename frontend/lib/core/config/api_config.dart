import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import 'package:barbearia_frontend/core/responsive/app_platform.dart';
import 'package:barbearia_frontend/core/storage/app_database.dart';
import 'package:barbearia_frontend/core/config/desktop_config_storage.dart';

class ApiConfig {
  static const defaultUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
  // No desenvolvimento, o servidor Flutter não encaminha /api para o backend.
  // Em produção, o Nginx atende /api na mesma origem do painel.
  static const webUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kDebugMode ? defaultUrl : '',
  );
  static String _url = defaultUrl;

  static String get baseUrl => AppPlatform.web ? webUrl : _url;

  static Future<void> initialize() async {
    if (AppPlatform.web) return;
    final persisted = AppPlatform.mobile
        ? await AppDatabase.readApiUrl()
        : await readDesktopApiUrl();
    if (persisted != null && isValidUrl(persisted)) {
      _url = persisted;
    } else if (AppPlatform.native && !AppPlatform.mobile) {
      await writeDesktopApiUrl(_url);
    }
  }

  static bool isValidUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  static Future<void> save(String value) async {
    if (AppPlatform.web) {
      throw UnsupportedError('A URL da API é fixa na versão Web.');
    }
    final normalized = value.trim().replaceFirst(RegExp(r'/$'), '');
    if (!isValidUrl(normalized)) {
      throw const FormatException(
          'Informe uma URL válida com http:// ou https://.');
    }
    if (AppPlatform.mobile) {
      await AppDatabase.writeApiUrl(normalized);
    } else if (AppPlatform.native) {
      await writeDesktopApiUrl(normalized);
    }
    _url = normalized;
  }

  static Future<void> validateConnection(String value) async {
    final normalized = value.trim().replaceFirst(RegExp(r'/$'), '');
    if (!isValidUrl(normalized)) {
      throw const FormatException(
          'Informe uma URL válida com http:// ou https://.');
    }
    final uri = Uri.parse('$normalized/api/ping');
    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('A URL não aponta para uma API válida.');
    }
    try {
      final body = jsonDecode(response.body);
      if (body is! Map || body['status'] != 'ok') {
        throw Exception('A resposta da API é incompatível.');
      }
    } on FormatException {
      throw Exception('A resposta da API é incompatível.');
    }
  }
}
