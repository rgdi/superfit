// Interpreta el QR / NFC que llevan las máquinas.
//
// Las Technogym llevan junto al logo NFC un QR con una URL del tipo
//   http://s.technogym.com/artis/chest_press
// = línea + modelo. NO identifica la unidad concreta (dos Chest Press Artis
// tienen el mismo código), pero basta para saber en qué máquina estás.
// Cualquier otro QR/NFC (p. ej. una pegatina propia) se guarda tal cual
// como identificador y se vincula a la máquina que elija el usuario.
import 'machine_matcher.dart';

class MachineCode {
  final String raw; // contenido normalizado (clave de vínculo)
  final String? brand; // "Technogym"
  final String? line; // "Artis"
  final String? model; // "Chest Press"

  const MachineCode({required this.raw, this.brand, this.line, this.model});

  bool get isTechnogym => brand == 'Technogym';

  /// Nombre sugerido: "Technogym Artis Chest Press"
  String? get suggestedName =>
      model == null ? null : [brand, line, model].whereType<String>().join(' ');

  /// Tipos de catálogo deducidos del modelo.
  List<String> get guessedTypes => model == null ? const [] : MachineMatcher.guessTypes(model!);

  static const _lines = {
    'artis': 'Artis',
    'selection': 'Selection',
    'selection700': 'Selection 700',
    'selection_700': 'Selection 700',
    'selection900': 'Selection 900',
    'selection_900': 'Selection 900',
    'purestrength': 'Pure Strength',
    'pure_strength': 'Pure Strength',
    'element': 'Element+',
    'elementplus': 'Element+',
    'element_plus': 'Element+',
    'biostrength': 'Biostrength',
    'kinesis': 'Kinesis',
    'plurima': 'Plurima',
  };

  static MachineCode? parse(String? input) {
    if (input == null) return null;
    final text = input.trim();
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    if (uri != null && uri.host.toLowerCase().endsWith('technogym.com')) {
      final segs = uri.pathSegments.where((s) => s.isNotEmpty).map((s) => s.toLowerCase()).toList();
      final raw = 'technogym:${segs.join('/')}';
      if (segs.length >= 2) {
        final line = _lines[segs[segs.length - 2]] ?? _title(segs[segs.length - 2]);
        return MachineCode(raw: raw, brand: 'Technogym', line: line, model: _title(segs.last));
      }
      if (segs.length == 1) {
        return MachineCode(raw: raw, brand: 'Technogym', model: _title(segs.first));
      }
      return MachineCode(raw: raw, brand: 'Technogym');
    }
    return MachineCode(raw: text);
  }

  static String _title(String slug) => slug
      .split(RegExp(r'[_\-+ ]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

enum ScanMatch { linked, probable, unknown }

class ScanResolution<M> {
  final MachineCode code;
  final ScanMatch match;
  final M? machine;
  const ScanResolution(this.code, this.match, this.machine);
}

/// Busca la máquina del usuario para un código escaneado.
/// 1) vinculada exactamente → linked
/// 2) Technogym cuyo modelo encaja con los tipos de una máquina sin código → probable
/// 3) nada → unknown (proponer crearla)
ScanResolution<M> resolveScan<M>(
  MachineCode code,
  List<M> machines, {
  required List<String> Function(M) codesOf,
  required List<String> Function(M) typesOf,
  required String Function(M) nameOf,
}) {
  for (final m in machines) {
    if (codesOf(m).contains(code.raw)) return ScanResolution(code, ScanMatch.linked, m);
  }
  final types = code.guessedTypes.toSet();
  if (types.isNotEmpty) {
    final cands = machines.where((m) => typesOf(m).toSet().containsAll(types)).toList();
    // Preferir la que coincide también en nombre de modelo y no tiene códigos aún
    int score(M m) {
      final n = nameOf(m).toLowerCase();
      return (code.model != null && n.contains(code.model!.toLowerCase()) ? 2 : 0) +
          (code.line != null && n.contains(code.line!.toLowerCase()) ? 1 : 0) +
          (codesOf(m).isEmpty ? 1 : 0);
    }
    cands.sort((a, b) => score(b).compareTo(score(a)));
    if (cands.isNotEmpty) return ScanResolution(code, ScanMatch.probable, cands.first);
  }
  return ScanResolution(code, ScanMatch.unknown, null);
}

/// Decodifica un registro NDEF de tipo URI ("U"): el primer byte es un
/// prefijo abreviado (0x03 = "http://", 0x04 = "https://", ...).
String? decodeNdefUri(List<int> payload) {
  if (payload.isEmpty) return null;
  const prefixes = [
    '', 'http://www.', 'https://www.', 'http://', 'https://', 'tel:', 'mailto:',
    'ftp://anonymous:anonymous@', 'ftp://ftp.', 'ftps://', 'sftp://', 'smb://',
    'nfs://', 'ftp://', 'dav://', 'news:', 'telnet://', 'imap:', 'rtsp://', 'urn:',
    'pop:', 'sip:', 'sips:', 'tftp:', 'btspp://', 'btl2cap://', 'btgoep://',
    'tcpobex://', 'irdaobex://', 'file://', 'urn:epc:id:', 'urn:epc:tag:',
    'urn:epc:pat:', 'urn:epc:raw:', 'urn:epc:', 'urn:nfc:',
  ];
  final p = payload[0] < prefixes.length ? prefixes[payload[0]] : '';
  return p + String.fromCharCodes(payload.sublist(1));
}

/// Decodifica un registro NDEF de texto ("T"): byte 0 = longitud del idioma.
String? decodeNdefText(List<int> payload) {
  if (payload.isEmpty) return null;
  final langLen = payload[0] & 0x3F;
  if (payload.length <= 1 + langLen) return null;
  return String.fromCharCodes(payload.sublist(1 + langLen));
}
