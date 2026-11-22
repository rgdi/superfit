// Demostración animada de un ejercicio con FOTOS REALES.
// Fotos: Free Exercise DB (dominio público), dos posiciones por ejercicio.
// Se alternan con el ritmo del tempo (fundido corto + zoom suave), con
// indicador de fase y un mini mapa anatómico que late con cada repetición.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../data/models/exercise.dart';
import 'body_heatmap.dart';

String exercisePhoto(String exerciseId, int frame) => 'assets/images/exercise_photos/${exerciseId}_$frame.jpg';

/// Front si el músculo principal se ve de frente.
bool exerciseIsFront(Exercise ex) {
  const front = ['pectoralis', 'deltoid_anterior', 'deltoid_lateral', 'biceps', 'brachialis',
    'rectus_abdominis', 'obliques', 'quadriceps', 'adductors'];
  return ex.primaryMuscles.any((m) => front.any(m.contains));
}

class ExerciseAnimation extends StatefulWidget {
  final Exercise exercise;
  final String? tempo; // "3-1-2-0" (bajada-pausa-subida-pausa)
  final double height;
  final bool showMuscles;
  final bool compact;
  const ExerciseAnimation({
    super.key,
    required this.exercise,
    this.tempo,
    this.height = 230,
    this.showMuscles = true,
    this.compact = false,
  });

  @override
  State<ExerciseAnimation> createState() => _ExerciseAnimationState();
}

class _ExerciseAnimationState extends State<ExerciseAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late double _holdA, _holdB; // segundos en cada posición
  static const double _fade = 0.45;
  bool _paused = false;
  bool _hasPhotos = true;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() {
    final t = (widget.tempo ?? widget.exercise.tempo)
        .split('-')
        .map((x) => double.tryParse(x) ?? 1)
        .toList();
    final ecc = t.isNotEmpty ? t[0] : 2, pb = t.length > 1 ? t[1] : 0, con = t.length > 2 ? t[2] : 1, pt = t.length > 3 ? t[3] : 0;
    // Ritmo de demostración algo más ágil que el real, mínimo 0,7 s por posición
    _holdA = math.max(0.7, (ecc + pb) * 0.45);
    _holdB = math.max(0.7, (con + pt) * 0.45 + 0.3);
    final total = _holdA + _holdB + 2 * _fade;
    _c = AnimationController(vsync: this, duration: Duration(milliseconds: (total * 1000).round()))..repeat();
  }

  @override
  void didUpdateWidget(covariant ExerciseAnimation old) {
    super.didUpdateWidget(old);
    if (old.exercise.id != widget.exercise.id || old.tempo != widget.tempo) {
      _c.dispose();
      _hasPhotos = true;
      _setup();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Opacidad de la foto B (0..1) y fase en el instante v (0..1 del ciclo).
  (double, int) _state(double v) {
    final total = _holdA + _holdB + 2 * _fade;
    final s = v * total;
    if (s < _holdA) return (0, 0);
    if (s < _holdA + _fade) return (Curves.easeInOut.transform((s - _holdA) / _fade), 1);
    if (s < _holdA + _fade + _holdB) return (1, 2);
    return (1 - Curves.easeInOut.transform((s - _holdA - _fade - _holdB) / _fade), 3);
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    if (!_hasPhotos) return _fallback(ex);
    return GestureDetector(
      onTap: () => setState(() {
        _paused = !_paused;
        _paused ? _c.stop() : _c.repeat();
      }),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.compact ? 12 : 18),
        child: SizedBox(
          height: widget.height,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final (b, phase) = _state(_c.value);
              final zoom = 1.0 + 0.035 * math.sin(_c.value * 2 * math.pi);
              final effort = phase == 1 || phase == 3 ? 1.0 : 0.35;
              return Stack(fit: StackFit.expand, children: [
                Transform.scale(
                  scale: zoom,
                  child: Stack(fit: StackFit.expand, children: [
                    Image.asset(exercisePhoto(ex.id, 0), fit: BoxFit.cover, gaplessPlayback: true,
                        errorBuilder: (_, __, ___) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _hasPhotos) setState(() => _hasPhotos = false);
                      });
                      return const SizedBox.shrink();
                    }),
                    Opacity(
                      opacity: b,
                      child: Image.asset(exercisePhoto(ex.id, 1), fit: BoxFit.cover, gaplessPlayback: true,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                    ),
                  ]),
                ),
                // Degradado inferior para legibilidad
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.transparent, Color(0xCC000000)],
                      stops: [0, 0.55, 1],
                    ),
                  ),
                ),
                if (widget.showMuscles && !widget.compact)
                  Positioned(
                    right: 8,
                    top: 8,
                    bottom: 34,
                    width: widget.height * 0.32,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: BodyHeatmap(
                        colors: exerciseMuscleColors(
                          ex.primaryMuscles,
                          ex.secondaryMuscles,
                          color: Color.lerp(const Color(0xFFB03A3E), const Color(0xFFFF5A5F), effort)!,
                        ),
                        showLabels: false,
                        frontOnly: exerciseIsFront(ex),
                        backOnly: !exerciseIsFront(ex),
                        height: widget.height,
                      ),
                    ),
                  ),
                if (!widget.compact)
                  Positioned(
                    left: 12,
                    right: widget.showMuscles ? widget.height * 0.32 + 16 : 12,
                    bottom: 10,
                    child: Row(children: [
                      _phaseChip(phase),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: _c.value,
                            minHeight: 4,
                            backgroundColor: Colors.white24,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(_paused ? Icons.play_arrow : Icons.pause, size: 18, color: Colors.white70),
                    ]),
                  ),
              ]);
            },
          ),
        ),
      ),
    );
  }

  Widget _phaseChip(int phase) {
    final (text, color) = switch (phase) {
      0 => ('Posición inicial', Colors.white70),
      1 => ('Movimiento ▸', AppTheme.primary),
      2 => ('Posición final', Colors.white70),
      _ => ('◂ Vuelta controlada', Colors.amberAccent),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: ValueKey(phase),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ),
    );
  }

  Widget _fallback(Exercise ex) => SizedBox(
        height: widget.height,
        child: BodyHeatmap(
          colors: exerciseMuscleColors(ex.primaryMuscles, ex.secondaryMuscles),
          height: widget.height,
        ),
      );
}

/// Miniatura (primera foto) para listas.
class ExerciseThumb extends StatelessWidget {
  final String exerciseId;
  final double size;
  const ExerciseThumb(this.exerciseId, {super.key, this.size = 56});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          exercisePhoto(exerciseId, 0),
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: (size * 3).round(),
          errorBuilder: (_, __, ___) => Container(
            width: size,
            height: size,
            color: AppTheme.surfaceLight,
            child: const Icon(Icons.fitness_center, color: AppTheme.primary),
          ),
        ),
      );
}
