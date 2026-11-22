// Perfil de entrenamiento: datos que usa el generador de programa.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/training_profile.dart';

class TrainingProfileScreen extends ConsumerWidget {
  const TrainingProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(trainingProfileProvider);
    final n = ref.read(trainingProfileProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil de entrenamiento')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _h('Disponibilidad'),
          _slider(
            label: 'Días por semana',
            value: p.daysPerWeek,
            min: 2,
            max: 6,
            display: '${p.daysPerWeek} días',
            onChanged: (v) => n.update(p.copyWith(daysPerWeek: v)),
          ),
          _slider(
            label: 'Minutos por sesión',
            value: p.sessionMinutes,
            min: 30,
            max: 90,
            divisions: 12,
            display: '${p.sessionMinutes} min',
            onChanged: (v) => n.update(p.copyWith(sessionMinutes: v)),
          ),
          _slider(
            label: 'Duración del bloque (mesociclo)',
            value: p.mesocycleWeeks,
            min: 4,
            max: 6,
            display: '${p.mesocycleWeeks} semanas (la última, descarga)',
            onChanged: (v) => n.update(p.copyWith(mesocycleWeeks: v)),
          ),
          const SizedBox(height: 8),
          _h('Sobre ti (para el peso inicial)'),
          SegmentedButton<Sex>(
            segments: const [
              ButtonSegment(value: Sex.male, label: Text('Hombre')),
              ButtonSegment(value: Sex.female, label: Text('Mujer')),
              ButtonSegment(value: Sex.unspecified, label: Text('Otro / NS')),
            ],
            selected: {p.sex},
            onSelectionChanged: (s) => n.update(p.copyWith(sex: s.first)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  label: 'Peso corporal (kg)',
                  value: p.bodyweightKg?.toStringAsFixed(0),
                  onChanged: (v) => n.update(p.copyWith(bodyweightKg: double.tryParse(v))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumberField(
                  label: 'Edad',
                  value: p.age?.toString(),
                  onChanged: (v) => n.update(p.copyWith(age: int.tryParse(v))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _h('Molestias o lesiones'),
          const Text(
            'Se excluyen los ejercicios que suelen cargar esa zona. Esto NO sustituye a un fisio o médico.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final e in kInjuryLabels.entries)
                FilterChip(
                  label: Text(e.value),
                  selected: p.injuries.contains(e.key),
                  onSelected: (v) => n.update(p.copyWith(
                    injuries: v ? {...p.injuries, e.key} : ({...p.injuries}..remove(e.key)),
                  )),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _h('Músculos prioritarios'),
          const Text(
            'Reciben unas 4 series más por semana. Elige 1-3: priorizar todo es no priorizar nada.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final e in kMuscleGroupLabels.entries)
                FilterChip(
                  label: Text(e.value),
                  selected: p.priorities.contains(e.key),
                  onSelected: (v) => n.update(p.copyWith(
                    priorities: v ? {...p.priorities, e.key} : ({...p.priorities}..remove(e.key)),
                  )),
                ),
            ],
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => context.push('/program'),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Ver / generar mi programa'),
          ),
        ],
      ),
    );
  }

  Widget _h(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 8),
        child: Text(t.toUpperCase(),
            style: const TextStyle(
                color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      );

  Widget _slider({
    required String label,
    required int value,
    required int min,
    required int max,
    int? divisions,
    required String display,
    required ValueChanged<int> onChanged,
  }) {
    final step = divisions == null ? 1 : (max - min) ~/ divisions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(display,
                textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ]),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: divisions ?? (max - min),
          onChanged: (v) {
            final snapped = (min + ((v - min) / step).round() * step).clamp(min, max);
            if (snapped != value) onChanged(snapped);
          },
        ),
      ],
    );
  }
}

class _NumberField extends StatefulWidget {
  final String label;
  final String? value;
  final ValueChanged<String> onChanged;
  const _NumberField({required this.label, required this.value, required this.onChanged});
  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _c = TextEditingController(text: widget.value ?? '');

  @override
  void didUpdateWidget(covariant _NumberField old) {
    super.didUpdateWidget(old);
    // Primera carga asíncrona del perfil
    if (_c.text.isEmpty && (widget.value ?? '').isNotEmpty) _c.text = widget.value!;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: widget.label),
        onChanged: widget.onChanged,
      );
}
