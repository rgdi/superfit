// Carga assets JSON
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/exercise.dart';
import '../models/machine.dart';
import '../models/muscle.dart';
import '../models/routine.dart';
import '../models/routine_plan.dart';

class AssetLoader {
  static const _exercises = 'assets/data/exercises.json';
  static const _machines = 'assets/data/machines.json';
  static const _muscles = 'assets/data/muscles.json';
  static const _plan = 'assets/data/routine_plan.json';

  static const List<String> _routineFiles = [
    'assets/data/routines/upper_a.json',
    'assets/data/routines/upper_b.json',
    'assets/data/routines/lower_a.json',
    'assets/data/routines/lower_b.json',
    'assets/data/routines/deload.json',
    'assets/data/routines/maintenance.json',
  ];

  static Future<List<Exercise>> loadExercises() async {
    final raw = await rootBundle.loadString(_exercises);
    final list = jsonDecode(raw) as List;
    return list.map((e) => Exercise.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<Machine>> loadMachines() async {
    final raw = await rootBundle.loadString(_machines);
    final list = jsonDecode(raw) as List;
    return list.map((e) => Machine.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<Muscle>> loadMuscles() async {
    final raw = await rootBundle.loadString(_muscles);
    final list = jsonDecode(raw) as List;
    return list.map((e) => Muscle.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<Routine>> loadRoutines() async {
    final out = <Routine>[];
    for (final path in _routineFiles) {
      final raw = await rootBundle.loadString(path);
      final map = jsonDecode(raw) as Map<String, dynamic>;
      out.add(Routine.fromJson(map));
    }
    return out;
  }

  static Future<RoutinePlan> loadPlan() async {
    final raw = await rootBundle.loadString(_plan);
    return RoutinePlan.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
