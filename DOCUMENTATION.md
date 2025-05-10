# Documentación Técnica - OxiCloud Client

## 1. Introducción

OxiCloud Client es una aplicación multiplataforma desarrollada en Flutter que sirve como cliente para el servidor OxiCloud. La aplicación está diseñada siguiendo los principios de la arquitectura hexagonal y las mejores prácticas de desarrollo Flutter.

## 2. Arquitectura

### 2.1 Arquitectura Hexagonal

La aplicación sigue una arquitectura hexagonal (también conocida como puertos y adaptadores) con las siguientes capas:

#### 2.1.1 Capa de Dominio
- **Entidades**: Representaciones de los objetos de negocio
  - `User`
  - `File`
  - `Folder`
  - `Share`
  - `Calendar`
  - `CalendarEvent`
  - `TrashedItem`

- **Repositorios (Interfaces)**:
  - `AuthRepository`
  - `FileRepository`
  - `FolderRepository`
  - `ShareRepository`
  - `CalendarRepository`
  - `TrashRepository`

- **Servicios de Dominio**:
  - `AuthService`
  - `FileService`
  - `FolderService`
  - `ShareService`
  - `CalendarService`
  - `TrashService`

#### 2.1.2 Capa de Aplicación
- **Casos de Uso**:
  - `LoginUseCase`
  - `UploadFileUseCase`
  - `DownloadFileUseCase`
  - `ShareFileUseCase`
  - `CreateFolderUseCase`
  - `MoveFileUseCase`
  - `DeleteFileUseCase`
  - `RestoreFromTrashUseCase`

- **Servicios de Aplicación**:
  - `FileManagementService`
  - `UserManagementService`
  - `ShareManagementService`
  - `CalendarManagementService`

#### 2.1.3 Capa de Infraestructura
- **Adaptadores de Repositorio**:
  - `ApiAuthRepository`
  - `ApiFileRepository`
  - `ApiFolderRepository`
  - `ApiShareRepository`
  - `ApiCalendarRepository`
  - `ApiTrashRepository`

- **Servicios de Infraestructura**:
  - `ApiClient`
  - `LocalStorageService`
  - `FileSystemService`
  - `NetworkService`

#### 2.1.4 Capa de Presentación
- **Vistas**:
  - `LoginView`
  - `HomeView`
  - `FileExplorerView`
  - `ShareView`
  - `CalendarView`
  - `SettingsView`

- **Controladores**:
  - `AuthController`
  - `FileController`
  - `FolderController`
  - `ShareController`
  - `CalendarController`
  - `SettingsController`

- **Widgets**:
  - `FileItem`
  - `FolderItem`
  - `ShareDialog`
  - `UploadProgress`
  - `FilePreview`
  - `CalendarWidget`

### 2.2 Patrones de Diseño

- **Inyección de Dependencias**: Uso de `get_it` para la gestión de dependencias
- **Estado**: Uso de `flutter_bloc` para la gestión del estado
- **Navegación**: Uso de `go_router` para la navegación
- **Almacenamiento Local**: Uso de `isar` para el almacenamiento local
- **Redes**: Uso de `dio` para las llamadas a la API
- **Gestión de Archivos**: Uso de `file_picker` y `path_provider`

## 3. Características Principales

### 3.1 Autenticación y Seguridad
- Login/Logout
- Gestión de sesiones
- Almacenamiento seguro de tokens
- Soporte para autenticación biométrica

### 3.2 Gestión de Archivos
- Explorador de archivos
- Subida/descarga de archivos
- Vista previa de archivos
- Compartir archivos
- Gestión de favoritos
- Búsqueda de archivos

### 3.3 Calendario
- Vista de calendario
- Gestión de eventos
- Sincronización con CalDAV
- Notificaciones de eventos

### 3.4 Características Adicionales
- Modo offline
- Sincronización automática
- Gestión de papelera
- Compartir archivos
- Gestión de contactos

## 4. Tecnologías y Dependencias

### 4.1 Dependencias Principales
```yaml
dependencies:
  flutter:
    sdk: flutter
  # Estado
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  
  # Navegación
  go_router: ^13.0.0
  
  # Redes
  dio: ^5.4.0
  connectivity_plus: ^5.0.2
  
  # Almacenamiento
  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1
  path_provider: ^2.1.2
  
  # UI
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0
  flutter_markdown: ^0.6.18
  
  # Utilidades
  intl: ^0.18.1
  file_picker: ^6.1.1
  permission_handler: ^11.1.0
  url_launcher: ^6.2.2
  share_plus: ^7.2.1
  image_picker: ^1.0.5
  video_player: ^2.8.1
  pdf_render: ^1.4.0
  flutter_local_notifications: ^16.2.0
```

### 4.2 Dependencias de Desarrollo
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.7
  isar_generator: ^3.1.0+1
  mockito: ^5.4.4
  flutter_launcher_icons: ^0.13.1
  flutter_native_splash: ^2.3.9
```

## 5. Estructura de Directorios

```
lib/
├── core/
│   ├── config/
│   ├── error/
│   ├── network/
│   ├── storage/
│   └── utils/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── services/
├── application/
│   ├── use_cases/
│   └── services/
├── infrastructure/
│   ├── repositories/
│   └── services/
└── presentation/
    ├── views/
    ├── controllers/
    └── widgets/
```

## 6. Flujos de Trabajo Principales

### 6.1 Autenticación
1. Usuario ingresa credenciales
2. `LoginUseCase` valida credenciales
3. `ApiAuthRepository` realiza la petición
4. Token se almacena localmente
5. Usuario es redirigido al home

### 6.2 Subida de Archivos
1. Usuario selecciona archivo
2. `UploadFileUseCase` inicia el proceso
3. `ApiFileRepository` maneja la subida
4. Progreso se muestra en UI
5. Archivo aparece en el explorador

### 6.3 Compartir Archivos
1. Usuario selecciona archivo
2. `ShareFileUseCase` inicia el proceso
3. `ApiShareRepository` crea el enlace
4. UI muestra opciones de compartir
5. Usuario comparte el enlace

## 7. Consideraciones de Seguridad

- Almacenamiento seguro de tokens
- Validación de certificados SSL
- Manejo seguro de archivos locales
- Permisos de aplicación
- Cifrado de datos sensibles

## 8. Optimizaciones

- Caché de archivos frecuentes
- Compresión de imágenes
- Lazy loading de listas
- Gestión eficiente de memoria
- Modo offline

## 9. Pruebas

### 9.1 Tipos de Pruebas
- Pruebas unitarias
- Pruebas de integración
- Pruebas de widget
- Pruebas de UI
- Pruebas de rendimiento

### 9.2 Cobertura
- Dominio: 90%
- Aplicación: 85%
- Infraestructura: 80%
- Presentación: 75%

## 10. Despliegue

### 10.1 Plataformas Soportadas
- Android
- iOS
- Windows
- macOS
- Linux

### 10.2 Proceso de Build
1. Validación de código
2. Ejecución de pruebas
3. Generación de assets
4. Build de la aplicación
5. Firma del paquete
6. Despliegue en stores

## 11. Mantenimiento

### 11.1 Monitoreo
- Crashlytics
- Analytics
- Performance Monitoring
- Error Tracking

### 11.2 Actualizaciones
- Actualizaciones automáticas
- Notificaciones de nuevas versiones
- Migración de datos
- Backward compatibility 