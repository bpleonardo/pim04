import 'dart:convert';
import 'package:barbearia_frontend/features/appointments/data/offline_booking_repository.dart';

import 'package:barbearia_frontend/core/network/api_client.dart';
import 'package:barbearia_frontend/core/network/barbershop_api.dart';
import 'package:barbearia_frontend/core/storage/app_database.dart';
import 'package:barbearia_frontend/features/appointments/models/appointment.dart';
import 'package:sqflite/sqflite.dart';

enum CompletionState { pending, sent, rejected }

class DailyAgenda {
  const DailyAgenda(this.appointments,
      {this.completions = const {},
      this.offline = false,
      this.pending = const []});

  final List<Appointment> appointments;
  final Map<String, CompletionState> completions;
  final bool offline;
  final List<PendingAppointment> pending;
}

class AppointmentRepository {
  final BarbershopApi api = BarbershopApi();
  final OfflineBookingRepository bookings = OfflineBookingRepository();
  bool offline = false;
  List<Appointment> _lastAppointments = [];

  Future<List<Appointment>> list({DateTime? date}) async {
    final day = date?.toIso8601String().split('T').first;
    if (!AppDatabase.available) return api.appointments(date: day);
    final store = bookings.store;
    final key = 'report:$day';
    try {
      if (ApiClient.connectionUnavailable) {
        throw const ApiException('Sem conexão');
      }
      final rows = await api.appointments(date: day, mine: true);
      offline = false;
      await store.write(key, rows.map((a) => a.toJson()).toList());
      return rows;
    } on ApiException catch (error) {
      if (!error.retryable) rethrow;
      offline = true;
      final cached = await store.read(key) as List?;
      if (cached == null) rethrow;
      return cached
          .map((a) => Appointment.fromJson(Map<String, dynamic>.from(a)))
          .toList();
    }
  }

  Future<void> changeStatus(Appointment appointment, String status) async {
    final preview = Appointment.fromJson(appointment.toJson()
      ..['status'] = status
      ..['revision'] = appointment.revision + 1);
    await bookings.enqueue('status', preview,
        {'status': status, 'expectedRevision': appointment.revision});
  }

  Future<void> updateStatus(String id, String status) =>
      api.updateStatus(id, status);

  ({String scope, String token}) _session() {
    final employee = ApiClient.user;
    final token = ApiClient.token;
    if (employee == null || token == null) {
      throw const ApiException('Entre novamente para acessar sua agenda.', 401);
    }
    return (scope: jsonEncode([ApiClient.baseUrl, employee.id]), token: token);
  }

  Future<DailyAgenda> loadDay(DateTime date) async {
    final session = _session();
    final day = date.toIso8601String().split('T').first;
    final db = await AppDatabase.instance;
    List<Appointment> appointments;
    var offline = false;
    try {
      if (ApiClient.connectionUnavailable) {
        throw const ApiException('Sem conexão');
      }
      await bookings.sync();
      if (ApiClient.connectionUnavailable) {
        throw const ApiException('Sem conexão');
      }
      final rows = await _completions(db, session.scope);
      for (final entry in rows.entries) {
        if (entry.value == CompletionState.pending) {
          final result = await _send(db, session, entry.key);
          if (result == CompletionState.pending) break;
        }
      }
      if (ApiClient.connectionUnavailable) {
        throw const ApiException('Sem conexão');
      }
      appointments = await api.appointments(
        date: day,
        mine: true,
        bearerToken: session.token,
      );
      await bookings.acknowledgeDay(date);
      await bookings.store
          .write('report:$day', appointments.map((a) => a.toJson()).toList());
      await bookings.warmUp(date);
      await db.transaction((transaction) async {
        await transaction.insert(
            'daily_agenda',
            {
              'scope': session.scope,
              'day': day,
              'json': jsonEncode(
                  appointments.map((item) => item.toJson()).toList()),
            },
            conflictAlgorithm: ConflictAlgorithm.replace);
        await transaction.delete(
          'pending_completions',
          where: 'scope = ? AND state = ?',
          whereArgs: [session.scope, CompletionState.sent.name],
        );
      });
    } on ApiException catch (error) {
      if (!error.retryable) rethrow;
      final cached = await db.query(
        'daily_agenda',
        where: 'scope = ? AND day = ?',
        whereArgs: [session.scope, day],
      );
      if (cached.isEmpty &&
          (await bookings.pending()).isEmpty &&
          (await bookings.overlay([], date)).isEmpty) {
        rethrow;
      }
      final items = cached.isEmpty
          ? []
          : jsonDecode(cached.single['json'] as String) as List;
      appointments = items
          .map((item) => Appointment.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
      offline = true;
    }
    _lastAppointments = await bookings.overlay(appointments, date);
    return DailyAgenda(
      _lastAppointments,
      pending: await bookings.pending(),
      completions: await _completions(db, session.scope),
      offline: offline,
    );
  }

  Future<CompletionState> complete(String id) async {
    final found = _lastAppointments.where((a) => a.id == id);
    if (found.isNotEmpty) {
      await changeStatus(found.first, 'concluido');
      final pending = (await bookings.pending()).where((p) => p.entityId == id);
      if (pending.any((p) => p.rejected)) return CompletionState.rejected;
      return pending.isEmpty ? CompletionState.sent : CompletionState.pending;
    }
    final session = _session();
    final db = await AppDatabase.instance;
    await db.insert(
        'pending_completions',
        {
          'scope': session.scope,
          'appointment_id': id,
          'state': CompletionState.pending.name,
          'nonce': ApiClient.newNonce(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore);
    return _send(db, session, id);
  }

  Future<Map<String, CompletionState>> _completions(
      Database db, String scope) async {
    final rows = await db.query(
      'pending_completions',
      where: 'scope = ?',
      whereArgs: [scope],
    );
    return {
      for (final row in rows)
        row['appointment_id'] as String:
            CompletionState.values.byName(row['state'] as String),
    };
  }

  Future<CompletionState> _send(
    Database db,
    ({String scope, String token}) session,
    String id,
  ) async {
    final rows = await db.query(
      'pending_completions',
      where: 'scope = ? AND appointment_id = ?',
      whereArgs: [session.scope, id],
    );
    if (rows.isEmpty) return CompletionState.sent;
    final row = rows.single;
    final current = CompletionState.values.byName(row['state'] as String);
    if (current != CompletionState.pending) return current;
    final nonce = row['nonce'] as String;
    var state = CompletionState.sent;
    try {
      await api.updateStatus(id, 'concluido',
          bearerToken: session.token, nonce: nonce);
    } on ApiException catch (error) {
      if (error.retryable) return CompletionState.pending;
      if (error.statusCode == 401) rethrow;
      state = CompletionState.rejected;
    }
    await db.update(
      'pending_completions',
      {'state': state.name},
      where: 'scope = ? AND appointment_id = ?',
      whereArgs: [session.scope, id],
    );
    return state;
  }
}
