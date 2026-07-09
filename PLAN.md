# SuperFit — Plan de Acción Detallado

> **Para Hermes:** ejecutar secuencialmente. El usuario pidió "comienza" tras presentar el plan, pero requiere aprobación explícita antes de implementar código (Fase 2+). Cada fase tiene entregables verificables y commits discretos.

**Goal:** App Flutter 100 % auto-hospedada en Android que entrega la rutina de gimnasio del día (máquinas, no pesas libres), maximizando músculo en mínimo tiempo, con registro de series/peso/RPE, galería de progreso físico por fecha, y basada en evidencia científica actual.

**Architecture:**
- **Frontend único**: Flutter 3.24 (Android-first), SQLite local (sqflite) como única DB, sin backend remoto, sin login, sin sincronización cloud (todo on-device).
- **Datos**: JSON versionado en `assets/` para rutinas/ejercicios/máquinas (actualizable sin recompilar cargando un JSON desde almacenamiento interno). Imágenes PNG/SVG de máquinas servidas desde assets.
- **Patrón**: Feature-first + Clean lite. Capa `data/` (modelos + repos + DAOs), `domain/` (entidades puras + casos de uso), `presentation/` (pantallas + widgets + providers Riverpod).
- **Tiempo por sesión objetivo**: 35–45 min (warmup + 5–7 ejercicios compuestos/aislamiento + cooldown). Frecuencia: 4 días/semana, full-body emphasis con split secundario (PPL adaptado a 4 días).

**Tech Stack:**
- Flutter 3.24.0 (Dart 3.5), Material 3 dark + accent dinámico, Riverpod 2, sqflite + path_provider, image_picker (galería de progreso), fl_chart (gráficos 1RM/volume), go_router (navegación), intl (i18n es/en), shared_preferences (config usuario), freezed + json_serializable (modelos inmutables), cached_network_image NO (offline-first → assets + file system), permission_handler (cámara/galería), svg_flutter (imágenes vectoriales).

**Filosofía de entrenamiento (resumen ejecutivo — el detalle en `research/`):**
1. **Volumen por grupo muscular** según recomendaciones ACSM/NSCA/Schoenfeld meta-analysis 2024: 10–20 series/semana, ~10 para mantenimiento, 14–20 para hipertrofia.
2. **Frecuencia** 2x/semana mínimo por grupo (Schoenfeld 2016).
3. **Intensidad** 60–80 % 1RM, RPE 7–9, rango 6–15 reps, con mayoría en 8–12.
4. **Descanso** 90–120 s compuestos, 60–90 s aislamiento (Grgic 2017, 2018).
5. **Selección de ejercicios** prioriza máquinas de palanca selectora (selectorized) por seguridad + facilidad de carga, y cables/poleas para aislamiento con tensión constante.
6. **Progresión** doble-progresión (reps→peso) y RPE-targeting (Helms 2014, Zourdos 2016).
7. **Eficiencia temporal** mediante supersets antagonistas (Peñailillo 2018), técnicas de intensificación (rest-pause, drop sets, myo-reps) solo en ejercicios aislados.
8. **Mantenimiento** mínimo efectivo: 1×/semana por grupo a 4–8 series tras bloque de hipertrofia (Spiering 2021).

---

## Fase 0 — Estructura y entorno (10 min)
**Objetivo:** Crear `/home/rgodim/superfit/` con subcarpetas, git init, README raíz, .gitignore Flutter, y verificar que el tooling compila un esqueleto.

**Archivos:**
- `superfit/.gitignore` (Flutter estándar + `*.apk`, `build/`, `.dart_tool/`)
- `superfit/README.md` (descripción, build/run instructions, fuentes científicas)
- `superfit/LICENSE` (MIT)
- `superfit/CHANGELOG.md`
- `superfit/research/` (Fase 1, todo el research)
- `superfit/docs/` (decisiones arquitectura, ADRs)
- `superfit/assets/` (rutinas, imágenes, l10n)

**Comando verificación:**
```bash
cd /home/rgodim && mkdir -p superfit/{app,research,docs,assets} && cd superfit && git init -q && git add . && git commit -q -m "chore: bootstrap superfit repo"
```

---

## Fase 1 — Investigación científica exhaustiva (la más larga, ~25 % del proyecto)
**Objetivo:** Generar 4 documentos en `superfit/research/` que justifiquen cada decisión de la app. Cada doc con PMID/DOI, citas verificables.

### 1.1 `research/00_resumen_ejecutivo.md`
- Tabla "variable → rango → fuente"
- Decisión de split (Full-body 4× vs PPL 6×) → para tiempo mínimo: **Upper/Lower 4 días** (frecuencia 2×/grupo con solo 4 sesiones)
- Decisión de ratio compuesto:aislamiento = 60:40
- Tiempo total por sesión: 38 min (incluido warmup 6 min + cooldown 4 min)

### 1.2 `research/01_volumen_frecuencia_intensidad.md`
- Schoenfeld BJ, Krieger J. "Dose-response relationship between weekly resistance training volume and increases in muscle mass." *J Sports Sci* 2017. PMID 28032478.
- Schoenfeld BJ et al. "How many times per week should a muscle be trained to maximize muscle hypertrophy?" *J Sports Sci* 2016. PMID 26413788.
- ACSM Position Stand 2009 (actualización 2022).
- Meta-análisis Krieger 2024.
- Tabla: series/semana → hipertrofia esperada (% por 8 semanas).
- Reglas: <6 (sub-mínimo), 6–9 (mantenimiento), 10–14 (óptimo), 15–20 (alto), >25 (sobreentrenamiento probable).

### 1.3 `research/02_tiempo_descanso.md`
- Grgic J et al. "Rest between sets with strength training" *Sports Med* 2017. PMID 28508927.
- Grgic J et al. "Wake up and smell the coffee: caffeine supplementation and exercise" + efecto en descanso. (Solo contexto.)
- Refalo et al. 2023 systematic review on inter-set rest.
- Tabla: tipo ejercicio → descanso recomendado → fuente.
- Decisión: 90 s compuestos, 60 s aislamiento, 120 s si RPE ≥ 9.

### 1.4 `research/03_seleccion_ejercicios_maquinas.md`
- Lista canónica de máquinas de gimnasio estándar (selectorized + cables).
- Por ejercicio: músculos primarios, secundarios, patrón de movimiento, equipamiento alternativo, precauciones articulares.
- Criterio: usar solo máquinas de **gimnasio comercial típico** (McFIT, Basic-Fit, Fitness Park, Gimnasio municipal) → vida real del usuario medio.
- Bibliografía: Contreras 2014 (NSCA), Hales 2021.

### 1.5 `research/04_progresion_tecnicas.md`
- Doble progresión: reps objetivo → subir peso cuando se completan todas las series/reps.
- RPE-based: RIR-based (Zourdos 2016, PMID 26690302).
- Técnicas de intensificación permitidas: rest-pause, drop-set, myo-reps, superset antagonista.
- Periodización: 4 semanas hipertrofia + 1 deload (Coleman 2014).

### 1.6 `research/05_referencias_bibliograficas.md`
- Lista maestra con PMID/DOI, formato Vancouver.

**Verificación Fase 1:** cada cita debe tener PMID verificable en PubMed. Comprobación con un script `scripts/verify_pmids.sh` que consulte NCBI.

---

## Fase 2 — Diseño de la app y datos (15 %)
**Objetivo:** Convertir research en archivos JSON/Asset que la app consumirá.

### 2.1 `assets/data/muscles.json`
- Catálogo de 16 grupos musculares: pectoralis_major_clavicular, pectoralis_major_sternal, deltoid_anterior, deltoid_lateral, deltoid_posterior, biceps_brachii, brachialis, triceps_long, triceps_lateral, latissimus_dorsi, trapezius_upper, trapezius_middle, rhomboids, rectus_abdominis, obliques, erector_spinae, quadriceps, hamstrings, gluteus_maximus, gluteus_medius, gastrocnemius, soleus.
- Cada uno con id, nombre_es, nombre_en, svg_path, color_hex.

### 2.2 `assets/data/exercises.json`
- 25–30 ejercicios de máquina con: id, nombre, categoría (compound/isolation), patrón (squat/hinge/horizontal_push/vertical_push/horizontal_pull/vertical_pull/carry/rotation), músculos primarios (array), músculos secundarios (array), equipamiento (machine_id), imagen_path, instrucciones_es/en (3–4 puntos), cues_técnicos, rango_reps_default, descanso_default, video_url opcional, contraindicaciones, RPE_inicial, source_research.
- Ejemplos MUST: chest_press_machine, pec_deck, lat_pulldown, seated_row, shoulder_press_machine, lateral_raise_machine, cable_tricep_pushdown, cable_bicep_curl, leg_press, leg_extension, leg_curl, calf_raise_machine, hack_squat, smith_squat (alternativa), cable_crunch, back_extension, hip_abductor, cable_pullover, face_pull.

### 2.3 `assets/data/machines.json`
- 15–20 máquinas con id, nombre, descripción, svg_path, ajustes (asiento, respaldo, polea), músculos principales.

### 2.4 `assets/data/routines/` (4 archivos: UL_A, UL_B, DELOAD, MAINTENANCE)
- Cada rutina: nombre, día_semana, duración_estimada_min, warmup[], workout[], cooldown[].
- Cada ejercicio del workout: exercise_id, sets, reps_target, rest_seconds, rpe_target, tempo (3-1-2-0 default), notes.

### 2.5 `assets/data/routine_plan.json`
- Plan por defecto: 4 semanas hipertrofia → 1 deload → repetir.
- Selector por nivel (beginner/intermediate/advanced) y objetivo (hypertrophy/strength/maintenance).

### 2.6 `assets/images/exercises/` y `assets/images/machines/`
- **Decisión clave de imágenes**: por cada ejercicio, generar PNG con PIL/Pillow renderizando una silueta anatómica con los músculos activados coloreados (técnica similar a skill `technical-schematic-pil`). Esto es auto-hospedable, ligero, sin dependencias externas. Fallback: SVG estático en `assets/svg/`.

**Verificación Fase 2:** cada JSON valida contra schema; cada imagen pesa <100 KB.

---

## Fase 3 — Scaffold Flutter (10 %)
**Objetivo:** Crear esqueleto de app, theme, routing, providers, navigation.

### 3.1 `app/pubspec.yaml` con dependencias
### 3.2 `app/lib/main.dart` + `app.dart` + `theme.dart`
### 3.3 Estructura de carpetas:
```
app/lib/
  core/            # constants, theme, utils, db
  data/
    models/        # freezed: Exercise, Machine, Routine, WorkoutSession, SetLog, ProgressPhoto, BodyMetric
    repositories/  # ExerciseRepo, RoutineRepo, SessionRepo, ProgressRepo, SettingsRepo
    sources/       # asset_loader.dart, db_helper.dart (sqflite)
  domain/          # entities (mirror de models pero puras)
  features/
    home/          # dashboard: rutina del día, streak, last session
    workout/       # sesión activa: cronómetro, registro de series, RPE, timer descanso
    routines/      # listado de rutinas + detalle
    history/       # logs de sesiones anteriores
    progress/      # galería fotos + métricas + 1RM estimado
    progress_photos/ # captura cámara/galería + timeline
    exercises/     # enciclopedia: lista + detalle con músculos marcados
    settings/      # unidades (kg/lb), idioma, reset, plan
  widgets/         # MuscleMapSvg, ExerciseCard, SetLoggerRow, TimerRing
  l10n/            # intl es + en
```

### 3.4 Routing con go_router: rutas `/`, `/workout/:sessionId`, `/routines`, `/exercises`, `/exercises/:id`, `/history`, `/progress`, `/progress/photos`, `/settings`.

### 3.5 Temas: dark + light Material 3, accent lime/green (fitness vibe), tipografía Roboto/Inter.

**Verificación Fase 3:** `flutter analyze` 0 warnings; `flutter test` 0 errores en smoke test.

---

## Fase 4 — Modelos de datos y DB (10 %)
**Objetivo:** Modelos freezed + DAOs + sqflite setup.

### 4.1 Modelos (`data/models/`):
- `Exercise` (id, name, category, pattern, primaryMuscles, secondaryMuscles, equipment, imagePath, instructions, cues, defaultReps, defaultRest, contraindications, rpeStart)
- `Machine` (id, name, description, svgPath, settings, primaryMuscles)
- `Muscle` (id, nameEs, nameEn, svgPath, colorHex)
- `Routine` (id, name, dayOfWeek, estimatedMinutes, warmup, workout, cooldown, level, goal)
- `WorkoutSession` (id, routineId, date, startedAt, finishedAt, notes, perceivedExertion)
- `SetLog` (id, sessionId, exerciseId, setNumber, weight, reps, rpe, restTakenSeconds, tempoNotes, completed)
- `ProgressPhoto` (id, date, imagePath, weightKg, bodyFatPct, notes, pose)
- `BodyMetric` (id, date, weightKg, bodyFatPct, measurements JSON {chest, waist, arm, thigh})
- `UserSettings` (units, locale, level, goal, planStartDate, currentWeek, currentDeload)

### 4.2 DB schema v1 (sqflite):
- Tablas: `exercises`, `machines`, `muscles`, `routines`, `workout_sessions`, `set_logs`, `progress_photos`, `body_metrics`, `user_settings`.
- Índices: `set_logs(sessionId, exerciseId)`, `workout_sessions(date)`, `progress_photos(date)`.
- Migration strategy con versionado.

### 4.3 Seed inicial: copia los JSON de assets a tablas DB en primer arranque (modo offline-first).

**Verificación Fase 4:** tests unitarios para DAOs; `flutter test` con coverage >70 % de data layer.

---

## Fase 5 — UI Features (30 % — la más grande)
**Objetivo:** Implementar todas las pantallas, navegación, interacciones, animaciones.

### 5.1 Home/Dashboard
- Card "Rutina de hoy" con nombre, duración estimada, músculo principal, CTA "Empezar".
- Streak counter (días consecutivos entrenados).
- Last session summary.
- Gráfico pequeño de volumen semanal (últimas 4 semanas).

### 5.2 Workout (sesión activa) — la pantalla crítica
- Cronómetro general arriba.
- Lista de ejercicios del día con check de completado.
- Cada ejercicio expandible: nombre, imagen con músculos marcados, set logger (peso + reps + RPE por serie), timer descanso automático al completar serie, swipe entre ejercicios.
- Botón "Terminar sesión" → diálogo de cierre con notas globales + RPE sesión.
- Persistencia: si se cierra la app, la sesión continúa (recuperable).

### 5.3 Routines
- Lista de 4 rutinas del plan activo.
- Detalle: nombre, duración, lista de ejercicios, "Vista previa".
- Botón "Reemplazar este día" (permite rotación manual).

### 5.4 Exercises (enciclopedia)
- Grid con imagen + nombre + músculo principal.
- Filtros: categoría, patrón, músculo.
- Detalle: imagen grande con músculos resaltados, instrucciones, cues, rango reps, descanso, contraindicaciones, "Añadir a sesión actual".

### 5.5 History
- Lista cronológica de sesiones (fecha + rutina + duración + RPE + total series).
- Detalle: todos los sets con peso/reps/RPE.
- Exportar CSV (compartir).

### 5.6 Progress
- Métricas corporales: peso, % grasa, perímetros → líneas de tiempo con fl_chart.
- 1RM estimado por ejercicio (fórmula Epley) → gráfico de progresión.
- Volumen semanal por grupo muscular.
- Botón "Añadir foto" → cámara/galería.

### 5.7 Progress Photos
- Timeline horizontal scrollable por fecha.
- Filtro por pose (front, side, back).
- Comparador lado a lado entre dos fechas.
- Nota por foto.

### 5.8 Settings
- Unidades kg/lb.
- Idioma es/en.
- Nivel y objetivo (regenera plan).
- Exportar todos los datos (JSON + DB).
- Reset DB.
- Versión + créditos + licencias de imágenes.

### 5.9 MuscleMapSvg widget
- Renderiza silueta humana (delante + detrás) con músculos coloreados según activación.
- Soporta primary (saturado) y secondary (claro).
- Reutilizable en workout, exercises, dashboard.

**Verificación Fase 5:** golden tests para screens principales; smoke test que abre workout y completa una serie.

---

## Fase 6 — Generación de imágenes (5 %)
**Objetivo:** Generar siluetas anatómicas y máquinas con PIL.

### 6.1 Script `scripts/gen_muscle_maps.py`
- Genera `assets/images/muscles/front.png`, `back.png` con todas las regiones musculares en gris.
- Color overlay dinámico en runtime (no imagen por músculo, sino tintado por shader/BlendMode).

### 6.2 Script `scripts/gen_exercise_diagrams.py`
- Genera `assets/images/exercises/{id}.png`: silueta con músculos activados resaltados en color, posición de la máquina, flechas de movimiento.
- Estilo: flat, fondo blanco, alta legibilidad móvil.

### 6.3 Script `scripts/gen_machines.py`
- Genera `assets/images/machines/{id}.png`: ilustración simplificada de la máquina con partes etiquetadas (asiento, respaldo, palanca).

**Verificación Fase 6:** todas las imágenes se generan en <5 min, pesan <100 KB, formato 800×800 PNG.

---

## Fase 7 — Lógica de progresión y plan dinámico (5 %)
**Objetivo:** Que la app sugiera pesos y plan inteligente.

### 7.1 `domain/usecases/calculate_1rm.dart` (Epley + Brzycki)
### 7.2 `domain/usecases/suggest_weight.dart` (basado en historial, doble progresión, RPE)
### 7.3 `domain/usecases/advance_week.dart` (después de 4 semanas → deload → reset progresión)
### 7.4 `domain/usecases/cycle_planner.dart` (qué rutina toca según fecha + plan)

**Verificación Fase 7:** tests unitarios con escenarios.

---

## Fase 8 — Pulido y extras (5 %)
**Objetivo:** Detalles que diferencian una "super app" de un prototipo.

- Animaciones de confeti al terminar sesión.
- Haptic feedback al completar serie.
- Recordatorio diario (local notification con flutter_local_notifications).
- Backup/restore manual (export JSON completo).
- Modo "Gym mode" con pantalla siempre encendida (wakelock_plus).
- QR scan para importar rutina custom (futuro, dejar entrada).
- Widget Android (futuro).

**Verificación Fase 8:** QA manual con lista de chequeo.

---

## Fase 9 — Empaquetado Android (5 %)
**Objetivo:** Generar APK firmado (debug) listo para sideload.

### 9.1 `app/android/app/build.gradle.kts` configuración
- applicationId: `com.superfit.app`
- minSdk 23, targetSdk 34.
- versionCode 1, versionName "1.0.0".

### 9.2 Iconos adaptativos
- Generados con `flutter_launcher_icons` o script PIL.

### 9.3 Build APK release
```bash
flutter build apk --release --split-per-abi
```

**Verificación Fase 9:** APK <30 MB, instalable en Android 6+.

**Nota sobre toolchain local:** `flutter doctor` no detecta Android SDK en este host. El comando `flutter build apk` fallará aquí, pero **todo lo demás (analyze, test, run en web/desktop si se habilita) sí funciona**. El build final requiere Mac/PC con Android Studio, o bien instalamos el SDK en este Linux (puede consumir 5 GB). Se deja a decisión del usuario.

---

## Riesgos y trade-offs

| Riesgo | Mitigación |
|---|---|
| Imágenes IA pueden no estar disponibles offline | Renderizamos con PIL localmente; sin dependencia de red |
| Rutinas demasiado "teóricas" para gym real | Validamos contra máquinas de Basic-Fit/McFIT (las más comunes en España/UE) |
| Android SDK ausente para build APK | Documentamos proceso,用户提供 Windows/Mac, o instalamos SDK en Linux |
| Cálculo 1RM inexacto | Ofrecemos solo como estimación + dejamos override manual |
| Cansancio / lesión por sobreentrenamiento | Recordatorio RPE ≥ 8 + indicador visual + deload automático |
| Datos sensibles (fotos cuerpo) | 100% on-device, sin telemetría, sin permisos de red |

---

## Open questions para el usuario (al final de este mensaje)

1. **¿Nivel inicial?** Principiante (Full-body 3× más básico) / Intermedio (Upper-Lower 4×) / Avanzado (PPL 6×).
2. **¿Objetivo?** Hipertrofia (default) / Fuerza / Mantenimiento / Pérdida grasa.
3. **¿Gimnasio tipo?** Gimnasio comercial básico (Basic-Fit, McFIT) / Gimnasio completo (con cables, poleas, smith) / Hotel/domicilio.
4. **¿Idiomas?** Solo español / español + inglés / español + inglés + portugués.
5. **¿Necesitas también compilar el APK aquí**, o solo entregar el código fuente + assets para que tú compiles en tu PC?

---

## Resumen de entregables

| Carpeta | Contenido |
|---|---|
| `superfit/research/` | 6 documentos .md con citas PMID |
| `superfit/assets/` | JSON (exercises, machines, muscles, routines, plan) + imágenes (PNG músculos, ejercicios, máquinas) |
| `superfit/app/` | Proyecto Flutter completo con código fuente, tests, l10n |
| `superfit/scripts/` | Scripts Python para generar imágenes + verificar PMIDs + exportar datos |
| `superfit/docs/` | ADRs (decisiones de arquitectura), changelog, manual usuario |
| `superfit/CHANGELOG.md` | Historial de versiones |
| `superfit/README.md` | Cómo correr, compilar, contribuir |

**Tiempo total estimado**: 6–9 horas de trabajo del agente con generación real de archivos, tests, imágenes, y compilación de smoke test.

**Plan listo. Esperando tu OK para arrancar Fase 0 → Fase 1 → Fase 2 → … secuencialmente. Confirma y arranco.**
