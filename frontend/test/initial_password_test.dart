import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barbearia_frontend/app/routes/app_router.dart';
import 'package:barbearia_frontend/core/network/api_client.dart';
import 'package:barbearia_frontend/core/network/barbershop_api.dart';
import 'package:barbearia_frontend/features/auth/presentation/login_page.dart';

class FirstLoginApi extends BarbershopApi {
  bool changed = false;
  bool invalidCredentials = false;
  int changes = 0;
  @override
  Future<Map<String, dynamic>> login(String login, String password) async {
    if (invalidCredentials) {
      throw const ApiException(
          'Login ou senha inválidos.', 401, 'INVALID_CREDENTIALS');
    }
    if (!changed) {
      throw const ApiException(
          'Defina uma nova senha.', 403, 'PASSWORD_CHANGE_REQUIRED');
    }
    expect(login, 'novo.profissional');
    expect(password, 'nova senha');
    return {
      'access_token': 'test-access',
      'refresh_token': 'test-refresh',
      'user': {'id': 'test-employee', 'nome': 'Teste', 'login': login},
    };
  }

  @override
  Future<void> setInitialPassword(
      String login, String password, String newPassword) async {
    expect(login, 'novo.profissional');
    expect(password, 'senha inicial');
    expect(newPassword, 'nova senha');
    expect(ApiClient.token, isNull);
    changed = true;
    changes++;
  }
}

void main() {
  tearDown(() => ApiClient.signOut());
  testWidgets('Primeiro acesso exige nova senha antes de iniciar sessão',
      (tester) async {
    final api = FirstLoginApi();
    await tester.pumpWidget(MaterialApp(home: LoginPage(api: api), routes: {
      AppRouter.home: (_) => const Scaffold(body: Text('Agenda autenticada')),
    }));
    await tester.enterText(
        find.byType(TextFormField).at(0), 'novo.profissional');
    await tester.enterText(find.byType(TextFormField).at(1), 'senha inicial');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(ApiClient.token, isNull);
    expect(find.text('Defina sua senha'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(2), 'nova senha');
    await tester.enterText(find.byType(TextFormField).at(3), 'diferente');
    await tester.ensureVisible(find.text('Definir senha'));
    await tester.tap(find.text('Definir senha'));
    await tester.pumpAndSettle();
    expect(find.text('As senhas não conferem'), findsOneWidget);
    expect(api.changes, 0);
    await tester.enterText(find.byType(TextFormField).at(3), 'nova senha');
    await tester.ensureVisible(find.text('Definir senha'));
    await tester.tap(find.text('Definir senha'));
    await tester.pumpAndSettle();
    expect(api.changes, 1);
    expect(ApiClient.token, 'test-access');
    expect(find.text('Agenda autenticada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('Credencial inválida não libera troca de senha', (tester) async {
    final api = FirstLoginApi()..invalidCredentials = true;
    await tester.pumpWidget(MaterialApp(home: LoginPage(api: api)));
    await tester.enterText(
        find.byType(TextFormField).at(0), 'novo.profissional');
    await tester.enterText(find.byType(TextFormField).at(1), 'senha errada');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Login ou senha inválidos.'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(ApiClient.token, isNull);
    expect(api.changes, 0);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}
