// Nombres legibles en español para ids internos (ejercicios, músculos,
// patrones). Se rellena al cargar el catálogo; si falta algo, se humaniza el id.
class Names {
  static final Map<String, String> exercises = {};
  static final Map<String, String> muscles = {};

  static const Map<String, String> patterns = {
    'squat': 'Sentadilla',
    'hinge': 'Bisagra de cadera',
    'horizontal_push': 'Empuje horizontal',
    'vertical_push': 'Empuje vertical',
    'horizontal_pull': 'Tirón horizontal',
    'vertical_pull': 'Tirón vertical',
    'isolation': 'Aislamiento',
  };

  static const Map<String, String> contraindications = {
    'shoulder_impingement': 'pinzamiento de hombro',
    'shoulder_impingement_severe': 'pinzamiento de hombro grave',
    'knee_pain': 'dolor de rodilla',
    'knee_pain_severe': 'dolor de rodilla grave',
    'patellar_tendinopathy': 'tendinopatía rotuliana',
    'lower_back_pain': 'dolor lumbar',
    'lower_back_pain_severe': 'dolor lumbar grave',
    'disc_herniation': 'hernia discal',
    'elbow_tendinopathy': 'tendinopatía de codo',
    'hip_impingement': 'pinzamiento de cadera',
    'cervical_pain': 'dolor cervical',
    'achilles_tendinopathy': 'tendinopatía de Aquiles',
    'hamstring_strain_recent': 'rotura reciente de isquios',
    'groin_strain_recent': 'lesión reciente de ingle',
  };

  static String _human(String id) {
    final t = id.replaceAll('_', ' ').trim();
    return t.isEmpty ? id : t[0].toUpperCase() + t.substring(1);
  }

  static String exercise(String id) => exercises[id] ?? _human(id);
  static String muscle(String id) => muscles[id] ?? _human(id);
  static String pattern(String id) => patterns[id] ?? _human(id);
  static String contraindication(String id) => contraindications[id] ?? _human(id).toLowerCase();
}
