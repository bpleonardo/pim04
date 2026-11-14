import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barbearia_frontend/core/network/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final values = <String, String>{};
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      final args = Map<String, dynamic>.from(call.arguments as Map);
      final key = args['key'] as String;
      switch (call.method) {
        case 'write':
          values[key] = args['value'] as String;
          return null;
        case 'read':
          return values[key];
        case 'delete':
          values.remove(key);
          return null;
      }
      return null;
    });
  });
  tearDown(() async {
    await ApiClient.signOut();
    values.clear();
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  test('Restaura sessão do armazenamento seguro sem internet e remove ao sair',
      () async {
    await ApiClient.startSession({
      'access_token': 'expired-access',
      'refresh_token': 'refresh',
      'user': {'id': 'ana', 'nome': 'Ana', 'login': 'ana'}
    });
    expect(values.length, 1);
    expect(jsonDecode(values.values.single)['refresh_token'], 'refresh');
    ApiClient.user = null;
    ApiClient.token = null;
    await ApiClient.restoreSession();
    expect(ApiClient.user!.id, 'ana');
    expect(ApiClient.token, 'expired-access');
    await ApiClient.signOut();
    expect(values, isEmpty);
    expect(ApiClient.user, isNull);
  });
}
