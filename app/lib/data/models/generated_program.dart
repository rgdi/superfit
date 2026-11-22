// Programa generado a medida (rutinas + orden de rotación + mesociclo).
import 'dart:convert';
import 'routine.dart';

class GeneratedProgram {
  final DateTime createdAt;
  final DateTime startDate;
  final String splitName; // "Torso / Pierna", "Cuerpo completo"...
  final List<Routine> routines;
  final List<String> rotation; // orden en el que se repiten las sesiones
  final int mesocycleWeeks; // la última semana es descarga
  final List<String> rationale; // por qué se ha decidido así
  final Map<String, int> weeklySets; // grupo -> series/semana planificadas

  const GeneratedProgram({
    required this.createdAt,
    required this.startDate,
    required this.splitName,
    required this.routines,
    required this.rotation,
    required this.mesocycleWeeks,
    required this.rationale,
    required this.weeklySets,
  });

  GeneratedProgram copyWith({DateTime? startDate, List<Routine>? routines}) => GeneratedProgram(
        createdAt: createdAt,
        startDate: startDate ?? this.startDate,
        splitName: splitName,
        routines: routines ?? this.routines,
        rotation: rotation,
        mesocycleWeeks: mesocycleWeeks,
        rationale: rationale,
        weeklySets: weeklySets,
      );

  /// Semana del mesociclo (1..mesocycleWeeks) para una fecha.
  int weekFor(DateTime date) {
    final d0 = DateTime(startDate.year, startDate.month, startDate.day);
    final days = DateTime(date.year, date.month, date.day).difference(d0).inDays;
    if (days < 0) return 1;
    return (days ~/ 7) % mesocycleWeeks + 1;
  }

  bool isDeloadWeek(DateTime date) => weekFor(date) == mesocycleWeeks;

  Map<String, dynamic> toJson() => {
        'created_at': createdAt.millisecondsSinceEpoch,
        'start_date': startDate.millisecondsSinceEpoch,
        'split_name': splitName,
        'routines': routines.map((r) => r.toJson()).toList(),
        'rotation': rotation,
        'mesocycle_weeks': mesocycleWeeks,
        'rationale': rationale,
        'weekly_sets': weeklySets,
      };

  factory GeneratedProgram.fromJson(Map<String, dynamic> j) => GeneratedProgram(
        createdAt: DateTime.fromMillisecondsSinceEpoch(j['created_at'] as int),
        startDate: DateTime.fromMillisecondsSinceEpoch(j['start_date'] as int),
        splitName: j['split_name'] as String? ?? '',
        routines: (j['routines'] as List)
            .map((e) => Routine.fromJson(e as Map<String, dynamic>))
            .toList(),
        rotation: (j['rotation'] as List).cast<String>(),
        mesocycleWeeks: j['mesocycle_weeks'] as int? ?? 5,
        rationale: (j['rationale'] as List?)?.cast<String>() ?? const [],
        weeklySets: (j['weekly_sets'] as Map?)?.map(
              (k, v) => MapEntry(k as String, (v as num).toInt()),
            ) ??
            const {},
      );

  String encode() => jsonEncode(toJson());

  static GeneratedProgram? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return GeneratedProgram.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
