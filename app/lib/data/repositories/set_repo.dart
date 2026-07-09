// Repositorio de sets registrados
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../core/db/db_helper.dart';
import '../models/set_log.dart';

class SetRepo {
  static const _uuid = Uuid();

  Future<Database> get _db => DBHelper.database;

  Future<SetLog> logSet({
    required String sessionId,
    required String exerciseId,
    required int setNumber,
    required double weight,
    required int reps,
    int? rpe,
    int? restTakenSeconds,
    String? technique,
    String? tempoNotes,
    bool completed = true,
  }) async {
    final db = await _db;
    final setLog = SetLog(
      id: _uuid.v4(),
      sessionId: sessionId,
      exerciseId: exerciseId,
      setNumber: setNumber,
      weight: weight,
      reps: reps,
      rpe: rpe,
      restTakenSeconds: restTakenSeconds,
      technique: technique,
      tempoNotes: tempoNotes,
      completed: completed,
      performedAt: DateTime.now(),
    );
    await db.insert('set_logs', setLog.toMap());
    return setLog;
  }

  Future<void> updateSet(SetLog setLog) async {
    final db = await _db;
    await db.update('set_logs', setLog.toMap(), where: 'id = ?', whereArgs: [setLog.id]);
  }

  Future<void> deleteSet(String id) async {
    final db = await _db;
    await db.delete('set_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<SetLog>> setsForSession(String sessionId) async {
    final db = await _db;
    final rows = await db.query(
      'set_logs',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'performed_at ASC',
    );
    return rows.map(SetLog.fromMap).toList();
  }

  Future<List<SetLog>> setsForExercise(String exerciseId, {int limit = 50}) async {
    final db = await _db;
    final rows = await db.query(
      'set_logs',
      where: 'exercise_id = ? AND completed = 1',
      whereArgs: [exerciseId],
      orderBy: 'performed_at DESC',
      limit: limit,
    );
    return rows.map(SetLog.fromMap).toList();
  }

  /// Devuelve el último set con un peso X reps dado para un ejercicio (para doble progresión)
  Future<SetLog?> lastSetForExercise(String exerciseId) async {
    final sets = await setsForExercise(exerciseId, limit: 5);
    if (sets.isEmpty) return null;
    return sets.first;
  }

  /// Devuelve el mejor set (mayor peso × reps) histórico para un ejercicio
  Future<SetLog?> bestSetForExercise(String exerciseId) async {
    final sets = await setsForExercise(exerciseId, limit: 100);
    if (sets.isEmpty) return null;
    sets.sort((a, b) => b.volume.compareTo(a.volume));
    return sets.first;
  }

  /// Devuelve sets efectivos (RPE >= 7) de los últimos N días
  Future<List<SetLog>> effectiveSetsInLastDays(int days) async {
    final db = await _db;
    final cutoff = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    final rows = await db.query(
      'set_logs',
      where: 'performed_at >= ? AND completed = 1 AND rpe >= 7',
      whereArgs: [cutoff],
    );
    return rows.map(SetLog.fromMap).toList();
  }

  /// RPE promedio de últimos N días
  Future<double?> averageRpeLastDays(int days) async {
    final db = await _db;
    final cutoff = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    final r = await db.rawQuery(
      'SELECT AVG(rpe) as avg_rpe FROM set_logs WHERE performed_at >= ? AND completed = 1 AND rpe IS NOT NULL',
      [cutoff],
    );
    final v = r.first['avg_rpe'];
    if (v == null) return null;
    return (v as num).toDouble();
  }

  /// Volumen total (kg × reps) por ejercicio en últimos N días
  Future<double> volumeForExerciseLastDays(String exerciseId, int days) async {
    final db = await _db;
    final cutoff = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    final r = await db.rawQuery(
      'SELECT SUM(weight * reps) as vol FROM set_logs WHERE exercise_id = ? AND performed_at >= ? AND completed = 1',
      [exerciseId, cutoff],
    );
    final v = r.first['vol'];
    if (v == null) return 0;
    return (v as num).toDouble();
  }

  /// 1RM estimado (Epley) por ejercicio en últimos N días
  Future<double?> estimated1RM(String exerciseId) async {
    final sets = await setsForExercise(exerciseId, limit: 20);
    if (sets.isEmpty) return null;
    double best = 0;
    for (final s in sets) {
      final epley = s.weight * (1 + s.reps / 30.0);
      if (epley > best) best = epley;
    }
    return best;
  }
}
