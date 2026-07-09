// Muscle enums and helpers
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum MuscleGroup {
  chest('chest'),
  shoulder('shoulder'),
  back('back'),
  arms('arm'),
  core('core'),
  legs('leg'),
  glutes('leg');

  final String region;
  const MuscleGroup(this.region);

  String get labelEs {
    switch (this) {
      case MuscleGroup.chest: return 'Pecho';
      case MuscleGroup.shoulder: return 'Hombros';
      case MuscleGroup.back: return 'Espalda';
      case MuscleGroup.arms: return 'Brazos';
      case MuscleGroup.core: return 'Core';
      case MuscleGroup.legs: return 'Piernas';
      case MuscleGroup.glutes: return 'Glúteos';
    }
  }
}

Color muscleColorFromId(String muscleId) {
  // Mapeo directo desde el ID del muscle
  if (muscleId.contains('pectoralis')) return AppTheme.muscleChest;
  if (muscleId.contains('deltoid')) return AppTheme.muscleShoulder;
  if (muscleId.contains('biceps') || muscleId.contains('brachialis')) return AppTheme.muscleArm;
  if (muscleId.contains('triceps')) return AppTheme.muscleTriceps;
  if (muscleId.contains('lat')) return AppTheme.muscleBack;
  if (muscleId.contains('trapezius') || muscleId.contains('rhomboid')) return AppTheme.muscleTrapezius;
  if (muscleId.contains('abdomin') || muscleId.contains('obliqu')) return AppTheme.muscleCore;
  if (muscleId.contains('erector')) return AppTheme.muscleErector;
  if (muscleId.contains('quad')) return AppTheme.muscleQuads;
  if (muscleId.contains('hamstring')) return AppTheme.muscleHamstring;
  if (muscleId.contains('gluteus')) return AppTheme.muscleGlute;
  if (muscleId.contains('gastrocnemius') || muscleId.contains('soleus')) return AppTheme.muscleCalf;
  return Colors.grey;
}
