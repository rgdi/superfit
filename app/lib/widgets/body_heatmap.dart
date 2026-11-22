// Mapa corporal interactivo (frontal + posterior) con mapa de calor.
// Cada músculo se colorea según un valor 0..∞ (p. ej. series/objetivo o
// recuperación) y se puede tocar.
import 'dart:math' as math;
import 'package:flutter/material.dart';

class _Region {
  final String id;
  final bool front;
  final double cx, cy, rx, ry, rot; // coordenadas normalizadas (0..1)
  final bool mirror;
  const _Region(this.id, this.front, this.cx, this.cy, this.rx, this.ry, {this.rot = 0, this.mirror = true});
}

// Figura en un lienzo de proporción 1:2 (ancho:alto). x se refleja respecto a 0.5.
const List<_Region> _regions = [
  // ---- Frontal
  _Region('trapezius_upper', true, 0.415, 0.142, 0.05, 0.018, rot: -0.45),
  _Region('deltoid_anterior', true, 0.345, 0.195, 0.042, 0.036),
  _Region('deltoid_lateral', true, 0.292, 0.205, 0.028, 0.042, rot: 0.15),
  _Region('pectoralis_major_clavicular', true, 0.435, 0.188, 0.062, 0.022, rot: 0.1),
  _Region('pectoralis_major_sternal', true, 0.435, 0.232, 0.068, 0.034),
  _Region('biceps_brachii', true, 0.272, 0.29, 0.028, 0.058, rot: 0.08),
  _Region('brachialis', true, 0.252, 0.345, 0.018, 0.026, rot: 0.1),
  _Region('rectus_abdominis', true, 0.5, 0.335, 0.042, 0.088, mirror: false),
  _Region('obliques', true, 0.425, 0.345, 0.026, 0.066),
  _Region('quadriceps', true, 0.418, 0.615, 0.045, 0.105, rot: 0.05),
  _Region('adductors', true, 0.478, 0.57, 0.017, 0.055, rot: -0.1),
  _Region('gastrocnemius', true, 0.425, 0.8, 0.026, 0.055, rot: 0.03),
  // ---- Posterior
  _Region('trapezius_upper', false, 0.5, 0.152, 0.085, 0.022, mirror: false),
  _Region('trapezius_middle', false, 0.5, 0.215, 0.07, 0.04, mirror: false),
  _Region('deltoid_posterior', false, 0.318, 0.205, 0.038, 0.034),
  _Region('rhomboids', false, 0.455, 0.235, 0.024, 0.034),
  _Region('latissimus_dorsi', false, 0.41, 0.305, 0.058, 0.075, rot: 0.18),
  _Region('triceps_long', false, 0.282, 0.285, 0.022, 0.058, rot: 0.06),
  _Region('triceps_lateral', false, 0.255, 0.3, 0.016, 0.046, rot: 0.1),
  _Region('erector_spinae', false, 0.475, 0.37, 0.018, 0.068),
  _Region('gluteus_medius', false, 0.405, 0.442, 0.036, 0.022, rot: -0.25),
  _Region('gluteus_maximus', false, 0.445, 0.502, 0.05, 0.04),
  _Region('hamstrings', false, 0.43, 0.63, 0.044, 0.095, rot: 0.04),
  _Region('gastrocnemius', false, 0.43, 0.785, 0.035, 0.058),
  _Region('soleus', false, 0.432, 0.865, 0.026, 0.035),
];

/// Color de calor: gris (0) → azul → verde (≈1) → naranja → rojo (≥2)
Color heatColor(double v, {Color base = const Color(0xFF34343A)}) {
  if (v <= 0.02) return base;
  const stops = [
    (0.0, Color(0xFF2B4C7E)),
    (0.5, Color(0xFF1FA4B8)),
    (1.0, Color(0xFF3DDC84)),
    (1.5, Color(0xFFFFB020)),
    (2.0, Color(0xFFFF4D4D)),
  ];
  final x = v.clamp(0.0, 2.0);
  for (int i = 1; i < stops.length; i++) {
    if (x <= stops[i].$1) {
      final t = (x - stops[i - 1].$1) / (stops[i].$1 - stops[i - 1].$1);
      return Color.lerp(stops[i - 1].$2, stops[i].$2, t)!;
    }
  }
  return stops.last.$2;
}

/// Color de recuperación: rojo (0) → ámbar → verde (1)
Color recoveryColor(double r) => r < 0.5
    ? Color.lerp(const Color(0xFFFF4D4D), const Color(0xFFFFB020), r / 0.5)!
    : Color.lerp(const Color(0xFFFFB020), const Color(0xFF3DDC84), (r - 0.5) / 0.5)!;

class BodyHeatmap extends StatefulWidget {
  final Map<String, Color> colors; // músculo → color
  final String? selected;
  final ValueChanged<String>? onTap;
  final double height;
  const BodyHeatmap({super.key, required this.colors, this.selected, this.onTap, this.height = 360});

  @override
  State<BodyHeatmap> createState() => _BodyHeatmapState();
}

class _BodyHeatmapState extends State<BodyHeatmap> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant BodyHeatmap old) {
    super.didUpdateWidget(old);
    _syncPulse();
  }

  // Solo anima (y repinta) cuando hay un músculo seleccionado
  void _syncPulse() {
    if (widget.selected != null && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (widget.selected == null && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Row(children: [
        Expanded(child: _view(true, 'FRONTAL')),
        Expanded(child: _view(false, 'POSTERIOR')),
      ]),
    );
  }

  Widget _view(bool front, String label) {
    return LayoutBuilder(builder: (context, c) {
      // Lienzo 1:2 centrado
      final h = math.min(c.maxHeight - 18, c.maxWidth * 2);
      final w = h / 2;
      final size = Size(w, h);
      return Column(children: [
        Expanded(
          child: Center(
            child: GestureDetector(
              onTapUp: (d) {
                final id = _hit(d.localPosition, size, front);
                if (id != null) widget.onTap?.call(id);
              },
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, appear, __) => AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => CustomPaint(
                    size: size,
                    painter: _BodyPainter(
                      front: front,
                      colors: widget.colors,
                      selected: widget.selected,
                      appear: appear,
                      pulse: _pulse.value,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white38)),
      ]);
    });
  }

  String? _hit(Offset p, Size s, bool front) {
    for (final r in _regions.reversed.where((r) => r.front == front)) {
      for (final mirrored in r.mirror ? [false, true] : [false]) {
        final cx = (mirrored ? 1 - r.cx : r.cx) * s.width;
        final cy = r.cy * s.height;
        final rot = mirrored ? -r.rot : r.rot;
        final dx = p.dx - cx, dy = p.dy - cy;
        final x = dx * math.cos(-rot) - dy * math.sin(-rot);
        final y = dx * math.sin(-rot) + dy * math.cos(-rot);
        final ex = r.rx * s.width * 1.25, ey = r.ry * s.height * 1.25; // margen táctil
        if ((x * x) / (ex * ex) + (y * y) / (ey * ey) <= 1) return r.id;
      }
    }
    return null;
  }
}

class _BodyPainter extends CustomPainter {
  final bool front;
  final Map<String, Color> colors;
  final String? selected;
  final double appear;
  final double pulse;
  _BodyPainter({required this.front, required this.colors, this.selected, required this.appear, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = Paint()..color = const Color(0xFF26262B);
    final outline = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    void both(void Function(bool m) f) {
      f(false);
      f(true);
    }

    double mx(double x, bool m) => (m ? 1 - x : x) * w;

    // ---- Silueta
    final sil = Path()..addOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.07), width: w * 0.15, height: h * 0.085));
    sil.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.455, h * 0.105, w * 0.545, h * 0.14), Radius.circular(w * 0.03)));
    sil.addRRect(RRect.fromRectAndCorners(Rect.fromLTRB(w * 0.33, h * 0.14, w * 0.67, h * 0.46),
        topLeft: Radius.circular(w * 0.12), topRight: Radius.circular(w * 0.12),
        bottomLeft: Radius.circular(w * 0.06), bottomRight: Radius.circular(w * 0.06)));
    sil.addRRect(RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.36, h * 0.42, w * 0.64, h * 0.54), Radius.circular(w * 0.08)));
    both((m) {
      // brazo y antebrazo
      sil.addRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(math.min(mx(0.235, m), mx(0.315, m)), h * 0.17, math.max(mx(0.235, m), mx(0.315, m)), h * 0.37),
          Radius.circular(w * 0.04)));
      sil.addRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(math.min(mx(0.205, m), mx(0.28, m)), h * 0.355, math.max(mx(0.205, m), mx(0.28, m)), h * 0.5),
          Radius.circular(w * 0.035)));
      sil.addOval(Rect.fromCenter(center: Offset(mx(0.235, m), h * 0.52), width: w * 0.06, height: h * 0.035));
      // pierna
      sil.addRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(math.min(mx(0.365, m), mx(0.495, m)), h * 0.5, math.max(mx(0.365, m), mx(0.495, m)), h * 0.72),
          Radius.circular(w * 0.06)));
      sil.addRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(math.min(mx(0.385, m), mx(0.48, m)), h * 0.7, math.max(mx(0.385, m), mx(0.48, m)), h * 0.93),
          Radius.circular(w * 0.045)));
      sil.addOval(Rect.fromCenter(center: Offset(mx(0.43, m), h * 0.95), width: w * 0.11, height: h * 0.03));
    });
    canvas.drawPath(sil, body);
    canvas.drawPath(sil, outline);

    // ---- Músculos
    for (final r in _regions.where((r) => r.front == front)) {
      final base = colors[r.id] ?? const Color(0xFF34343A);
      final isSel = r.id == selected;
      final c = Color.lerp(const Color(0xFF34343A), base, appear)!;
      for (final m in r.mirror ? [false, true] : [false]) {
        canvas.save();
        canvas.translate(mx(r.cx, m), r.cy * h);
        canvas.rotate(m ? -r.rot : r.rot);
        final rect = Rect.fromCenter(center: Offset.zero, width: r.rx * 2 * w, height: r.ry * 2 * h);
        final paint = Paint()
          ..shader = RadialGradient(
            colors: [Color.lerp(c, Colors.white, 0.18)!, c],
            stops: const [0.0, 1.0],
          ).createShader(rect);
        canvas.drawOval(rect, paint);
        if (isSel) {
          canvas.drawOval(
            rect.inflate(2 + 2 * pulse),
            Paint()
              ..color = Colors.white.withOpacity(0.5 + 0.4 * pulse)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        } else {
          canvas.drawOval(rect, outline);
        }
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BodyPainter old) =>
      old.appear != appear || old.pulse != pulse || old.selected != selected || old.colors != colors || old.front != front;
}
