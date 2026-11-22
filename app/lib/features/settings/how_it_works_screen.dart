// Explicación honesta de la lógica de la app y su respaldo.
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum _Level { solid, partial, heuristic }

class _Rule {
  final String title;
  final String body;
  final _Level level;
  final String source;
  const _Rule(this.title, this.body, this.level, this.source);
}

const _rules = [
  _Rule(
    'Entrenar cada músculo ≥2 veces por semana',
    'Con el mismo volumen semanal, repartirlo en 2+ sesiones es al menos igual de eficaz que 1, '
        'y facilita hacer más series de calidad. Por eso el split depende de tus días.',
    _Level.solid,
    'Schoenfeld 2016 · PMID 27102172 · Pelland 2026 · PMID 41343037',
  ),
  _Rule(
    'Más series semanales → más músculo (con rendimientos decrecientes)',
    'La relación dosis-respuesta está bien documentada. Los números exactos que uso '
        '(8 / 12 / 16 series según nivel) son un punto de partida práctico, no un umbral demostrado.',
    _Level.partial,
    'Schoenfeld 2017 · PMID 27805470 · Pelland 2026 · PMID 41343037',
  ),
  _Rule(
    'Descansos de ~2 min en multiarticulares',
    'Descansos más largos permiten más reps de calidad y en algunos estudios dan más fuerza e hipertrofia. '
        'En ejercicios de aislamiento uso ~75-90 s para ahorrar tiempo.',
    _Level.partial,
    'Schoenfeld 2016 · PMID 26605807 · Grgic 2018 (fuerza) · PMID 28933024',
  ),
  _Rule(
    'RPE / repeticiones en reserva',
    'RPE 8 = te quedaban ~2 reps. Es una escala válida, pero la gente suele infravalorar cuántas reps le quedan, '
        'sobre todo lejos del fallo. Marca el RPE con sinceridad: el sistema lo usa para ajustar el peso.',
    _Level.solid,
    'Zourdos 2016 · PMID 26049792 · Refalo 2024 · PMID 37967832',
  ),
  _Rule(
    'Autorregulación (ajustar al día)',
    'Ajustar carga por RPE funciona al menos igual que porcentajes fijos. La pregunta "¿cómo llegas hoy?" '
        'y el reajuste entre series se basan en esto; el beneficio extra es modesto, pero evita pasarte cuando estás cansado.',
    _Level.partial,
    'Helms 2018 · PMID 29628895',
  ),
  _Rule(
    'Doble progresión',
    'Subir reps dentro del rango y, al llegar arriba en todas las series, subir peso. Es el método estándar '
        'de los manuales, sencillo y seguro. No hay un ensayo que lo declare "el mejor".',
    _Level.heuristic,
    'NSCA, manuales de entrenamiento',
  ),
  _Rule(
    '1RM estimado',
    'Fórmula de Epley contando las reps en reserva. Sirve para comparar tu progreso consigo mismo; '
        'no es tu 1RM real y se equivoca más por encima de ~12 reps.',
    _Level.heuristic,
    'Epley 1985 (fórmula empírica)',
  ),
  _Rule(
    'Máquinas vs peso libre',
    'Para ganar músculo y fuerza, las máquinas funcionan de forma similar al peso libre. '
        'Entrenar 100% en máquinas es una opción válida.',
    _Level.partial,
    'Haugen 2023 · PMID 37582807',
  ),
  _Rule(
    'Mantenimiento con poco volumen',
    'Mantener lo ganado requiere bastante menos volumen (en torno a 1/3) si mantienes la intensidad.',
    _Level.partial,
    'Bickel 2011 · PMID 21131862',
  ),
  _Rule(
    'Semana de descarga',
    'Cada 4-6 semanas bajo a la mitad de series. Hay poca evidencia directa de que sea necesaria; '
        'la uso porque gestiona fatiga y molestias con un coste mínimo. Si detecto caída de rendimiento te propongo adelantarla.',
    _Level.heuristic,
    'Práctica común; evidencia directa limitada',
  ),
  _Rule(
    'Peso inicial',
    'No existe una tabla científica de pesos por máquina (cada fabricante tiene palancas distintas). '
        'Propongo algo conservador y recalibro tras tu primera serie.',
    _Level.heuristic,
    'Criterio propio',
  ),
];

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cómo decide la app')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Cada regla lleva una etiqueta honesta de cuánto respaldo tiene. '
            'Los PMID se pueden buscar en pubmed.ncbi.nlm.nih.gov.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            for (final l in _Level.values) _badge(l),
          ]),
          const SizedBox(height: 16),
          for (final r in _rules)
            Card(
              color: AppTheme.surfaceMid,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700))),
                      _badge(r.level),
                    ]),
                    const SizedBox(height: 6),
                    Text(r.body, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(r.source, style: const TextStyle(fontSize: 11, color: Colors.white54)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _badge(_Level l) {
    final (text, color) = switch (l) {
      _Level.solid => ('Evidencia sólida', Colors.greenAccent),
      _Level.partial => ('Evidencia parcial', Colors.amberAccent),
      _Level.heuristic => ('Criterio práctico', Colors.white54),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color)),
    );
  }
}
