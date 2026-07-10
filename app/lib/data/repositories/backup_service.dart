// Backup/Restore: serializa toda la DB a JSON y permite restaurar
// Settings + sesiones + sets + progress photos metadata
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class BackupService {
  final Database db;

  BackupService(this.db);

  /// Exporta toda la base a un JSON y devuelve la ruta al archivo
  Future<File> exportToJson() async {
    final tables = ['user_settings', 'exercises', 'routines', 'routine_items', 'sessions', 'set_logs', 'progress_photos'];
    final data = <String, dynamic>{
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': {},
    };
    for (final t in tables) {
      final rows = await db.query(t);
      data['data'][t] = rows;
    }
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
        final rows = entry.value as List<dynamic>;
        await txn.delete(table);
        for (final row in rows) {
          await txn.insert(table, row as Map<String, dynamic>);
        }
      }
    });
  }
}
