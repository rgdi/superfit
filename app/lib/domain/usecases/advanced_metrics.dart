// Advanced training metrics: ACWR, Strain, Volume Landmarks, Plateau, RPE×Load
// Basado en:
// - Gabbett 2016 (ACWR y carga de entrenamiento)
// - Hulin 2014 (ACWR y lesión)
// - Zourdos 2016 (RPE-based load)
// - Helms 2014 (Volume landmarks: MEV/MAV/MRV)
import '../../data/models/exercise.dart';
import '../../data/models/set_log.dart';
// use minimal interface for ACWR

class AdvancedMetrics {
  // ... helper: load de una sesión
  static double sessionLoad(List<SetLog> sets) {
    double load = 0;
    for (final s in sets) {
      load += s.weight * s.reps;
    }
    return load;
  }

  // ... RPE-weighted load
  static double sessionLoadRPE(List<SetLog> sets) {
    double load = 0;
    for (final s in sets) {
      final rpe = s.rpe ?? 8.0;
      load += s.weight * s.reps * rpe;
    }
    return load;
  }
}

/// ACWR (Acute:Chronic Workload Ratio)
/// - Acute = carga últimos 7 días
/// - Chronic = carga últimos 28 días (rolling average)
/// Sweet spot 0.8-1.3, peligro si > 1.5 (Hulin 2014, Gabbett 2016)
class ACWR {
  final double acuteLoad;        // total kg×reps últimos 7d
  final double chronicDailyAvg;  // promedio diario últimos 28d
  final double ratio;
  final ACWRZone zone;
  final String message;

  const ACWR({
    required this.acuteLoad,
    required this.chronicDailyAvg,
    required this.ratio,
    required this.zone,
    required this.message,
  });
}

enum ACWRZone {
  underTrained,  // < 0.8
  sweetSpot,     // 0.8-1.3
  highRisk,      // 1.3-1.5
  overtraining,  // > 1.5
}

class ACWRCalculator {
  /// Devuelve el ACWR basado en sesiones cerradas en los últimos 28 días.
  static ACWR compute(List<dynamic> recentSessions, List<List<SetLog>> allSets) {
    if (recentSessions.isEmpty || allSets.isEmpty) {
      return const ACWR(
        acuteLoad: 0,
        chronicDailyAvg: 0,
        ratio: 0,
        zone: ACWRZone.underTrained,
        message: 'Sin datos suficientes',
      );
    }
    final now = DateTime.now();
    final acuteCutoff = now.subtract(const Duration(days: 7));
    final chronicCutoff = now.subtract(const Duration(days: 28));

    double acute = 0;
    double chronic = 0;

    for (int i = 0; i < recentSessions.length; i++) {
      final s = recentSessions[i];
      if (s.endedAt == null) continue;
      final sets = i < allSets.length ? allSets[i] : <SetLog>[];
      final load = AdvancedMetrics.sessionLoadRPE(sets);
      if (s.startedAt.isAfter(acuteCutoff)) {
        acute += load;
      }
      if (s.startedAt.isAfter(chronicCutoff)) {
        chronic += load;
      }
    }

    final chronicDaily = chronic / 28.0;
    final double ratio = chronicDaily > 0 ? ((acute / 7.0) / chronicDaily) : 0.0;
    ACWRZone zone;
    String msg;
    if (ratio == 0) {
      zone = ACWRZone.underTrained;
      msg = 'Sin datos';
    } else if (ratio < 0.8) {
      zone = ACWRZone.underTrained;
      msg = 'Sub-entrenado: considera subir volumen';
    } else if (ratio <= 1.3) {
      zone = ACWRZone.sweetSpot;
      msg = 'Zona óptima: progresión segura';
    } else if (ratio <= 1.5) {
      zone = ACWRZone.highRisk;
      msg = 'Riesgo elevado: reduce 10% esta semana';
    } else {
      zone = ACWRZone.overtraining;
      msg = '¡Peligro! Deload inmediato recomendado';
    }
    return ACWR(
      acuteLoad: acute,
      chronicDailyAvg: chronicDaily,
      ratio: ratio,
      zone: zone,
      message: msg,
    );
  }
}

/// Volume Landmarks: MEV (Minimum Effective Volume), MAV (Maximum Adaptive Volume), MRV (Maximum Recoverable Volume)
/// Helms 2014, equipo Renaissance Periodization
class VolumeLandmarks {
  final int mev;  // sets/semana mínimo
  final int mav;  // sets/semana óptimo
  final int mrv;  // sets/semana máximo
  final int currentSets;
  final VolumeZone zone;
  final String message;

  const VolumeLandmarks({
    required this.mev,
    required this.mav,
    required this.mrv,
    required this.currentSets,
    required this.zone,
    required this.message,
  });
}

enum VolumeZone {
  belowMEV,
  optimal,    // dentro de MAV
  high,       // MAV → MRV
  overreached, // > MRV
}

class VolumeLandmarkCalculator {
  static VolumeLandmarks computeForMuscle(String muscleId, int currentSets) {
    // Landmarks ajustados por grupo muscular (Renaissance Periodization)
    final Map<String, Map<String, int>> landmarks = {
      'chest':       {'mev': 8,  'mav': 14, 'mrv': 22},
      'back':        {'mev': 8,  'mav': 16, 'mrv': 25},
      'shoulders':   {'mev': 6,  'mav': 12, 'mrv': 18},
      'biceps':      {'mev': 4,  'mav': 10, 'mrv': 16},
      'triceps':     {'mev': 4,  'mav': 10, 'mrv': 16},
      'quads':       {'mev': 6,  'mav': 12, 'mrv': 20},
      'hamstrings':  {'mev': 4,  'mav': 10, 'mrv': 16},
      'glutes':      {'mev': 4,  'mav': 10, 'mrv': 16},
      'calves':      {'mev': 6,  'mav': 12, 'mrv': 18},
      'core':        {'mev': 4,  'mav': 10, 'mrv': 16},
    };
    final lm = landmarks[muscleId] ?? {'mev': 6, 'mav': 12, 'mrv': 18};
    VolumeZone zone;
    String msg;
    if (currentSets < lm['mev']!) {
      zone = VolumeZone.belowMEV;
      msg = 'Por debajo del mínimo efectivo';
    } else if (currentSets <= lm['mav']!) {
      zone = VolumeZone.optimal;
      msg = 'Zona de hipertrofia máxima';
    } else if (currentSets <= lm['mrv']!) {
      zone = VolumeZone.high;
      msg = 'Alto volumen: cerca del techo';
    } else {
      zone = VolumeZone.overreached;
      msg = 'Sobrepasado: reduce volumen';
    }
    return VolumeLandmarks(
      mev: lm['mev']!,
      mav: lm['mav']!,
      mrv: lm['mrv']!,
      currentSets: currentSets,
      zone: zone,
      message: msg,
    );
  }
}

/// Plateau detector: 3+ semanas sin progresar en 1RM estimado
class PlateauDetector {
  static bool isPlateau(List<double> epleyHistory) {
    if (epleyHistory.length < 3) return false;
    final last3 = epleyHistory.sublist(epleyHistory.length - 3);
    // Si la variación entre los 3 es < 2.5%
    final maxV = last3.reduce((a, b) => a > b ? a : b);
    final minV = last3.reduce((a, b) => a < b ? a : b);
    if (maxV == 0) return false;
    return ((maxV - minV) / maxV) < 0.025;
  }
}
