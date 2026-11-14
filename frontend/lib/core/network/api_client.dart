import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:barbearia_frontend/core/responsive/app_platform.dart';
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
  static bool connectionUnavailable = false;
  static Future<bool> probeConnection() async {
    final client = http.Client();
    try {
      final response = await client
          .get(Uri.parse('$baseUrl/api/ping'))
          .timeout(const Duration(seconds: 3));
      connectionUnavailable =
          response.statusCode >= 500 || response.statusCode == 408;
    } catch (_) {
      connectionUnavailable = true;
    } finally {
      client.close();
    }
    return !connectionUnavailable;
  }

  static String? token;
  static User? user;
  static String? _refreshToken;
  static Future<void>? _refreshing;
  static int _session = 0;
  static bool _signingOut = false;

  static const _storage = FlutterSecureStorage();
  static bool _storedSession = false;
  static String get _storageKey => 'barbershop_session:$baseUrl';

  static Future<void> persistSession() async {
    if (!AppPlatform.mobile || token == null || user == null) return;
    await _storage.write(
        key: _storageKey,
        value: jsonEncode({
          'access_token': token,
          'refresh_token': _refreshToken,
          'user': {'id': user!.id, 'nome': user!.name, 'login': user!.login},
        }));
    _storedSession = true;
  }

  static Future<void> restoreSession() async {
    if (!AppPlatform.mobile) return;
    final value = await _storage.read(key: _storageKey);
    if (value == null) return;
    try {
      final data = Map<String, dynamic>.from(jsonDecode(value));
      _setSession(data);
      _storedSession = true;
      connectionUnavailable = true;
    } on FormatException {
      await _storage.delete(key: _storageKey);
    }
  }

  static Future<void> startSession(Map<String, dynamic> response) async {
    _setSession(response);
    connectionUnavailable = false;
    try {
      await persistSession();
    } catch (_) {
      await signOut();
      rethrow;
    }
  }

  static void _setSession(Map<String, dynamic> response) {
    _session++;
    _refreshing = null;
    token = response['access_token'] as String;
    _refreshToken = response['refresh_token'] as String;
    user = User.fromJson(Map<String, dynamic>.from(response['user'] as Map));
  }

  static Future<void> logout() async {
    if (_signingOut) return;
    _signingOut = true;
    final session = _session;
    try {
      try {
        await _refreshing;
      } on ApiException {
        // Tenta revogar a credencial disponível mesmo após falha de renovação.
      }
      if (session != _session) return;
      final refresh = _refreshToken;
      if (refresh != null) {
        try {
          await ApiClient().request('POST', '/api/login/logout',
              body: {'refresh_token': refresh});
        } on ApiException catch (error) {
          if (error.statusCode != 401 && !error.retryable) rethrow;
        }
      }
      if (session == _session) await signOut();
    } finally {
      _signingOut = false;
    }
  }

  static Future<void> signOut() async {
    _session++;
    _refreshToken = null;
    _refreshing = null;
    token = null;
    user = null;
    if (_storedSession) {
      await _storage.delete(key: _storageKey);
      _storedSession = false;
    }
  }

  static final _random = Random.secure();

  static String newNonce() => List.generate(16, (_) => _random.nextInt(256))
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();

  Future<void> _renew(int session) async {
    final refresh = _refreshToken;
    if (refresh == null) {
      throw const ApiException('Sessão expirada. Entre novamente.', 401);
    }
    try {
      final data = await request('POST', '/api/login/refresh',
          body: {'refresh_token': refresh}) as Map;
      if (session != _session) return;
      token = data['access_token'] as String;
      _refreshToken = data['refresh_token'] as String;
      await persistSession();
    } on ApiException catch (error) {
      if (error.statusCode == 401 && session == _session) await signOut();
      rethrow;
    }
  }

  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  Future<dynamic> request(String method, String path,
          {Object? body, String? bearerToken, String? nonce}) =>
      _request(method, path,
          body: body, bearerToken: bearerToken, nonce: nonce);

  Future<dynamic> _request(String method, String path,
      {Object? body,
      String? bearerToken,
      String? nonce,
      bool retry = true}) async {
    final uri = Uri.parse('$baseUrl$path');
    final session = _session;
    final authRoute = path.toLowerCase().startsWith('/api/login');
    final authorization = authRoute ? null : bearerToken ?? token;
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (!authRoute &&
          const {'POST', 'PUT', 'PATCH', 'DELETE'}.contains(method))
        'Nonce': nonce ?? newNonce(),
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
      connectionUnavailable = true;
      throw ApiException('Falha de conexão: $e');
    }
    connectionUnavailable =
        response.statusCode == 408 || response.statusCode >= 500;
    if (retry &&
        authorization != null &&
        response.statusCode == 401 &&
        response.headers['access-token-expired'] == 'true' &&
        session == _session &&
        !_signingOut) {
      if (token == authorization) {
        final pending = _refreshing ??= _renew(session);
        try {
          await pending;
        } finally {
          if (identical(_refreshing, pending)) _refreshing = null;
        }
      }
      if (session != _session || token == null || _signingOut) {
        throw const ApiException('Sessão expirada. Entre novamente.', 401);
      }
      return _request(method, path,
          body: body,
          bearerToken: token,
          nonce: headers['Nonce'],
          retry: false);
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
