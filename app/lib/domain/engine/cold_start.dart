// Peso inicial cuando no hay historial.
//
// No existe una tabla "científica" de pesos por máquina: cada fabricante
// tiene palancas y poleas distintas (40 kg en un Chest Press Technogym no son
// 40 kg en otro modelo). Por eso esto es deliberadamente CONSERVADOR y sólo
// sirve para la primera serie; el motor recalibra con tu RPE real.
import '../../data/models/exercise.dart';
import '../../data/models/training_profile.dart';
import '../../data/models/user_settings.dart';

/// Fracción del peso corporal para ~10 reps a RPE 6-7 (hombre, intermedio).
const Map<String, double> _bwRatio = {
  'leg_press': 1.0,
  'hack_squat': 0.5,
  'chest_press_machine': 0.4,
  'incline_chest_press_machine': 0.3,
  'shoulder_press_machine': 0.25,
  'lat_pulldown': 0.45,
  'seated_row_machine': 0.45,
  'pec_deck': 0.3,
  'reverse_pec_deck': 0.15,
  'lateral_raise_machine': 0.12,
  'leg_extension': 0.35,
  'leg_curl': 0.3,
  'standing_calf_raise': 0.5,
  'seated_calf_raise': 0.3,
  'hip_thrust_machine': 0.6,
  'hip_abductor': 0.35,
  'hip_adductor_machine': 0.35,
  'glute_kickback_machine': 0.2,
  'back_extension': 0.15,
  'arm_curl_machine': 0.15,
  'arm_extension_machine': 0.2,
  'abdominal_crunch_machine': 0.25,
  'face_pull': 0.12,
  'cable_tricep_pushdown': 0.15,
  'cable_bicep_curl': 0.12,
  'cable_crunch': 0.2,
  'cable_pullover': 0.15,
  'cable_crossover': 0.08,
  'cable_lateral_raise': 0.05,
};

const _lowerBody = {
  'squat', 'hinge',
};

double coldStartWeight(Exercise ex, TrainingProfile p, UserLevel level) {
  final bw = p.bodyweightKg ?? (p.sex == Sex.female ? 62.0 : 75.0);
  final ratio = _bwRatio[ex.id] ?? (ex.category == 'compound' ? 0.35 : 0.15);
  final isLower = _lowerBody.contains(ex.pattern) ||
      ex.primaryMuscles.any((m) => m.startsWith('quad') || m.startsWith('ham') ||
          m.startsWith('glute') || m.startsWith('gastro') || m == 'soleus' || m == 'adductors');
  final sexMult = p.sex == Sex.female ? (isLower ? 0.8 : 0.6) : 1.0;
  final levelMult = switch (level) {
    UserLevel.beginner => 0.65,
    UserLevel.intermediate => 0.9,
    UserLevel.advanced => 1.15,
  };
  final ageMult = (p.age != null && p.age! >= 60) ? 0.8 : 1.0;
  return bw * ratio * sexMult * levelMult * ageMult;
}
