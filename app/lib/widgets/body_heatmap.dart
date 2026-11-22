// Mapa corporal anatómico (frontal + posterior) con mapa de calor.
// Siluetas: react-body-highlighter (MIT), ver anatomy_data.dart.
// Se dibujan con bordes suavizados, sombreado de volumen y brillo en los
// músculos activos. Cada grupo puede representar varios músculos de SuperFit
// (p. ej. CHEST = pectoral clavicular + esternal): su color es la mezcla.
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'anatomy_data.dart';

const Color kBodyBase = Color(0xFF2E2E35);
// El viewBox original es 0..200 en vertical; algunas piezas (pies) se salen un poco.
const double _kTop = 2, _kViewH = 210;
const Color _nonMuscle = Color(0xFF3A3A42);

/// Color de calor: gris (0) → azul → verde (≈1) → naranja → rojo (≥2)
Color heatColor(double v, {Color base = kBodyBase}) {
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

/// Colores para un ejercicio: principales intensos, secundarios suaves.
Map<String, Color> exerciseMuscleColors(Iterable<String> primary, Iterable<String> secondary,
        {Color color = const Color(0xFFFF5A5F)}) =>
    {
      for (final m in secondary) m: Color.lerp(kBodyBase, color, 0.45)!,
      for (final m in primary) m: color,
    };

/// Path suavizado: curvas cuadráticas entre los puntos medios de cada lado.
Path smoothPolygon(List<double> pts, double sx, double sy, {double dx = 0, double dy = 0}) {
  final n = pts.length ~/ 2;
  Offset p(int i) => Offset(pts[(i % n) * 2] * sx + dx, pts[(i % n) * 2 + 1] * sy + dy);
  Offset mid(int i) => Offset.lerp(p(i), p(i + 1), 0.5)!;
  final path = Path()..moveTo(mid(0).dx, mid(0).dy);
  for (int i = 1; i <= n; i++) {
    final c = p(i);
    final m = mid(i);
    path.quadraticBezierTo(c.dx, c.dy, m.dx, m.dy);
  }
  return path..close();
}

class BodyHeatmap extends StatefulWidget {
  final Map<String, Color> colors; // músculo (id SuperFit) → color
  final String? selected; // id de músculo
  final ValueChanged<String>? onTap;
  final double height;
  final bool showLabels;
  final bool frontOnly;
  final bool backOnly;
  const BodyHeatmap({
    super.key,
    required this.colors,
    this.selected,
    this.onTap,
    this.height = 360,
    this.showLabels = true,
    this.frontOnly = false,
    this.backOnly = false,
  });

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
    final views = [
      if (!widget.backOnly) (kAnatomyFront, 'FRONTAL'),
      if (!widget.frontOnly) (kAnatomyBack, 'POSTERIOR'),
    ];
    return SizedBox(
      height: widget.height,
      child: Row(children: [for (final v in views) Expanded(child: _view(v.$1, v.$2))]),
    );
  }

  Widget _view(List<AnatomyPart> parts, String label) {
    return LayoutBuilder(builder: (context, c) {
      final labelH = widget.showLabels ? 16.0 : 0.0;
      final h = math.min(c.maxHeight - labelH, c.maxWidth * 2);
      final size = Size(h / 2, h);
      return Column(children: [
        Expanded(
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) {
                final id = _hit(parts, d.localPosition, size);
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
                    painter: _AnatomyPainter(
                      parts: parts,
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
        if (widget.showLabels)
          SizedBox(
            height: labelH,
            child: Text(label, style: const TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white38)),
          ),
      ]);
    });
  }

  /// Músculo tocado. Si el grupo tiene varios (pecho = 2 porciones), el
  /// segundo toque pasa al siguiente.
  String? _hit(List<AnatomyPart> parts, Offset p, Size s) {
    for (final part in parts.reversed) {
      if (part.muscles.isEmpty) continue;
      for (final poly in part.polygons) {
        if (smoothPolygon(poly, s.width / 100, s.height / _kViewH, dy: s.height * _kTop / _kViewH).contains(p)) {
          final ms = part.muscles;
          final cur = ms.indexOf(widget.selected ?? '');
          if (cur >= 0) return ms[(cur + 1) % ms.length];
          // El más "relevante": el que tiene color asignado
          return ms.firstWhere((m) => widget.colors.containsKey(m), orElse: () => ms.first);
        }
      }
    }
    return null;
  }
}

class _AnatomyPainter extends CustomPainter {
  final List<AnatomyPart> parts;
  final Map<String, Color> colors;
  final String? selected;
  final double appear;
  final double pulse;
  _AnatomyPainter({required this.parts, required this.colors, this.selected, required this.appear, required this.pulse});

  Color? _partColor(AnatomyPart part) {
    final cs = part.muscles.map((m) => colors[m]).whereType<Color>().toList();
    if (cs.isEmpty) return null;
    var r = 0.0, g = 0.0, b = 0.0;
    for (final c in cs) {
      r += c.red;
      g += c.green;
      b += c.blue;
    }
    return Color.fromARGB(255, r ~/ cs.length, g ~/ cs.length, b ~/ cs.length);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 100, sy = size.height / _kViewH, dy = size.height * _kTop / _kViewH;
    final bounds = Offset.zero & size;

    // Sombra suave bajo la figura
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width / 2, size.height * 0.985), width: size.width * 0.55, height: size.height * 0.02),
      Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    for (final part in parts) {
      final active = _partColor(part);
      final isSel = selected != null && part.muscles.contains(selected);
      final base = part.muscles.isEmpty ? _nonMuscle : kBodyBase;
      final color = active == null ? base : Color.lerp(base, active, appear)!;
      for (final poly in part.polygons) {
        final path = smoothPolygon(poly, sx, sy, dy: dy);
        final r = path.getBounds();
        // Brillo exterior en músculos activos
        if (active != null && appear > 0.5) {
          canvas.drawPath(
            path,
            Paint()
              ..color = active.withOpacity(0.35 * appear + (isSel ? 0.3 * pulse : 0))
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, isSel ? 6 + 4 * pulse : 4),
          );
        }
        // Relleno con volumen: luz arriba-izquierda, sombra abajo
        canvas.drawPath(
          path,
          Paint()
            ..shader = ui.Gradient.radial(
              Offset(r.left + r.width * 0.38, r.top + r.height * 0.3),
              math.max(r.width, r.height) * 0.9,
              [Color.lerp(color, Colors.white, active == null ? 0.06 : 0.28)!, color, Color.lerp(color, Colors.black, 0.35)!],
              const [0.0, 0.55, 1.0],
            ),
        );
        // Fibras sutiles en músculos (líneas paralelas al eje largo)
        if (part.muscles.isNotEmpty) {
          canvas.save();
          canvas.clipPath(path);
          final fiber = Paint()
            ..color = Colors.black.withOpacity(0.10)
            ..strokeWidth = 0.6;
          final vertical = r.height >= r.width;
          for (double t = 0.15; t < 1; t += 0.17) {
            if (vertical) {
              final x = r.left + r.width * t;
              canvas.drawLine(Offset(x, r.top), Offset(x + r.width * 0.08, r.bottom), fiber);
            } else {
              final y = r.top + r.height * t;
              canvas.drawLine(Offset(r.left, y), Offset(r.right, y + r.height * 0.08), fiber);
            }
          }
          canvas.restore();
        }
        // Contorno
        canvas.drawPath(
          path,
          Paint()
            ..color = isSel ? Colors.white.withOpacity(0.6 + 0.4 * pulse) : Colors.black.withOpacity(0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSel ? 1.8 : 0.9,
        );
      }
    }
    // Viñeta sutil
    canvas.drawRect(
      bounds,
      Paint()
        ..blendMode = BlendMode.srcATop
        ..shader = ui.Gradient.linear(
          Offset(0, 0),
          Offset(0, size.height),
          [Colors.white.withOpacity(0.04), Colors.transparent, Colors.black.withOpacity(0.10)],
          const [0.0, 0.5, 1.0],
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _AnatomyPainter old) =>
      old.appear != appear || old.pulse != pulse || old.selected != selected || old.colors != colors || old.parts != parts;
}
