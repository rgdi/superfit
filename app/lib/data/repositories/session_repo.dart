// Repositorio de sesiones de workout
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../core/db/db_helper.dart';
import '../models/workout_session.dart';

class SessionRepo {
  static const _uuid = Uuid();

  Future<Database> get _db => DBHelper.database;

  Future<WorkoutSession> startSession(String routineId) async {
    final db = await _db;
    final id = _uuid.v4();
    final session = WorkoutSession(
      id: id,
      routineId: routineId,
      startedAt: DateTime.now(),
    );
    await db.insert('workout_sessions', session.toMap());
    return session;
  }

  Future<void> finishSession(String id, {
    int? perceivedExertion,
    String? notes,
    int? totalSets,
    double? totalVolume,
  }) async {
    final db = await _db;
    await db.update(
      'workout_sessions',
      {
        'finished_at': DateTime.now().millisecondsSinceEpoch,
        'perceived_exertion': perceivedExertion,
        'notes': notes,
        'total_sets': totalSets,
        'total_volume': totalVolume,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteSession(String id) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('set_logs', where: 'session_id = ?', whereArgs: [id]);
      await txn.delete('workout_sessions', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<WorkoutSession?> activeSession() async {
    final db = await _db;
    final rows = await db.query(
      'workout_sessions',
      where: 'finished_at IS NULL',
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WorkoutSession.fromMap(rows.first);
  }

  Future<WorkoutSession?> sessionById(String id) async {
    final db = await _db;
    final rows = await db.query('workout_sessions', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return WorkoutSession.fromMap(rows.first);
  }

  Future<List<WorkoutSession>> recentSessions({int limit = 20}) async {
    final db = await _db;
    final rows = await db.query(
      'workout_sessions',
      where: 'finished_at IS NOT NULL',
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return rows.map(WorkoutSession.fromMap).toList();
  }

  Future<List<WorkoutSession>> sessionsInRange(DateTime from, DateTime to) async {
    final db = await _db;
    final rows = await db.query(
      'workout_sessions',
      where: 'started_at >= ? AND started_at <= ?',
      whereArgs: [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
      orderBy: 'started_at ASC',
    );
    return rows.map(WorkoutSession.fromMap).toList();
  }

  Future<int> totalCompletedSessions() async {
    final db = await _db;
    final r = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM workout_sessions WHERE finished_at IS NOT NULL'
    ));
    return r ?? 0;
  }

  Future<int> currentStreakDays() async {
    final sessions = await recentSessions(limit: 30);
    if (sessions.isEmpty) return 0;
    int streak = 0;
    DateTime? day;
    for (final s in sessions) {
      final d = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
      if (day == null) {
        day = d;
        streak = 1;
        continue;
      }
      final diff = day!.difference(d).inDays;
      if (diff == 1) {
        streak++;
        day = d;
      } else if (diff == 0) {
        continue;
      } else {
        break;
      }
    }
    return streak;
  }
}
