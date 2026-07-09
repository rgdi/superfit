// Repositorio de métricas corporales
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../core/db/db_helper.dart';
import '../models/body_metric.dart';

class BodyMetricRepo {
  static const _uuid = Uuid();

  Future<Database> get _db => DBHelper.database;

  Future<BodyMetric> add({
    required DateTime date,
    double? weightKg,
    double? bodyFatPct,
    double? chestCm,
    double? waistCm,
    double? armCm,
    double? thighCm,
  }) async {
    final db = await _db;
    final m = BodyMetric(
      id: _uuid.v4(),
      date: date,
      weightKg: weightKg,
      bodyFatPct: bodyFatPct,
      chestCm: chestCm,
      waistCm: waistCm,
      armCm: armCm,
      thighCm: thighCm,
    );
    await db.insert('body_metrics', m.toMap());
    return m;
  }

  Future<void> update(BodyMetric m) async {
    final db = await _db;
    await db.update('body_metrics', m.toMap(), where: 'id = ?', whereArgs: [m.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('body_metrics', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<BodyMetric>> all() async {
    final db = await _db;
    final rows = await db.query('body_metrics', orderBy: 'date ASC');
    return rows.map(BodyMetric.fromMap).toList();
  }

  Future<BodyMetric?> latest() async {
    final db = await _db;
    final rows = await db.query('body_metrics', orderBy: 'date DESC', limit: 1);
    if (rows.isEmpty) return null;
    return BodyMetric.fromMap(rows.first);
  }
}
