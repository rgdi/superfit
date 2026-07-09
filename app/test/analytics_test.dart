// Tests unitarios para ProgressionMath y lógica de adaptación
import 'package:flutter_test/flutter_test.dart';
import 'package:superfit/domain/usecases/advanced_analytics.dart';
import 'package:superfit/data/models/exercise.dart';
import 'package:superfit/domain/usecases/progression_service.dart';

void main() {
  group('ProgressionMath', () {
    test('Epley 1RM básico', () {
      expect(ProgressionMath.epley1RM(100, 5), closeTo(116.67, 0.1));
      expect(ProgressionMath.epley1RM(100, 1), closeTo(103.33, 0.1));
      expect(ProgressionMath.epley1RM(100, 10), closeTo(133.33, 0.1));
    });

    test('Brzycki 1RM básico', () {
      expect(ProgressionMath.brzycki1RM(100, 5), closeTo(112.5, 0.1));
      expect(ProgressionMath.brzycki1RM(100, 1), 100.0);
    });

    test('Lombardi 1RM', () {
      expect(ProgressionMath.lombardi1RM(100, 5), isNotNull);
    });

    test('Consensus 1RM es promedio de los 3', () {
      final c = ProgressionMath.consensus1RM(100, 5);
      final expected = (ProgressionMath.epley1RM(100, 5) +
                       ProgressionMath.brzycki1RM(100, 5) +
                       ProgressionMath.lombardi1RM(100, 5)) / 3;
      expect(c, closeTo(expected, 0.1));
    });
  });

  group('ProgressionService.suggestInitialWeight', () {
    test('Squat da peso mayor que bíceps', () {
      final squat = Exercise(
        id: 'test', nameEs: 's', nameEn: 's',
        category: 'compound', pattern: 'squat',
        primaryMuscles: [], secondaryMuscles: [],
        equipmentId: '', imagePath: '',
        instructionsEs: [], instructionsEn: [],
        cuesEs: [], cuesEn: [],
        defaultReps: '8-12', defaultRestSeconds: 120,
        rpeTarget: 8, contraindications: [],
        tempo: '2-1-2-0', sourceResearch: '',
      );
      final biceps = Exercise(
        id: 'test2', nameEs: 'b', nameEn: 'b',
        category: 'isolation', pattern: 'isolation',
        primaryMuscles: [], secondaryMuscles: [],
        equipmentId: '', imagePath: '',
        instructionsEs: [], instructionsEn: [],
        cuesEs: [], cuesEn: [],
        defaultReps: '12-15', defaultRestSeconds: 60,
        rpeTarget: 8, contraindications: [],
        tempo: '2-1-2-0', sourceResearch: '',
      );
      final wSquat = ProgressionService.suggestInitialWeight(squat, level: 'intermediate');
      final wBiceps = ProgressionService.suggestInitialWeight(biceps, level: 'intermediate');
      expect(wSquat, greaterThan(wBiceps));
    });

    test('Advanced > Intermediate > Beginner para mismo ejercicio', () {
      final ex = Exercise(
        id: 'test', nameEs: 's', nameEn: 's',
        category: 'compound', pattern: 'horizontal_push',
        primaryMuscles: [], secondaryMuscles: [],
        equipmentId: '', imagePath: '',
        instructionsEs: [], instructionsEn: [],
        cuesEs: [], cuesEn: [],
        defaultReps: '8-12', defaultRestSeconds: 120,
        rpeTarget: 8, contraindications: [],
        tempo: '2-1-2-0', sourceResearch: '',
      );
      final wAdv = ProgressionService.suggestInitialWeight(ex, level: 'advanced');
      final wInt = ProgressionService.suggestInitialWeight(ex, level: 'intermediate');
      final wBeg = ProgressionService.suggestInitialWeight(ex, level: 'beginner');
      expect(wAdv, greaterThan(wInt));
      expect(wInt, greaterThan(wBeg));
    });

    test('Pesos se redondean a 2.5 kg', () {
      final ex = Exercise(
        id: 'test', nameEs: 's', nameEn: 's',
        category: 'compound', pattern: 'vertical_pull',
        primaryMuscles: [], secondaryMuscles: [],
        equipmentId: '', imagePath: '',
        instructionsEs: [], instructionsEn: [],
        cuesEs: [], cuesEn: [],
        defaultReps: '8-12', defaultRestSeconds: 120,
        rpeTarget: 8, contraindications: [],
        tempo: '2-1-2-0', sourceResearch: '',
      );
      final w = ProgressionService.suggestInitialWeight(ex, level: 'intermediate');
      expect(w % 2.5, 0.0);
    });
  });
}
