// Pesos que existen de verdad en una máquina.
//
// Las pilas no siempre suben igual (p. ej. 5, 10, 15, 22.5, 30...) y muchas
// Technogym tienen microcargas (+1,25 / +2,5 kg) que se suman a cualquier placa.
// MachineSpec calcula la lista completa de pesos posibles y redondea a ella.
import 'dart:math' as math;

enum RoundMode { nearest, down, up }

class MachineSpec {
  /// Pesos disponibles, ordenados y sin duplicados.
  final List<double> weights;

  MachineSpec._(this.weights);

  factory MachineSpec({
    double minWeight = 0,
    double maxWeight = 500,
    double increment = 2.5,
    List<double>? stack,
    List<double> addOns = const [],
  }) {
    final base = <double>[];
    if (stack != null && stack.isNotEmpty) {
      base.addAll(stack.where((w) => w >= 0));
    } else {
      final inc = increment <= 0 ? 2.5 : increment;
      final lo = math.min(minWeight, maxWeight), hi = math.max(minWeight, maxWeight);
      for (var w = lo; w <= hi + 1e-9 && base.length < 1000; w += inc) {
        base.add(w);
      }
    }
    // Combinaciones de microcargas (cada una se usa o no)
    final extras = addOns.where((a) => a > 0).take(4).toList();
    final sums = <double>{0};
    for (final a in extras) {
      sums.addAll(sums.map((s) => s + a).toList());
    }
    final all = <double>{
      for (final b in base)
        for (final s in sums) double.parse((b + s).toStringAsFixed(2)),
    }.toList()
      ..sort();
    return MachineSpec._(all.isEmpty ? [0] : all);
  }

  static final MachineSpec generic = MachineSpec();

  double get minWeight => weights.first;
  double get maxWeight => weights.last;

  /// Salto típico (mediana de las diferencias), para mostrar/compatibilidad.
  double get increment {
    if (weights.length < 2) return 2.5;
    final d = [for (int i = 1; i < weights.length; i++) weights[i] - weights[i - 1]]..sort();
    return d[d.length ~/ 2];
  }

  /// Siguiente peso disponible por encima (o el máximo).
  double up(double w) => weights.firstWhere((x) => x > w + 1e-6, orElse: () => maxWeight);

  /// Peso disponible inmediatamente por debajo (o el mínimo).
  double down(double w) => weights.lastWhere((x) => x < w - 1e-6, orElse: () => minWeight);

  double round(double w, {RoundMode mode = RoundMode.nearest}) {
    if (w <= minWeight) return minWeight;
    if (w >= maxWeight) return maxWeight;
    final hiIdx = weights.indexWhere((x) => x >= w - 1e-6);
    final hi = weights[hiIdx];
    if ((hi - w).abs() < 1e-6) return hi;
    final lo = weights[hiIdx - 1];
    return switch (mode) {
      RoundMode.down => lo,
      RoundMode.up => hi,
      RoundMode.nearest => (w - lo) <= (hi - w) ? lo : hi,
    };
  }
}

/// "5, 10, 15, 22,5" / "5 10 22.5" / "5,10,15" / "5; 10; 12,5" → [5, 10, 15, 22.5]
/// Coma seguida de espacio o punto y coma = separador; si además hay espacios,
/// la coma restante es decimal; si no hay espacios, la coma separa.
List<double> parseWeightList(String text) {
  var t = text.replaceAll(';', ' ').replaceAll(RegExp(r',\s+'), ' ').trim();
  if (t.isEmpty) return const [];
  t = t.contains(RegExp(r'\s')) ? t.replaceAll(',', '.') : t.replaceAll(',', ' ');
  return t
      .split(RegExp(r'\s+'))
      .map(double.tryParse)
      .whereType<double>()
      .where((w) => w >= 0)
      .toSet()
      .toList()
    ..sort();
}
