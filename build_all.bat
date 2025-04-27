@echo off
setlocal enabledelayedexpansion

:: Verificar que Flutter está instalado
where flutter >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Flutter no está instalado. Por favor, instala Flutter primero.
    exit /b 1
)

:: Verificar que estamos en el directorio correcto
if not exist pubspec.yaml (
    echo [ERROR] No se encontró el archivo pubspec.yaml. Asegúrate de estar en el directorio raíz del proyecto.
    exit /b 1
)

:: Limpiar el proyecto
echo [INFO] Limpiando el proyecto...
flutter clean

:: Obtener dependencias
echo [INFO] Obteniendo dependencias...
flutter pub get

:: Generar código
echo [INFO] Generando código...
flutter pub run build_runner build --delete-conflicting-outputs

:: Compilar para Windows
echo [INFO] Compilando para Windows...
flutter build windows --release

:: Compilar para Linux
echo [INFO] Compilando para Linux...
flutter build linux --release

:: Compilar para macOS
echo [INFO] Compilando para macOS...
flutter build macos --release

:: Compilar para Android
echo [INFO] Compilando para Android...
flutter build apk --release

:: Compilar para iOS
echo [INFO] Compilando para iOS...
flutter build ios --release

echo [INFO] ¡Compilación completada con éxito!
echo [INFO] Los archivos compilados se encuentran en:
echo [INFO] - Windows: build\windows\runner\Release
echo [INFO] - Linux: build\linux\x64\release\bundle
echo [INFO] - macOS: build\macos\Build\Products\Release
echo [INFO] - Android: build\app\outputs\flutter-apk\app-release.apk
echo [INFO] - iOS: build\ios\Release-iphoneos 