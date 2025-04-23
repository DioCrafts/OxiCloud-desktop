# OxiCloud Desktop Client

Cliente de escritorio multiplataforma para OxiCloud, implementado con Flutter utilizando arquitectura hexagonal.

## Características

- Sincronización de archivos eficiente con servidor OxiCloud
- Disponible para Windows, macOS, Linux, Android e iOS
- Soporte offline y sincronización inteligente basada en recursos
- Interfaz de usuario optimizada para escritorio y dispositivos móviles
- Papelera de reciclaje para recuperación de archivos eliminados
- Integración con sistemas de archivos nativos
- Visor de archivos integrado para formatos comunes
- Soporte para múltiples cuentas
- Temas claros y oscuros

## Requisitos del Sistema

### Windows
- Windows 10 (1809) o superior
- 2 GB de RAM mínimo
- 200 MB de espacio en disco para la aplicación
- WinFsp 1.9 o superior (para integración nativa de archivos)

### macOS
- macOS 10.15 (Catalina) o superior
- 2 GB de RAM mínimo
- 200 MB de espacio en disco para la aplicación
- macFUSE 4.0 o superior (para integración nativa de archivos)

### Linux
- Ubuntu 20.04 LTS, Fedora 34 o posterior
- 2 GB de RAM mínimo
- 200 MB de espacio en disco para la aplicación
- FUSE 2.9 o superior (para integración nativa de archivos)

### Android
- Android 6.0 (API 23) o superior
- 3 GB de RAM recomendado
- 100 MB de espacio en disco para la aplicación

### iOS
- iOS 13.0 o superior
- 3 GB de RAM recomendado
- 100 MB de espacio en disco para la aplicación

## Compilación desde Código Fuente

Este documento explica cómo compilar el cliente OxiCloud para diferentes plataformas y crear instaladores/paquetes de distribución.

### Configuración del Entorno de Desarrollo

1. **Instalar Flutter SDK**:
   ```bash
   git clone https://github.com/flutter/flutter.git
   cd flutter
   git checkout 3.10.0  # Recomendamos usar esta versión
   export PATH="$PATH:`pwd`/bin"  # Agregar Flutter al PATH
   ```

2. **Verificar dependencias**:
   ```bash
   flutter doctor
   ```
   Sigue las instrucciones para instalar las dependencias faltantes.

3. **Clonar el repositorio**:
   ```bash
   git clone https://github.com/yourusername/oxicloud-desktop.git
   cd oxicloud-desktop
   ```

4. **Instalar dependencias**:
   ```bash
   flutter pub get
   ```

### Compilación para Windows

#### Requisitos Previos
- Windows 10/11
- Visual Studio 2019 o 2022 con "Desktop development with C++"
- Git para Windows

#### Pasos para compilar
1. Asegúrate de tener Flutter configurado para Windows:
   ```bash
   flutter config --enable-windows-desktop
   ```

2. Compilar en modo debug:
   ```bash
   flutter build windows --debug
   ```

3. Compilar en modo release:
   ```bash
   flutter build windows --release
   ```
   El ejecutable se creará en `build\windows\runner\Release\`.

#### Crear Instalador
1. Instalar [Inno Setup](https://jrsoftware.org/isdl.php).

2. Usar el script de Inno Setup en `windows/inno_setup.iss`:
   ```bash
   "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" windows/inno_setup.iss
   ```
   El instalador se creará en `build\windows\installer\`.

### Compilación para macOS

#### Requisitos Previos
- macOS 10.15 o superior
- Xcode 13 o superior
- Cocoapods

#### Pasos para compilar
1. Asegúrate de tener Flutter configurado para macOS:
   ```bash
   flutter config --enable-macos-desktop
   ```

2. Compilar en modo debug:
   ```bash
   flutter build macos --debug
   ```

3. Compilar en modo release:
   ```bash
   flutter build macos --release
   ```
   La aplicación se creará en `build/macos/Build/Products/Release/`.

#### Crear DMG
1. Instalar [create-dmg](https://github.com/sindresorhus/create-dmg):
   ```bash
   brew install create-dmg
   ```

2. Crear el DMG:
   ```bash
   create-dmg \
     --volname "OxiCloud" \
     --volicon "assets/icons/macos/AppIcon.icns" \
     --window-pos 200 120 \
     --window-size 800 400 \
     --icon-size 100 \
     --icon "OxiCloud.app" 200 190 \
     --hide-extension "OxiCloud.app" \
     --app-drop-link 600 185 \
     "build/OxiCloud.dmg" \
     "build/macos/Build/Products/Release/OxiCloud.app"
   ```

### Compilación para Linux

#### Requisitos Previos
- Ubuntu 20.04 LTS o cualquier distribución compatible
- Dependencias necesarias:
  ```bash
  sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libfuse-dev
  ```

#### Pasos para compilar
1. Asegúrate de tener Flutter configurado para Linux:
   ```bash
   flutter config --enable-linux-desktop
   ```

2. Compilar en modo debug:
   ```bash
   flutter build linux --debug
   ```

3. Compilar en modo release:
   ```bash
   flutter build linux --release
   ```
   El ejecutable se creará en `build/linux/x64/release/bundle/`.

#### Crear Paquetes de Distribución

##### Crear .deb (Debian/Ubuntu)
1. Instalar herramientas de empaquetado:
   ```bash
   sudo apt-get install debhelper
   ```

2. Utilizar el script de creación de paquetes:
   ```bash
   cd packaging/linux
   ./create_deb.sh
   ```
   El paquete .deb se creará en `packaging/linux/build/`.

##### Crear .rpm (Fedora/RHEL)
1. Instalar herramientas de empaquetado:
   ```bash
   sudo dnf install rpm-build
   ```

2. Utilizar el script de creación de paquetes:
   ```bash
   cd packaging/linux
   ./create_rpm.sh
   ```
   El paquete .rpm se creará en `packaging/linux/build/`.

##### Crear AppImage
1. Descargar linuxdeploy y plugin AppImage:
   ```bash
   cd packaging/linux
   wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
   wget https://github.com/linuxdeploy/linuxdeploy-plugin-appimage/releases/download/continuous/linuxdeploy-plugin-appimage-x86_64.AppImage
   chmod +x linuxdeploy-x86_64.AppImage
   chmod +x linuxdeploy-plugin-appimage-x86_64.AppImage
   ```

2. Crear AppImage:
   ```bash
   ./create_appimage.sh
   ```
   El AppImage se creará en `packaging/linux/build/`.

### Compilación para Android

#### Requisitos Previos
- Android Studio
- JDK 11
- Android SDK

#### Pasos para compilar
1. Configurar la firma de la aplicación:
   - Crear archivo `android/key.properties` con información de la keystore
   - Configurar la keystore como se describe en [documentación de Flutter](https://flutter.dev/docs/deployment/android#signing-the-app)

2. Compilar APK:
   ```bash
   flutter build apk --release
   ```
   El APK se creará en `build/app/outputs/flutter-apk/app-release.apk`.

3. Compilar Bundle (recomendado para Google Play):
   ```bash
   flutter build appbundle --release
   ```
   El bundle se creará en `build/app/outputs/bundle/release/app-release.aab`.

### Compilación para iOS

#### Requisitos Previos
- macOS con Xcode 13 o superior
- Cuenta de desarrollador de Apple

#### Pasos para compilar
1. Configurar perfiles de aprovisionamiento en Xcode:
   - Abrir el proyecto iOS: `open ios/Runner.xcworkspace`
   - Configurar los perfiles de firma en Xcode

2. Compilar para dispositivos:
   ```bash
   flutter build ios --release --no-codesign
   ```

3. Archivar y distribuir a través de Xcode:
   - En Xcode, seleccionar `Product > Archive`
   - Usar el Organizador para validar y distribuir el IPA

## Optimizaciones de Rendimiento

### Batería
- Sincronización adaptativa según nivel de batería y estado de carga
- Suspensión de procesos no críticos en batería baja
- Monitoreo de consumo energético

### Red
- Sincronización delta (solo se envían los cambios)
- Compresión adaptativa según tipo de conexión
- Priorización de tráfico según importancia
- Estrategias de reconexión con backoff exponencial

### Almacenamiento
- Caché inteligente con priorización basada en uso
- Limpieza automática según límites configurables
- Gestión eficiente de archivos temporales
- Algoritmos de detección de cambios optimizados

### Memoria
- Liberación proactiva de recursos
- Carga diferida de datos y componentes
- Algoritmos de paginación eficientes
- Monitoreo y optimización del uso de memoria

## Estructura del Proyecto

El proyecto sigue una arquitectura hexagonal (puertos y adaptadores) para una clara separación de responsabilidades:

```
desktop_client/
├── lib/
│   ├── core/                    # Configuración y utilidades core
│   ├── domain/                  # Capa de dominio 
│   │   ├── entities/            # Entidades de dominio
│   │   ├── repositories/        # Interfaces de repositorios
│   │   └── services/            # Servicios de dominio
│   ├── application/             # Capa de aplicación
│   │   ├── dtos/                # Data Transfer Objects
│   │   ├── ports/               # Puertos (interfaces para adaptadores)
│   │   └── services/            # Casos de uso de la aplicación
│   ├── infrastructure/          # Capa de infraestructura
│   │   ├── adapters/            # Adaptadores de puertos
│   │   ├── repositories/        # Implementaciones de repositorios
│   │   └── services/            # Servicios de infraestructura
│   └── presentation/            # Capa de presentación (UI)
│       ├── pages/               # Páginas de la aplicación
│       ├── widgets/             # Widgets reutilizables
│       ├── providers/           # Proveedores de estado
│       └── routes/              # Definición de rutas
├── assets/                      # Recursos (imágenes, fuentes, etc.)
└── test/                        # Pruebas automatizadas
```

## Contribuir

Consulta [CONTRIBUTING.md](CONTRIBUTING.md) para obtener información sobre cómo contribuir al proyecto.

## Licencia

Este proyecto está licenciado bajo la Licencia MIT. Consulta el archivo [LICENSE](LICENSE) para más detalles.