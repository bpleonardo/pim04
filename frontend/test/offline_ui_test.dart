import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barbearia_frontend/core/network/api_client.dart';
import 'package:barbearia_frontend/core/shop_time.dart';
import 'package:barbearia_frontend/features/auth/models/user.dart';
import 'package:barbearia_frontend/features/appointments/models/appointment.dart';
import 'package:barbearia_frontend/features/appointments/data/offline_booking_repository.dart';
import 'package:barbearia_frontend/features/appointments/presentation/agendamento_screen.dart';
import 'package:barbearia_frontend/features/catalog/data/service_repository.dart';
import 'package:barbearia_frontend/features/catalog/models/service.dart';
import 'package:barbearia_frontend/features/catalog/presentation/catalogo_screen.dart';

const cachedServices = [
  Service(id: 'hair', name: 'Cabelo', price: 35),
  Service(id: 'hydration', name: 'Hidratação', price: 20)
];

class OfflineFormRepository extends OfflineBookingRepository {
  OfflineFormRepository() {
    offline = true;
  }
  String? kind;
  Map<String, dynamic>? payload;
  Appointment? saved;
  @override
  Future<List<Service>> services() async => cachedServices;
  @override
  Future<List<Map<String, dynamic>>> slots(DateTime date) async => [
        {'slot': '10:00', 'available': true}
      ];
  @override
  Future<void> enqueue(
      String kind, Appointment preview, Map<String, dynamic> payload,
      {String? replacingConflict}) async {
    this.kind = kind;
    this.payload = payload;
    saved = preview;
  }

  @override
  Future<List<PendingAppointment>> pending() async => saved == null
      ? []
      : [
          PendingAppointment({
            'sequence': 1,
            'entity_id': saved!.id,
            'kind': kind,
            'state': 'pending',
            'error': null,
            'preview': encodePreview(saved!),
          })
        ];
}

String encodePreview(Appointment a) => jsonEncode(a.toJson());

class ReadOnlyServices extends ServiceRepository {
  ReadOnlyServices() {
    offline = true;
  }
  @override
  Future<List<Service>> list() async => cachedServices;
}

void main() {
  setUp(() {
    ApiClient.user = const User(id: 'ana', name: 'Ana', login: 'ana');
    ApiClient.token = 'test';
    ApiClient.connectionUnavailable = true;
  });
  tearDown(() async {
    await ApiClient.signOut();
    ApiClient.connectionUnavailable = false;
  });

  testWidgets(
      'Edita dados offline preservando serviços, horário e revisão da base',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final today = shopTime(DateTime.now());
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final existing = Appointment(
        id: 'remote',
        scheduledAt: shopSlotToUtc(tomorrow, 10, 0).toIso8601String(),
        status: 'agendado',
        clientName: 'Maria Silva',
        phone: '5511999999999',
        employeeName: 'Ana',
        employeeId: 'ana',
        total: 55,
        revision: 4,
        services: const ['Cabelo', 'Hidratação'],
        serviceIds: const ['hair', 'hydration']);
    final repo = OfflineFormRepository();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => AgendamentoScreen(
                                forCurrentEmployee: true,
                                appointment: existing,
                                offlineRepository: repo))),
                    child: const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sem conexão. Serviços salvos'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Maria Oliveira');
    await tester.tap(find.text('Confirmar agendamento'));
    await tester.pumpAndSettle();
    expect(repo.kind, 'edit');
    expect(repo.payload!['expectedRevision'], 4);
    expect(repo.payload!['booking']['idServicos'], ['hair', 'hydration']);
    expect(repo.saved!.clientName, 'Maria Oliveira');
    expect(repo.saved!.revision, 5);
    expect(repo.saved!.scheduledAt, existing.scheduledAt);
    expect(find.textContaining('Salvo no aparelho.'), findsOneWidget);
  });

  testWidgets('Catálogo offline mantém consulta e desabilita todas as mutações',
      (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: CatalogoScreen(repository: ReadOnlyServices())));
    await tester.pumpAndSettle();
    expect(find.text('Cabelo'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(
                find.byWidgetPredicate((widget) => widget is FilledButton))
            .onPressed,
        isNull);
    expect(
        tester
            .widget<IconButton>(find.byWidgetPredicate((widget) =>
                widget is IconButton && widget.tooltip == 'Editar Cabelo'))
            .onPressed,
        isNull);
    expect(
        tester
            .widget<IconButton>(find.byWidgetPredicate((widget) =>
                widget is IconButton && widget.tooltip == 'Excluir Cabelo'))
            .onPressed,
        isNull);
    for (final element in find
        .byWidgetPredicate((widget) =>
            widget is IconButton && widget.tooltip == 'Desabilitar serviço')
        .evaluate()) {
      expect((element.widget as IconButton).onPressed, isNull);
    }
  });
}
