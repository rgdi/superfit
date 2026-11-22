import 'package:flutter_test/flutter_test.dart';
import 'package:superfit/data/models/gym_machine.dart';
import 'package:superfit/domain/engine/machine_code.dart';

ScanResolution<GymMachine> _resolve(String s, List<GymMachine> ms) => resolveScan<GymMachine>(
      MachineCode.parse(s)!,
      ms,
      codesOf: (m) => m.codes,
      typesOf: (m) => m.typeIds,
      nameOf: (m) => m.name,
    );

void main() {
  test('QR real de una Technogym Artis', () {
    final c = MachineCode.parse('http://s.technogym.com/artis/chest_press')!;
    expect(c.isTechnogym, isTrue);
    expect(c.line, 'Artis');
    expect(c.model, 'Chest Press');
    expect(c.suggestedName, 'Technogym Artis Chest Press');
    expect(c.guessedTypes, ['chest_press']);
    expect(c.raw, 'technogym:artis/chest_press');
  });

  test('variantes: https, mayúsculas, barra final, otras líneas', () {
    expect(MachineCode.parse('HTTPS://S.Technogym.com/Artis/Chest_Press/')!.raw, 'technogym:artis/chest_press');
    final c = MachineCode.parse('http://s.technogym.com/selection900/leg_curl')!;
    expect(c.line, 'Selection 900');
    expect(c.guessedTypes, ['leg_curl']);
    expect(MachineCode.parse('http://s.technogym.com/artis/low_row')!.guessedTypes, ['seated_row']);
  });

  test('código ajeno se guarda tal cual', () {
    final c = MachineCode.parse('mi-pegatina-42')!;
    expect(c.isTechnogym, isFalse);
    expect(c.raw, 'mi-pegatina-42');
    expect(MachineCode.parse('  '), isNull);
  });

  test('resolución: vinculada > probable > desconocida', () {
    const a = GymMachine(id: 'a', name: 'Technogym Artis Chest Press', typeIds: ['chest_press']);
    const b = GymMachine(id: 'b', name: 'Leg Press', typeIds: ['leg_press'], codes: ['technogym:artis/leg_press']);
    expect(_resolve('http://s.technogym.com/artis/leg_press', [a, b]).match, ScanMatch.linked);
    final p = _resolve('http://s.technogym.com/artis/chest_press', [a, b]);
    expect(p.match, ScanMatch.probable);
    expect(p.machine!.id, 'a');
    expect(_resolve('http://s.technogym.com/artis/leg_curl', [a, b]).match, ScanMatch.unknown);
  });

  test('NDEF URI y texto', () {
    final uri = [0x03, ...'s.technogym.com/artis/chest_press'.codeUnits];
    expect(decodeNdefUri(uri), 'http://s.technogym.com/artis/chest_press');
    expect(MachineCode.parse(decodeNdefUri(uri))!.model, 'Chest Press');
    final txt = [0x02, ...'es'.codeUnits, ...'hola'.codeUnits];
    expect(decodeNdefText(txt), 'hola');
  });
}
