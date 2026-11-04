import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Database? _db;

  static bool get disponivel =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<Database> get instance async {
    if (!disponivel) {
      throw UnsupportedError('SQLite disponível apenas no Android e iOS.');
    }
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'barbearia_cache.db');
    return _db =
        await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute(
          'CREATE TABLE servicos_cache (id TEXT PRIMARY KEY, json TEXT NOT NULL, atualizado_em TEXT NOT NULL)');
      await db.execute(
          'CREATE TABLE agendamentos_cache (id TEXT PRIMARY KEY, json TEXT NOT NULL, atualizado_em TEXT NOT NULL)');
    });
  }
}
