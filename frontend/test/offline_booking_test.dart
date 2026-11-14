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
  @override
  Future<List<Service>> services() async {
    if (failure != null) throw failure!;
    return const [Service(id: 'hair', name: 'Cabelo', price: 35)];
  }

  @override
  Future<List<Map<String, dynamic>>> timeSlots(DateTime date) async {
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
}
