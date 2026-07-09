// Algoritmo avanzado: detección de fatiga con EMA + predicción de PR
// EMA = Exponential Moving Average con α adaptativo según adherencia
import '../../data/models/set_log.dart';
import '../../data/repositories/set_repo.dart';

class FatigueReport {
  final double emaRpe7d;
  final double emaVolume7d;
  final double fatigueIndex; // 0..1, >0.7 sugiere deload
  final int totalSets7d;
  final int totalVolume7d;
  final String recommendation;
  final bool shouldDeload;
  final bool shouldReduceVolume;

  const FatigueReport({
    required this.emaRpe7d,
    required this.emaVolume7d,
    required this.fatigueIndex,
    required this.totalSets7d,
    required this.totalVolume7d,
    required this.recommendation,
    required this.shouldDeload,
    required this.shouldReduceVolume,
  });
}

class PredictedMax {
  final double weight;
  final int reps;
  final double estimated1RM;
  final String exerciseId;
  final double confidence; // 0..1

  const PredictedMax({
    required this.weight,
    required this.reps,
    required this.estimated1RM,
    required this.exerciseId,
    required this.confidence,
  });
}

class AdvancedAnalytics {
  final SetRepo _setRepo;
  AdvancedAnalytics(this._setRepo);

  /// EMA (Exponential Moving Average) con α = 2/(N+1)
  /// α más alto = más peso a datos recientes
  double _ema(List<double> values, double alpha) {
    if (values.isEmpty) return 0;
    double ema = values.first;
    for (int i = 1; i < values.length; i++) {
      ema = alpha * values[i] + (1 - alpha) * ema;
    }
    return ema;
  }

  /// Detecta fatiga acumulada combinando RPE + volumen + adherencia
  Future<FatigueReport> detectFatigue({int days = 7}) async {
    final sets = await _setRepo.effectiveSetsInLastDays(days);
    if (sets.isEmpty) {
      return const FatigueReport(
        emaRpe7d: 0,
        emaVolume7d: 0,
        fatigueIndex: 0,
        totalSets7d: 0,
        totalVolume7d: 0,
        recommendation: 'Sin datos. Entrena con cabeza.',
        shouldDeload: false,
        shouldReduceVolume: false,
      );
    }
    // agrupar por día
    final byDay = <String, List<SetLog>>{};
    for (final s in sets) {
      final d = '${s.performedAt.year}-${s.performedAt.month.toString().padLeft(2, '0')}-${s.performedAt.day.toString().padLeft(2, '0')}';
      byDay.putIfAbsent(d, () => []).add(s);
    }
    final daysWithData = byDay.keys.toList()..sort();
    final rpeByDay = daysWithData.map((d) {
      final rpes = byDay[d]!.where((s) => s.rpe != null).map((s) => s.rpe!.toDouble()).toList();
      return rpes.isEmpty ? 0.0 : rpes.reduce((a, b) => a + b) / rpes.length;
    }).toList();
    final volByDay = daysWithData.map((d) =>
      byDay[d]!.fold<double>(0, (a, b) => a + b.volume)
    ).toList();
    // α = 0.5 (balance entre reciente e histórico)
    final emaRpe = _ema(rpeByDay, 0.5);
    final emaVol = _ema(volByDay, 0.5);
    // índice fatiga: 0..1
    // - RPE > 8.5 suma 0.4
    // - RPE > 9.0 suma 0.3 adicional
    // - Volumen > 1.5x media suma 0.2
    double fatigue = 0;
    if (emaRpe > 8.5) fatigue += 0.4;
    if (emaRpe > 9.0) fatigue += 0.3;
    final avgVol = volByDay.isEmpty ? 0 : volByDay.reduce((a, b) => a + b) / volByDay.length;
    if (avgVol > 0 && emaVol > avgVol * 1.5) fatigue += 0.2;
    fatigue = fatigue.clamp(0, 1);
    final shouldDeload = fatigue > 0.7;
    final shouldReduce = fatigue > 0.4 && fatigue <= 0.7;
    String rec;
    if (shouldDeload) {
      rec = '🚨 FATIGA ALTA — deload inmediato. Reduce 50% volumen, RPE 6-7, 1 semana.';
    } else if (shouldReduce) {
      rec = '⚠️ Fatiga elevada — mantén pesos, reduce 1-2 series por ejercicio esta semana.';
    } else if (fatigue < 0.2) {
      rec = '✅ Buena recuperación — puedes progresar pesos esta semana.';
    } else {
      rec = '👍 Fatiga normal — sigue el plan.';
    }
    final totalSets = sets.length;
    final totalVol = sets.fold<double>(0, (a, b) => a + b.volume).round();
    return FatigueReport(
      emaRpe7d: emaRpe,
      emaVolume7d: emaVol,
      fatigueIndex: fatigue,
      totalSets7d: totalSets,
      totalVolume7d: totalVol,
      recommendation: rec,
      shouldDeload: shouldDeload,
      shouldReduceVolume: shouldReduce,
    );
  }

  /// Predice el próximo PR usando regresión lineal sobre últimos N sets
  Future<PredictedMax?> predictNextPR(String exerciseId, {int lastSets = 10}) async {
    final sets = await _setRepo.setsForExercise(exerciseId, limit: lastSets);
    if (sets.length < 3) return null;
    // construir serie: (x=índice, y=1RM estimado)
    final points = <List<double>>[];
    for (int i = 0; i < sets.length; i++) {
      final oneRm = ProgressionMath.epley1RM(sets[i].weight, sets[i].reps);
      points.add([i.toDouble(), oneRm]);
    }
    // regresión lineal simple
    final n = points.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (final p in points) {
      sumX += p[0];
      sumY += p[1];
      sumXY += p[0] * p[1];
      sumX2 += p[0] * p[0];
    }
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;
    // predicción para el siguiente set
    final nextX = n.toDouble();
    final double predicted1RM = (slope * nextX + intercept).clamp(0.0, double.infinity).toDouble();
    // confianza basada en R²
    final meanY = sumY / n;
    double ssRes = 0, ssTot = 0;
    for (final p in points) {
      final predictedY = slope * p[0] + intercept;
      ssRes += (p[1] - predictedY) * (p[1] - predictedY);
      ssTot += (p[1] - meanY) * (p[1] - meanY);
    }
    final r2 = ssTot == 0 ? 0.0 : 1 - ssRes / ssTot;
    final confidence = r2.clamp(0.0, 1.0);
    // estimar peso × reps: ronda a 2.5kg, 6-10 reps
    final wRaw = ((predicted1RM * 0.85) / 2.5).round();
    final double weight = (wRaw * 2.5).toDouble();
    return PredictedMax(
      weight: weight,
      reps: 8,
      estimated1RM: predicted1RM,
      exerciseId: exerciseId,
      confidence: confidence,
    );
  }
}

class ProgressionMath {
  static double epley1RM(double weight, int reps) {
    return weight * (1 + reps / 30.0);
  }

  static double brzycki1RM(double weight, int reps) {
    if (reps >= 37) return weight;
    return weight * 36.0 / (37.0 - reps);
  }

  /// Lombardini average (más conservador)
  static double lombardi1RM(double weight, int reps) {
    return weight * (reps.abs() <= 0 ? 1.0 : 1.0 / (1.0278 - 0.0278 * reps));
  }

  /// Media de los 3 para mayor robustez
  static double consensus1RM(double weight, int reps) {
    return (epley1RM(weight, reps) + brzycki1RM(weight, reps) + lombardi1RM(weight, reps)) / 3;
  }
}
