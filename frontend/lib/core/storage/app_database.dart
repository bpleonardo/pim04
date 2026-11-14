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
    return openDatabase(path, version: 6, onUpgrade: upgrade,
        onCreate: (db, version) async {
      await db.execute(
          'CREATE TABLE servicos_cache (id TEXT PRIMARY KEY, json TEXT NOT NULL, atualizado_em TEXT NOT NULL)');
      await _createSyncTables(db);
      await _createConfigTable(db);
      await createOfflineTables(db);
    });
  }

  static Future<void> upgrade(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 6) await createOfflineTables(db);
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
  }

  static Future<void> createOfflineTables(Database db) async {
    await db.execute(
        'CREATE TABLE offline_cache (scope TEXT NOT NULL, key TEXT NOT NULL, json TEXT NOT NULL, PRIMARY KEY(scope, key))');
    await db.execute(
        'CREATE TABLE pending_appointments (sequence INTEGER PRIMARY KEY AUTOINCREMENT, scope TEXT NOT NULL, entity_id TEXT NOT NULL, kind TEXT NOT NULL, payload TEXT NOT NULL, preview TEXT NOT NULL, nonce TEXT NOT NULL, state TEXT NOT NULL, error TEXT)');
    await db.execute(
        'CREATE TABLE appointment_links (scope TEXT NOT NULL, local_id TEXT NOT NULL, remote_id TEXT NOT NULL, PRIMARY KEY(scope, local_id))');
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
