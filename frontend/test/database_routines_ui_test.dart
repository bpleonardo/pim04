import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barbearia_frontend/core/network/api_client.dart';
import 'package:barbearia_frontend/features/appointments/data/appointment_repository.dart';
import 'package:barbearia_frontend/features/appointments/models/appointment.dart';
import 'package:barbearia_frontend/features/dashboard/models/daily_report.dart';
import 'package:barbearia_frontend/features/dashboard/presentation/dashboard_screen.dart';
import 'package:barbearia_frontend/features/catalog/data/service_repository.dart';
import 'package:barbearia_frontend/features/catalog/models/service.dart';
import 'package:barbearia_frontend/features/catalog/models/service_price_change.dart';
import 'package:barbearia_frontend/features/catalog/presentation/catalogo_screen.dart';

class Reports extends AppointmentRepository {
  int calls = 0;
  bool cached = false;
  @override
  Future<DailyReport> dailyReport(DateTime date) async {
    calls++;
    return DailyReport(
        completedRevenue: 70,
        completedCount: 2,
        pendingRevenue: 30,
        activeCount: 3,
        serviceCounts: {'Cabelo': 2, 'Barba (desabilitado)': 2},
        cached: cached);
  }
}

class Services extends ServiceRepository {
  @override
  Future<List<Service>> list() async =>
      const [Service(id: 'hair', name: 'Cabelo', price: 45)];
  @override
  Future<List<ServicePriceChange>> priceHistory(String id) async => [
        ServicePriceChange(
            oldPrice: 35,
            newPrice: 45,
            changedAt: DateTime.utc(2026, 11, 15, 15, 30))
      ];
}

void main() {
  setUp(() {
    ApiClient.connectionUnavailable = false;
  });
  test(
      'Resumo legado offline conserva valores, cancelamentos e serviços desabilitados',
      () {
    Appointment appointment(
            String status, double total, List<String> services) =>
        Appointment(
            id: status,
            scheduledAt: '2026-11-15T12:00:00Z',
            status: status,
            clientName: 'Cliente',
            employeeName: 'Barbeiro',
            total: total,
            services: services);
    final report = DailyReport.fromAppointments([
      appointment(
          'concluido', 50, ['Cabelo', 'Barba (desabilitado)', 'Cabelo']),
      appointment('agendado', 30, ['Cabelo']),
      appointment('cancelado', 999, ['Cabelo'])
    ]);
    expect(report.completedRevenue, 50);
    expect(report.completedCount, 1);
    expect(report.pendingRevenue, 30);
    expect(report.activeCount, 2);
    expect(report.serviceCounts, {'Cabelo': 2, 'Barba (desabilitado)': 1});
    expect(report.cached, isTrue);
    final restored = DailyReport.fromJson(report.toJson(), cached: true);
    expect(restored.toJson(), report.toJson());
  });

  testWidgets('Dashboard usa o resumo diário e recarrega sem erro de setState',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final reports = Reports()..cached = true;
    await tester
        .pumpWidget(MaterialApp(home: DashboardScreen(repository: reports)));
    await tester.pumpAndSettle();
    expect(find.text('R\$ 100,00'), findsOneWidget);
    expect(find.text('R\$ 70,00'), findsOneWidget);
    expect(find.text('R\$ 35,00'), findsOneWidget);
    expect(find.text('2 concluídos'), findsOneWidget);
    expect(find.text('Barba (desabilitado)'), findsOneWidget);
    expect(find.textContaining('Sem conexão. Indicadores'), findsOneWidget);
    await tester.tap(find.byTooltip('Atualizar dashboard'));
    await tester.pumpAndSettle();
    expect(reports.calls, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Catálogo desktop abre histórico de preços com horário de São Paulo',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await tester
        .pumpWidget(MaterialApp(home: CatalogoScreen(repository: Services())));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Histórico de preços de Cabelo'));
    await tester.pumpAndSettle();
    expect(find.text('Histórico de preços · Cabelo'), findsOneWidget);
    expect(find.text('R\$ 35,00 → R\$ 45,00'), findsOneWidget);
    expect(find.textContaining('12:30'), findsOneWidget);
    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
