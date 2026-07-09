// ProgressScreen: métricas + 1RM + galería accesos
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/body_metric.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progreso')),
      body: FutureBuilder<List<BodyMetric>>(
        future: ref.read(bodyMetricRepoProvider).all(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final metrics = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _photosEntry(context),
              const SizedBox(height: 16),
              _weightCard(metrics),
              const SizedBox(height: 16),
              _bodyFatCard(metrics),
              const SizedBox(height: 16),
              _measurementsCard(metrics),
              const SizedBox(height: 16),
              _addMetricButton(context, ref),
              const SizedBox(height: 24),
              _top1RMCard(ref),
            ],
          );
        },
      ),
    );
  }

  Widget _photosEntry(BuildContext context) {
    return Card(
      color: AppTheme.primary.withOpacity(0.1),
      child: ListTile(
        leading: const Icon(Icons.photo_library, color: AppTheme.primary, size: 32),
        title: const Text('Galería de fotos', style: TextStyle(fontWeight: FontWeight.w700)),
        subtitle: const Text('Compara tu evolución visual'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/progress/photos'),
      ),
    );
  }

  Widget _weightCard(List<BodyMetric> m) {
    final filtered = m.where((x) => x.weightKg != null).toList();
    if (filtered.isEmpty) {
      return _emptyCard('Peso corporal', 'Añade tu peso para ver evolución', Icons.monitor_weight);
    }
    return _chartCard(
      'Peso (kg)',
      Icons.monitor_weight,
      filtered.map((x) => FlSpot(x.date.millisecondsSinceEpoch.toDouble(), x.weightKg!)).toList(),
      AppTheme.primary,
      unit: 'kg',
    );
  }

  Widget _bodyFatCard(List<BodyMetric> m) {
    final filtered = m.where((x) => x.bodyFatPct != null).toList();
    if (filtered.isEmpty) {
      return _emptyCard('% Grasa', 'Añade tu % grasa para ver evolución', Icons.percent);
    }
    return _chartCard(
      '% Grasa',
      Icons.percent,
      filtered.map((x) => FlSpot(x.date.millisecondsSinceEpoch.toDouble(), x.bodyFatPct!)).toList(),
      AppTheme.secondary,
      unit: '%',
    );
  }

  Widget _measurementsCard(List<BodyMetric> m) {
    if (m.isEmpty) {
      return _emptyCard('Perímetros', 'Añade medidas para ver evolución', Icons.straighten);
    }
    return Card(
      color: AppTheme.surfaceMid,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.straighten, color: AppTheme.primary),
                SizedBox(width: 8),
                Text('Perímetros (cm)', style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            _measurementRow('Pecho', m.map((x) => x.chestCm).toList()),
            _measurementRow('Cintura', m.map((x) => x.waistCm).toList()),
            _measurementRow('Brazo', m.map((x) => x.armCm).toList()),
            _measurementRow('Muslo', m.map((x) => x.thighCm).toList()),
          ],
        ),
      ),
    );
  }

  Widget _measurementRow(String label, List<double?> values) {
    final valid = values.whereType<double>().toList();
    if (valid.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text('$label: sin datos', style: const TextStyle(color: Colors.white60, fontSize: 12)),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '${valid.last.toStringAsFixed(1)} cm  (${valid.first.toStringAsFixed(1)} → ${valid.last.toStringAsFixed(1)})',
            style: TextStyle(
              color: valid.last > valid.first ? AppTheme.secondary : AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String title, String subtitle, IconData icon) {
    return Card(
      color: AppTheme.surfaceMid,
      child: ListTile(
        leading: Icon(icon, color: Colors.white60),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ),
    );
  }

  Widget _chartCard(String title, IconData icon, List<FlSpot> spots, Color color, {String unit = ''}) {
    if (spots.isEmpty) return const SizedBox.shrink();
    return Card(
      color: AppTheme.surfaceMid,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(
                  '${spots.last.y.toStringAsFixed(1)}$unit',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.2)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addMetricButton(BuildContext context, WidgetRef ref) {
    return FilledButton.icon(
      onPressed: () => _addMetricDialog(context, ref),
      icon: const Icon(Icons.add),
      label: const Text('Añadir métrica'),
    );
  }

  Widget _top1RMCard(WidgetRef ref) {
    return Card(
      color: AppTheme.surfaceMid,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top 1RM estimados', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Calculado con fórmula de Epley (peso × (1 + reps/30))',
                style: TextStyle(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 12),
            FutureBuilder(
              future: _calcTop1RMs(ref),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = (snap.data as List<MapEntry<String, double>>)
                  ..sort((a, b) => b.value.compareTo(a.value));
                return Column(
                  children: [
                    for (int i = 0; i < list.take(5).length; i++)
                      ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.surfaceLight,
                          child: Text('${i + 1}'),
                        ),
                        title: Text(list[i].key.replaceAll('_', ' ')),
                        trailing: Text('${list[i].value.toStringAsFixed(1)} kg',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<List<MapEntry<String, double>>> _calcTop1RMs(WidgetRef ref) async {
    final exercises = await ref.read(catalogRepoProvider).exercises();
    final result = <MapEntry<String, double>>[];
    for (final ex in exercises) {
      final oneRm = await ref.read(setRepoProvider).estimated1RM(ex.id);
      if (oneRm != null) result.add(MapEntry(ex.id, oneRm));
    }
    return result;
  }

  Future<void> _addMetricDialog(BuildContext context, WidgetRef ref) async {
    final weight = TextEditingController();
    final bodyFat = TextEditingController();
    final chest = TextEditingController();
    final waist = TextEditingController();
    final arm = TextEditingController();
    final thigh = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nueva métrica'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: weight, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Peso (kg)')),
              const SizedBox(height: 8),
              TextField(controller: bodyFat, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '% Grasa')),
              const SizedBox(height: 8),
              TextField(controller: chest, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Pecho (cm)')),
              const SizedBox(height: 8),
              TextField(controller: waist, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cintura (cm)')),
              const SizedBox(height: 8),
              TextField(controller: arm, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Brazo (cm)')),
              const SizedBox(height: 8),
              TextField(controller: thigh, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Muslo (cm)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(bodyMetricRepoProvider).add(
      date: DateTime.now(),
      weightKg: double.tryParse(weight.text),
      bodyFatPct: double.tryParse(bodyFat.text),
      chestCm: double.tryParse(chest.text),
      waistCm: double.tryParse(waist.text),
      armCm: double.tryParse(arm.text),
      thighCm: double.tryParse(thigh.text),
    );
    if (context.mounted) Navigator.pop(context);
  }
}
