# Decisiones de arquitectura (ADR)

## ADR-0001 — Flutter como framework único

**Contexto:** Necesitamos una app Android nativa con buen rendimiento de UI y DB local.

**Decisión:** Flutter 3.24 con Dart 3, Material 3 dark theme.

**Consecuencias:**
- ✅ Single codebase, fácil de mantener
- ✅ Excelente rendimiento de UI (60fps)
- ✅ sqflite y shared_preferences bien soportados
- ❌ No podemos usar Kotlin/Java nativo (no nos importa)

## ADR-0002 — 100% offline, sin backend

**Contexto:** El usuario pidió una app que se adapte a él, sin tracking, privada.

**Decisión:** Cero llamadas de red, cero cuentas, cero telemetría. Todos los datos en SQLite local + SharedPreferences.

**Consecuencias:**
- ✅ Privacidad total
- ✅ Funciona sin internet
- ✅ Sin coste de infraestructura
- ❌ No hay sync entre dispositivos (feature futura opcional)

## ADR-0003 — Riverpod para state management

**Contexto:** Necesitamos un state management reactivo y simple.

**Decisión:** flutter_riverpod 2.5, con StateNotifier para user settings y Provider para repos.

**Consecuencias:**
- ✅ Compile-time safe
- ✅ Sin BuildContext en providers
- ❌ Curva de aprendizaje inicial

## ADR-0004 — JSON en assets + DB SQLite

**Contexto:** Tenemos datos de catálogo (ejercicios, máquinas, músculos, rutinas, plan) y datos de usuario (sesiones, sets, fotos).

**Decisión:**
- **Catálogo**: JSON en `assets/data/`, cargado con `rootBundle.loadString` al inicio. No se modifica.
- **Datos de usuario**: SQLite (`sqflite`) con tablas por entidad.

**Consecuencias:**
- ✅ Catálogo actualizable reemplazando JSON (no requiere recompilar si se carga de archivos)
- ✅ Búsquedas SQL eficientes para historial
- ❌ Dos fuentes de verdad (mitigado: el JSON es inmutable)

## ADR-0005 — Imágenes generadas con PIL, no descargadas

**Contexto:** Necesitamos imágenes de ejercicios y máquinas, pero el usuario quiere 100% offline.

**Decisión:** Generar PNGs con PIL en tiempo de build (scripts en `scripts/`). 44 imágenes, 416 KB total.

**Consecuencias:**
- ✅ Sin dependencias externas
- ✅ Licencias limpias (hecho por nosotros)
- ✅ Personalizables
- ❌ Calidad limitada vs ilustraciones profesionales (mitigado: silueta es básica, la app tintará los músculos con CustomPainter)

## ADR-0006 — Upper/Lower 4×/semana como split por defecto

**Contexto:** Schoenfeld 2016 (PMID 27102172) recomienda 2×/semana mínimo por grupo.

**Decisión:** Upper A/B + Lower A/B en 4 días, descanso entre días.

**Consecuencias:**
- ✅ Frecuencia 2× por grupo
- ✅ ~40 min por sesión
- ✅ Compatible con agenda media
- ❌ Algunos avanzados querrán PPL 6× (configurable en settings)

## ADR-0007 — Doble progresión como motor de progresión

**Contexto:** Helms 2014 (PMID 24864135) recomienda doble progresión.

**Decisión:** Si completas todas las reps a RPE ≤ target dos veces seguidas, sube peso.

**Consecuencias:**
- ✅ Auto-regulación natural
- ✅ Compatible con cualquier nivel
- ❌ No detecta mesetas rápido (mitigado: `ProgressionService.isStagnant`)

## ADR-0008 — go_router para navegación

**Decisión:** `go_router` 14.x con rutas declarativas y redirect para onboarding.

**Consecuencias:**
- ✅ Deep linking nativo en Android
- ✅ Rutas type-safe
- ✅ Redirect declarativo

## ADR-0009 — CustomPainter para silueta de músculos

**Decisión:** Dibujar silueta humana con CustomPainter, tintando músculos según activación.

**Consecuencias:**
- ✅ Sin dependencias de SVG
- ✅ Tinte dinámico en runtime (primary/secondary)
- ✅ Funciona en cualquier tamaño
- ❌ Calidad visual limitada vs SVG vector (pero aceptable para móvil)
