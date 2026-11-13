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
    return openDatabase(path, version: 5, onUpgrade: (db, oldVersion, _) async {
      if (oldVersion < 2) await _createSyncTables(db);
      if (oldVersion >= 2 && oldVersion < 5) {
        await db.execute(
            "ALTER TABLE pending_completions ADD COLUMN nonce TEXT NOT NULL DEFAULT ''");
        await db.execute(
            "UPDATE pending_completions SET nonce = lower(hex(randomblob(16))) WHERE nonce = ''");
      }
      if (oldVersion < 3) await _createConfigTable(db);
      if (oldVersion >= 2 && oldVersion < 4) {
        await db
            .execute('ALTER TABLE daily_agenda RENAME TO legacy_daily_agenda');
        await _createAgendaTable(db);
        await db.execute(
            'INSERT INTO daily_agenda SELECT scope, day, json FROM legacy_daily_agenda');
        await db.execute('DROP TABLE legacy_daily_agenda');
      }
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

  static Future<void> _createAgendaTable(Database db) => db.execute(
        'CREATE TABLE daily_agenda (scope TEXT NOT NULL, day TEXT NOT NULL, json TEXT NOT NULL, PRIMARY KEY(scope, day))',
      );

  static Future<void> _createSyncTables(Database db) async {
    await _createAgendaTable(db);
    await db.execute(
      'CREATE TABLE pending_completions (scope TEXT NOT NULL, appointment_id TEXT NOT NULL, state TEXT NOT NULL, nonce TEXT NOT NULL, PRIMARY KEY(scope, appointment_id))',
    );
  }
}
