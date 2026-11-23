// "Mi IA": qué ha aprendido el modelo local, cuánto acierta y su estimación
// por ejercicio. Todo calculado en el móvil.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/exercise.dart';
import '../../data/models/gym_machine.dart';
import '../../domain/ai/performance_model.dart';
import '../../widgets/tip_tier_widgets.dart';

class AiScreen extends ConsumerWidget {
  const AiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelAsync = ref.watch(performanceModelProvider);
    final machines = ref.watch(gymMachinesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu modelo'),
        actions: [
          IconButton(
            tooltip: 'Reentrenar',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(performanceModelProvider),
          ),
        ],
      ),
      body: modelAsync.when(
        loading: () => const Center(child: _Training()),
        error: (e, _) => Center(child: Text('No se pudo entrenar: $e')),
        data: (m) => FutureBuilder<List<Exercise>>(
          future: ref.read(catalogRepoProvider).exercises(),
          builder: (context, snap) => _content(m, {for (final e in snap.data ?? <Exercise>[]) e.id: e}, machines),
        ),
      ),
    );
  }

  Widget _content(PerformanceModel m, Map<String, Exercise> catalog, List<GymMachine> machines) {
    final ins = m.insights!;
    final items = <Widget>[
      _hero(ins),
      if (ins.observations > 0) _accuracy(ins),
      if (ins.observations > 0) _learned(ins),
      ..._exercises(m, catalog, machines),
      _privacy(),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (int i = 0; i < items.length; i++)
          items[i].animate().fadeIn(delay: (90 * i).ms, duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOut),
      ],
    );
  }

  Widget _hero(ModelInsights ins) {
    final level = ins.observations < 30
        ? ('Aprendiendo', 'Necesita unas 3-4 sesiones por ejercicio para afinar. Mientras, mandan las reglas.')
        : ins.observations < 150
            ? ('Conociéndote', 'Ya ajusta pesos en los ejercicios que más repites.')
            : ('Te conoce', 'Ajusta pesos y predice reps en casi todo tu programa.');
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${ins.observations}', style: AppTheme.number.copyWith(fontSize: 52, fontWeight: FontWeight.w700, height: 1)),
        const Text('series aprendidas', style: TextStyle(fontSize: 15, color: AppTheme.textMuted)),
        const SizedBox(height: 16),
        Text(level.$1, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(level.$2, style: const TextStyle(fontSize: 14, color: AppTheme.textMuted, height: 1.45)),
      ]),
    );
  }

  Widget _accuracy(ModelInsights ins) {
    final card = _card(
      title: '¿Acierta?',
      children: [
        if (ins.maeModel == null)
          const Text('Aún no hay sesiones suficientes para medirlo (hacen falta ≥3 por ejercicio).',
              style: TextStyle(color: Colors.white60, fontSize: 13))
        else ...[
          Text(
            'Predice las reps de tu 1ª serie con un error medio de ±${ins.maeModel!.toStringAsFixed(1)} reps '
            '(fórmula genérica: ±${ins.maeBaseline!.toStringAsFixed(1)}). Medido en ${ins.backtestN} sesiones, '
            'prediciendo cada una antes de verla.',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          _bar('Modelo', ins.maeModel!, ins.maeBaseline!, Colors.white),
          const SizedBox(height: 6),
          _bar('Fórmula', ins.maeBaseline!, ins.maeBaseline!, AppTheme.surfaceHigher),
          if (ins.maeModel! >= ins.maeBaseline!)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('De momento no mejora a la fórmula: con más datos debería. Mientras, el peso lo deciden las reglas.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
            ),
        ],
      ],
    );
    return card;
  }

  Widget _bar(String label, double v, double ref, Color c) {
    final frac = (v / (ref * 1.15)).clamp(0.05, 1.0);
    return Row(children: [
      SizedBox(width: 64, child: Text(label, style: const TextStyle(fontSize: 12))),
      Expanded(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: frac),
          duration: 1000.ms,
          curve: Curves.easeOutCubic,
          builder: (_, f, __) => Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: f,
              child: Container(height: 12, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6))),
            ),
          ),
        ),
      ),
      SizedBox(width: 56, child: Text('±${v.toStringAsFixed(1)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
    ]);
  }

  Widget _learned(ModelInsights ins) {
    String pct(double x) => '${(x * 100).toStringAsFixed(1)} %';
    String curve(double k) {
      final rel = k * 30;
      if ((rel - 1).abs() < 0.06) return 'como la media';
      return rel > 1 ? 'aguantas más reps que la media con el mismo % de tu máximo' : 'haces menos reps que la media con el mismo %';
    }

    return _card(title: 'Lo que ha aprendido de ti', children: [
      _fact('Fatiga entre series', 'Pierdes ~${pct(ins.fatiguePerSet)} de rendimiento por serie',
          'Por eso la 3ª serie puede salir con 1-2 reps menos sin que sea mala señal.'),
      _fact('"¿Cómo llegas hoy?"',
          ins.readinessEffect >= 0
              ? '"A tope": ~${pct(ins.readinessEffect)} más · "Cansado": ~${pct(ins.readinessEffect)} menos'
              : 'No se nota diferencia clara',
          'Contestar con sinceridad le ayuda a no pasarse los días malos.'),
      _fact('Entrenar seguido',
          ins.recentTrainingEffect < -0.005
              ? 'Repetir ejercicio con <3 días de descanso te resta ~${pct(-ins.recentTrainingEffect)}'
              : 'No detecta pérdida por repetir pronto',
          null),
      _fact('Tu curva reps↔carga', 'Multiarticulares: ${curve(ins.slopeCompound)}. Aislamiento: ${curve(ins.slopeIsolation)}.',
          'Ajusta cuánto peso quitar o poner cuando cambian las reps objetivo.'),
    ]);
  }

  List<Widget> _exercises(PerformanceModel m, Map<String, Exercise> catalog, List<GymMachine> machines) {
    final names = {for (final mm in machines) mm.id: mm.name};
    final rows = <(String, StrengthEstimate)>[];
    for (final key in m.keys) {
      final parts = key.split('@');
      final st = m.strength(parts.first, parts.length > 1 ? parts[1] : null);
      if (st != null) rows.add((key, st));
    }
    if (rows.isEmpty) return const [];
    rows.sort((a, b) => b.$2.observations.compareTo(a.$2.observations));
    return [
      _card(title: 'Fuerza estimada por ejercicio', children: [
        for (final (key, st) in rows.take(20))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(catalog[key.split('@').first]?.nameEs ?? key.split('@').first,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '${key.contains('@') ? '${names[key.split('@')[1]] ?? 'máquina'} · ' : ''}'
                    '${st.observations} series · confianza ${st.confidence}',
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                NumberCounter(
                  value: st.oneRm,
                  suffix: ' kg',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary),
                ),
                if (st.trendPerWeek.abs() > 0.002)
                  Text(
                    '${st.trendPerWeek > 0 ? '↗' : '↘'} ${(st.trendPerWeek * 100).toStringAsFixed(1)} %/sem',
                    style: TextStyle(fontSize: 11, color: st.trendPerWeek > 0 ? Colors.greenAccent : Colors.redAccent),
                  ),
              ]),
            ]),
          ),
      ]),
    ];
  }

  Widget _privacy() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'El modelo se entrena en tu móvil con tus series y nunca sale de él. Es un modelo estadístico '
          '(filtro de Kalman + regresión con valores típicos de partida), no un chatbot: no inventa, '
          'solo extrapola lo que has hecho. Siempre puedes cambiar el peso a mano.',
          style: TextStyle(fontSize: 11, color: Colors.white54),
        ),
      );

  Widget _fact(String title, String value, String? note) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.white54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (note != null) Text(note, style: const TextStyle(fontSize: 11, color: Colors.white60)),
        ]),
      );

  Widget _card({required String title, required List<Widget> children}) => Card(
        color: AppTheme.surfaceMid,
        margin: const EdgeInsets.only(top: 14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ...children,
          ]),
        ),
      );
}

class _Training extends StatelessWidget {
  const _Training();
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.memory, size: 48, color: AppTheme.textMuted)
            .animate(onPlay: (c) => c.repeat())
            .rotate(begin: -0.03, end: 0.03, duration: 400.ms)
            .then()
            .rotate(begin: 0.03, end: -0.03, duration: 400.ms),
        const SizedBox(height: 12),
        const Text('Entrenando con tus series…'),
      ]);
}
