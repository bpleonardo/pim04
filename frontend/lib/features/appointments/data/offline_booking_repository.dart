import 'dart:convert';
import 'package:barbearia_frontend/core/network/api_client.dart';
import 'package:barbearia_frontend/core/network/barbershop_api.dart';
import 'package:barbearia_frontend/core/storage/offline_store.dart';
import 'package:barbearia_frontend/core/shop_time.dart';
import 'package:barbearia_frontend/features/appointments/models/appointment.dart';
import 'package:barbearia_frontend/features/catalog/models/service.dart';
import 'package:sqflite/sqflite.dart';

class PendingAppointment {
  PendingAppointment(Map<String, Object?> row)
      : sequence = row['sequence'] as int,
        entityId = row['entity_id'] as String,
        kind = row['kind'] as String,
        rejected = row['state'] == 'rejected',
        error = row['error'] as String?,
        appointment = Appointment.fromJson(
            Map<String, dynamic>.from(jsonDecode(row['preview'] as String)));
  final int sequence;
  final String entityId;
  final String kind;
  final bool rejected;
  final String? error;
  final Appointment appointment;
}

class OfflineBookingRepository {
  OfflineBookingRepository({BarbershopApi? api, OfflineStore? store})
      : api = api ?? BarbershopApi(),
        store = store ?? OfflineStore();
  final BarbershopApi api;
  final OfflineStore store;
  bool offline = false;
  static final Map<String, Future<void>> _syncing = {};
  Future<List<Service>> services() async {
    try {
      if (ApiClient.connectionUnavailable) {
        throw const ApiException('Sem conexão');
      }
      final services = await api.services();
      await store.write('services', services.map((s) => s.toJson()).toList());
      offline = false;
      return services;
    } on ApiException catch (error) {
      if (!error.retryable) rethrow;
      offline = true;
      final cached = await store.read('services') as List?;
      if (cached == null) {
        throw const ApiException('Conecte uma vez para carregar os serviços.');
      }
      return cached
          .map((s) => Service.fromJson(Map<String, dynamic>.from(s)))
          .toList();
    }
  }

  Future<List<Map<String, dynamic>>> slots(DateTime date) async {
    List<Map<String, dynamic>> slots;
    try {
      if (ApiClient.connectionUnavailable) {
        throw const ApiException('Sem conexão');
      }
      slots = await api.timeSlots(date);
      await store.write('slot_template', slots.map((s) => s['slot']).toList());
    } on ApiException catch (error) {
      if (!error.retryable) rethrow;
      offline = true;
      final cached = await store.read('slot_template') as List?;
      if (cached == null) {
        throw const ApiException(
            'Conecte uma vez para carregar os horários de funcionamento.');
      }
      // O cache define a grade, nunca garante disponibilidade no servidor.
      slots = [
        for (final slot in cached) {'slot': slot, 'available': true}
      ];
    }
    return slots.where((s) {
      final parts = s['slot'].toString().split(':');
      return shopSlotToUtc(date, int.parse(parts[0]), int.parse(parts[1]))
          .isAfter(DateTime.now().toUtc());
    }).toList();
  }

  Future<bool> prepared() async =>
      await store.read('services') != null &&
      await store.read('slot_template') != null;

  Future<void> warmUp(DateTime date) async {
    await Future.wait([
      services().then<void>((_) {}).catchError((Object _) {}),
      slots(date).then<void>((_) {}).catchError((Object _) {}),
    ]);
  }

  Future<List<PendingAppointment>> pending() async {
    final rows = await (await store.database()).query('pending_appointments',
        where: 'scope = ?',
        whereArgs: [OfflineStore.scope],
        orderBy: 'sequence');
    return rows.map(PendingAppointment.new).toList();
  }

  Future<void> enqueue(
      String kind, Appointment preview, Map<String, dynamic> payload,
      {String? replacingConflict}) async {
    if (ApiClient.user == null) {
      throw const ApiException('Entre novamente.', 401);
    }
    final db = await store.database();
    await db.transaction((tx) async {
      if (replacingConflict != null) {
        final rows = await tx.query('pending_appointments',
            where: 'scope = ? AND entity_id = ? AND state = ?',
            whereArgs: [OfflineStore.scope, replacingConflict, 'rejected']);
        if (rows.isEmpty) {
          throw const ApiException(
              'O conflito já foi resolvido. Atualize a agenda.');
        }
        await tx.delete('pending_appointments',
            where: 'scope = ? AND entity_id = ?',
            whereArgs: [OfflineStore.scope, replacingConflict]);
      }
      await tx.insert('pending_appointments', {
        'scope': OfflineStore.scope,
        'entity_id': preview.id,
        'kind': kind,
        'payload': jsonEncode(payload),
        'preview': jsonEncode(preview.toJson()),
        'nonce': ApiClient.newNonce(),
        'state': 'pending',
        'error': null,
      });
    });
    await sync();
  }

  Future<String> remoteId(String id) async {
    if (!id.startsWith('local:')) return id;
    final rows = await (await store.database()).query('appointment_links',
        where: 'scope = ? AND local_id = ?',
        whereArgs: [OfflineStore.scope, id]);
    return rows.isEmpty ? id : rows.single['remote_id'] as String;
  }

  Future<void> sync() async {
    final scope = OfflineStore.scope;
    final running = _syncing[scope];
    if (running != null) {
      await running;
      return sync();
    }
    final work = _drain(scope);
    _syncing[scope] = work;
    try {
      await work;
    } finally {
      _syncing.remove(scope);
    }
  }

  Future<void> _drain(String scope) async {
    if (ApiClient.connectionUnavailable) {
      offline = true;
      return;
    }
    final db = await store.database();
    final rows = await db.query('pending_appointments',
        where: 'scope = ?', whereArgs: [scope], orderBy: 'sequence');
    final blocked = <String>{};
    for (final row in rows) {
      if (OfflineStore.scope != scope || ApiClient.user == null) return;
      final entityId = row['entity_id'] as String;
      if (row['state'] == 'rejected') {
        blocked.add(entityId);
        continue;
      }
      if (blocked.contains(entityId)) continue;
      final payload =
          Map<String, dynamic>.from(jsonDecode(row['payload'] as String));
      final nonce = row['nonce'] as String;
      try {
        final id = await remoteId(entityId);
        Map<String, dynamic>? result;
        if (row['kind'] == 'create') {
          result = await api.createBooking(payload, nonce);
        } else if (row['kind'] == 'edit') {
          result = await api.editAppointment(id, payload, nonce: nonce);
        } else {
          result = await api.setAppointmentStatus(id, payload, nonce: nonce);
        }
        // Cache e remoção da fila são atômicos: não reapresenta uma criação já confirmada.
        await db.transaction((tx) async {
          if (row['kind'] == 'create') {
            await tx.insert(
                'appointment_links',
                {
                  'scope': scope,
                  'local_id': entityId,
                  'remote_id': result!['id'].toString()
                },
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
          await tx.insert(
              'offline_cache',
              {
                'scope': scope,
                'key': 'synced:$entityId',
                'json': jsonEncode({
                  ...Map<String, dynamic>.from(
                      jsonDecode(row['preview'] as String)),
                  ...result!
                })
              },
              conflictAlgorithm: ConflictAlgorithm.replace);
          await tx.delete('pending_appointments',
              where: 'sequence = ? AND scope = ?',
              whereArgs: [row['sequence'], scope]);
        });
      } on ApiException catch (error) {
        if (error.retryable || error.statusCode == 401) {
          offline = true;
          return;
        }
        await db.update('pending_appointments',
            {'state': 'rejected', 'error': error.message},
            where: 'sequence = ? AND scope = ?',
            whereArgs: [row['sequence'], scope]);
        blocked.add(entityId);
      }
    }
  }

  Future<void> discardConflict(String id) async {
    final db = await store.database();
    final conflicts = await pending();
    if (!conflicts.any((p) => p.entityId == id && p.rejected)) {
      throw const ApiException('Aguarde a confirmação antes de descartar.');
    }
    await db.delete('pending_appointments',
        where: 'scope = ? AND entity_id = ?',
        whereArgs: [OfflineStore.scope, id]);
  }

  Future<void> acknowledgeDay(DateTime day) async {
    final db = await store.database();
    final rows = await db.query('offline_cache',
        where: 'scope = ? AND key LIKE ?',
        whereArgs: [OfflineStore.scope, 'synced:%']);
    for (final row in rows) {
      final appointment = Appointment.fromJson(
          Map<String, dynamic>.from(jsonDecode(row['json'] as String)));
      final date = appointmentShopTime(appointment.scheduledAt)!;
      if (date.year == day.year &&
          date.month == day.month &&
          date.day == day.day) {
        await db.delete('offline_cache',
            where: 'scope = ? AND key = ?',
            whereArgs: [OfflineStore.scope, row['key']]);
      }
    }
  }

  Future<List<Appointment>> overlay(
      List<Appointment> cached, DateTime day) async {
    final byId = {for (final a in cached) a.id: a};
    final synced = await (await store.database()).query('offline_cache',
        where: 'scope = ? AND key LIKE ?',
        whereArgs: [OfflineStore.scope, 'synced:%']);
    for (final row in synced) {
      final item = Appointment.fromJson(
          Map<String, dynamic>.from(jsonDecode(row['json'] as String)));
      if (!byId.containsKey(item.id) ||
          byId[item.id]!.revision < item.revision) {
        byId[item.id] = item;
      }
    }
    final entries = await pending();
    final latest = <String, Appointment>{};
    for (final entry in entries) {
      latest[entry.entityId] = entry.appointment;
    }
    for (final entry in latest.entries) {
      byId.remove(await remoteId(entry.key));
      byId[entry.key] = entry.value;
    }
    return byId.values.where((a) {
      final date = appointmentShopTime(a.scheduledAt);
      return date != null &&
          date.year == day.year &&
          date.month == day.month &&
          date.day == day.day;
    }).toList();
  }
}
