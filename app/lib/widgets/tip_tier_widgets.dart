// Widgets tip-tier: animated number counter, glass card, confetti burst, shimmer card
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

/// NumberCounter — cuenta desde 0 hasta el valor dado con tween animado
class NumberCounter extends StatelessWidget {
  final num value;
  final TextStyle? style;
  final Duration duration;
  final int decimals;
  final String suffix;

  const NumberCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 1200),
    this.decimals = 0,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final formatted = v.toStringAsFixed(decimals);
        // Remove trailing zeros if decimals=0
        final display = decimals == 0 ? formatted.split('.').first : formatted;
        return Text(
          '$display$suffix',
          style: style,
        );
      },
    );
  }
}

/// GlassCard — efecto glassmorphism con blur
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final double opacity;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 20,
    this.opacity = 0.12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(opacity),
            Colors.white.withOpacity(opacity * 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withOpacity(opacity * 2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// ConfettiBurst — animación de partículas al alcanzar un PR o completar sesión
class ConfettiBurst extends StatefulWidget {
  final bool trigger;
  final int particleCount;
  final VoidCallback? onComplete;

  const ConfettiBurst({
    super.key,
    required this.trigger,
    this.particleCount = 30,
    this.onComplete,
  });

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.trigger) _start();
  }

  @override
  void didUpdateWidget(ConfettiBurst old) {
    super.didUpdateWidget(old);
    if (widget.trigger && !old.trigger) _start();
  }

  void _start() {
    HapticFeedback.heavyImpact();
    final colors = [
      AppTheme.primary,
      AppTheme.accent,
      Colors.amber,
      Colors.pinkAccent,
      Colors.cyanAccent,
    ];
    _particles = List.generate(widget.particleCount, (i) {
      return _Particle(
        color: colors[i % colors.length],
        angle: (i / widget.particleCount) * 6.28 + (i % 3) * 0.5,
        speed: 100 + (i % 5) * 30,
        rotation: i * 0.4,
      );
    });
    _ctrl.forward(from: 0).then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(300, 300),
          painter: _ConfettiPainter(
            particles: _particles,
            progress: _ctrl.value,
          ),
        );
      },
    );
  }
}

class _Particle {
  final Color color;
  final double angle;   // radianes
  final double speed;   // pixeles
  final double rotation;
  _Particle({required this.color, required this.angle, required this.speed, required this.rotation});
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint();
    for (final p in particles) {
      final t = progress;
      final distance = p.speed * t;
      final gravity = 150 * t * t;
      final dx = center.dx + (distance * _cos(p.angle));
      final dy = center.dy + (distance * _sin(p.angle)) + gravity;
      final opacity = (1 - t).clamp(0.0, 1.0);
      paint.color = p.color.withOpacity(opacity);
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.rotation + t * 6.28);
      // rectángulo confetti
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 8, height: 14), paint);
      canvas.restore();
    }
  }

  // helpers sin import math
  double _cos(double r) => _cosLut(r);
  double _sin(double r) => _sinLut(r);

  double _cosLut(double r) {
    // Taylor
    r = r % 6.28318530718;
    return 1 - r * r / 2 + r * r * r * r / 24;
  }

  double _sinLut(double r) {
    r = r % 6.28318530718;
    return r - r * r * r / 6 + r * r * r * r * r / 120;
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.progress != progress;
}

/// PulseButton — botón con animación de pulso continuo (CTA destacada)
class PulseButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color color;
  final double radius;

  const PulseButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color = AppTheme.primary,
    this.radius = 28,
  });

  @override
  State<PulseButton> createState() => _PulseButtonState();
}

class _PulseButtonState extends State<PulseButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final scale = 1 + _ctrl.value * 0.05;
        return Transform.scale(
          scale: scale,
          child: FilledButton(
            onPressed: widget.onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: widget.color,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(widget.radius)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.2),
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
