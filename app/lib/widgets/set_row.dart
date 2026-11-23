// Fila de una serie: peso (solo pesos reales de la máquina), reps, RPE,
// tipo de serie y predicción de la IA. Animada al completar.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_theme.dart';

enum SetKind { warmup, work, backoff, drop }

extension SetKindX on SetKind {
  String get technique => switch (this) {
        SetKind.warmup => 'warmup',
        SetKind.work => 'work',
        SetKind.backoff => 'backoff',
        SetKind.drop => 'drop',
      };
  String get label => switch (this) {
        SetKind.warmup => 'Aproximación',
        SetKind.work => 'Efectiva',
        SetKind.backoff => 'Back-off',
        SetKind.drop => 'Drop set',
      };
  Color get color => switch (this) {
        SetKind.work => Colors.white,
        _ => AppTheme.textMuted,
      };
  static SetKind parse(String? t) => switch (t) {
        'warmup' => SetKind.warmup,
        'backoff' => SetKind.backoff,
        'drop' => SetKind.drop,
        _ => SetKind.work,
      };
}

String fmtKg(double w) =>
    w == w.roundToDouble() ? w.toStringAsFixed(0) : w.toStringAsFixed(2).replaceAll(RegExp(r'0$'), '');

class SetRow extends StatefulWidget {
  final String badge; // "1", "A1", "D"
  final SetKind kind;
  final double weight;
  final int reps;
  final int? rpe;
  final bool completed;
  final List<double> weights; // pesos disponibles en la máquina
  final int rpeHint;
  final String? aiHint; // "IA: ~10 reps"
  final bool highlight; // es la siguiente serie a hacer
  final void Function(double weight, int reps, int? rpe, bool completed) onChanged;
  final VoidCallback? onRemove;

  const SetRow({
    super.key,
    required this.badge,
    required this.kind,
    required this.weight,
    required this.reps,
    this.rpe,
    this.completed = false,
    required this.weights,
    this.rpeHint = 8,
    this.aiHint,
    this.highlight = false,
    required this.onChanged,
    this.onRemove,
  });

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
  late double _w = widget.weight;
  late int _reps = widget.reps;
  late int? _rpe = widget.rpe;
  late bool _done = widget.completed;

  void _emit() => widget.onChanged(_w, _reps, _rpe, _done);

  double _step(int dir) {
    final ws = widget.weights;
    if (ws.isEmpty) return (_w + 2.5 * dir).clamp(0, 999).toDouble();
    return dir > 0
        ? ws.firstWhere((x) => x > _w + 1e-6, orElse: () => ws.last)
        : ws.lastWhere((x) => x < _w - 1e-6, orElse: () => ws.first);
  }

  Future<void> _pickWeight() async {
    final ws = widget.weights;
    var shown = ws;
    if (ws.length > 48) {
      shown = ws.where((x) => x >= _w * 0.6 && x <= _w * 1.4 + 5).toList();
      if (shown.isEmpty) shown = ws;
    }
    final v = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pesos de esta máquina', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final x in shown)
                        ChoiceChip(
                          label: Text(fmtKg(x)),
                          selected: (x - _w).abs() < 1e-6,
                          onSelected: (_) => Navigator.pop(context, x),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (v != null) {
      setState(() => _w = v);
      if (_done) _emit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.kind.color;
    final card = AnimatedContainer(
      duration: 350.ms,
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMid,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: widget.highlight && !_done ? AppTheme.surfaceHigher : Colors.transparent),
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 4),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: 300.ms,
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _done ? Colors.white : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: _done ? Colors.white : AppTheme.surfaceHigher),
                ),
                child: Text(widget.badge,
                    style: TextStyle(fontWeight: FontWeight.w700, color: _done ? Colors.black : c)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _stepper(
                      label: 'kg',
                      value: fmtKg(_w),
                      onTap: _pickWeight,
                      onMinus: () => setState(() {
                        _w = _step(-1);
                        if (_done) _emit();
                      }),
                      onPlus: () => setState(() {
                        _w = _step(1);
                        if (_done) _emit();
                      }),
                    ),
                    _stepper(
                      label: 'reps',
                      value: '$_reps',
                      onMinus: () => setState(() {
                        _reps = (_reps - 1).clamp(0, 100);
                        if (_done) _emit();
                      }),
                      onPlus: () => setState(() {
                        _reps = (_reps + 1).clamp(0, 100);
                        if (_done) _emit();
                      }),
                    ),
                  ],
                ),
              ),
              IconButton(
                iconSize: 36,
                icon: AnimatedSwitcher(
                  duration: 250.ms,
                  transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                  child: Icon(
                    _done ? Icons.check_circle : Icons.radio_button_unchecked,
                    key: ValueKey(_done),
                    color: _done ? Colors.white : AppTheme.textFaint,
                  ),
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _done = !_done;
                  });
                  _emit();
                },
              ),
            ],
          ),
          Row(
            children: [
              if (widget.kind != SetKind.work)
                Text(widget.kind.label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              if (widget.aiHint != null) ...[
                if (widget.kind != SetKind.work) const SizedBox(width: 8),
                Flexible(
                  child: Text(widget.aiHint!,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ),
              ],
              const Spacer(),
              if (widget.kind != SetKind.warmup) ...[
                Text(_rpe == null ? 'RPE —' : 'RPE $_rpe',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _rpe == null ? AppTheme.textFaint : Colors.white)),
                SizedBox(
                  width: 120,
                  child: Slider(
                    value: (_rpe ?? widget.rpeHint).clamp(5, 10).toDouble(),
                    min: 5,
                    max: 10,
                    divisions: 10,
                    onChanged: (v) {
                      setState(() => _rpe = v.round());
                      if (_done) _emit();
                    },
                  ),
                ),
              ],
              if (widget.onRemove != null && !_done)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 16, color: Colors.white38),
                  onPressed: widget.onRemove,
                ),
            ],
          ),
        ],
      ),
    );
    return card;
  }

  Widget _stepper({
    required String label,
    required String value,
    VoidCallback? onTap,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _round(Icons.remove, onMinus),
        GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: 58,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: 200.ms,
                  transitionBuilder: (child, a) => SlideTransition(
                    position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(a),
                    child: FadeTransition(opacity: a, child: child),
                  ),
                  child: Text(value,
                      key: ValueKey(value),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                Text(label,
                    style: const TextStyle(fontSize: 10, color: Colors.white54)),
              ],
            ),
          ),
        ),
        _round(Icons.add, onPlus),
      ],
    );
  }

  Widget _round(IconData icon, VoidCallback onTap) => InkResponse(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 20, color: Colors.white70),
        ),
      );
}
