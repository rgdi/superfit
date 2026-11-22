// Sugerencias de nombres de máquinas (Technogym y genéricos) y detector
// de tipo a partir del nombre que escribe el usuario.
//
// IMPORTANTE: los nombres son sugerencias de autocompletado. Cada gimnasio
// tiene modelos distintos; el usuario siempre puede editar nombre, tipo y
// rango de pesos de su máquina real.

class MachineTemplate {
  final String name; // "Chest Press"
  final List<String> typeIds;
  final bool plateLoaded;
  const MachineTemplate(this.name, this.typeIds, {this.plateLoaded = false});
}

/// Líneas de fuerza de Technogym (para prefijar el nombre).
const List<String> kTechnogymLines = [
  'Selection 700',
  'Selection 900',
  'Pure Strength',
  'Element+',
  'Artis',
  'Biostrength',
  'Kinesis',
  'Plurima',
];

/// Nombres típicos de estaciones (en inglés, como aparecen en la máquina).
const List<MachineTemplate> kTechnogymMachines = [
  MachineTemplate('Chest Press', ['chest_press']),
  MachineTemplate('Incline Chest Press', ['incline_chest_press']),
  MachineTemplate('Pectoral', ['pec_deck']),
  MachineTemplate('Rear Delt Row', ['rear_delt']),
  MachineTemplate('Shoulder Press', ['shoulder_press']),
  MachineTemplate('Lateral Raise', ['lateral_raise']),
  MachineTemplate('Lat Machine', ['lat_pulldown']),
  MachineTemplate('Vertical Traction', ['lat_pulldown']),
  MachineTemplate('Pulldown', ['lat_pulldown']),
  MachineTemplate('Low Row', ['seated_row']),
  MachineTemplate('Upper Back', ['seated_row']),
  MachineTemplate('Row', ['seated_row']),
  MachineTemplate('Arm Curl', ['arm_curl']),
  MachineTemplate('Arm Extension', ['arm_extension']),
  MachineTemplate('Abdominal Crunch', ['abdominal_crunch']),
  MachineTemplate('Lower Back', ['back_extension']),
  MachineTemplate('Leg Press', ['leg_press']),
  MachineTemplate('Hack Squat', ['hack_squat'], plateLoaded: true),
  MachineTemplate('Leg Extension', ['leg_extension']),
  MachineTemplate('Leg Curl', ['leg_curl']),
  MachineTemplate('Prone Leg Curl', ['leg_curl']),
  MachineTemplate('Abductor', ['hip_abductor']),
  MachineTemplate('Adductor', ['hip_adductor']),
  MachineTemplate('Glute', ['glute_machine']),
  MachineTemplate('Multi Hip', ['hip_abductor', 'hip_adductor', 'glute_machine']),
  MachineTemplate('Hip Thrust', ['hip_thrust'], plateLoaded: true),
  MachineTemplate('Calf', ['calf_raise']),
  MachineTemplate('Seated Calf', ['seated_calf_raise'], plateLoaded: true),
  MachineTemplate('Dual Adjustable Pulley', ['functional_trainer', 'cable_pulley']),
  MachineTemplate('Cable Station', ['cable_pulley']),
  MachineTemplate('Crossover', ['functional_trainer', 'cable_pulley']),
];

/// Palabras clave (es/en/it) → tipo. El orden importa: lo más específico primero.
const List<(List<String>, List<String>)> _rules = [
  (['incline', 'inclinad'], ['incline_chest_press']),
  (['rear delt', 'reverse fly', 'reverse pec', 'deltoide post', 'posterior', 'aperturas invers'], ['rear_delt']),
  (['multi hip', 'multihip', 'multi-hip'], ['hip_abductor', 'hip_adductor', 'glute_machine']),
  (['adductor', 'aductor', 'adduct'], ['hip_adductor']),
  (['abductor', 'abduct'], ['hip_abductor']),
  (['seated calf', 'gemelo sentado', 'soleo', 'sóleo'], ['seated_calf_raise']),
  (['calf', 'gemel', 'pantorr'], ['calf_raise']),
  (['leg press', 'prensa', 'pressa'], ['leg_press']),
  (['hack', 'sentadilla', 'squat'], ['hack_squat']),
  (['leg ext', 'extension de pierna', 'extensión de pierna', 'extension cuadri', 'cuadriceps', 'cuádriceps'], ['leg_extension']),
  (['leg curl', 'curl femoral', 'femoral', 'isquio', 'hamstring'], ['leg_curl']),
  (['hip thrust', 'empuje de cadera'], ['hip_thrust']),
  (['glute', 'glúteo', 'gluteo', 'kickback', 'patada'], ['glute_machine']),
  (['lower back', 'lumbar', 'back ext', 'hiperext'], ['back_extension']),
  (['abdominal', 'crunch', 'abdomen', 'total abdominal'], ['abdominal_crunch']),
  (['arm curl', 'biceps', 'bíceps', 'scott'], ['arm_curl']),
  (['arm ext', 'triceps', 'tríceps', 'dip'], ['arm_extension']),
  (['lateral raise', 'elevacion lateral', 'elevación lateral', 'delts', 'deltoid'], ['lateral_raise']),
  (['shoulder', 'hombro', 'militar', 'overhead'], ['shoulder_press']),
  (['lat ', 'lat machine', 'pulldown', 'jalon', 'jalón', 'vertical traction', 'traction', 'dorsal'], ['lat_pulldown']),
  (['row', 'remo', 'upper back'], ['seated_row']),
  (['pectoral', 'pec deck', 'peck deck', 'butterfly', 'contractor', 'aperturas', 'fly'], ['pec_deck']),
  (['chest', 'pecho', 'bench', 'press banca'], ['chest_press']),
  (['dual', 'crossover', 'cruce', 'functional', 'kinesis', 'cable cross'], ['functional_trainer', 'cable_pulley']),
  (['pulley', 'polea', 'cable'], ['cable_pulley']),
];

class MachineMatcher {
  /// Devuelve los tipos de catálogo que mejor encajan con el nombre libre.
  /// Lista vacía si no reconoce nada (el usuario lo elige a mano).
  static List<String> guessTypes(String rawName) {
    final name = ' ${rawName.toLowerCase().trim()} ';
    if (name.trim().isEmpty) return const [];
    // 1) Coincidencia con plantilla exacta de nombre
    final byLength = List<MachineTemplate>.of(kTechnogymMachines)
      ..sort((a, b) => b.name.length.compareTo(a.name.length));
    for (final t in byLength) {
      if (name.trim().endsWith(t.name.toLowerCase())) return t.typeIds;
    }
    // 2) Palabras clave
    for (final (keys, types) in _rules) {
      if (keys.any((k) => name.contains(k))) return types;
    }
    return const [];
  }

  /// Sugerencias de autocompletado ("Technogym Selection 700 Chest Press"...)
  static List<String> suggestions(String query, {int max = 8}) {
    final q = query.toLowerCase().trim();
    final out = <String>[];
    for (final m in kTechnogymMachines) {
      final base = 'Technogym ${m.name}';
      if (q.isEmpty || base.toLowerCase().contains(q) || m.name.toLowerCase().contains(q)) {
        out.add(base);
      }
      for (final line in kTechnogymLines) {
        final full = 'Technogym $line ${m.name}';
        if (q.length >= 3 && full.toLowerCase().contains(q)) out.add(full);
      }
      if (out.length >= max * 3) break;
    }
    return out.toSet().take(max).toList();
  }

  static bool isPlateLoaded(String name) {
    final n = name.toLowerCase();
    if (n.contains('pure strength') || n.contains('plate')) return true;
    return kTechnogymMachines.any((t) => t.plateLoaded && n.endsWith(t.name.toLowerCase()));
  }
}
