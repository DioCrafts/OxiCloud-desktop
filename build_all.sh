#!/bin/bash

# Colores para la salida
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Función para mostrar mensajes
function print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

function print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

function print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Verificar que Flutter está instalado
if ! command -v flutter &> /dev/null; then
    print_error "Flutter no está instalado. Por favor, instala Flutter primero."
    exit 1
fi

# Verificar que estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
    print_error "No se encontró el archivo pubspec.yaml. Asegúrate de estar en el directorio raíz del proyecto."
    exit 1
fi

# Limpiar el proyecto
print_message "Limpiando el proyecto..."
flutter clean

# Obtener dependencias
print_message "Obteniendo dependencias..."
flutter pub get

# Generar código
print_message "Generando código..."
dart run build_runner build --delete-conflicting-outputs

# Compilar para Linux
print_message "Compilando para Linux..."
if flutter build linux; then
    print_message "Compilación para Linux completada con éxito"
else
    print_error "Error al compilar para Linux"
    print_warning "Asegúrate de tener instaladas las dependencias de desarrollo de Flutter para Linux"
    print_warning "Ejecuta: sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev"
fi

# Compilar para Android
print_message "Compilando para Android..."
if flutter build apk; then
    print_message "Compilación para Android completada con éxito"
else
    print_error "Error al compilar para Android"
    print_warning "Asegúrate de tener configurado correctamente el entorno de desarrollo de Android"
fi

print_message "¡Compilación completada!"
print_message "Los archivos compilados se encuentran en:"
print_message "- Linux: build/linux/x64/release/bundle"
print_message "- Android: build/app/outputs/flutter-apk/app-release.apk" 