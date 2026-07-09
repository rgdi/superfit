# Changelog

Todas las versiones siguen [SemVer](https://semver.org/lang/es/).

## [1.0.0] - 9 jul 2026

### v1.0.0 - Initial release

**Fase 0 — Estructura**
- Repo `/home/rgodim/superfit/` con git
- Carpetas: `research/`, `assets/`, `app/`, `scripts/`, `docs/`
- `.gitignore` completo
- `README.md` con instrucciones
- `PLAN.md` con 9 fases detalladas

**Fase 1 — Research científico (6 documentos, 10 PMIDs verificados)**
- `00_resumen_ejecutivo.md`: tabla de decisiones
- `01_volumen_frecuencia_intensidad.md`: Schoenfeld 2017 (PMID 27805470)
- `02_tiempo_descanso.md`: Grgic 2018 (PMID 28933024)
- `03_seleccion_ejercicios_maquinas.md`: catálogo de 18 máquinas
- `04_progresion_tecnicas.md`: doble progresión + RPE
- `05_referencias_bibliograficas.md`: 28 referencias Vancouver
- `06_manual_usuario.md`: guía de uso
- `scripts/verify_pmids.py`: 10/10 PMIDs verificados en NCBI

**Fase 2 — Assets JSON**
- 22 músculos
- 24 ejercicios de máquina
- 18 máquinas
- 6 rutinas (Upper A/B, Lower A/B, Deload, Mantenimiento)
- 1 plan de 4 semanas (3 carga + 1 deload)

**Fase 3 — Scaffold Flutter**
- pubspec.yaml con 19 dependencias
- Tema Material 3 dark + accent verde
- Routing con go_router (10 rutas)
- Estructura feature-first

**Fase 4 — Modelos + DB**
- 12 modelos de datos inmutables
- SQLite con 6 tablas, índices optimizados
- Asset loader con cache
- 6 repositorios

**Fase 5 — UI Features (8 pantallas)**
- Onboarding (4 pasos: nivel, objetivo, unidades, idioma)
- Home (dashboard con rutina del día, streak, gráfico)
- Routines (lista + detalle)
- Exercises (enciclopedia con filtros + detalle con músculos)
- Workout (sesión activa, set logger, timer descanso, RPE)
- History (lista + detalle de sesión)
- Progress (métricas + 1RM estimado)
- Photos (galería + comparador)
- Settings (nivel, objetivo, unidades, idioma, reset)

**Fase 6 — Imágenes**
- 2 siluetas humanas (front + back) vía CustomPainter en runtime
- 24 diagramas de ejercicios generados con PIL
- 18 máquinas generadas con PIL
- Total: 44 PNGs, 416 KB

**Fase 7 — Lógica de adaptación**
- `ProgressionService`: doble progresión, detección de meseta, 1RM Epley
- `CyclePlanner`: plan 4:1 según fecha
- `RoutineRecommender`: rutina del día con detección de descanso
- RPE-based auto-regulación

**Fase 8 — UX**
- Haptic feedback en timer
- Animaciones de check
- RPE con colores (azul/verde/amarillo/rojo)
- Wakelock durante sesión

**Fase 9 — Build setup**
- `flutter analyze`: 0 errores, 25 warnings menores
- `flutter test`: pasa smoke test
- Compilación: requiere Android SDK (no instalado en este host Linux; instrucciones en README)

### Métricas
- ~5,800 líneas de código Dart
- 12 modelos, 6 repos, 6 use cases, 8 features
- 0 dependencias de red
- 0 permisos invasivos (solo cámara/galería para fotos de progreso)
