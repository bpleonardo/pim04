import 'dart:convert';
import 'package:barbearia_frontend/core/config/api_config.dart';
import 'package:barbearia_frontend/features/auth/models/user.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  bool get retryable {
    final code = statusCode;
    return code == null || code == 408 || code == 429 || code >= 500;
  }

  @override
  String toString() => message;
}

class ApiClient {
  static String get baseUrl => ApiConfig.baseUrl;
  static String? token;
  static User? user;
  static void signOut() {
    token = null;
    user = null;
  }

  final http.Client _client = http.Client();
  Future<dynamic> request(String method, String path,
      {Object? body, String? bearerToken}) async {
    final uri = Uri.parse('$baseUrl$path');
    final authorization = bearerToken ?? token;
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (authorization != null) 'Authorization': 'Bearer $authorization'
    };
    late http.Response response;
    try {
      switch (method) {
        case 'POST':
          response = await _client
              .post(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 15));
          break;
        case 'PUT':
          response = await _client
              .put(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 15));
          break;
        case 'DELETE':
          response = await _client
              .delete(uri, headers: headers)
              .timeout(const Duration(seconds: 15));
          break;
        case 'PATCH':
          response = await _client
              .patch(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 15));
          break;
        default:
          response = await _client
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 15));
      }
    } catch (e) {
      throw ApiException('Falha de conexão: $e');
    }
    Object? decoded;
    try {
      decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      throw ApiException('Resposta inválida da API.', response.statusCode);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded is Map
          ? (decoded['error'] ??
              decoded['title'] ??
              'Erro HTTP ${response.statusCode}')
          : response.reasonPhrase;
      throw ApiException(
          error is Map ? '${error['message'] ?? error}' : '$error',
          response.statusCode);
    }
    if (decoded is Map && decoded['success'] == false) {
      throw Exception('${decoded['error'] ?? 'Erro da API'}');
    }
    return decoded is Map && decoded.containsKey('data')
        ? decoded['data']
        : decoded;
  }
}
