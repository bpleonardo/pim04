import 'dart:convert';
import 'package:barbearia_frontend/core/network/api_client.dart';
import 'package:barbearia_frontend/core/storage/app_database.dart';
import 'package:sqflite/sqflite.dart';

class OfflineStore {
  OfflineStore({Future<Database> Function()? database})
      : database = database ?? (() => AppDatabase.instance);
  final Future<Database> Function() database;
  static String get scope =>
      jsonEncode([ApiClient.baseUrl, ApiClient.user?.id]);

  Future<void> write(String key, Object value) async {
    await (await database()).insert('offline_cache',
        {'scope': scope, 'key': key, 'json': jsonEncode(value)},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Object?> read(String key) async {
    final rows = await (await database()).query('offline_cache',
        where: 'scope = ? AND key = ?', whereArgs: [scope, key]);
    return rows.isEmpty ? null : jsonDecode(rows.single['json'] as String);
  }
}
