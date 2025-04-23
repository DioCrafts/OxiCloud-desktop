# OxiCloud Desktop Client - Implementación con Flutter

## Estructura del Proyecto (Arquitectura Hexagonal)

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

## TODO List de Implementación (Estado Actual)

### Fase 1: Configuración e Infraestructura Base ✅

- [x] Crear proyecto Flutter con soporte para todas las plataformas
- [x] Configurar análisis estático y linting
- [x] Implementar sistema de inyección de dependencias
- [x] Configurar sistema de logging eficiente
- [x] Definir entidades base del dominio (basadas en las DTOs de OxiCloud)
- [x] Implementar manejo de errores centralizado
- [x] Configurar CI/CD para todas las plataformas

### Fase 2: Autenticación y Sincronización Básica ✅

- [x] Implementar cliente HTTP base con soporte para JWT
- [x] Crear adaptadores para API REST de OxiCloud
- [x] Implementar cliente WebDAV para operaciones de archivos
- [x] Desarrollar sistema de almacenamiento seguro de credenciales
- [x] Crear servicio de sincronización base (manual)
- [x] Implementar gestión de sesión (login, logout, refresh token)
- [x] Desarrollar pantallas de configuración de servidor y autenticación

### Fase 3: Gestión de Archivos y Carpetas ✅ (Completado)

- [x] Implementar navegador de archivos/carpetas
- [x] Desarrollar vista de detalles de archivos
- [x] Crear funcionalidad de subida de archivos (con soporte para pausar/reanudar)
- [x] Implementar descarga de archivos (con soporte para pausar/reanudar)
- [x] Desarrollar operaciones básicas (crear carpeta, renombrar, mover, eliminar)
- [x] Implementar visor de archivos integrado para formatos comunes
- [x] Crear sistema de cola de operaciones para manejo offline

### Fase 4: Sincronización Avanzada ✅

- [x] Implementar sincronización en segundo plano
- [x] Desarrollar sistema de detección de cambios locales
- [x] Crear resolución de conflictos
- [x] Implementar sincronización selectiva (carpetas específicas)
- [x] Optimizar sincronización para uso eficiente de ancho de banda y batería
- [x] Desarrollar mecanismo de reconexión automática
- [x] Implementar notificaciones de sincronización

### Fase 5: Características Avanzadas ✅ (Completado)

- [x] Integrar CardDAV para sincronización de contactos
- [x] Implementar vista de elementos recientes
- [x] Desarrollar sistema de favoritos
- [x] Crear funcionalidad de compartir archivos/carpetas
- [x] Implementar búsqueda avanzada (local y remota)
- [x] Desarrollar papelera de reciclaje
- [x] Crear monitoreo de cuota de almacenamiento
- [x] Implementar múltiples cuentas

### Fase 6: Optimizaciones y Características Específicas por Plataforma ✅ (Casi Completado)

- [x] Optimizar rendimiento en dispositivos de gama baja
- [x] Implementar gestión avanzada de memoria y caché
- [x] Desarrollar integración con exploradores de archivos nativos
- [ ] Crear extensiones de sistema para compartir archivos nativamente
- [x] Implementar reconocimiento de huellas/Face ID para seguridad
- [x] Optimizar UI para diferentes tamaños de pantalla
- [x] Implementar modo oscuro y temas personalizables
- [x] Crear widgets para acceso rápido (Android/iOS)

### Fase 7: Testing, Seguridad y Preparación para Producción ⚠️ (Parcialmente Completado)

- [ ] Implementar tests unitarios y de integración
- [x] Realizar pruebas de seguridad
- [x] Optimizar uso de recursos (CPU, memoria, batería)
- [x] Realizar pruebas de rendimiento
- [x] Implementar analíticas de uso (opt-in)
- [x] Crear sistema de reporte de errores
- [x] Preparar documentación de usuario
- [ ] Configurar distribución en tiendas (App Store, Google Play, Microsoft Store)

## Componentes Principales Implementados

### Core
- Sistema de logging optimizado con rotación de archivos
- Inyección de dependencias con GetIt
- Configuración de la aplicación con persistencia
- Servicios de plataforma (batería, conectividad, información de dispositivo)
- Seguridad y almacenamiento seguro de credenciales
- Sistema de analíticas con opt-in y reportes de errores

### Dominio
- Entidades básicas: File, Folder, StorageItem, User, TrashedItem, etc.
- Interfaces de repositorios: FileRepository, FolderRepository, SyncRepository, TrashRepository, NativeFileSystemRepository, etc.
- Servicios de dominio: MimeTypeService, PathService
- Soporte para múltiples cuentas y perfiles de usuario

### Aplicación
- Servicios de aplicación: FileService, FolderService, SyncService, AuthService, TrashService, NativeFileSystemService
- Manejo de casos de uso con verificación de permisos y recursos
- Sistema de manejo de errores contextualizado
- Visor de archivos integrado para formatos comunes (PDF, imágenes, texto, código)

### Infraestructura
- Adaptadores WebDAV para operaciones de archivos, carpetas y papelera
- Adaptadores para integración con sistemas de archivos nativos (Windows, macOS, Linux)
- Sistema de almacenamiento local optimizado con caché inteligente
- Sincronización en segundo plano adaptativa con monitoreo de recursos
- Gestión de recursos basada en estado del dispositivo
- Sistema de colas para operaciones con soporte offline
- Widgets para acceso rápido en dispositivos móviles

### Presentación
- Páginas principales: Login, ServerSetup, InitialSyncSetup, FileBrowser, TrashPage, SyncStatus, NativeFileSystemSettings
- Routing con protección de rutas basado en autenticación
- Proveedores de estado con Riverpod para manejo reactivo
- Widgets optimizados para uso eficiente de recursos
- Componentes UI adaptativos para diferentes tamaños de pantalla
- Sistema de notificaciones para estados de sincronización
- Tema oscuro y configuraciones de UI personalizables

## Pendientes Principales

### Prioridad Alta
1. Configurar distribución en tiendas (App Store, Google Play, Microsoft Store)
2. Implementar tests unitarios y de integración
3. Crear extensiones de sistema para compartir archivos nativamente

### Prioridad Media
1. Optimizar rendimiento de sincronización en sistemas de archivos nativos
2. Refinar documentación del código
3. Mejorar experiencia de onboarding para nuevos usuarios

### Prioridad Baja
1. Implementar integraciones con servicios de terceros (Google Drive, OneDrive)
2. Mejorar la accesibilidad de la interfaz
3. Añadir funcionalidades de colaboración avanzadas