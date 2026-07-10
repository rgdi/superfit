// SettingsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final notifier = ref.read(userSettingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          const _SectionHeader('Entrenamiento'),
          ListTile(
            title: const Text('Nivel'),
            subtitle: Text(_levelLabel(settings.level)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickLevel(context, ref, settings, notifier),
          ),
          ListTile(
            title: const Text('Objetivo'),
            subtitle: Text(_goalLabel(settings.goal)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickGoal(context, ref, settings, notifier),
          ),
          ListTile(
            title: const Text('Reiniciar plan'),
            subtitle: const Text('Vuelve a la semana 1'),
            trailing: const Icon(Icons.refresh),
            onTap: () async {
              await notifier.update(settings.copyWith(
                planStartDate: DateTime.now(),
                currentWeek: 1,
                currentDeload: false,
              ));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Plan reiniciado.')),
                );
              }
            },
          ),
          const Divider(),
          const _SectionHeader('Preferencias'),
          ListTile(
            title: const Text('Unidades'),
            subtitle: Text(settings.units == WeightUnits.kg ? 'Kilogramos' : 'Libras'),
            trailing: Switch(
              value: settings.units == WeightUnits.lb,
              onChanged: (v) => notifier.update(settings.copyWith(
                units: v ? WeightUnits.lb : WeightUnits.kg,
              )),
            ),
          ),
          ListTile(
            title: const Text('Idioma'),
            subtitle: Text(settings.locale == 'es' ? 'Español' : 'English'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => notifier.update(settings.copyWith(
              locale: settings.locale == 'es' ? 'en' : 'es',
            )),
          ),
          const Divider(),
          const _SectionHeader('Datos'),
          ListTile(
            title: const Text('Resetear todo'),
            subtitle: const Text('Borra sesiones, fotos y métricas. Irreversible.'),
            trailing: const Icon(Icons.delete_forever, color: AppTheme.secondary),
            onTap: () => _confirmReset(context, notifier),
          ),
          const Divider(),
          const _SectionHeader('Acerca de'),
          const ListTile(
            title: Text('SuperFit v1.0.0'),
            subtitle: Text('100% offline · sin tracking · basado en evidencia'),
          ),
          const ListTile(
            title: Text('Referencias científicas'),
            subtitle: Text('Schoenfeld, NSCA, ACSM, Helms (ver research/05)'),
          ),
        ],
      ),
    );
  }

  String _levelLabel(UserLevel l) => switch (l) {
    UserLevel.beginner => 'Principiante',
    UserLevel.intermediate => 'Intermedio',
    UserLevel.advanced => 'Avanzado',
  };

  String _goalLabel(UserGoal g) => switch (g) {
    UserGoal.hypertrophy => 'Hipertrofia',
    UserGoal.strength => 'Fuerza',
    UserGoal.maintenance => 'Mantenimiento',
    UserGoal.definition => 'Definición',
  };

  Future<void> _pickLevel(BuildContext ctx, WidgetRef ref, UserSettings s, UserSettingsNotifier n) async {
    final pick = await showDialog<UserLevel>(
      context: ctx,
      builder: (_) => SimpleDialog(
        title: const Text('Nivel'),
        children: UserLevel.values.map((l) => SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, l),
          child: Text(_levelLabel(l)),
        )).toList(),
      ),
    );
    if (pick != null) await n.update(s.copyWith(level: pick));
  }

  Future<void> _pickGoal(BuildContext ctx, WidgetRef ref, UserSettings s, UserSettingsNotifier n) async {
    final pick = await showDialog<UserGoal>(
      context: ctx,
      builder: (_) => SimpleDialog(
        title: const Text('Objetivo'),
        children: UserGoal.values.map((g) => SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, g),
          child: Text(_goalLabel(g)),
        )).toList(),
      ),
    );
    if (pick != null) await n.update(s.copyWith(goal: pick));
  }

  Future<void> _confirmReset(BuildContext ctx, UserSettingsNotifier n) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('¿Borrar todo?'),
        content: const Text('Esta acción es irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.secondary),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await n.reset();
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Datos borrados. Reinicia la app.')),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
