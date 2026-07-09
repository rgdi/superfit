// Repositorio de fotos de progreso
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../core/db/db_helper.dart';
import '../models/progress_photo.dart';

class PhotoRepo {
  static const _uuid = Uuid();

  Future<Database> get _db => DBHelper.database;

  Future<ProgressPhoto> add({
    required String imagePath,
    required String pose,
    required DateTime date,
    double? weightKg,
    double? bodyFatPct,
    String? notes,
  }) async {
    final db = await _db;
    final photo = ProgressPhoto(
      id: _uuid.v4(),
      date: date,
      imagePath: imagePath,
      pose: pose,
      weightKg: weightKg,
      bodyFatPct: bodyFatPct,
      notes: notes,
    );
    await db.insert('progress_photos', photo.toMap());
    return photo;
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('progress_photos', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ProgressPhoto>> all({String? pose}) async {
    final db = await _db;
    final rows = await db.query(
      'progress_photos',
      where: pose != null ? 'pose = ?' : null,
      whereArgs: pose != null ? [pose] : null,
      orderBy: 'date DESC',
    );
    return rows.map(ProgressPhoto.fromMap).toList();
  }

  Future<ProgressPhoto?> byId(String id) async {
    final db = await _db;
    final rows = await db.query('progress_photos', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return ProgressPhoto.fromMap(rows.first);
  }
}
