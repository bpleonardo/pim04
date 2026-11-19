import 'package:flutter/foundation.dart';
import 'package:barbearia_frontend/features/appointments/data/appointment_repository.dart';
import 'package:barbearia_frontend/features/dashboard/models/period_report.dart';
import 'package:barbearia_frontend/features/dashboard/models/daily_report.dart';
import 'package:barbearia_frontend/core/shop_time.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:barbearia_frontend/core/network/api_client.dart';
import 'package:barbearia_frontend/core/network/barbershop_api.dart';
import 'package:barbearia_frontend/core/storage/app_database.dart';
import 'package:barbearia_frontend/core/storage/offline_store.dart';
import 'package:barbearia_frontend/features/appointments/data/offline_booking_repository.dart';
import 'package:barbearia_frontend/features/appointments/models/appointment.dart';
import 'package:barbearia_frontend/features/auth/models/user.dart';
import 'package:barbearia_frontend/features/catalog/models/service.dart';

class SyncApi extends BarbershopApi {
  ApiException? failure = const ApiException('Timeout do servidor', 408);
  bool loseCreateResponse = false;
  final requests = <String, Map<String, dynamic>>{};
  final nonces = <String>[];
  int mutations = 0;
  final slotDates = <DateTime>[];
  @override
  Future<List<Service>> services() async {
    if (failure != null) throw failure!;
    return const [Service(id: 'hair', name: 'Cabelo', price: 35)];
  }

  @override
  Future<List<Map<String, dynamic>>> timeSlots(DateTime date) async {
    slotDates.add(date);
    if (failure != null) throw failure!;
    return [
      {'slot': '10:00', 'available': false},
      {'slot': '11:00', 'available': true}
    ];
  }

  @override
  Future<Map<String, dynamic>> createBooking(
      Map<String, dynamic> payload, String nonce) async {
    nonces.add(nonce);
    if (failure != null) throw failure!;
    final response =
        requests.putIfAbsent(payload['clientRequestId'] as String, () {
      mutations++;
      return {'id': 'server-id', 'revision': 0};
    });
    if (loseCreateResponse) {
      loseCreateResponse = false;
      throw const ApiException('Resposta perdida');
    }
    return response;
  }

  @override
  Future<Map<String, dynamic>> editAppointment(
      String id, Map<String, dynamic> payload,
      {String? nonce}) async {
    if (failure != null) throw failure!;
    expect(id, 'server-id');
    expect(payload['expectedRevision'], 0);
    mutations++;
    return {'id': id, 'revision': 1};
  }

  @override
  Future<Map<String, dynamic>> setAppointmentStatus(
      String id, Map<String, dynamic> payload,
      {String? nonce}) async {
    if (failure != null) throw failure!;
    expect(id, 'server-id');
    expect(payload['expectedRevision'], 1);
    mutations++;
    return {'id': id, 'revision': 2, 'status': payload['status']};
  }
}

class PeriodApi extends SyncApi {
  int reportCalls = 0;
  @override
  Future<PeriodReport> periodReport(DateTime date, String period,
      {bool mine = false}) async {
    reportCalls++;
    expect(mine, isTrue);
    return PeriodReport(
        startDate: date,
        endDate: date,
        summary: const DailyReport(
            completedRevenue: 50,
            completedCount: 1,
            pendingRevenue: 30,
            activeCount: 2,
            serviceCounts: {'Cabelo': 2}),
        revenueByDay: {date: 50});
  }
}

Appointment preview(
        {String name = 'Maria',
        int revision = 0,
        String status = 'agendado'}) =>
    Appointment(
        id: 'local:request',
        scheduledAt: '2099-11-14T14:00:00Z',
        status: status,
        clientName: name,
        phone: '5511999999999',
        employeeName: 'Ana',
        employeeId: 'ana',
        services: const ['Cabelo'],
        serviceIds: const ['hair'],
        total: 35,
        revision: revision);

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late Database db;
  late SyncApi api;
  late OfflineBookingRepository repo;
  setUp(() async {
    ApiClient.connectionUnavailable = false;
    ApiClient.user = const User(id: 'ana', name: 'Ana', login: 'ana');
    ApiClient.token = 'test-token';
    directory =
        await Directory.systemTemp.createTemp('barbershop-offline-test-');
    db = await databaseFactoryFfi.openDatabase('${directory.path}/test.db');
    await AppDatabase.createOfflineTables(db);
    api = SyncApi();
    repo = OfflineBookingRepository(
        api: api, store: OfflineStore(database: () async => db));
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
    await ApiClient.signOut();
  });

  test(
      'Persiste criação, edição e status e sincroniza em ordem após reabrir SQLite',
      () async {
    await repo.enqueue('create', preview(), {'clientRequestId': 'request'});
    await repo.enqueue('edit', preview(name: 'Maria Silva', revision: 1),
        {'expectedRevision': 0});
    await repo.enqueue(
        'status',
        preview(name: 'Maria Silva', revision: 2, status: 'concluido'),
        {'status': 'concluido', 'expectedRevision': 1});
    expect((await repo.pending()).length, 3);
    await db.close();
    db = await databaseFactoryFfi.openDatabase('${directory.path}/test.db');
    repo = OfflineBookingRepository(
        api: api, store: OfflineStore(database: () async => db));
    expect((await repo.pending()).last.appointment.clientName, 'Maria Silva');
    api.failure = null;
    await repo.sync();
    expect(await repo.pending(), isEmpty);
    expect(api.mutations, 3);
    final agenda = await repo.overlay([], DateTime(2099, 11, 14));
    expect(agenda.single.id, 'server-id');
    expect(agenda.single.status, 'concluido');
    await repo.sync();
    expect(api.mutations, 3);
  });

  test('Reenvia a mesma criação e nonce após resposta perdida sem duplicar',
      () async {
    api.failure = null;
    api.loseCreateResponse = true;
    await repo.enqueue('create', preview(), {'clientRequestId': 'request'});
    expect((await repo.pending()).length, 1);
    await repo.sync();
    expect(await repo.pending(), isEmpty);
    expect(api.mutations, 1);
    expect(api.nonces.toSet().length, 1);
  });

  test(
      'Conflito preserva dados locais, bloqueia dependências e permite descarte explícito',
      () async {
    api.failure = const ApiException('Horário ocupado', 409);
    await repo.enqueue('create', preview(), {'clientRequestId': 'request'});
    await repo.enqueue('edit', preview(name: 'Maria Silva', revision: 1),
        {'expectedRevision': 0});
    final pending = await repo.pending();
    expect(pending.first.rejected, isTrue);
    expect(pending.first.error, 'Horário ocupado');
    api.failure = null;
    await repo.sync();
    expect(api.mutations, 0);
    expect((await repo.overlay([], DateTime(2099, 11, 14))).single.clientName,
        'Maria Silva');
    await repo.discardConflict('local:request');
    expect(await repo.pending(), isEmpty);
  });

  test('Uma sessão expirada mantém a fila pendente', () async {
    api.failure = const ApiException('Sessão expirada', 401);
    await repo.enqueue('create', preview(), {'clientRequestId': 'request'});
    expect((await repo.pending()).single.rejected, isFalse);
  });

  test(
      'Cache offline usa serviços e grade conhecidos; usuário diferente não acessa a fila',
      () async {
    api.failure = null;
    await repo.services();
    await repo.slots(DateTime(2099, 11, 14));
    api.failure = const ApiException('Timeout', 504);
    expect((await repo.services()).single.name, 'Cabelo');
    expect(repo.offline, isTrue);
    expect((await repo.slots(DateTime(2099, 11, 15))).length, 2);
    await repo.enqueue('create', preview(), {'clientRequestId': 'request'});
    ApiClient.user = const User(id: 'bruno', name: 'Bruno', login: 'bruno');
    expect(await repo.pending(), isEmpty);
    await repo.sync();
    expect(api.mutations, 0);
    await expectLater(repo.services(), throwsA(isA<ApiException>()));
  });

  test('Sincronizações concorrentes não enviam a mesma operação em paralelo',
      () async {
    await repo.enqueue('create', preview(), {'clientRequestId': 'request'});
    api.failure = null;
    await Future.wait([repo.sync(), repo.sync(), repo.sync()]);
    expect(api.mutations, 1);
    expect(await repo.pending(), isEmpty);
  });

  test('Migração v5 para v6 mantém dados existentes', () async {
    await db.close();
    db = await databaseFactoryFfi.openDatabase('${directory.path}/legacy.db');
    await db.execute('CREATE TABLE daily_agenda (json TEXT)');
    await db.insert('daily_agenda', {'json': 'dados anteriores'});
    await AppDatabase.upgrade(db, 5, 6);
    expect((await db.query('daily_agenda')).single['json'], 'dados anteriores');
    expect(await db.query('pending_appointments'), isEmpty);
  });
  test(
      'Agenda passada prepara a grade de hoje sem consultar horários no passado',
      () async {
    api.failure = null;
    final now = shopTime(DateTime.now());
    final today = DateTime.utc(now.year, now.month, now.day);
    await repo.warmUp(today.subtract(const Duration(days: 3)));
    expect(api.slotDates, [today]);
    api.slotDates.clear();
    await repo.warmUp(today.add(const Duration(days: 30)));
    expect(api.slotDates, [today]);
    api.slotDates.clear();
    final tomorrow = today.add(const Duration(days: 1));
    await repo.warmUp(tomorrow);
    expect(api.slotDates, [tomorrow]);
  });
  test(
      'Relatórios mobile usam uma chamada e conservam cache de períodos e resumos legados',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final reportsApi = PeriodApi();
      final reports = AppointmentRepository(api: reportsApi, bookings: repo);
      final date = DateTime(2026, 11, 16);
      final online = await reports.periodReport(date, 'monthly');
      expect(online.summary.completedRevenue, 50);
      expect(reportsApi.reportCalls, 1);
      ApiClient.connectionUnavailable = true;
      final cached = await reports.periodReport(date, 'monthly');
      expect(cached.summary.completedRevenue, 50);
      expect(cached.summary.cached, isTrue);
      expect(reportsApi.reportCalls, 1);
      for (var day = 9; day <= 15; day++) {
        await repo.store.write(
            'daily_summary:2026-11-${day.toString().padLeft(2, '0')}',
            online.summary.toJson());
      }
      final legacy =
          await reports.periodReport(DateTime(2026, 11, 15), 'weekly');
      expect(legacy.summary.completedRevenue, 350);
      expect(legacy.summary.completedCount, 7);
      expect(legacy.summary.cached, isTrue);
      expect(legacy.revenueByDay.length, 7);
      expect(reportsApi.reportCalls, 1);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
