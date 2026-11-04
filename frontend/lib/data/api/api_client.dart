import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const baseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://localhost:8080');
  static String? token;
  final http.Client _client = http.Client();
  Future<dynamic> request(String method, String path, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token'
    };
    late http.Response response;
    try {
      switch (method) {
        case 'POST':
          response = await _client
              .post(uri, headers: headers, body: jsonEncode(body))
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
      throw Exception('Falha de conexão: $e');
    }
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded is Map
          ? (decoded['error'] ??
              decoded['title'] ??
              'Erro HTTP ${response.statusCode}')
          : response.reasonPhrase;
      throw Exception('$error');
    }
    if (decoded is Map && decoded['success'] == false)
      throw Exception('${decoded['error'] ?? 'Erro da API'}');
    return decoded is Map && decoded.containsKey('data')
        ? decoded['data']
        : decoded;
  }
}
