// Modelo de Músculo (loaded from assets/data/muscles.json)
class Muscle {
  final String id;
  final String nameEs;
  final String nameEn;
  final String colorHex;
  final String region;
  final String side; // front | back

  const Muscle({
    required this.id,
    required this.nameEs,
    required this.nameEn,
    required this.colorHex,
    required this.region,
    required this.side,
  });

  factory Muscle.fromJson(Map<String, dynamic> j) => Muscle(
    id: j['id'] as String,
    nameEs: j['name_es'] as String,
    nameEn: j['name_en'] as String,
    colorHex: j['color_hex'] as String,
    region: j['region'] as String,
    side: j['side'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name_es': nameEs,
    'name_en': nameEn,
    'color_hex': colorHex,
    'region': region,
    'side': side,
  };
}
