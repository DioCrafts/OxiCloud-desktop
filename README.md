# OxiCloud Desktop Client

## Compilación Automática con GitHub Actions

Este proyecto utiliza GitHub Actions para compilar automáticamente la aplicación para todas las plataformas soportadas. Los pipelines se ejecutarán automáticamente cuando:

- Se haga push a la rama `main`
- Se cree un pull request a la rama `main`

### Plataformas Soportadas

- Linux
- Windows
- macOS
- Android
- iOS

### Estructura de los Pipelines

El archivo de configuración de GitHub Actions se encuentra en `.github/workflows/build.yml` y contiene los siguientes jobs:

1. `build-linux`: Compila la aplicación para Linux
2. `build-windows`: Compila la aplicación para Windows
3. `build-macos`: Compila la aplicación para macOS
4. `build-android`: Compila la aplicación para Android
5. `build-ios`: Compila la aplicación para iOS
6. `upload-artifacts`: Sube los archivos compilados como release de GitHub

### Requisitos Previos

Para que los pipelines funcionen correctamente, necesitas:

1. Un repositorio en GitHub
2. Tener permisos para crear releases en el repositorio
3. Tener configurado el token de GitHub (`GITHUB_TOKEN`)

### Compilación Manual

Si necesitas compilar manualmente, puedes usar los siguientes comandos:

```bash
# Linux
flutter build linux

# Windows
flutter build windows

# macOS
flutter build macos

# Android
flutter build apk

# iOS
flutter build ios
```

### Dependencias

Asegúrate de tener instaladas las siguientes dependencias para compilación local:

#### Linux
```bash
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
```

#### Windows
- Visual Studio 2019 o superior
- Windows 10 SDK

#### macOS
- Xcode
- CocoaPods

#### Android
- Android Studio
- Android SDK
- Java Development Kit (JDK)

#### iOS
- Xcode
- CocoaPods
- macOS (requerido para compilación iOS)

### Solución de Problemas

Si encuentras problemas con la compilación:

1. Verifica que todas las dependencias estén instaladas
2. Ejecuta `flutter doctor` para diagnosticar problemas
3. Limpia el proyecto con `flutter clean`
4. Obtén las dependencias con `flutter pub get`
5. Genera el código con `dart run build_runner build --delete-conflicting-outputs`

### Contacto

Si necesitas ayuda adicional, por favor abre un issue en el repositorio. 