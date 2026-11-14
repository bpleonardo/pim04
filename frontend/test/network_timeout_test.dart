import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:barbearia_frontend/core/network/api_client.dart';

void main() {
  tearDown(() {
    ApiClient.connectionUnavailable = false;
  });
  test('Timeout é falha de conexão recuperável', () async {
    final client = MockClient(
        (_) async => throw TimeoutException('Servidor não respondeu'));
    final api = ApiClient(client: client);
    await expectLater(
        api.request('GET', '/api/servicos'),
        throwsA(isA<ApiException>()
            .having((e) => e.retryable, 'retryable', isTrue)));
    expect(ApiClient.connectionUnavailable, isTrue);
    client.close();
  });
  for (final status in [408, 504]) {
    test('HTTP $status também permite cache e reenvio', () async {
      final client = MockClient((_) async => http.Response('{}', status));
      final api = ApiClient(client: client);
      await expectLater(
          api.request('GET', '/api/servicos'),
          throwsA(isA<ApiException>()
              .having((e) => e.retryable, 'retryable', isTrue)));
      expect(ApiClient.connectionUnavailable, isTrue);
      client.close();
    });
  }
}
