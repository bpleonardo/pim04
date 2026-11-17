import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barbearia_frontend/app/layout/desktop_layout.dart';
import 'package:barbearia_frontend/app/routes/app_router.dart';
import 'package:barbearia_frontend/core/config/api_config.dart';
import 'package:barbearia_frontend/features/appointments/data/appointment_repository.dart';
import 'package:barbearia_frontend/features/appointments/models/appointment.dart';
import 'package:barbearia_frontend/features/appointments/presentation/agenda_screen.dart';
import 'package:barbearia_frontend/features/catalog/presentation/catalogo_screen.dart';
import 'package:barbearia_frontend/features/employees/presentation/employees_screen.dart';
import 'package:barbearia_frontend/features/availability/presentation/availability_screen.dart';
import 'package:barbearia_frontend/features/dashboard/presentation/dashboard_screen.dart';
import 'package:barbearia_frontend/features/settings/presentation/api_settings_screen.dart';

class EmptyAgenda extends AppointmentRepository {
  @override
  Future<List<Appointment>> list({DateTime? date}) async => [];
}

void main() {
  test(
      'Web e desktop mapeiam todas as funções administrativas para as mesmas telas',
      () {
    expect(AppRouter.desktopPage(AppRouter.home), isA<AgendaScreen>());
    expect(AppRouter.desktopPage(AppRouter.catalog), isA<CatalogoScreen>());
    expect(AppRouter.desktopPage(AppRouter.employees), isA<EmployeesScreen>());
    expect(AppRouter.desktopPage(AppRouter.availability),
        isA<AvailabilityScreen>());
    expect(AppRouter.desktopPage(AppRouter.dashboard), isA<DashboardScreen>());
  });

  testWidgets(
      'Menu lateral mantém todas as funções, com URL editável somente no desktop',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: DesktopLayout(
            initialRoute: AppRouter.home, initialContent: SizedBox.shrink())));
    await tester.pumpAndSettle();
    for (final entry in AppRouter.adminDestinations) {
      expect(find.text(entry.$2), findsOneWidget);
    }
    expect(find.text('Configurações'), kIsWeb ? findsNothing : findsOneWidget);
    expect(find.text('Sair'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Menu compacto dá acesso às mesmas funções e fecha ao navegar',
      (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
        MaterialApp(home: AgendaScreen(repository: EmptyAgenda()), routes: {
      for (final entry in AppRouter.adminDestinations.skip(1))
        entry.$1: (_) =>
            Scaffold(appBar: AppBar(title: Text('Tela: ${entry.$2}'))),
      AppRouter.settingsRoute: (_) => const Scaffold(body: Text('URL da API')),
    }));
    await tester.pumpAndSettle();
    for (final entry in AppRouter.adminDestinations.skip(1)) {
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      for (final destination in AppRouter.adminDestinations) {
        expect(find.text(destination.$2), findsWidgets);
      }
      expect(
          find.text('Configurações'), kIsWeb ? findsNothing : findsOneWidget);
      await tester.tap(find.text(entry.$2));
      await tester.pumpAndSettle();
      expect(find.text('Tela: ${entry.$2}'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('N&E'), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Configuração da API permanece fixa no navegador, inclusive por acesso direto',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ApiSettingsScreen()));
    await tester.pumpAndSettle();
    if (kIsWeb) {
      final previous = ApiConfig.baseUrl;
      expect(find.text('A URL da API é fixa na versão Web.'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.text('Salvar'), findsNothing);
      await expectLater(
          ApiConfig.save('https://other.invalid'), throwsUnsupportedError);
      expect(ApiConfig.baseUrl, previous);
    } else {
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Salvar'), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
