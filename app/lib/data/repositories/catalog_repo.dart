// Repositorio de catálogos (ejercicios, máquinas, músculos) — solo lectura
import '../models/exercise.dart';
import '../models/machine.dart';
import '../models/muscle.dart';
import '../models/routine.dart';
import '../models/routine_plan.dart';
import '../sources/asset_loader.dart';

class CatalogRepo {
  List<Exercise>? _exercises;
  List<Machine>? _machines;
  List<Muscle>? _muscles;
  List<Routine>? _routines;
  RoutinePlan? _plan;

  Future<List<Exercise>> exercises() async {
    _exercises ??= await AssetLoader.loadExercises();
    return _exercises!;
  }

  Future<List<Machine>> machines() async {
    _machines ??= await AssetLoader.loadMachines();
    return _machines!;
  }

  Future<List<Muscle>> muscles() async {
    _muscles ??= await AssetLoader.loadMuscles();
    return _muscles!;
  }

  Future<List<Routine>> routines() async {
    _routines ??= await AssetLoader.loadRoutines();
    return _routines!;
  }

  Future<RoutinePlan> plan() async {
    _plan ??= await AssetLoader.loadPlan();
    return _plan!;
  }

  Future<Exercise?> exerciseById(String id) async {
    final all = await exercises();
    try {
      return all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Machine?> machineById(String id) async {
    final all = await machines();
    try {
      return all.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Routine?> routineById(String id) async {
    final all = await routines();
    try {
      return all.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Encuentra sustitutos de un ejercicio por patrón + músculos primarios
  Future<List<Exercise>> substitutesFor(String exerciseId, {int max = 3}) async {
    final original = await exerciseById(exerciseId);
    if (original == null) return [];
    final all = await exercises();
    final candidates = all.where((e) =>
      e.id != exerciseId &&
      e.pattern == original.pattern
    ).toList();
    // scoring: overlap en músculos primarios
    candidates.sort((a, b) {
      final aOverlap = a.primaryMuscles.where((m) => original.primaryMuscles.contains(m)).length;
      final bOverlap = b.primaryMuscles.where((m) => original.primaryMuscles.contains(m)).length;
      return bOverlap.compareTo(aOverlap);
    });
    return candidates.take(max).toList();
  }
}
