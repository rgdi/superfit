// Widget visual de progreso con animación — barra de volumen, sparks, anillo de fatiga
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/usecases/advanced_analytics.dart';

class FatigueRing extends StatelessWidget {
  final double fatigue; // 0..1
  final String recommendation;
  const FatigueRing({super.key, required this.fatigue, required this.recommendation});

  Color get _color {
    if (fatigue < 0.3) return AppTheme.primary;
    if (fatigue < 0.6) return AppTheme.rpeMid;
    if (fatigue < 0.8) return AppTheme.rpeHigh;
    return AppTheme.secondary;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surfaceMid,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              height: 90,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: fatigue),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (_, value, __) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 8,
                      backgroundColor: AppTheme.surfaceLight,
                      valueColor: AlwaysStoppedAnimation(_color),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(fatigue * 100).round()}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _color,
                        ),
                      ),
                      const Text('fatiga', style: TextStyle(fontSize: 10, color: Colors.white60)),
                    ],
                  ),
                ],
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_icon, color: _color, size: 20),
                      const SizedBox(width: 6),
                      Text(_label, style: TextStyle(color: _color, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(recommendation, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData get _icon {
    if (fatigue < 0.3) return Icons.flash_on;
    if (fatigue < 0.6) return Icons.directions_run;
    if (fatigue < 0.8) return Icons.warning_amber;
    return Icons.local_fire_department;
  }

  String get _label {
    if (fatigue < 0.3) return 'Recuperado';
    if (fatigue < 0.6) return 'Normal';
    if (fatigue < 0.8) return 'Acumulando';
    return 'Sobrecargado';
  }
}

class GainBadge extends StatelessWidget {
  final double weight;
  final int reps;
  final String exerciseName;
  const GainBadge({super.key, required this.weight, required this.reps, required this.exerciseName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF00BFA5)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.trending_up, color: Colors.black, size: 14),
          const SizedBox(width: 4),
          Text(
            '$weight kg × $reps',
            style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1.0, end: 1.05, duration: 1500.ms, curve: Curves.easeInOut);
  }
}

class StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  const StatChip({super.key, required this.icon, required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: c, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontSize: 9, color: Colors.white60)),
              Text(value, style: TextStyle(color: c, fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}
