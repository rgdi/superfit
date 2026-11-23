# Changelog

Todas las versiones siguen [SemVer](https://semver.org/lang/es/).

## [1.6.0] - 23 nov 2026

### Auditoría completa (ver docs/AUDITORIA.md)
**Planificación**
- Generador nuevo: reparte las series por músculo (no por grupo) y por minuto disponible.
  Primero asegura los patrones básicos de cada sesión (empuje, tirones vertical y horizontal,
  pierna) y después añade el ejercicio que más volumen útil aporta por minuto.
- Objetivo semanal único por músculo para generador, mapa y programa (antes había tres).
  Mantenimiento = 1/3, fuerza ×0,8, músculos prioritarios ×1,35; lumbares, oblicuos y
  trapecio superior cuentan como "opcional" (se trabajan de forma indirecta).
- Penaliza pasarse de 1,5× el objetivo y equilibra empuje/tirón.
- El tiempo estimado incluye calentamiento y nunca supera tus minutos.
- Pantalla Programa: barras de volumen planificado frente al objetivo de cada músculo.
- Datos corregidos: pec deck y cruce de poleas son empuje horizontal; prensa y hack
  trabajan aductores (Kubo 2019), no isquios; el remo trabaja deltoides posterior y bíceps.
- Lesiones: press de hombro se excluye con pinzamiento; elevaciones laterales y crunch
  pasan a "con precaución" en vez de excluirse.

**Cargas y progresión**
- Detecta saltos de peso demasiado grandes para tu máquina: mantiene el peso y sube reps.
- Si fue claramente fácil (RPE ≤ objetivo−2) sube aunque no hayas tocado el tope.
- Las semanas de descarga y las series de calentamiento/drop ya no cuentan para progresar.
- Descarga: un único recorte del 10 % sobre tu peso real (antes se aplicaba dos veces).
- Series top + back-off: el peso de trabajo sale de la serie principal.
- El modelo necesita 3 sesiones para opinar, redondea a pesos reales de tu máquina,
  predice reps y tiene en cuenta la fatiga dentro de la misma sesión.
- Recuperación: si los músculos de la sesión de hoy no están recuperados propone otra
  sesión o descansar. Rotación por la sesión hecha hace más tiempo.
- Cálculo de semanas del mesociclo corregido en el cambio de hora.

**Fallos de la app**
- Se podían perder máquinas y ajustes si se guardaba antes de terminar de cargar.
- Sesiones a medias duplicadas: ahora preguntas si continuar o descartar.
- Al reanudar un entreno se recuperan series extra, back-offs y cambios de ejercicio.
- Copia de seguridad completa (todos los ajustes) y restauración que recarga todo.
- "Borrar todo" borra de verdad (incluidas las fotos).
- Inicio: récords comparados con todo tu historial; la semana va de lunes a domingo.
- Onboarding, comparación de fotos, métricas corporales con coma decimal, cargas infinitas
  en historial y detalle de rutina.
- Eliminada la opción de libras (no estaba implementada en ningún sitio).

## [1.5.0] - 23 nov 2026

### Rediseño minimalista
- Interfaz monocroma: negro, grises y blanco; botones blancos con texto negro. El color
  solo aparece para comunicar datos (un único verde lima de progreso, coral solo si te pasas).
- Tipografía **Inter** en toda la app, números con cifras tabulares.
- Sin emojis, degradados, brillos ni confeti. Animaciones reducidas a lo necesario.
- Inicio reescrito: la sesión de hoy con foto real y un solo botón, la semana en una línea
  (7 días + volumen, series y récords) y accesos en lista.
- Listas (Historial, Rutinas, Máquinas) como filas con separadores, sin cajas ni iconos repetidos.
- Pantalla de entreno: una línea de datos en vez de chips; el peso del día en grande con un
  único motivo (antes el texto de la regla y el del modelo se contradecían).
- Mapa muscular plano, escala de un solo tono.
- Barra de navegación nueva; "Mi IA" pasa a "Tu modelo".

### Correcciones
- Nombres internos en inglés ("chest press machine", "quadriceps", "squat") sustituidos por
  sus nombres en español en todas las pantallas.
- Error al salir de la pantalla de entreno mientras cargaba (actualizaba una pantalla cerrada).
- Símbolos que la tipografía no tenía (▸ ▾ ⇄) y se veían como cuadros.

### Herramientas
- Capturas automáticas de 14 pantallas con datos de ejemplo:
  `SHOTS_DIR=/ruta flutter test test/screenshots_test.dart`.

## [1.4.0] - 22 nov 2026

### Realismo
- **Fotos reales** de cómo se hace cada uno de los 29 ejercicios (2 posiciones por
  ejercicio, máquinas reales), de Free Exercise DB (dominio público).
- **Demostración animada**: las dos posiciones se alternan al ritmo del tempo del
  ejercicio, con fundido, zoom suave, indicador de fase y mini mapa anatómico que late
  con cada repetición. Toca para pausar. En la ficha del ejercicio y en el entreno.
- **Mapa anatómico** con siluetas musculares reales (react-body-highlighter, MIT),
  bordes suavizados, sombreado de volumen, fibras y brillo en los músculos activos.
  Sustituye a los óvalos en todo la app.
- Miniaturas con foto en la lista de ejercicios, el programa y las máquinas eficientes.
- Pantalla "Licencias y créditos".

## [1.3.0] - 22 nov 2026

### Mapa muscular
- Mapa corporal interactivo (frontal y posterior, los 23 músculos) con dos modos:
  **volumen semanal** (series/objetivo, mapa de calor) y **recuperación estimada**.
- Series fraccionales: músculo principal = 1, secundario = 0,5 (Pelland 2026).
- Toca un músculo: series de la semana vs objetivo, recuperación, qué ejercicios lo han
  trabajado y el mejor ejercicio para él con tus máquinas.
- Lista de lo que más necesita trabajo.

### Máquinas más eficientes
- Optimizador de cobertura: el menor conjunto de ejercicios, con TUS máquinas y evitando
  tus molestias, que trabaja todos los músculos. Dos niveles: **Esencial** (6 máquinas,
  ~37 min con todas disponibles) y **Completo**.
- Prioriza multiarticulares y músculos grandes, penaliza lo que carga la columna y premia
  variantes con el músculo estirado (Maeo 2021/2023, Pedrosa 2022, Kassiano 2023).
- No optimiza "activación EMG", que no predice hipertrofia (Vigotsky 2017).
- Indica qué queda sin trabajar y qué máquina añadir. Botón "Usar como mi programa".

### Correcciones
- Carrera al guardar máquinas/perfil/programa: si escribías antes de que terminase la
  carga inicial, la carga lo sobrescribía con el valor antiguo.
- Textos que se desbordaban en pantallas estrechas o con letra grande.

## [1.2.0] - 22 nov 2026

### 🤖 IA local que aprende de ti (100 % en el móvil)
- Modelo de rendimiento propio, entrenado en el dispositivo con tus series cada vez que
  abres un entreno (milisegundos, sin internet, nada sale del móvil):
  - **Filtro de Kalman** por ejercicio *y máquina*: sigue tu fuerza y su incertidumbre.
  - Aprende tu **fatiga entre series**, el efecto de **"¿cómo llegas hoy?"** y de
    **repetir ejercicio con poco descanso** (regresión con valores típicos de partida).
  - Aprende tu **curva reps↔carga** personal, elegida por error de predicción fuera de muestra.
- Usa el modelo para afinar el peso (±10 % sobre la regla de progresión), predecir tus
  reps en cada serie y reajustar las series pendientes en vivo.
- **Se evalúa a sí mismo** (backtest): pantalla *Mi IA* con su error real frente a la
  fórmula genérica. En datos simulados: ±0,45 reps frente a ±1,17.

### Pesos
- **Pila de pesos real**: lista exacta de placas (aunque no suban igual) + microcargas
  (+1, +1,25, +2, +2,5, +5 kg). La app solo propone pesos que existen; selector visual.
- **Historial por máquina física**: cada serie guarda en qué máquina se hizo; dos
  máquinas del mismo ejercicio no se mezclan (cada una pesa distinto).
- **Peso por ejercicio** en máquinas multiuso (polea, Multi Hip…), con su propio historial.
- **Series con pesos distintos**: aproximación (50 % / 75 %), top set + back-off (−10 %),
  drop sets y series extra. Las aproximaciones no cuentan para progresión ni volumen.
- Ficha de cada máquina con gráficas del 1RM estimado, peso máximo y estimación de la IA.

### Animaciones
- Transiciones entre ejercicios, series que "rebotan" y brillan al completarse, números
  animados, barra de progreso de la sesión, confeti y aviso al batir un récord, entrada
  escalonada en Inicio, gráficas animadas y resumen final animado.

### Otros
- Migración de base de datos v2 (columna `machine_id`), automática.
- Test de flujo completo de la pantalla de entrenamiento.

## [1.1.0] - 22 nov 2026

### Mi gimnasio (Ajustes)
- **Mis máquinas**: registra tus máquinas reales por nombre (autocompletado con nombres
  típicos de Technogym: Selection 700/900, Pure Strength, Element+, Artis…). La app detecta
  qué ejercicios permite cada una (también en español: "prensa", "jalón", "femoral"…).
- Alta rápida de un circuito Technogym completo.
- Pila de pesos por máquina (mínimo, máximo, salto): los pesos sugeridos son siempre
  pesos que existen en tu máquina.
- Ajuste de asiento guardado por máquina y visible durante el entreno.
- 6 tipos de máquina nuevos: adductor, curl de bíceps, extensión de tríceps, crunch,
  glúteo y deltoide posterior (con sus ejercicios).

### Escanear máquinas (QR / NFC)
- Las Technogym llevan un QR junto al logo NFC con `s.technogym.com/<línea>/<modelo>`
  (p. ej. `artis/chest_press`). SuperFit lo lee con la cámara y sabe en qué máquina estás.
- También intenta leer el NFC a la vez: funciona si ese punto es una etiqueta con la URL;
  si es un lector (llave mywellness), el móvil no puede leerlo y hay que usar el QR.
- Primer escaneo: propone vincularlo a tu máquina o crearla ya rellenada (nombre y tipo).
- Durante el entreno: escanear salta al ejercicio de esa máquina con el peso listo para
  marcar; si no está en la sesión de hoy, propone cambiar el ejercicio actual.
- Desde Inicio: con sesión activa salta al ejercicio; sin sesión, abre la ficha de la máquina.
- Las repeticiones y el peso se confirman en la app: las máquinas no los exponen a apps de
  terceros (van a la nube de Technogym/mywellness, sin API pública).

### Sistema más inteligente
- **Perfil de entrenamiento**: días/semana, minutos por sesión, sexo/edad/peso, molestias,
  músculos prioritarios, duración del bloque.
- **Generador de programa**: split según días (2-3 cuerpo completo, 4 torso/pierna,
  5 híbrido, 6 PPL), volumen semanal por grupo según nivel y objetivo, filtrado por tus
  máquinas y molestias, recortado para caber en tus minutos y con el "por qué" de cada decisión.
- **Motor de cargas nuevo**: doble progresión real con tu historial, e1RM con RIR,
  redondeo a las placas de tu máquina, detección de meseta y de caída de rendimiento.
- **Calibración en sesión**: sin historial, la primera serie ajusta el peso de las siguientes.
- **"¿Cómo llegas hoy?"**: si llegas cansado, una serie menos y RPE −1.
- Mesociclo con RPE creciente (7 → 9) y descarga; opción de adelantar la descarga.
- Rotación de sesiones: si faltas un día, no se pierde la sesión.
- Cambiar un ejercicio por otro que puedas hacer en tu gimnasio (⇄).

### Correcciones
- El peso sugerido en el entreno ignoraba el historial (siempre salía el inicial).
- Mover el RPE de una serie ya marcada la guardaba otra vez (series duplicadas).
- Desmarcar una serie no la borraba.
- La copia de seguridad fallaba (exportaba tablas que no existen) y no incluía máquinas/programa.
- Citas científicas mal atribuidas (ver `docs/EVIDENCIA.md`).
- Nueva pantalla *Ajustes → Cómo decide la app* con el nivel de evidencia de cada regla.

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
