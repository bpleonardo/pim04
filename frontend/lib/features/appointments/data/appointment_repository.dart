import 'dart:convert';

import 'package:barbearia_frontend/core/network/api_client.dart';
import 'package:barbearia_frontend/core/network/barbershop_api.dart';
import 'package:barbearia_frontend/core/storage/app_database.dart';
import 'package:barbearia_frontend/features/appointments/models/appointment.dart';
import 'package:sqflite/sqflite.dart';

enum CompletionState { pending, sent, rejected }

class DailyAgenda {
  const DailyAgenda(this.appointments,
      {this.completions = const {}, this.offline = false});

  final List<Appointment> appointments;
  final Map<String, CompletionState> completions;
  final bool offline;
}

class AppointmentRepository {
  final BarbershopApi api = BarbershopApi();

  Future<List<Appointment>> list({DateTime? date}) => api.appointments(
        date: date?.toIso8601String().split('T').first,
      );

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
      final rows = await _completions(db, session.scope);
      for (final entry in rows.entries) {
        if (entry.value == CompletionState.pending) {
          final result = await _send(db, session, entry.key);
          if (result == CompletionState.pending) break;
        }
      }
      appointments = await api.appointments(
        date: day,
        mine: true,
        bearerToken: session.token,
      );
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
      if (cached.isEmpty) rethrow;
      final items = jsonDecode(cached.single['json'] as String) as List;
      appointments = items
          .map((item) => Appointment.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
      offline = true;
    }
    return DailyAgenda(
      appointments,
      completions: await _completions(db, session.scope),
      offline: offline,
    );
  }

  Future<CompletionState> complete(String id) async {
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
