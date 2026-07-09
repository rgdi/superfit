// Timer widget con countdown + haptic
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

class RestTimer extends StatefulWidget {
  final int seconds;
  final VoidCallback? onComplete;
  final void Function(int remaining)? onTick;

  const RestTimer({
    super.key,
    required this.seconds,
    this.onComplete,
    this.onTick,
  });

  @override
  State<RestTimer> createState() => _RestTimerState();
}

class _RestTimerState extends State<RestTimer> with SingleTickerProviderStateMixin {
  late int _remaining;
  late int _total;
  bool _running = false;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _total = widget.seconds;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _start();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _start() {
    setState(() => _running = true);
    _tick();
  }

  void _pause() {
    setState(() => _running = false);
  }

  void _reset() {
    setState(() {
      _remaining = _total;
      _running = false;
    });
  }

  void _addSeconds(int s) {
    setState(() {
      _remaining = (_remaining + s).clamp(0, _total * 2);
    });
  }

  Future<void> _tick() async {
    while (_running && _remaining > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_running) return;
      setState(() => _remaining--);
      widget.onTick?.call(_remaining);
      if (_remaining == 0) {
        HapticFeedback.heavyImpact();
        _running = false;
        widget.onComplete?.call();
        return;
      } else if (_remaining == 3) {
        HapticFeedback.lightImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _total > 0 ? _remaining / _total : 0.0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: AppTheme.surfaceLight,
                      valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                    ),
                  ),
                  Text(
                    '$_remaining',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _running ? 'Descansando...' : (_remaining == 0 ? '¡Listo!' : 'En pausa'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(_running ? Icons.pause : Icons.play_arrow, size: 20),
                        onPressed: _running ? _pause : _start,
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: _reset,
                      ),
                      TextButton(
                        onPressed: () => _addSeconds(15),
                        child: const Text('+15s'),
                      ),
                      TextButton(
                        onPressed: () => _addSeconds(-15),
                        child: const Text('-15s'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
