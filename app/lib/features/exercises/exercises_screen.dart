// ExercisesScreen: enciclopedia con filtros
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/exercise.dart';

class ExercisesScreen extends ConsumerStatefulWidget {
  const ExercisesScreen({super.key});
  @override
  ConsumerState<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends ConsumerState<ExercisesScreen> {
  String? _filterPattern;
  String? _filterCategory;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(userSettingsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejercicios'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Exercise>>(
        future: ref.read(catalogRepoProvider).exercises(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data!;
          final filtered = all.where((e) {
            if (_filterPattern != null && e.pattern != _filterPattern) return false;
            if (_filterCategory != null && e.category != _filterCategory) return false;
            if (_query.isNotEmpty &&
                !e.nameEs.toLowerCase().contains(_query) &&
                !e.nameEn.toLowerCase().contains(_query)) return false;
            return true;
          }).toList();
          return Column(
            children: [
              _filterRow(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final e = filtered[i];
                    return Card(
                      color: AppTheme.surfaceMid,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        onTap: () => context.push('/exercises/${e.id}'),
                        leading: const Icon(Icons.fitness_center, color: AppTheme.primary),
                        title: Text(e.localizedName(settings.locale)),
                        subtitle: Text(
                          '${e.category == "compound" ? "Compuesto" : "Aislamiento"} · ${e.primaryMuscles.length} músculos',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterRow() {
    Widget chip(String label, String? value, String? current, void Function(String?) set) {
      final selected = value == current;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => set(selected ? null : value),
          backgroundColor: AppTheme.surfaceMid,
          selectedColor: AppTheme.primary.withOpacity(0.2),
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          chip('Todos', null, _filterCategory, (v) => setState(() => _filterCategory = v)),
          chip('Compuestos', 'compound', _filterCategory, (v) => setState(() => _filterCategory = v)),
          chip('Aislamiento', 'isolation', _filterCategory, (v) => setState(() => _filterCategory = v)),
          const SizedBox(width: 12),
          chip('Horizontal push', 'horizontal_push', _filterPattern, (v) => setState(() => _filterPattern = v)),
          chip('Vertical push', 'vertical_push', _filterPattern, (v) => setState(() => _filterPattern = v)),
          chip('Horizontal pull', 'horizontal_pull', _filterPattern, (v) => setState(() => _filterPattern = v)),
          chip('Vertical pull', 'vertical_pull', _filterPattern, (v) => setState(() => _filterPattern = v)),
          chip('Squat', 'squat', _filterPattern, (v) => setState(() => _filterPattern = v)),
          chip('Hinge', 'hinge', _filterPattern, (v) => setState(() => _filterPattern = v)),
        ],
      ),
    );
  }
}
