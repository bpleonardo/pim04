import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:barbearia_frontend/core/network/api_client.dart';
import 'package:barbearia_frontend/core/network/barbershop_api.dart';
import 'package:barbearia_frontend/features/appointments/data/appointment_repository.dart';
import 'package:barbearia_frontend/features/dashboard/presentation/dashboard_screen.dart';

void main() {
  testWidgets(
      'Cada seletor e atualização envia apenas uma requisição de relatório',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final requests = <Uri>[];
    final client = MockClient((request) async {
      requests.add(request.url);
      final date = request.url.queryParameters['date']!;
      return http.Response(
          jsonEncode({
            'data': {
              'startDate': date,
              'endDate': date,
              'summary': {
                'completedRevenue': 70,
                'completedCount': 2,
                'pendingRevenue': 30,
                'activeCount': 3,
                'serviceCounts': {'Cabelo': 2}
              },
              'revenueByDay': [
                {'date': date, 'revenue': 70}
              ],
            }
          }),
          200);
    });
    addTearDown(client.close);
    final repository = AppointmentRepository(
        api: BarbershopApi(client: ApiClient(client: client)));
    await tester
        .pumpWidget(MaterialApp(home: DashboardScreen(repository: repository)));
    await tester.pumpAndSettle();
    expect(requests.length, 1);
    expect(requests.last.path, '/api/reports');
    expect(requests.last.queryParameters['period'], 'daily');
    for (final choice in [('Esta semana', 'weekly'), ('Este mês', 'monthly')]) {
      final before = requests.length;
      await tester.tap(find.text(choice.$1));
      await tester.pumpAndSettle();
      expect(requests.length, before + 1);
      expect(requests.last.queryParameters['period'], choice.$2);
    }
    await tester.tap(find.byTooltip('Atualizar dashboard'));
    await tester.pumpAndSettle();
    expect(requests.length, 4);
    expect(find.text('R\$ 100,00'), findsOneWidget);
    expect(find.text('R\$ 35,00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}
