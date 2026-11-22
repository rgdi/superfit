# 🎯 SuperFit

> **La app de gimnasio que se adapta a ti. 100% offline. Basada en evidencia científica.**

[![Build APK](https://github.com/rgdi/superfit/actions/workflows/build.yml/badge.svg)](https://github.com/rgdi/superfit/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Flutter 3.24](https://img.shields.io/badge/Flutter-3.24-02569B?logo=flutter)](https://flutter.dev)
[![Dart 3.5](https://img.shields.io/badge/Dart-3.5-0175C2?logo=dart)](https://dart.dev)

**[⬇️ Descargar APK](https://github.com/rgdi/superfit/releases)** · **[📚 Documentación](docs/)** · **[🔬 Research](research/)**

---

## ✨ Features

- 🧠 **Adaptativa** — aprende de tu RPE, adherencia y PRs; ajusta pesos, descansos y ejercicios
- 🏋️ **Tus máquinas** — registra tus Technogym (u otras) desde Ajustes: nombre, pila de pesos y ajuste de asiento
- 🤖 **IA local que aprende de ti** — modelo entrenado en tu móvil con tus series: afina pesos, predice tus reps y mide su propio acierto
- ⚖️ **Pesos reales** — pila exacta + microcargas, historial por máquina, aproximación / top set + back-off / drop sets
- 📷 **Escanea la máquina** — el QR (o NFC) que llevan las Technogym te lleva directo a ese ejercicio con el peso listo
- 🔬 **Honesta con la evidencia** — cada regla indica si tiene evidencia sólida, parcial o es criterio práctico
- 📊 **Upper/Lower 4×/semana** — frecuencia 2×/grupo, 38 min por sesión
- 🖼️ **Mapa muscular interactivo** — silueta con músculos activados por ejercicio (22 músculos)
- 📷 **Galería de progreso** — fotos por fecha con comparador lado a lado
- 💯 **RPE-based auto-regulación** — doble progresión + detección de meseta
- 🔒 **100% privada** — sin cuentas, sin nube, sin tracking. Tus datos viven en tu dispositivo

## 🏋️ Catálogo

| | |
|---|---|
| 24 ejercicios | 18 máquinas |
| 6 rutinas | 1 plan 4 semanas |
| 22 músculos mapeados | 10 PMIDs verificados |

## 📦 Build local

```bash
cd app
flutter pub get
flutter run                      # device/emulator
flutter build apk --release       # APK release
```

## 🤖 Build automático

Cada `git push` genera un APK vía [GitHub Actions](.github/workflows/build.yml).
En tags `v*` se publica release automática.

## 🧬 Algoritmos

- **Doble progresión** (criterio práctico, NSCA): sube reps dentro del rango; cuando todas las series llegan al tope sin pasarte de RPE, sube peso — redondeado a las placas reales de **tu** máquina
- **e1RM con RIR** (escala RPE/RIR de Zourdos 2016, PMID 26049792): estima tu fuerza para recalcular cargas
- **Calibración en sesión**: sin historial, la 1ª serie calibra el peso de las siguientes
- **Meseta y caída de rendimiento**: 4 sesiones sin mejorar → propone variante; caída en muchos ejercicios → propone adelantar la descarga
- **Programa a medida**: split según días, volumen por grupo, filtrado por tus máquinas y molestias, ajustado a tus minutos

Qué tiene respaldo y qué es criterio práctico: ver [`docs/EVIDENCIA.md`](docs/EVIDENCIA.md) o *Ajustes → Cómo decide la app*.
- **Cycle planning 4:1** (Coleman 2014): 3 semanas carga + 1 deload
- **1RM Epley** (Epley 1985): `peso × (1 + reps/30)`
- **Fatigue detection**: RPE promedio 7 días > 8.5 → sugerir deload

## 📚 Documentación

- [Plan completo](PLAN.md) — 9 fases
- [Research con PMIDs](research/) — 7 documentos verificados
- [Arquitectura](docs/ARCHITECTURE.md) — ADRs
- [Build](docs/BUILD.md) — instrucciones
- [Manual usuario](docs/USER_GUIDE.md)

## 📜 Licencia

MIT. Hecho con evidencia, para gente que quiere resultados.

---

<p align="center">
  <sub>Built with 💪 for the iron game</sub>
</p>
