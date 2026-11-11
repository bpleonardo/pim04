import 'package:barbearia_frontend/core/responsive/app_platform.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Future<Database>? _opening;

  static bool get available => AppPlatform.mobile;

  static Future<Database> get instance async {
    if (!available) {
      throw UnsupportedError('SQLite disponível apenas no Android e iOS.');
    }
    try {
      return await (_opening ??= _open());
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'barbearia_cache.db');
    return openDatabase(path, version: 3, onUpgrade: (db, oldVersion, _) async {
      if (oldVersion < 2) await _createSyncTables(db);
      if (oldVersion < 3) await _createConfigTable(db);
    }, onCreate: (db, version) async {
      await db.execute(
          'CREATE TABLE servicos_cache (id TEXT PRIMARY KEY, json TEXT NOT NULL, atualizado_em TEXT NOT NULL)');
      await _createSyncTables(db);
      await _createConfigTable(db);
    });
  }

  static Future<void> _createConfigTable(Database db) async {
    await db.execute(
      'CREATE TABLE api_config (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
    );
  }

  static Future<String?> readApiUrl() async {
    final rows = await (await instance).query(
      'api_config',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['apiUrl'],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  static Future<void> writeApiUrl(String value) async {
    await (await instance).insert(
      'api_config',
      {'key': 'apiUrl', 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> _createSyncTables(Database db) async {
    await db.execute(
      'CREATE TABLE daily_agenda (scope TEXT PRIMARY KEY, day TEXT NOT NULL, json TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE pending_completions (scope TEXT NOT NULL, appointment_id TEXT NOT NULL, state TEXT NOT NULL, PRIMARY KEY(scope, appointment_id))',
    );
  }
}
