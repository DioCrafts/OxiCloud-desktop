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

:: Obtener las últimas versiones de los paquetes
echo [INFO] Actualizando paquetes...
flutter pub upgrade

:: Obtener dependencias
echo [INFO] Obteniendo dependencias...
flutter pub get

:: Generar código
echo [INFO] Generando código...
dart run build_runner build --delete-conflicting-outputs

echo [INFO] ¡Actualización completada con éxito! 