// Persistencia de "mi gimnasio": máquinas, perfil y programa generado.
// Todo en SharedPreferences (JSON) para que viva junto al resto de ajustes
// y se incluya en el backup.
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/generated_program.dart';
import '../models/gym_machine.dart';
import '../models/training_profile.dart';

class GymRepo {
  static const kMachines = 'gym_machines_v1';
  static const kProfile = 'training_profile_v1';
  static const kProgram = 'generated_program_v1';
  static const _uuid = Uuid();

  static String newId() => _uuid.v4();

  Future<List<GymMachine>> machines() async {
    final p = await SharedPreferences.getInstance();
    return GymMachine.decodeList(p.getString(kMachines));
  }

  Future<void> saveMachines(List<GymMachine> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(kMachines, GymMachine.encodeList(list));
  }

  Future<TrainingProfile> profile() async {
    final p = await SharedPreferences.getInstance();
    return TrainingProfile.decode(p.getString(kProfile));
  }

  Future<void> saveProfile(TrainingProfile profile) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(kProfile, profile.encode());
  }

  Future<GeneratedProgram?> program() async {
    final p = await SharedPreferences.getInstance();
    return GeneratedProgram.decode(p.getString(kProgram));
  }

  Future<void> saveProgram(GeneratedProgram? program) async {
    final p = await SharedPreferences.getInstance();
    if (program == null) {
      await p.remove(kProgram);
    } else {
      await p.setString(kProgram, program.encode());
    }
  }

  /// Para backup: devuelve las claves crudas
  Future<Map<String, String?>> exportRaw() async {
    final p = await SharedPreferences.getInstance();
    return {
      kMachines: p.getString(kMachines),
      kProfile: p.getString(kProfile),
      kProgram: p.getString(kProgram),
    };
  }

  Future<void> importRaw(Map<String, dynamic> raw) async {
    final p = await SharedPreferences.getInstance();
    for (final k in [kMachines, kProfile, kProgram]) {
      final v = raw[k];
      if (v is String) await p.setString(k, v);
    }
  }
}
