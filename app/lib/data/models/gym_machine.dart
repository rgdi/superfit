// Máquina real del gimnasio del usuario (p. ej. "Technogym Selection Chest Press").
// Se mapea a uno o varios "tipos" del catálogo (chest_press, leg_curl...)
// para saber qué ejercicios se pueden hacer con ella.
import 'dart:convert';

class GymMachine {
  final String id;
  final String name; // nombre libre que pone el usuario
  final String brand; // Technogym, Life Fitness... (libre)
  final List<String> typeIds; // ids de machines.json
  final double minWeight; // kg (primera placa)
  final double maxWeight; // kg (pila completa)
  final double increment; // kg entre placas
  final String setupNotes; // "Asiento 4 · Respaldo 2"

  const GymMachine({
    required this.id,
    required this.name,
    this.brand = '',
    required this.typeIds,
    this.minWeight = 5,
    this.maxWeight = 100,
    this.increment = 5,
    this.setupNotes = '',
  });

  GymMachine copyWith({
    String? name,
    String? brand,
    List<String>? typeIds,
    double? minWeight,
    double? maxWeight,
    double? increment,
    String? setupNotes,
  }) =>
      GymMachine(
        id: id,
        name: name ?? this.name,
        brand: brand ?? this.brand,
        typeIds: typeIds ?? this.typeIds,
        minWeight: minWeight ?? this.minWeight,
        maxWeight: maxWeight ?? this.maxWeight,
        increment: increment ?? this.increment,
        setupNotes: setupNotes ?? this.setupNotes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'type_ids': typeIds,
        'min_weight': minWeight,
        'max_weight': maxWeight,
        'increment': increment,
        'setup_notes': setupNotes,
      };

  factory GymMachine.fromJson(Map<String, dynamic> j) => GymMachine(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        brand: j['brand'] as String? ?? '',
        typeIds: (j['type_ids'] as List?)?.cast<String>() ?? const [],
        minWeight: (j['min_weight'] as num?)?.toDouble() ?? 5,
        maxWeight: (j['max_weight'] as num?)?.toDouble() ?? 100,
        increment: (j['increment'] as num?)?.toDouble() ?? 5,
        setupNotes: j['setup_notes'] as String? ?? '',
      );

  static String encodeList(List<GymMachine> l) =>
      jsonEncode(l.map((m) => m.toJson()).toList());

  static List<GymMachine> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => GymMachine.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
