// Lógica de adaptación: sugerir peso, detectar meseta, calcular 1RM
import 'package:collection/collection.dart';
import '../../data/models/exercise.dart';
import '../../data/models/set_log.dart';
import '../../data/repositories/set_repo.dart';
import '../../core/constants/app_constants.dart';

class WeightSuggestion {
  final double weight;
  final String reason;
  final int targetReps;
  final int rpeTarget;

  const WeightSuggestion({
    required this.weight,
    required this.reason,
    required this.targetReps,
    required this.rpeTarget,
  });
}

class ProgressionResult {
  final bool shouldProgress; // subir peso
  final bool shouldDeload; // bajar peso / descansar
  final bool shouldSubstitute; // cambiar ejercicio
  final String reason;
  final double? suggestedWeight;
  final String? suggestedSubstituteId;

  const ProgressionResult({
    required this.shouldProgress,
    required this.shouldDeload,
    required this.shouldSubstitute,
    required this.reason,
    this.suggestedWeight,
    this.suggestedSubstituteId,
  });
}

class ProgressionService {
  final SetRepo _setRepo;
  ProgressionService(this._setRepo);

  /// Calcula 1RM estimado (Epley) de un set
  static double epley1RM(double weight, int reps) {
    return weight * (1 + reps / 30.0);
  }

  /// Brzycki alternativo
  static double brzycki1RM(double weight, int reps) {
    if (reps >= 37) return weight;
    return weight * 36.0 / (37.0 - reps);
  }

  /// Sugiere peso inicial para un usuario sin historial
  /// Basado en patrón de movimiento y heurística conservadora
  static double suggestInitialWeight(Exercise exercise, {String level = 'intermediate'}) {
    final base = switch (exercise.pattern) {
      'squat' => 60.0,
      'hinge' => 50.0,
      'horizontal_push' => 40.0,
      'vertical_push' => 30.0,
      'horizontal_pull' => 40.0,
      'vertical_pull' => 45.0,
      _ => 20.0, // isolation
    };
    final mult = switch (level) {
      'beginner' => 0.7,
      'advanced' => 1.3,
      _ => 1.0,
    };
    final isolMult = exercise.category == 'isolation' ? 0.5 : 1.0;
    // redondear a 2.5 kg más cercano
    final raw = base * mult * isolMult;
    return (raw / 2.5).round() * 2.5;
  }

  /// Sugiere peso para la próxima sesión basado en historial (doble progresión)
  /// Lógica:
  /// - Si últimas 2 sesiones completó todas las reps objetivo a RPE ≤ target → subir
  /// - Si RPE promedio > target en últimas 2 → bajar
  /// - Si estancado 3 sesiones → mantener y marcar meseta
  Future<WeightSuggestion> suggestWeightForNextSession(
    String exerciseId, {
    required int targetReps,
    required int rpeTarget,
  }) async {
    final recent = await _setRepo.setsForExercise(exerciseId, limit: 20);
    if (recent.isEmpty) {
      // sin historial → fallback conservador
      return WeightSuggestion(
        weight: suggestInitialWeight(
          _fallbackExerciseForId(exerciseId),
          level: 'intermediate',
        ),
        reason: 'Sin historial. Peso conservador inicial.',
        targetReps: targetReps,
        rpeTarget: rpeTarget,
      );
    }
    // agrupar por sesión
    final bySession = groupBy<SetLog, DateTime>(recent, (s) {
      final d = s.performedAt;
      return DateTime(d.year, d.month, d.day, d.hour);
    });
    final sessions = bySession.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    if (sessions.length < 2) {
      // solo 1 sesión → repetir último peso
      final lastSet = recent.first;
      return WeightSuggestion(
        weight: lastSet.weight,
        reason: 'Primera repetición: usar mismo peso, intentar +1-2 reps.',
        targetReps: targetReps,
        rpeTarget: rpeTarget,
      );
    }

    // Analizar 2 últimas sesiones
    final last = sessions[0].value;
    final prev = sessions[1].value;
    final lastMaxReps = last.map((s) => s.reps).reduce((a, b) => a > b ? a : b);
    final lastAvgRpe = _avgRpe(last);
    final prevMaxReps = prev.map((s) => s.reps).reduce((a, b) => a > b ? a : b);
    final prevAvgRpe = _avgRpe(prev);
    final lastWeight = last.first.weight;

    // Progresión: completó reps objetivo a RPE ≤ target en ambas → subir
    final hitReps = lastMaxReps >= targetReps && prevMaxReps >= targetReps;
    final controlledRpe = lastAvgRpe != null && lastAvgRpe <= rpeTarget.toDouble()
        && prevAvgRpe != null && prevAvgRpe <= rpeTarget.toDouble();

    if (hitReps && controlledRpe) {
      return WeightSuggestion(
        weight: lastWeight + AppConstants.kWeightDeltaKg,
        reason: 'Dominado ${targetReps} reps a RPE ≤$rpeTarget → subimos ${AppConstants.kWeightDeltaKg} kg.',
        targetReps: targetReps,
        rpeTarget: rpeTarget,
      );
    }

    // RPE demasiado alto → bajar
    if (lastAvgRpe != null && lastAvgRpe >= 9.0) {
      final newW = (lastWeight * 0.95 / 2.5).round() * 2.5;
      return WeightSuggestion(
        weight: newW.toDouble(),
        reason: 'RPE ≥9 dos sesiones → bajamos 5% para recuperar forma.',
        targetReps: targetReps,
        rpeTarget: rpeTarget,
      );
    }

    // Si no llegó a reps pero RPE OK → repetir peso
    if (lastMaxReps < targetReps && lastAvgRpe != null && lastAvgRpe <= 8.0) {
      return WeightSuggestion(
        weight: lastWeight,
        reason: 'Casi llegas a ${targetReps} reps a buen RPE. Mantén peso, intenta +1 rep.',
        targetReps: targetReps,
        rpeTarget: rpeTarget,
      );
    }

    // default: repetir peso
    return WeightSuggestion(
      weight: lastWeight,
      reason: 'Mantén peso, busca consistencia en reps/RPE.',
      targetReps: targetReps,
      rpeTarget: rpeTarget,
    );
  }

  /// Detecta meseta: 3+ semanas sin subir peso
  Future<bool> isStagnant(String exerciseId, {int weeks = 3}) async {
    final all = await _setRepo.setsForExercise(exerciseId, limit: 100);
    if (all.length < 6) return false;
    final cutoff = DateTime.now().subtract(Duration(days: 7 * weeks));
    final recent = all.where((s) => s.performedAt.isAfter(cutoff)).toList();
    if (recent.length < 3) return false;
    // max peso por semana
    final byWeek = groupBy<SetLog, String>(recent, (s) {
      final iso = _isoWeek(s.performedAt);
      return iso;
    });
    if (byWeek.length < weeks) return false;
    final weeksList = byWeek.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
    final maxPerWeek = weeksList.take(weeks).map((e) {
      return e.value.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
    }).toList();
    if (maxPerWeek.length < 2) return false;
    final first = maxPerWeek.last;
    final last = maxPerWeek.first;
    return last <= first;
  }

  /// Análisis completo: ¿progresar? ¿deload? ¿sustituir?
  Future<ProgressionResult> analyze(String exerciseId) async {
    final recent = await _setRepo.setsForExercise(exerciseId, limit: 10);
    if (recent.isEmpty) {
      return ProgressionResult(
        shouldProgress: false,
        shouldDeload: false,
        shouldSubstitute: false,
        reason: 'Sin datos. Empieza con peso conservador.',
      );
    }
    final avgRpe = _avgRpe(recent);
    final stagnant = await isStagnant(exerciseId);
    if (stagnant) {
      return ProgressionResult(
        shouldProgress: false,
        shouldDeload: false,
        shouldSubstitute: true,
        reason: 'Estancado 3+ semanas → cambia de variante.',
      );
    }
    if (avgRpe != null && avgRpe >= 9.5) {
      return ProgressionResult(
        shouldProgress: false,
        shouldDeload: true,
        shouldSubstitute: false,
        reason: 'RPE ≥9.5 últimos sets → considera deload.',
      );
    }
    return ProgressionResult(
      shouldProgress: avgRpe != null && avgRpe <= 7.5,
      shouldDeload: false,
      shouldSubstitute: false,
      reason: avgRpe != null && avgRpe <= 7.5
          ? 'RPE bajo y progresión OK. Mantén/avanza.'
          : 'Dentro del rango. Sigue el plan.',
      suggestedWeight: avgRpe != null && avgRpe <= 7.5
          ? recent.first.weight + 2.5
          : null,
    );
  }

  double? _avgRpe(List<SetLog> sets) {
    final rpes = sets.where((s) => s.rpe != null).map((s) => s.rpe!.toDouble()).toList();
    if (rpes.isEmpty) return null;
    return rpes.reduce((a, b) => a + b) / rpes.length;
  }

  String _isoWeek(DateTime d) {
    // ISO week: año + número semana
    final dayOfYear = d.difference(DateTime(d.year, 1, 1)).inDays;
    final week = (dayOfYear / 7).floor() + 1;
    return '${d.year}-W$week';
  }

  Exercise _fallbackExerciseForId(String id) {
    return Exercise(
      id: id,
      nameEs: id,
      nameEn: id,
      category: 'compound',
      pattern: 'horizontal_push',
      primaryMuscles: [],
      secondaryMuscles: [],
      equipmentId: '',
      imagePath: '',
      instructionsEs: [],
      instructionsEn: [],
      cuesEs: [],
      cuesEn: [],
      defaultReps: '8-12',
      defaultRestSeconds: 90,
      rpeTarget: 8,
      contraindications: [],
      tempo: '2-1-2-0',
      sourceResearch: '',
    );
  }
}
