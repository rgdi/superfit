// Backup/Restore: serializa toda la DB a JSON y permite restaurar
// Settings + sesiones + sets + progress photos metadata
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'gym_repo.dart';

class BackupService {
  final Database db;

  BackupService(this.db);

  static const _tables = ['set_logs', 'workout_sessions', 'progress_photos', 'body_metrics', 'user_settings'];

  /// Exporta toda la base a un JSON y devuelve la ruta al archivo
  Future<File> exportToJson() async {
    // Solo tablas que existen en el esquema (antes había nombres inexistentes y fallaba)
    final data = <String, dynamic>{
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': {},
    };
    for (final t in _tables) {
      final rows = await db.query(t);
      data['data'][t] = rows;
    }
    // Máquinas, perfil y programa (SharedPreferences)
    data['prefs'] = await GymRepo().exportRaw();
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File(p.join(dir.path, 'superfit-backup-$ts.json'));
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    return file;
  }

  /// Importa un JSON y restaura la DB (borra las tablas existentes primero)
  Future<void> importFromJson(File file) async {
    final raw = await file.readAsString();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final tables = json['data'] as Map<String, dynamic>;
    await db.transaction((txn) async {
      for (final entry in tables.entries) {
        final table = entry.key;
        if (!_tables.contains(table)) continue;
        final rows = entry.value as List<dynamic>;
        await txn.delete(table);
        for (final row in rows) {
          await txn.insert(table, row as Map<String, dynamic>);
        }
      }
    });
    final prefs = json['prefs'];
    if (prefs is Map<String, dynamic>) await GymRepo().importRaw(prefs);
  }
}
