import 'dart:convert';
import '../../models/servico.dart';
import '../api/barbearia_api.dart';
import '../db/app_database.dart' show AppDatabase;
import 'package:sqflite/sqflite.dart';

class ServicoRepository {
  final BarbeariaApi api = BarbeariaApi();
  Future<List<Servico>> listar() async {
    try {
      final dados = await api.servicos();
      if (AppDatabase.disponivel) {
        final db = await AppDatabase.instance;
        final batch = db.batch();
        for (final s in dados) {
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
      return dados;
    } catch (e) {
      if (!AppDatabase.disponivel) rethrow;
      final db = await AppDatabase.instance;
      final rows = await db.query('servicos_cache');
      if (rows.isEmpty) rethrow;
      return rows
          .map((r) => Servico.fromJson(
              jsonDecode(r['json'] as String) as Map<String, dynamic>))
          .toList();
    }
  }
}
