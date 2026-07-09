// Set logger widget: peso + reps + RPE + check
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SetLoggerRow extends StatefulWidget {
  final int setNumber;
  final double initialWeight;
  final int initialReps;
  final int? initialRpe;
  final String? technique; // rest_pause, drop_set, myo_reps, null
  final void Function(double weight, int reps, int? rpe, bool completed) onSave;

  const SetLoggerRow({
    super.key,
    required this.setNumber,
    required this.initialWeight,
    required this.initialReps,
    this.initialRpe,
    this.technique,
    required this.onSave,
  });

  @override
  State<SetLoggerRow> createState() => _SetLoggerRowState();
}

class _SetLoggerRowState extends State<SetLoggerRow> {
  late double _weight;
  late int _reps;
  int? _rpe;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _weight = widget.initialWeight;
    _reps = widget.initialReps;
    _rpe = widget.initialRpe;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _completed ? AppTheme.primary : AppTheme.surfaceLight,
                  radius: 18,
                  child: Text(
                    '${widget.setNumber}',
                    style: TextStyle(
                      color: _completed ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _numStepper(
                        label: 'Peso (kg)',
                        value: _weight.toStringAsFixed(1),
                        onMinus: () => setState(() => _weight = (_weight - 2.5).clamp(0, 500)),
                        onPlus: () => setState(() => _weight = (_weight + 2.5).clamp(0, 500)),
                      ),
                      _numStepper(
                        label: 'Reps',
                        value: '$_reps',
                        onMinus: () => setState(() => _reps = (_reps - 1).clamp(0, 100)),
                        onPlus: () => setState(() => _reps = (_reps + 1).clamp(0, 100)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _completed ? Icons.check_circle : Icons.check_circle_outline,
                    color: _completed ? AppTheme.primary : Colors.white60,
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() => _completed = !_completed);
                    widget.onSave(_weight, _reps, _rpe, _completed);
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('RPE:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: (_rpe ?? 8).toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _rpe == null ? '—' : '$_rpe',
                    onChanged: (v) {
                      setState(() => _rpe = v.round());
                      widget.onSave(_weight, _reps, _rpe, _completed);
                    },
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _rpe == null ? Colors.transparent : AppTheme.rpeColor(_rpe!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _rpe == null ? '—' : '$_rpe',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _numStepper({
    required String label,
    required String value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 4),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 24),
              onPressed: onMinus,
              color: Colors.white70,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            SizedBox(
              width: 48,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 24),
              onPressed: onPlus,
              color: Colors.white70,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ],
    );
  }
}
