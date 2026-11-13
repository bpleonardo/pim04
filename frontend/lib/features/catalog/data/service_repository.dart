import 'dart:convert';
import 'package:barbearia_frontend/features/catalog/models/service.dart';
import 'package:barbearia_frontend/core/network/barbershop_api.dart';
import 'package:barbearia_frontend/core/storage/app_database.dart'
    show AppDatabase;
import 'package:sqflite/sqflite.dart';

class ServiceRepository {
  final BarbershopApi api = BarbershopApi();
  Future<void> save(Service service, {required bool creating}) =>
      api.saveService(service, creating: creating);

  Future<void> delete(String id) async {
    await api.deleteService(id);
    if (AppDatabase.available) {
      await (await AppDatabase.instance).delete(
        'servicos_cache',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<List<Service>> list() async {
    try {
      final records = await api.services();
      if (AppDatabase.available) {
        final db = await AppDatabase.instance;
        final batch = db.batch();
        batch.delete('servicos_cache');
        for (final s in records) {
          batch.insert(
              'servicos_cache',
              {
                'id': s.id,
                'json': jsonEncode(s.toJson()),
                'atualizado_em': DateTime.now().toIso8601String()
              },
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      }
      return records;
    } catch (e) {
      if (!AppDatabase.available) rethrow;
      final db = await AppDatabase.instance;
      final rows = await db.query('servicos_cache');
      if (rows.isEmpty) rethrow;
      return rows
          .map((r) => Service.fromJson(
              jsonDecode(r['json'] as String) as Map<String, dynamic>))
          .toList();
    }
  }
}
