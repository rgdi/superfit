# Cómo compilar e instalar SuperFit en tu Android

## Requisitos

- Flutter 3.24+ ([flutter.dev](https://flutter.dev))
- Android Studio o Android SDK
- Java 17

## Pasos

```bash
# 1. Clona o copia este repo
cd superfit/app

# 2. Instala dependencias
flutter pub get

# 3. Genera modelos (si usas freezed)
dart run build_runner build --delete-conflicting-outputs

# 4. Verifica que compila
flutter analyze

# 5. Ejecuta en device/emu
flutter run

# 6. Genera APK release
flutter build apk --release --split-per-abi

# Output: build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk (~15 MB)
#         build/app/outputs/flutter-apk/app-arm64-v8a-release.apk (~18 MB)
```

## Solución de problemas

### `flutter doctor` no detecta Android SDK
- Instala Android Studio: https://developer.android.com/studio
- O instala command-line tools y `sdkmanager`

### `build_runner` falla
- Los modelos del proyecto actual NO usan freezed, son clases manuales. El comando es opcional.
- Si quieres usar freezed, adapta los modelos en `lib/data/models/`

### `flutter build apk` falla con "license not accepted"
```bash
flutter doctor --android-licenses
# Acepta todas
```

### `image_picker` falla en Android < 13
- minSdk del proyecto: 23 (Android 6). Funciona, pero galería limitada en < 10.

## Estructura del APK

El APK pesa ~18 MB y contiene:
- Todo el código Flutter compilado
- 24 ejercicios, 6 rutinas, assets JSON
- 44 imágenes (siluetas, ejercicios, máquinas)
- SQLite engine (sqflite)

## Permisos de la app

- **Cámara**: solo cuando añades foto de progreso
- **Galería**: solo cuando importas foto existente
- **Almacenamiento**: solo en la carpeta privada de la app
- **Sin red**: la app no hace llamadas de red

## Primer uso

1. Instala el APK en tu Android
2. Abre SuperFit
3. Configura: nivel, objetivo, unidades, idioma
4. Pulsa EMPEZAR en la rutina del día
5. Registra tus series y RPE
6. La app aprende y se adapta a ti
