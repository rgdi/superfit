// Backup/Restore: serializa toda la DB a JSON y permite restaurar
// Settings + sesiones + sets + progress photos metadata
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    // TODAS las preferencias: ajustes (nivel, objetivo…), máquinas, perfil,
    // programa y "¿cómo llegas hoy?" de cada sesión (los usa el modelo).
    final prefs = await SharedPreferences.getInstance();
    data['prefs_all'] = {
      for (final k in prefs.getKeys())
        k: switch (prefs.get(k)) {
          final List<String> l => {'t': 'list', 'v': l},
          final bool b => {'t': 'bool', 'v': b},
          final int i => {'t': 'int', 'v': i},
          final double d => {'t': 'double', 'v': d},
          final Object o => {'t': 'string', 'v': o.toString()},
          _ => {'t': 'string', 'v': ''},
        },
    };
    data['photos_note'] = 'Las fotos de progreso no se incluyen (solo sus datos).';
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
    final all = json['prefs_all'];
    if (all is Map<String, dynamic>) {
      // Restauración completa: lo que no esté en la copia se borra (nada de mezclar estados)
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      for (final e in all.entries) {
        final m = e.value as Map<String, dynamic>;
        switch (m['t']) {
          case 'list':
            await prefs.setStringList(e.key, (m['v'] as List).cast<String>());
          case 'bool':
            await prefs.setBool(e.key, m['v'] as bool);
          case 'int':
            await prefs.setInt(e.key, (m['v'] as num).toInt());
          case 'double':
            await prefs.setDouble(e.key, (m['v'] as num).toDouble());
          default:
            await prefs.setString(e.key, m['v'] as String);
        }
      }
    } else if (json['prefs'] is Map<String, dynamic>) {
      // Copias antiguas (v2)
      await GymRepo().importRaw(json['prefs'] as Map<String, dynamic>);
    }
  }

  /// Borra TODO: sesiones, series, métricas, fotos (y sus archivos) y preferencias.
  Future<void> wipeAll() async {
    final photos = await db.query('progress_photos', columns: ['image_path']);
    for (final r in photos) {
      final f = File(r['image_path'] as String);
      if (await f.exists()) await f.delete();
    }
    await db.transaction((txn) async {
      for (final t in _tables) {
        await txn.delete(t);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
