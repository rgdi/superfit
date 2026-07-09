// Widget MuscleMapSvg - silueta humana con músculos resaltados
// Renderiza vía CustomPainter (no necesitamos assets SVG externos)
import 'package:flutter/material.dart';
import '../../core/constants/muscle_group.dart';
import '../../core/theme/app_theme.dart';

class MuscleMapPainter extends CustomPainter {
  final Set<String> primaryMuscles; // ids
  final Set<String> secondaryMuscles;
  final String view; // 'front' | 'back'

  MuscleMapPainter({
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.view,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final strokePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final bodyColor = const Color(0xFF3A3A3A);
    final bodyFill = Paint()..color = bodyColor;

    // helper: dibuja un óvalo músculo
    void drawMuscle(Offset center, double rx, double ry, String id) {
      final isPrimary = primaryMuscles.contains(id);
      final isSecondary = secondaryMuscles.contains(id);
      Color c = bodyColor;
      if (isPrimary) {
        c = muscleColorFromId(id);
      } else if (isSecondary) {
        c = muscleColorFromId(id).withOpacity(0.4);
      }
      final p = Paint()..color = c;
      canvas.drawOval(
        Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
        p,
      );
    }

    if (view == 'front') {
      // Cabeza
      canvas.drawCircle(Offset(w * 0.5, h * 0.08), w * 0.08, bodyFill);
      canvas.drawCircle(Offset(w * 0.5, h * 0.08), w * 0.08, strokePaint);

      // Cuello
      final neck = Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.15),
        width: w * 0.10,
        height: h * 0.03,
      );
      canvas.drawRect(neck, bodyFill);
      canvas.drawRect(neck, strokePaint);

      // Tronco
      final torso = Path()
        ..moveTo(w * 0.35, h * 0.17)
        ..lineTo(w * 0.65, h * 0.17)
        ..lineTo(w * 0.62, h * 0.45)
        ..lineTo(w * 0.55, h * 0.55) // cintura
        ..lineTo(w * 0.45, h * 0.55)
        ..lineTo(w * 0.38, h * 0.45)
        ..close();
      canvas.drawPath(torso, bodyFill);
      canvas.drawPath(torso, strokePaint);

      // Pectorales (izq y der)
      drawMuscle(Offset(w * 0.43, h * 0.24), w * 0.08, h * 0.04, 'pectoralis_major_sternal');
      drawMuscle(Offset(w * 0.57, h * 0.24), w * 0.08, h * 0.04, 'pectoralis_major_sternal');
      // Upper chest
      drawMuscle(Offset(w * 0.43, h * 0.20), w * 0.06, h * 0.025, 'pectoralis_major_clavicular');
      drawMuscle(Offset(w * 0.57, h * 0.20), w * 0.06, h * 0.025, 'pectoralis_major_clavicular');

      // Deltoides anteriores
      drawMuscle(Offset(w * 0.34, h * 0.21), w * 0.05, h * 0.04, 'deltoid_anterior');
      drawMuscle(Offset(w * 0.66, h * 0.21), w * 0.05, h * 0.04, 'deltoid_anterior');
      // Deltoides laterales
      drawMuscle(Offset(w * 0.32, h * 0.24), w * 0.04, h * 0.05, 'deltoid_lateral');
      drawMuscle(Offset(w * 0.68, h * 0.24), w * 0.04, h * 0.05, 'deltoid_lateral');

      // Bíceps
      drawMuscle(Offset(w * 0.28, h * 0.32), w * 0.04, h * 0.08, 'biceps_brachii');
      drawMuscle(Offset(w * 0.72, h * 0.32), w * 0.04, h * 0.08, 'biceps_brachii');
      // Antebrazo (braquial)
      drawMuscle(Offset(w * 0.26, h * 0.45), w * 0.035, h * 0.08, 'brachialis');
      drawMuscle(Offset(w * 0.74, h * 0.45), w * 0.035, h * 0.08, 'brachialis');

      // Recto abdominal
      for (int i = 0; i < 4; i++) {
        drawMuscle(
          Offset(w * 0.46, h * 0.30 + i * 0.025),
          w * 0.04, h * 0.018, 'rectus_abdominis',
        );
        drawMuscle(
          Offset(w * 0.54, h * 0.30 + i * 0.025),
          w * 0.04, h * 0.018, 'rectus_abdominis',
        );
      }
      // Oblicuos
      drawMuscle(Offset(w * 0.40, h * 0.34), w * 0.03, h * 0.10, 'obliques');
      drawMuscle(Offset(w * 0.60, h * 0.34), w * 0.03, h * 0.10, 'obliques');

      // Cuádriceps
      drawMuscle(Offset(w * 0.43, h * 0.65), w * 0.07, h * 0.12, 'quadriceps');
      drawMuscle(Offset(w * 0.57, h * 0.65), w * 0.07, h * 0.12, 'quadriceps');

      // Tibia (decorativa)
      // Piernas
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(w * 0.43, h * 0.85), width: w * 0.08, height: h * 0.20),
          const Radius.circular(8),
        ),
        bodyFill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(w * 0.57, h * 0.85), width: w * 0.08, height: h * 0.20),
          const Radius.circular(8),
        ),
        bodyFill,
      );
      // Gemelos (frontales - tibial anterior)
      // (los gemelos reales son back)
    } else {
      // BACK
      // Cabeza
      canvas.drawCircle(Offset(w * 0.5, h * 0.08), w * 0.08, bodyFill);
      canvas.drawCircle(Offset(w * 0.5, h * 0.08), w * 0.08, strokePaint);

      // Trapecio superior
      drawMuscle(Offset(w * 0.5, h * 0.16), w * 0.08, h * 0.04, 'trapezius_upper');
      // Trapecio medio
      drawMuscle(Offset(w * 0.45, h * 0.22), w * 0.08, h * 0.05, 'trapezius_middle');
      drawMuscle(Offset(w * 0.55, h * 0.22), w * 0.08, h * 0.05, 'trapezius_middle');

      // Deltoides posterior
      drawMuscle(Offset(w * 0.32, h * 0.24), w * 0.04, h * 0.05, 'deltoid_posterior');
      drawMuscle(Offset(w * 0.68, h * 0.24), w * 0.04, h * 0.05, 'deltoid_posterior');

      // Dorsales
      drawMuscle(Offset(w * 0.42, h * 0.32), w * 0.08, h * 0.10, 'latissimus_dorsi');
      drawMuscle(Offset(w * 0.58, h * 0.32), w * 0.08, h * 0.10, 'latissimus_dorsi');

      // Romboides (entre trapecio medio y dorsales)
      drawMuscle(Offset(w * 0.45, h * 0.27), w * 0.04, h * 0.03, 'rhomboids');
      drawMuscle(Offset(w * 0.55, h * 0.27), w * 0.04, h * 0.03, 'rhomboids');

      // Tríceps
      drawMuscle(Offset(w * 0.28, h * 0.34), w * 0.04, h * 0.08, 'triceps_lateral');
      drawMuscle(Offset(w * 0.72, h * 0.34), w * 0.04, h * 0.08, 'triceps_lateral');
      drawMuscle(Offset(w * 0.30, h * 0.36), w * 0.03, h * 0.05, 'triceps_long');
      drawMuscle(Offset(w * 0.70, h * 0.36), w * 0.03, h * 0.05, 'triceps_long');

      // Erector espinal (línea central)
      drawMuscle(Offset(w * 0.5, h * 0.40), w * 0.05, h * 0.15, 'erector_spinae');

      // Glúteo mayor
      drawMuscle(Offset(w * 0.43, h * 0.52), w * 0.09, h * 0.06, 'gluteus_maximus');
      drawMuscle(Offset(w * 0.57, h * 0.52), w * 0.09, h * 0.06, 'gluteus_maximus');

      // Isquios
      drawMuscle(Offset(w * 0.43, h * 0.65), w * 0.06, h * 0.12, 'hamstrings');
      drawMuscle(Offset(w * 0.57, h * 0.65), w * 0.06, h * 0.12, 'hamstrings');

      // Gemelos
      drawMuscle(Offset(w * 0.43, h * 0.82), w * 0.06, h * 0.08, 'gastrocnemius');
      drawMuscle(Offset(w * 0.57, h * 0.82), w * 0.06, h * 0.08, 'gastrocnemius');
      // Sóleo
      drawMuscle(Offset(w * 0.43, h * 0.92), w * 0.05, h * 0.05, 'soleus');
      drawMuscle(Offset(w * 0.57, h * 0.92), w * 0.05, h * 0.05, 'soleus');
    }
  }

  @override
  bool shouldRepaint(covariant MuscleMapPainter old) =>
      old.primaryMuscles != primaryMuscles ||
      old.secondaryMuscles != secondaryMuscles ||
      old.view != view;
}

class MuscleMapWidget extends StatelessWidget {
  final Set<String> primaryMuscles;
  final Set<String> secondaryMuscles;
  final String view;
  final double? height;

  const MuscleMapWidget({
    super.key,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    this.view = 'front',
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, height ?? 280),
      painter: MuscleMapPainter(
        primaryMuscles: primaryMuscles,
        secondaryMuscles: secondaryMuscles,
        view: view,
      ),
    );
  }
}
