// Empezar una sesión sin dejar otra a medias: si hay una activa, pregunta
// si continuarla o descartarla (antes se acumulaban sesiones "huérfanas"
// cuyas series seguían contando en volumen, récords y el modelo).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';

/// Si hay una sesión activa, pregunta qué hacer.
/// Devuelve: (seguir, idParaReanudar). seguir=false → el usuario canceló.
Future<(bool, String?)> resolveActiveSession(BuildContext context, WidgetRef ref) async {
  final repo = ref.read(sessionRepoProvider);
  final active = await repo.activeSession();
  if (active == null || !context.mounted) return (true, null);
  final choice = await showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Tienes una sesión sin terminar'),
      content: const Text('¿La continúas o la descartas para empezar una nueva? Si la descartas se borran sus series.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, 'discard'), child: const Text('Descartar')),
        FilledButton(onPressed: () => Navigator.pop(context, 'resume'), child: const Text('Continuar')),
      ],
    ),
  );
  if (choice == null) return (false, null);
  if (choice == 'resume') return (true, active.id);
  await repo.deleteSession(active.id);
  ref.invalidate(performanceModelProvider);
  return (true, null);
}

/// Devuelve el id de la sesión a abrir (la nueva o la que ya estaba), o null si se cancela.
Future<String?> startOrResumeSession(BuildContext context, WidgetRef ref, String routineId) async {
  final (go, resumeId) = await resolveActiveSession(context, ref);
  if (!go) return null;
  if (resumeId != null) return resumeId;
  final s = await ref.read(sessionRepoProvider).startSession(routineId);
  return s.id;
}

/// Atajo: empieza (o reanuda) y navega al entreno.
Future<void> startAndOpenSession(BuildContext context, WidgetRef ref, String routineId) async {
  final id = await startOrResumeSession(context, ref, routineId);
  if (id != null && context.mounted) context.push('/workout/$id');
}
