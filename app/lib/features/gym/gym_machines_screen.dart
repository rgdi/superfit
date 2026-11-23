// Mis máquinas: el usuario registra las máquinas reales de su gimnasio
// (p. ej. Technogym Selection 700 Chest Press) con su pila de pesos y
// sus ajustes de asiento.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/gym_machine.dart';
import '../../data/models/machine.dart';
import '../../data/repositories/gym_repo.dart';
import '../../domain/engine/machine_matcher.dart';
import 'scan_machine.dart';
import 'machine_history_screen.dart';
import '../../domain/engine/machine_spec.dart';

class GymMachinesScreen extends ConsumerWidget {
  const GymMachinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final machines = ref.watch(gymMachinesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis máquinas'),
        actions: [
          IconButton(
            tooltip: 'Escanear QR / NFC de una máquina',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () async {
              final m = await scanAndResolveMachine(context, ref);
              if (m != null && context.mounted) _openEditor(context, m);
            },
          ),
          IconButton(
            tooltip: 'Añadir circuito Technogym',
            icon: const Icon(Icons.playlist_add),
            onPressed: () => _bulkAdd(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Añadir máquina'),
      ),
      body: FutureBuilder<List<Machine>>(
        future: ref.read(catalogRepoProvider).machines(),
        builder: (context, snap) {
          if (machines.isEmpty) return _empty(context, ref);
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 8, AppTheme.gutter, 96),
            children: [
              Text(
                '${machines.length} máquinas',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 8),
              for (final m in machines) ...[
                InkWell(
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => MachineHistoryScreen(machine: m))),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(m.name.replaceFirst('Technogym ', ''),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (m.brand.isNotEmpty) m.brand,
                              '${_fmt(m.minWeight)}–${_fmt(m.maxWeight)} kg',
                              if (m.setupNotes.isNotEmpty) m.setupNotes,
                            ].join(' · '),
                            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                          ),
                        ]),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz, color: AppTheme.textFaint),
                        onSelected: (v) => v == 'edit'
                            ? _openEditor(context, m)
                            : ref.read(gymMachinesProvider.notifier).remove(m.id),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                          PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                        ],
                      ),
                    ]),
                  ),
                ),
                const Divider(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _empty(BuildContext context, WidgetRef ref) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.store_mall_directory_outlined, size: 64, color: Colors.white38),
              const SizedBox(height: 16),
              const Text(
                'Añade las máquinas de tu gimnasio',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Escribe el nombre tal como aparece en la máquina (p. ej. "Technogym Selection 700 Leg Press"). '
                'La app detecta qué ejercicios permite, usa sus saltos de peso reales y recuerda tu ajuste de asiento.',
                style: TextStyle(color: Colors.white60),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => scanAndResolveMachine(context, ref),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Escanear el QR de una máquina'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _bulkAdd(context, ref),
                icon: const Icon(Icons.playlist_add),
                label: const Text('Añadir un circuito Technogym'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _openEditor(context, null),
                icon: const Icon(Icons.add),
                label: const Text('Añadir una a una'),
              ),
            ],
          ),
        ),
      );

  void _openEditor(BuildContext context, GymMachine? m) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => MachineEditScreen(machine: m)));
  }

  Future<void> _bulkAdd(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<List<GymMachine>>(
      context: context,
      builder: (_) => const _BulkAddDialog(),
    );
    if (result != null && result.isNotEmpty) {
      await ref.read(gymMachinesProvider.notifier).addAll(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${result.length} máquinas añadidas. Revisa el rango de pesos de cada una.'),
        ));
      }
    }
  }
}

String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

// -----------------------------------------------------------------------------

class _BulkAddDialog extends StatefulWidget {
  const _BulkAddDialog();
  @override
  State<_BulkAddDialog> createState() => _BulkAddDialogState();
}

class _BulkAddDialogState extends State<_BulkAddDialog> {
  String _line = kTechnogymLines.first;
  final Set<int> _selected = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Circuito Technogym'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _line,
              decoration: const InputDecoration(labelText: 'Línea'),
              items: [
                for (final l in kTechnogymLines) DropdownMenuItem(value: l, child: Text(l)),
                const DropdownMenuItem(value: '', child: Text('(sin línea)')),
              ],
              onChanged: (v) => setState(() => _line = v ?? ''),
            ),
            const SizedBox(height: 8),
            const Text('Marca las que tiene tu gimnasio:', style: TextStyle(color: Colors.white60, fontSize: 12)),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (int i = 0; i < kTechnogymMachines.length; i++)
                    CheckboxListTile(
                      dense: true,
                      value: _selected.contains(i),
                      title: Text(kTechnogymMachines[i].name),
                      onChanged: (v) => setState(() => v == true ? _selected.add(i) : _selected.remove(i)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _selected.isEmpty
              ? null
              : () {
                  final out = <GymMachine>[];
                  for (final i in _selected.toList()..sort()) {
                    final t = kTechnogymMachines[i];
                    final name = ['Technogym', if (_line.isNotEmpty) _line, t.name].join(' ');
                    final plate = t.plateLoaded || _line == 'Pure Strength';
                    out.add(GymMachine(
                      id: GymRepo.newId(),
                      name: name,
                      brand: 'Technogym',
                      typeIds: t.typeIds,
                      minWeight: plate ? 0 : 5,
                      maxWeight: plate ? 250 : 100,
                      increment: plate ? 2.5 : 5,
                    ));
                  }
                  Navigator.pop(context, out);
                },
          child: Text('Añadir ${_selected.length}'),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------

class MachineEditScreen extends ConsumerStatefulWidget {
  final GymMachine? machine;
  final String? prefillName;
  final List<String> prefillTypes;
  final List<String> prefillCodes;
  const MachineEditScreen({
    super.key,
    this.machine,
    this.prefillName,
    this.prefillTypes = const [],
    this.prefillCodes = const [],
  });
  @override
  ConsumerState<MachineEditScreen> createState() => _MachineEditScreenState();
}

class _MachineEditScreenState extends ConsumerState<MachineEditScreen> {
  late final TextEditingController _name;
  late final TextEditingController _min;
  late final TextEditingController _max;
  late final TextEditingController _inc;
  late final TextEditingController _notes;
  late final TextEditingController _stack;
  late Set<double> _addOns;
  late Set<String> _types;
  bool _typesTouched = false;

  @override
  void initState() {
    super.initState();
    final m = widget.machine;
    _name = TextEditingController(text: m?.name ?? widget.prefillName ?? '');
    _min = TextEditingController(text: _fmt(m?.minWeight ?? 5));
    _max = TextEditingController(text: _fmt(m?.maxWeight ?? 100));
    _inc = TextEditingController(text: _fmt(m?.increment ?? 5));
    _notes = TextEditingController(text: m?.setupNotes ?? '');
    _stack = TextEditingController(text: (m?.stack ?? const []).map(_fmt).join(', '));
    _addOns = {...?m?.addOns};
    _types = {...?m?.typeIds, ...widget.prefillTypes};
    _typesTouched = m != null;
    if (m == null && widget.prefillName != null && MachineMatcher.isPlateLoaded(widget.prefillName!)) {
      _min.text = '0';
      _max.text = '250';
      _inc.text = '2.5';
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _min, _max, _inc, _notes, _stack]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onNameChanged(String v) {
    if (_typesTouched) return;
    final guess = MachineMatcher.guessTypes(v);
    setState(() {
      _types = guess.toSet();
      if (MachineMatcher.isPlateLoaded(v)) {
        _min.text = '0';
        _max.text = '250';
        _inc.text = '2.5';
      }
    });
  }

  double _num(TextEditingController c, double fallback) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? fallback;

  @override
  Widget build(BuildContext context) {
    final numFmt = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    return Scaffold(
      appBar: AppBar(title: Text(widget.machine == null ? 'Nueva máquina' : 'Editar máquina')),
      body: FutureBuilder<List<Machine>>(
        future: ref.read(catalogRepoProvider).machines(),
        builder: (context, snap) {
          final catalog = snap.data ?? const <Machine>[];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _name.text),
                optionsBuilder: (v) => MachineMatcher.suggestions(v.text),
                onSelected: (v) {
                  _name.text = v;
                  _onNameChanged(v);
                },
                fieldViewBuilder: (context, ctrl, focus, onSubmit) {
                  return TextField(
                    controller: ctrl,
                    focusNode: focus,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la máquina',
                      hintText: 'Technogym Selection 700 Chest Press',
                    ),
                    onChanged: (v) {
                      _name.text = v;
                      _onNameChanged(v);
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text('¿Qué ejercicios permite?', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  if (!_typesTouched && _types.isNotEmpty)
                    const Text('detectado', style: TextStyle(color: AppTheme.primary, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Marca uno o varios tipos (p. ej. una "Multi Hip" sirve de abductor, adductor y glúteo).',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final m in catalog)
                    FilterChip(
                      label: Text(m.nameEs),
                      selected: _types.contains(m.id),
                      onSelected: (v) => setState(() {
                        _typesTouched = true;
                        v ? _types.add(m.id) : _types.remove(m.id);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Pila de pesos', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text(
                'Mira la máquina: peso de la primera placa, el total y cuánto sube cada placa.',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: _min, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: numFmt, decoration: const InputDecoration(labelText: 'Mínimo (kg)'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _max, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: numFmt, decoration: const InputDecoration(labelText: 'Máximo (kg)'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _inc, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: numFmt, decoration: const InputDecoration(labelText: 'Salto (kg)'))),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _stack,
                keyboardType: TextInputType.text,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Pesos exactos de la pila (opcional)',
                  hintText: '5, 10, 15, 22.5, 30, 37.5…',
                  helperText: 'Si las placas no suben siempre igual, escríbelas aquí (sustituye mín/máx/salto).',
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: 12),
              const Text('Microcargas (se suman a cualquier placa)', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, children: [
                for (final a in const [1.0, 1.25, 2.0, 2.5, 5.0])
                  FilterChip(
                    label: Text('+${_fmt(a)} kg'),
                    selected: _addOns.contains(a),
                    onSelected: (v) => setState(() => v ? _addOns.add(a) : _addOns.remove(a)),
                  ),
              ]),
              const SizedBox(height: 8),
              _weightsPreview(),
              const SizedBox(height: 20),
              TextField(
                controller: _notes,
                decoration: const InputDecoration(
                  labelText: 'Mi ajuste (opcional)',
                  hintText: 'Asiento 4 · Respaldo 2 · Rango 3',
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  List<double> _parseStack() => parseWeightList(_stack.text);

  MachineSpec _previewSpec() {
    final st = _parseStack();
    return MachineSpec(
      minWeight: _num(_min, 0),
      maxWeight: _num(_max, 100),
      increment: _num(_inc, 2.5).clamp(0.25, 50).toDouble(),
      stack: st.isEmpty ? null : st,
      addOns: _addOns.toList(),
    );
  }

  Widget _weightsPreview() {
    final ws = _previewSpec().weights;
    final shown = ws.length > 24 ? [...ws.take(12), null, ...ws.skip(ws.length - 6)] : ws;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppTheme.surfaceMid, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${ws.length} pesos posibles', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        const SizedBox(height: 6),
        Wrap(spacing: 4, runSpacing: 4, children: [
          for (final w in shown)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(6)),
              child: Text(w == null ? '…' : _fmt(w), style: const TextStyle(fontSize: 11)),
            ),
        ]),
      ]),
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || _types.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pon un nombre y marca al menos un tipo de ejercicio.'),
      ));
      return;
    }
    var min = _num(_min, 0);
    var max = _num(_max, 100);
    if (max < min) (min, max) = (max, min);
    final inc = _num(_inc, 2.5).clamp(0.25, 50).toDouble();
    final m = (widget.machine ?? GymMachine(id: GymRepo.newId(), name: name, typeIds: const [])).copyWith(
      name: name,
      brand: name.toLowerCase().contains('technogym') ? 'Technogym' : '',
      typeIds: _types.toList(),
      minWeight: min,
      maxWeight: max,
      increment: inc,
      setupNotes: _notes.text.trim(),
      stack: _parseStack(),
      addOns: _addOns.toList()..sort(),
      codes: {...?widget.machine?.codes, ...widget.prefillCodes}.toList(),
    );
    await ref.read(gymMachinesProvider.notifier).upsert(m);
    if (mounted) Navigator.pop(context);
  }
}
