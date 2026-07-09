# SuperFit

> **La app de gimnasio que se adapta a ti.** Auto-hospedada en tu Android, sin cuentas, sin nube, sin tracking. Tus datos son tuyos.

**Tagline:** máximo músculo en mínimo tiempo, con mantenimiento inteligente.

## ¿Qué es?

App Flutter 100% offline para Android que:

- Te dice **la rutina del día** optimizada para tu nivel y objetivo.
- Registra **series, peso, RPE y notas** de cada sesión.
- Aprende de tu rendimiento y **adapta pesos, volumen y descansos**.
- Lleva una **galería de progreso físico** (fotos + métricas + 1RM estimado) por fecha.
- Se basa en los **mayores meta-análisis del mundo** sobre hipertrofia (Schoenfeld, NSCA, ACSM).

## Estructura del repo

```
superfit/
├── research/         # 6 documentos científicos con PMIDs (Fase 1)
├── assets/           # JSONs + imágenes (Fase 2 + 6)
├── app/              # Proyecto Flutter (Fases 3-9)
├── scripts/          # Python: generar imágenes, verificar PMIDs
├── docs/             # Decisiones de arquitectura (ADRs)
├── PLAN.md           # Plan completo de 9 fases
└── CHANGELOG.md
```

## Quick start (en tu PC con Flutter instalado)

```bash
# 1. Clona o copia esta carpeta
cd superfit/app

# 2. Instala dependencias
flutter pub get

# 3. Genera modelos (freezed)
dart run build_runner build --delete-conflicting-outputs

# 4. Ejecuta en Android
flutter run
```

## Build APK release

```bash
cd superfit/app
flutter build apk --release --split-per-abi
# Output: build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
```

## Generar imágenes (siluetas, máquinas, diagramas)

```bash
cd superfit/scripts
pip install pillow
python3 gen_muscle_maps.py
python3 gen_exercise_diagrams.py
python3 gen_machines.py
```

## Filosofía

- **On-device only**: nada de servidor, nada de login, nada de telemetría.
- **Basado en evidencia**: cada decisión de entrenamiento cita un PMID o DOI verificable.
- **Adaptable**: aprende de tus PRs, RPE, descansos y adherence.
- **Sin distracciones**: UX mínima, sin notificaciones invasivas, sin ads.

## Licencia

MIT. Hecho con evidencia, para gente que quiere resultados.
