// IA local: modelo de rendimiento que aprende SOLO de tus series.
//
// Se entrena en el móvil, sin internet, en milisegundos, cada vez que abres
// un entreno. Nada sale del dispositivo.
//
// Qué aprende:
//  1. Tu fuerza en cada ejercicio *y máquina* (dos Chest Press distintas
//     tienen escalas distintas) y cómo evoluciona: filtro de Kalman sobre
//     log(1RM estimado), con incertidumbre que crece con los días sin entrenar.
//  2. Parámetros personales compartidos (regresión ridge, con prior hacia
//     valores típicos para no sobreajustar con pocos datos):
//       · cuánto rendimiento pierdes por cada serie dentro de un ejercicio
//       · cuánto cambia tu rendimiento según "¿cómo llegas hoy?"
//       · efecto de haber entrenado ese ejercicio hace pocos días
//  3. Tu curva reps↔carga (pendiente de Epley personal) por tipo de ejercicio:
//     hay gente que hace muchas reps con un % alto de su máximo y gente que no.
//
// Cómo se evalúa: backtest — para cada sesión predice las reps de la 1ª serie
// ANTES de verla y compara con lo que hiciste. Se muestra el error real frente
// a la fórmula genérica, para que veas si de verdad aporta.
import 'dart:math' as math;
import '../engine/machine_spec.dart';

class TrainingObs {
  final String exerciseId;
  final String? machineId;
  final bool compound;
  final String sessionId;
  final DateTime at;
  final double weight;
  final int reps;
  final int? rpe;
  final int setIndex; // 0 = primera serie efectiva del ejercicio en la sesión
  final int readiness; // -1 cansado, 0 normal, 1 a tope
  final bool isDrop;

  const TrainingObs({
    required this.exerciseId,
    this.machineId,
    required this.compound,
    required this.sessionId,
    required this.at,
    required this.weight,
    required this.reps,
    this.rpe,
    required this.setIndex,
    this.readiness = 0,
    this.isDrop = false,
  });

  String get key => machineId == null ? exerciseId : '$exerciseId@$machineId';
  double get rir => rpe == null ? 2.0 : (10 - rpe!).clamp(0, 6).toDouble();
}

class _KState {
  double m; // media de log(1RM)
  double p; // varianza
  DateTime last;
  DateTime? lastSession;
  DateTime? prevSession; // sesión anterior a la última
  String? lastSessionId;
  int n = 0;
  final List<(DateTime, double)> history = []; // (fecha, media tras la sesión)
  _KState(this.m, this.p, this.last);
}

class StrengthEstimate {
  final double oneRm;
  final double sd; // desviación relativa (0.05 = ±5%)
  final int observations;
  final double trendPerWeek; // % por semana en las últimas ~4 semanas
  final List<(DateTime, double)> history;
  const StrengthEstimate(this.oneRm, this.sd, this.observations, this.trendPerWeek, this.history);

  /// Sesiones distintas (las series de una misma sesión no son evidencia independiente).
  int get sessions => history.length;
  String get confidence => sessions < 3 ? 'baja' : (sd < 0.05 ? 'alta' : (sd < 0.10 ? 'media' : 'baja'));
  bool get usable => sessions >= 3 && sd < 0.10;
}

class ModelInsights {
  final double fatiguePerSet; // fracción (0.03 = −3% por serie)
  final double readinessEffect; // fracción por nivel
  final double recentTrainingEffect;
  final double slopeCompound; // k personal
  final double slopeIsolation;
  final double? maeModel; // error medio en reps (backtest)
  final double? maeBaseline;
  final int backtestN;
  final int observations;
  const ModelInsights({
    required this.fatiguePerSet,
    required this.readinessEffect,
    required this.recentTrainingEffect,
    required this.slopeCompound,
    required this.slopeIsolation,
    this.maeModel,
    this.maeBaseline,
    required this.backtestN,
    required this.observations,
  });
}

class PerformanceModel {
  // Hiperparámetros (fijos, razonables)
  static const double _qPerDay = 0.00006; // varianza de paseo aleatorio / día (~0,8 %/día)
  static const double _r = 0.035 * 0.035; // ruido de observación (con RPE)
  static const double _rNoRpe = 0.06 * 0.06; // sin RPE
  static const double _p0 = 0.5 * 0.5; // prior muy amplio para un ejercicio nuevo
  static const double kEpley = 1 / 30;
  static const List<double> _kGrid = [1 / 42, 1 / 38, 1 / 34, 1 / 30, 1 / 27, 1 / 24, 1 / 21];

  // Parámetros aprendidos: β = [fatiga/serie, readiness, entreno reciente]
  List<double> beta = [-0.015, 0.02, 0.0];
  static const List<double> _betaPrior = [-0.015, 0.02, 0.0];
  static const List<double> _betaPriorSd = [0.015, 0.02, 0.02];
  double kCompound = kEpley;
  double kIsolation = kEpley;

  final Map<String, _KState> _states = {};
  ModelInsights? insights;
  int _nObs = 0;

  // ------------------------------------------------------------ entrenamiento

  /// Entrena desde cero con todo el historial (orden cronológico).
  static PerformanceModel fit(List<TrainingObs> raw) {
    final obs = raw.where((o) => !o.isDrop && o.weight > 0 && o.reps > 0).toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    final model = PerformanceModel().._nObs = obs.length;
    if (obs.isEmpty) {
      model.insights = model._makeInsights(null, null, 0);
      return model;
    }
    // Curva reps↔carga: se elige la que mejor PREDICE la siguiente sesión
    // (validación one-step-ahead), por coordenadas: compuestos y luego aislados.
    double score(double kc, double ki) {
      model.kCompound = kc;
      model.kIsolation = ki;
      model._fitBeta(obs);
      final (sse, n) = model._oneStepError(obs);
      double pen(double k) {
        final l = math.log(k * 30) / 0.2;
        return 5 * _r * l * l;
      }
      return (n == 0 ? 0 : sse) + pen(kc) + pen(ki);
    }

    final hasC = obs.any((o) => o.compound), hasI = obs.any((o) => !o.compound);
    var bestC = kEpley, bestI = kEpley, best = score(kEpley, kEpley);
    if (hasC) {
      for (final k in _kGrid) {
        final sc = score(k, bestI);
        if (sc < best) {
          best = sc;
          bestC = k;
        }
      }
    }
    if (hasI) {
      for (final k in _kGrid) {
        final sc = score(bestC, k);
        if (sc < best) {
          best = sc;
          bestI = k;
        }
      }
    }
    model.kCompound = bestC;
    model.kIsolation = bestI;
    model._fitBeta(obs);
    final (mae, base, n) = model._runFilterBacktest(obs);
    model.insights = model._makeInsights(mae, base, n);
    return model;
  }

  /// β en dos partes:
  ///  · fatiga/serie: dentro de cada sesión, (y_i − y_0) frente a i (no depende
  ///    de la fuerza, que es constante dentro de la sesión)
  ///  · readiness y entreno reciente: residuo frente a la estimación previa a la sesión
  void _fitBeta(List<TrainingObs> obs) {
    // 1) Fatiga
    final groups = <String, List<TrainingObs>>{};
    for (final o in obs) {
      groups.putIfAbsent('${o.sessionId}|${o.key}', () => []).add(o);
    }
    var sxy = 0.0, sxx = 0.0;
    for (final g in groups.values) {
      if (g.length < 2) continue;
      final y0 = _y(g.first, _k(g.first.compound));
      final i0 = g.first.setIndex;
      for (final o in g.skip(1)) {
        final dx = (o.setIndex - i0).toDouble();
        sxy += dx * (_y(o, _k(o.compound)) - y0);
        sxx += dx * dx;
      }
    }
    final precF = _r * 2 / (_betaPriorSd[0] * _betaPriorSd[0]);
    final fatigue = ((sxy + precF * _betaPrior[0]) / (sxx + precF)).clamp(-0.08, 0.01);
    beta = [fatigue, _betaPrior[1], _betaPrior[2]];

    // 2) Readiness + reciente (2 pasadas para estabilizar)
    for (int it = 0; it < 2; it++) {
      final data = _runFilter(obs, collect: true); // (x, residuo vs pre-sesión, sin fatiga)
      if (data.length < 8) return;
      final a = [
        [0.0, 0.0],
        [0.0, 0.0]
      ];
      final b = [0.0, 0.0];
      for (final (x, e) in data) {
        final xs = [x[1], x[2]];
        for (int i = 0; i < 2; i++) {
          b[i] += xs[i] * e;
          for (int j = 0; j < 2; j++) {
            a[i][j] += xs[i] * xs[j];
          }
        }
      }
      final s2 = _r * 2;
      for (int i = 0; i < 2; i++) {
        final prec = s2 / (_betaPriorSd[i + 1] * _betaPriorSd[i + 1]);
        a[i][i] += prec;
        b[i] += prec * _betaPrior[i + 1];
      }
      final det = a[0][0] * a[1][1] - a[0][1] * a[1][0];
      if (det.abs() < 1e-12) return;
      final r = (b[0] * a[1][1] - b[1] * a[0][1]) / det;
      final c = (a[0][0] * b[1] - a[1][0] * b[0]) / det;
      beta = [fatigue, r.clamp(-0.02, 0.10), c.clamp(-0.10, 0.05)];
    }
  }

  /// Error cuadrático one-step-ahead (log) en la 1ª serie de cada sesión.
  (double, int) _oneStepError(List<TrainingObs> obs) {
    _states.clear();
    var sse = 0.0;
    var n = 0;
    for (final o in obs) {
      final st = _states[o.key];
      final x = _features(o, st);
      final y = _y(o, _k(o.compound)) - _dot(beta, x);
      if (st == null) {
        final s = _KState(y, _p0, o.at);
        _observe(s, o, y);
        _states[o.key] = s;
        continue;
      }
      _predict(st, o.at);
      if (st.lastSessionId != o.sessionId && st.n >= 3) {
        sse += (y - st.m) * (y - st.m);
        n++;
      }
      _observe(st, o, y);
    }
    return (sse, n);
  }

  double _k(bool compound) => compound ? kCompound : kIsolation;

  List<double> _features(TrainingObs o, _KState? st) {
    final daysSince = (st?.lastSession == null || st!.lastSessionId == o.sessionId)
        ? 7.0
        : o.at.difference(st.lastSession!).inHours / 24.0;
    final recent = (3 - daysSince.clamp(0, 3)) / 3; // 1 = ayer, 0 = hace ≥3 días
    return [o.setIndex.clamp(0, 6).toDouble(), o.readiness.toDouble(), recent];
  }

  double _y(TrainingObs o, double k) => math.log(o.weight * (1 + k * (o.reps + o.rir)));

  double _dot(List<double> a, List<double> b) {
    var s = 0.0;
    for (int i = 0; i < a.length; i++) {
      s += a[i] * b[i];
    }
    return s;
  }

  /// Pasa el filtro de Kalman. Si collect: (x, residuo frente a la media
  /// ANTES de la sesión, ya descontada la fatiga por serie).
  List<(List<double>, double)> _runFilter(List<TrainingObs> obs, {bool collect = false}) {
    _states.clear();
    final out = <(List<double>, double)>[];
    final preSession = <String, double>{};
    for (final o in obs) {
      final st = _states[o.key];
      final x = _features(o, st);
      final yRaw = _y(o, _k(o.compound));
      if (st == null) {
        final s = _KState(yRaw - _dot(beta, x), _p0, o.at);
        _observe(s, o, yRaw - _dot(beta, x));
        _states[o.key] = s;
        continue;
      }
      _predict(st, o.at);
      final sk = '${o.sessionId}|${o.key}';
      if (st.lastSessionId != o.sessionId) preSession[sk] = st.m;
      if (collect && st.n >= 3 && preSession.containsKey(sk)) {
        out.add((x, yRaw - beta[0] * x[0] - preSession[sk]!));
      }
      _observe(st, o, yRaw - _dot(beta, x));
    }
    return out;
  }

  void _predict(_KState st, DateTime at) {
    final days = at.difference(st.last).inMinutes / 1440.0;
    if (days > 0) st.p += _qPerDay * days;
    st.last = at;
  }

  void _observe(_KState st, TrainingObs o, double y) {
    final r = o.rpe == null ? _rNoRpe : _r;
    final gain = st.p / (st.p + r);
    st.m += gain * (y - st.m);
    st.p *= (1 - gain);
    st.n++;
    if (st.lastSessionId != o.sessionId) {
      st.prevSession = st.lastSession;
      st.lastSessionId = o.sessionId;
      st.lastSession = o.at;
      st.history.add((o.at, st.m));
    } else if (st.history.isNotEmpty) {
      st.history[st.history.length - 1] = (st.history.last.$1, st.m);
    }
  }

  (double?, double?, int) _runFilterBacktest(List<TrainingObs> obs) {
    _states.clear();
    final lastE1rm = <String, double>{};
    var errM = 0.0, errB = 0.0, n = 0;
    String? prevSessionKey;
    for (final o in obs) {
      final st = _states[o.key];
      final x = _features(o, st);
      final k = _k(o.compound);
      final sessionKey = '${o.sessionId}|${o.key}';
      final firstOfSession = sessionKey != prevSessionKey && o.setIndex == 0;
      if (st != null) _predict(st, o.at);
      if (firstOfSession && st != null && st.n >= 3 && lastE1rm.containsKey(o.key)) {
        final sEff = math.exp(st.m + _dot(beta, x));
        final predM = (sEff / o.weight - 1) / k - o.rir;
        final predB = (lastE1rm[o.key]! / o.weight - 1) * 30 - o.rir;
        errM += (predM - o.reps).abs();
        errB += (predB - o.reps).abs();
        n++;
      }
      final y = _y(o, k) - _dot(beta, x);
      if (st == null) {
        final s = _KState(y, _p0, o.at);
        _observe(s, o, y);
        _states[o.key] = s;
      } else {
        _observe(st, o, y);
      }
      final e = o.weight * (1 + (o.reps + o.rir) / 30);
      if (o.setIndex == 0 || e > (lastE1rm[o.key] ?? 0)) {
        lastE1rm[o.key] = firstOfSession ? e : math.max(e, lastE1rm[o.key] ?? 0);
      }
      prevSessionKey = sessionKey;
    }
    return n == 0 ? (null, null, 0) : (errM / n, errB / n, n);
  }

  ModelInsights _makeInsights(double? mae, double? base, int n) => ModelInsights(
        fatiguePerSet: -beta[0],
        readinessEffect: beta[1],
        recentTrainingEffect: beta[2],
        slopeCompound: kCompound,
        slopeIsolation: kIsolation,
        maeModel: mae,
        maeBaseline: base,
        backtestN: n,
        observations: _nObs,
      );

  // ------------------------------------------------------------ predicción

  bool knows(String exerciseId, String? machineId) =>
      _states.containsKey(machineId == null ? exerciseId : '$exerciseId@$machineId');

  StrengthEstimate? strength(String exerciseId, String? machineId, {DateTime? at}) {
    final st = _states[machineId == null ? exerciseId : '$exerciseId@$machineId'];
    if (st == null) return null;
    final when = at ?? DateTime.now();
    final days = math.max(0, when.difference(st.last).inMinutes / 1440.0);
    final p = st.p + _qPerDay * days;
    // tendencia: regresión de las medias de las últimas 4 semanas
    final recent = st.history.where((h) => when.difference(h.$1).inDays <= 28).toList();
    var trend = 0.0;
    if (recent.length >= 3) {
      final t0 = recent.first.$1;
      final xs = recent.map((h) => h.$1.difference(t0).inHours / 168.0).toList();
      final ys = recent.map((h) => h.$2).toList();
      final mx = xs.reduce((a, b) => a + b) / xs.length, my = ys.reduce((a, b) => a + b) / ys.length;
      var num = 0.0, den = 0.0;
      for (int i = 0; i < xs.length; i++) {
        num += (xs[i] - mx) * (ys[i] - my);
        den += (xs[i] - mx) * (xs[i] - mx);
      }
      if (den > 0) trend = math.exp(num / den) - 1;
    }
    return StrengthEstimate(math.exp(st.m), math.sqrt(p), st.n, trend,
        st.history.map((h) => (h.$1, math.exp(h.$2))).toList());
  }

  double _sEff(String exerciseId, String? machineId, int setIndex, int readiness, DateTime at, {String? sessionId}) {
    final key = machineId == null ? exerciseId : '$exerciseId@$machineId';
    final st = _states[key]!;
    // Dentro de la sesión en curso, "entreno reciente" se mide desde la sesión anterior
    final ref = (sessionId != null && st.lastSessionId == sessionId) ? st.prevSession : st.lastSession;
    final daysSince = ref == null ? 7.0 : at.difference(ref).inHours / 24.0;
    final recent = (3 - daysSince.clamp(0, 3)) / 3;
    return math.exp(st.m + _dot(beta, [setIndex.clamp(0, 6).toDouble(), readiness.toDouble(), recent]));
  }

  /// Reps que harías con `weight` dejando `rir` en reserva.
  double? predictReps(String exerciseId, String? machineId, bool compound, double weight,
      {int setIndex = 0, int readiness = 0, double rir = 2, DateTime? at, String? sessionId}) {
    if (!knows(exerciseId, machineId) || weight <= 0) return null;
    final s = _sEff(exerciseId, machineId, setIndex, readiness, at ?? DateTime.now(), sessionId: sessionId);
    return math.max(0, (s / weight - 1) / _k(compound) - rir);
  }

  /// Peso para hacer `reps` a `rpe`, redondeado a lo que existe en la máquina.
  double? recommendWeight(String exerciseId, String? machineId, bool compound, int reps, int rpe,
      {int setIndex = 0, int readiness = 0, DateTime? at, MachineSpec? spec, String? sessionId}) {
    if (!knows(exerciseId, machineId)) return null;
    final s = _sEff(exerciseId, machineId, setIndex, readiness, at ?? DateTime.now(), sessionId: sessionId);
    final w = s / (1 + _k(compound) * (reps + (10 - rpe).clamp(0, 6)));
    return (spec ?? MachineSpec.generic).round(w, mode: RoundMode.down);
  }

  /// Actualiza en vivo con una serie recién hecha (sin reentrenar todo).
  void observeLive(TrainingObs o) {
    if (o.isDrop || o.weight <= 0 || o.reps <= 0) return;
    final st = _states[o.key];
    final x = _features(o, st);
    final y = _y(o, _k(o.compound)) - _dot(beta, x);
    if (st == null) {
      final s = _KState(y, _p0, o.at);
      _observe(s, o, y);
      _states[o.key] = s;
    } else {
      _predict(st, o.at);
      _observe(st, o, y);
    }
  }

  /// Mejor 1RM estimado histórico para detectar récords.
  static double e1rm(double w, int reps, int? rpe) =>
      w * (1 + (reps + (rpe == null ? 2 : (10 - rpe).clamp(0, 6))) / 30);

  Iterable<String> get keys => _states.keys;
}
