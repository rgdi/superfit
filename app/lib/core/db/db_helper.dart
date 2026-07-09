// DB initialization, schema, migrations
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final path = p.join(docsDir.path, AppConstants.dbName);
    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    // Setlogs
    batch.execute('''
      CREATE TABLE set_logs (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        set_number INTEGER NOT NULL,
        weight REAL NOT NULL,
        reps INTEGER NOT NULL,
        rpe INTEGER,
        rest_taken_seconds INTEGER,
        tempo_notes TEXT,
        completed INTEGER NOT NULL,
        performed_at INTEGER NOT NULL,
        technique TEXT
      )
    ''');
    batch.execute('CREATE INDEX idx_setlogs_session ON set_logs(session_id)');
    batch.execute('CREATE INDEX idx_setlogs_exercise ON set_logs(exercise_id, performed_at)');

    // Sessions
    batch.execute('''
      CREATE TABLE workout_sessions (
        id TEXT PRIMARY KEY,
        routine_id TEXT NOT NULL,
        started_at INTEGER NOT NULL,
        finished_at INTEGER,
        perceived_exertion INTEGER,
        notes TEXT,
        total_sets INTEGER,
        total_volume REAL
      )
    ''');
    batch.execute('CREATE INDEX idx_sessions_date ON workout_sessions(started_at)');

    // Progress photos
    batch.execute('''
      CREATE TABLE progress_photos (
        id TEXT PRIMARY KEY,
        date INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        weight_kg REAL,
        body_fat_pct REAL,
        notes TEXT,
        pose TEXT NOT NULL
      )
    ''');
    batch.execute('CREATE INDEX idx_photos_date ON progress_photos(date)');

    // Body metrics
    batch.execute('''
      CREATE TABLE body_metrics (
        id TEXT PRIMARY KEY,
        date INTEGER NOT NULL,
        weight_kg REAL,
        body_fat_pct REAL,
        chest_cm REAL,
        waist_cm REAL,
        arm_cm REAL,
        thigh_cm REAL
      )
    ''');
    batch.execute('CREATE INDEX idx_metrics_date ON body_metrics(date)');

    // Settings (single row)
    batch.execute('''
      CREATE TABLE user_settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        level TEXT NOT NULL,
        goal TEXT NOT NULL,
        units TEXT NOT NULL,
        locale TEXT NOT NULL,
        plan_start_date INTEGER,
        current_week INTEGER NOT NULL,
        current_deload INTEGER NOT NULL
      )
    ''');

    await batch.commit(noResult: true);
  }

  static Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    // Placeholder para migraciones futuras
  }

  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
