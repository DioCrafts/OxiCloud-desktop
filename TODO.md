# OxiCloud Desktop App — TODO

> Estado actual: La app Flutter compila y ejecuta en Linux con UI completa,  
> pero todas las llamadas al core Rust son **stubs** que devuelven datos falsos.  
> El código Rust existe y tiene la lógica implementada, pero **nunca se conectó** con Flutter.

---

## Fase 1: Puente Flutter ↔ Rust (flutter_rust_bridge)

### 1.1 Instalar flutter_rust_bridge

```bash
# En pubspec.yaml, descomentar y actualizar:
flutter_rust_bridge: ^2.0.0

# Instalar el CLI del codegen
cargo install flutter_rust_bridge_codegen

# Verificar
flutter_rust_bridge_codegen --version
```

**Archivos a modificar:**
- `pubspec.yaml` — descomentar `flutter_rust_bridge`
- `rust/Cargo.toml` — verificar que `flutter_rust_bridge = "=2.0.0"` esté activo (ya lo está)

### 1.2 Configurar flutter_rust_bridge.yaml

Ya existe `flutter_rust_bridge.yaml` en la raíz. Verificar que apunte a:
```yaml
rust_input: rust/src/api.rs
dart_output: lib/generated/
```

### 1.3 Generar el código puente

```bash
cd oxicloud-app/
flutter_rust_bridge_codegen generate
```

Esto genera automáticamente:
- `lib/generated/api.dart` — Funciones Dart que llaman a Rust vía FFI
- `lib/generated/api.freezed.dart` — Tipos de datos serializados
- `lib/generated/frb_generated.dart` — Inicialización del puente
- `rust/src/frb_generated.rs` — Lado Rust del puente

### 1.4 Compilar la librería nativa Rust

```bash
# El codegen también compila Rust, pero manualmente sería:
cd rust/
cargo build --release  # genera target/release/liboxicloud_core.so (Linux)
                       # genera target/release/oxicloud_core.dll (Windows)
                       # genera target/release/liboxicloud_core.dylib (macOS)
```

### 1.5 Conectar RustBridgeDataSource con el código generado

**Archivo:** `lib/data/datasources/rust_bridge_datasource.dart`

Reemplazar todos los stubs por llamadas reales. Ejemplo:

```dart
// ANTES (stub actual):
Future<AuthResultDto> login(String server, String username, String password) async {
  await Future.delayed(const Duration(seconds: 1));
  return AuthResultDto(success: true, token: 'fake-token', ...);
}

// DESPUÉS (puente real):
Future<AuthResultDto> login(String server, String username, String password) async {
  final result = await api.login(server: server, username: username, password: password);
  return AuthResultDto(
    success: result.success,
    token: result.token,
    userId: result.userId,
    displayName: result.displayName,
    serverVersion: result.serverVersion,
  );
}
```

**Métodos a conectar (17 total):**

| # | Método Dart (stub) | Función Rust (api.rs) | Prioridad |
|---|---|---|---|
| 1 | `initialize()` | `initialize()` | 🔴 Alta |
| 2 | `login()` | `login()` | 🔴 Alta |
| 3 | `logout()` | `logout()` | 🔴 Alta |
| 4 | `isLoggedIn()` | `is_logged_in()` | 🔴 Alta |
| 5 | `getServerInfo()` | `get_server_info()` | 🟡 Media |
| 6 | `startSync()` | `start_sync()` | 🔴 Alta |
| 7 | `stopSync()` | `stop_sync()` | 🔴 Alta |
| 8 | `syncNow()` | `sync_now()` | 🔴 Alta |
| 9 | `getSyncStatus()` | `get_sync_status()` | 🔴 Alta |
| 10 | `getRemoteFolders()` | `get_remote_folders()` | 🟡 Media |
| 11 | `setSyncFolders()` | `set_sync_folders()` | 🟡 Media |
| 12 | `getSyncFolders()` | `get_sync_folders()` | 🟡 Media |
| 13 | `getConflicts()` | `get_conflicts()` | 🟢 Baja |
| 14 | `resolveConflict()` | `resolve_conflict()` | 🟢 Baja |
| 15 | `updateConfig()` | `update_config()` | 🟡 Media |
| 16 | `getConfig()` | `get_config()` | 🟡 Media |
| 17 | `getPendingItems()` | `get_pending_items()` | 🟢 Baja |

---

## Fase 2: Verificar y completar el Core Rust

### 2.1 Compilar el crate Rust independientemente

```bash
cd rust/
cargo build 2>&1
cargo test 2>&1
```

**Posibles problemas:**
- Dependencias desactualizadas (flutter_rust_bridge 2.0.0 vs versión más reciente)
- Incompatibilidades de API con la versión del codegen
- Tests unitarios que falten o fallen

### 2.2 Verificar WebDavClient contra OxiCloud Server

El `webdav_client.rs` implementa:
- `PROPFIND` — listar directorios remotos
- `GET` — descargar archivos
- `PUT` — subir archivos
- `MKCOL` — crear directorios
- `DELETE` — eliminar
- `MOVE` / `COPY`

**Verificar contra el server real:**
```bash
# Probar PROPFIND manual contra tu servidor OxiCloud
curl -X PROPFIND http://localhost:8080/remote.php/webdav/ \
  -H "Depth: 1" \
  -u "usuario:password" \
  -H "Content-Type: application/xml"
```

**Ajustes necesarios según el server:**
- URL base del WebDAV (puede variar según configuración)
- Headers de autenticación (JWT vs Basic Auth)
- Formato de respuesta XML del servidor
- Manejo de ETags para control de cambios

### 2.3 Verificar SQLite Storage

`sqlite_storage.rs` implementa:
- Migración automática de esquema
- CRUD de items sincronizados
- Historial de sincronización
- Detección de cambios locales

**Verificar:**
- Que la ruta de la BD sea correcta en cada plataforma
- Que las migraciones se ejecuten sin errores
- Que el esquema soporte todos los campos necesarios

### 2.4 Verificar File Watcher

`file_watcher.rs` implementa:
- Vigilancia de cambios en filesystem con crate `notify`
- Debouncing de eventos (evitar duplicados)
- Filtrado por patrones ignore

**Verificar:**
- Que funcione en Linux (inotify), Windows (ReadDirectoryChanges), macOS (FSEvents)
- Que el debounce no pierda eventos
- Que los patrones ignore funcionen (.git, node_modules, etc.)

---

## Fase 3: Autenticación Real

### 3.1 Conectar login contra OxiCloud Server

**Estado actual:** `auth_service.rs` intenta POST a `/api/auth/login` con JSON.

**Verificar:**
- Endpoint correcto del servidor OxiCloud
- Formato de request/response
- Almacenamiento seguro del token (keyring crate ya está en dependencies)

### 3.2 Persistencia de sesión

- Guardar token en keyring del sistema (ya hay dependency)
- Auto-login al arrancar si hay token guardado y válido
- Refresh del token antes de que expire

### 3.3 Manejo de errores de auth

- Token expirado → redirect a login
- Servidor inalcanzable → modo offline
- Credenciales inválidas → mensaje claro

---

## Fase 4: Sincronización Funcional

### 4.1 Algoritmo de sincronización bidireccional

`sync_service.rs` ya implementa:
1. Escanear directorio local
2. Consultar servidor remoto (PROPFIND)
3. Comparar timestamps/hashes
4. Detectar: nuevos, modificados, eliminados, conflictos
5. Ejecutar: uploads, downloads, deletes

**Verificar que funcione end-to-end:**
```
Local: ~/OxiCloud/
Remote: servidor:8080/remote.php/webdav/
```

### 4.2 Resolución de conflictos

- Conflicto: archivo modificado en ambos lados desde última sincronización
- Opciones: mantener local, mantener remoto, mantener ambos (renombrar)
- UI ya existe en `home_page.dart` para mostrar conflictos

### 4.3 Sincronización selectiva

- Elegir qué carpetas remotas sincronizar
- UI ya existe en `selective_sync_page.dart`
- Backend ya existe en `set_sync_folders()` / `get_sync_folders()`

### 4.4 Sincronización en tiempo real

- File watcher detecta cambios locales → sincroniza inmediatamente
- Polling periódico al servidor → detecta cambios remotos
- Configurar intervalo de polling en settings

---

## Fase 5: Funcionalidades Desktop

### 5.1 System Tray (bandeja del sistema)

**Dependencias ya instaladas:** `tray_manager`, `window_manager`

**Implementar:**
- Icono en bandeja del sistema
- Menú contextual: Abrir, Sincronizar ahora, Pausar, Configuración, Salir
- Indicador de estado: ✅ sincronizado, 🔄 sincronizando, ⚠️ conflictos, ❌ error
- Cerrar ventana → minimizar a bandeja (no salir)

**Archivo a crear:** `lib/presentation/services/tray_service.dart`

### 5.2 Inicio automático con el sistema

**Dependencia ya instalada:** `launch_at_startup`

**Implementar:**
- Opción en configuración para auto-arranque
- Registrar/desregistrar en el sistema operativo
- Arrancar minimizado en bandeja

### 5.3 Notificaciones del sistema

**Dependencia a añadir:** `flutter_local_notifications`

**Implementar:**
- Notificación cuando la sincronización termina
- Notificación cuando hay conflictos nuevos
- Notificación de errores de conexión

### 5.4 Gestión de ventana

**Ya parcialmente implementado en `main.dart`:**
- Tamaño inicial: 1200x800
- Tamaño mínimo: 800x600
- Centrado en pantalla

**Pendiente:**
- Recordar posición y tamaño de ventana
- Soporte multi-monitor

---

## Fase 6: Widgets Reutilizables

**Directorio vacío:** `lib/presentation/widgets/`

### Widgets a crear:

| Widget | Descripción | Usado en |
|---|---|---|
| `sync_status_indicator.dart` | Icono animado de estado de sync | HomePage, Tray |
| `file_sync_tile.dart` | Tile con info de archivo sincronizando | HomePage |
| `conflict_card.dart` | Card de conflicto con acciones | HomePage |
| `folder_tree.dart` | Árbol de carpetas seleccionables | SelectiveSyncPage |
| `server_status_badge.dart` | Badge de conexión al servidor | HomePage, AppBar |
| `progress_ring.dart` | Anillo de progreso circular | HomePage |
| `storage_usage_bar.dart` | Barra de uso de almacenamiento | HomePage |

---

## Fase 7: Modelos de Datos (Freezed)

**Directorio vacío:** `lib/data/models/`

### Opción A: Usar tipos generados por flutter_rust_bridge
Los tipos de `api.rs` se generan automáticamente como clases Dart inmutables.
No necesitas modelos adicionales.

### Opción B: Modelos intermedios con Freezed
Si quieres desacoplar la capa de datos del puente:

```dart
// lib/data/models/auth_model.dart
@freezed
class AuthModel with _$AuthModel {
  const factory AuthModel({
    required bool success,
    required String token,
    required String userId,
    String? displayName,
  }) = _AuthModel;

  factory AuthModel.fromRustBridge(AuthResult result) => ...
}
```

**Generar con:**
```bash
dart run build_runner build
```

---

## Fase 8: Testing

### 8.1 Tests unitarios Rust
```bash
cd rust/
cargo test
```
- Tests de entities (ya hay lógica de validación)
- Tests de sync algorithm (mock de ports)
- Tests de WebDAV XML parsing

### 8.2 Tests unitarios Flutter
**Archivos existentes (a completar):**
- `test/blocs/auth_bloc_test.dart` — usa mocktail
- `test/blocs/sync_bloc_test.dart` — usa mocktail

**Tests a añadir:**
- `test/usecases/` — test de cada caso de uso
- `test/repositories/` — test de repositorios con datasource mockeado
- `test/data/` — test del datasource contra el puente (integration)

### 8.3 Tests de integración
```bash
flutter test integration_test/
```
- Login → sync → logout flow completo
- Sincronización de archivos reales
- Resolución de conflictos

---

## Fase 9: Build de Release

### 9.1 Linux
```bash
flutter build linux --release
# Output: build/linux/x64/release/bundle/oxicloud_app
```

**Packaging:**
- AppImage (portable)
- .deb (Debian/Ubuntu)
- Flatpak (universal)
- Snap

### 9.2 Windows
```powershell
flutter build windows --release
# Output: build\windows\x64\runner\Release\oxicloud_app.exe
```

**Packaging:**
- MSIX (Microsoft Store)
- Inno Setup (.exe installer)
- WiX (.msi)

### 9.3 macOS
```bash
flutter build macos --release
# Output: build/macos/Build/Products/Release/oxicloud_app.app
```

**Packaging:**
- .dmg
- .pkg
- Mac App Store

**Nota:** macOS requiere codesigning y notarización para distribución.

---

## Fase 10: CI/CD

### 10.1 GitHub Actions

```yaml
# .github/workflows/build.yml
- Linux: ubuntu-latest + flutter + rust
- Windows: windows-latest + flutter + rust
- macOS: macos-latest + flutter + rust
```

### 10.2 Pipeline por plataforma

1. Checkout
2. Instalar Rust toolchain
3. Instalar Flutter SDK
4. `flutter_rust_bridge_codegen generate`
5. `cargo test` (Rust)
6. `flutter test` (Dart)
7. `flutter build <platform> --release`
8. Upload artefacto

---

## Orden de ejecución recomendado

```
Fase 1 (Puente)        ████████████████████  ← PRIMERO: sin esto nada funciona
Fase 2 (Core Rust)     ████████████████
Fase 3 (Auth)          ████████████
Fase 4 (Sync)          ████████████████████
Fase 5 (Desktop)       ████████████
Fase 6 (Widgets)       ████████
Fase 7 (Modelos)       ████
Fase 8 (Testing)       ████████████████
Fase 9 (Release)       ████████
Fase 10 (CI/CD)        ████████████
```

**Estimación total:** ~40-60 horas de desarrollo

---

## Archivos clave del proyecto

| Archivo | Rol | Estado |
|---|---|---|
| `rust/src/api.rs` | API FFI con `#[frb]` | ✅ Definido, pendiente generar bindings |
| `rust/src/application/sync_service.rs` | Lógica de sync | ✅ Implementado |
| `rust/src/infrastructure/webdav_client.rs` | Cliente WebDAV | ✅ Implementado |
| `rust/src/infrastructure/sqlite_storage.rs` | Persistencia local | ✅ Implementado |
| `lib/data/datasources/rust_bridge_datasource.dart` | Puente Dart→Rust | ❌ **100% STUBBED** |
| `lib/presentation/blocs/auth/auth_bloc.dart` | Estado auth | ✅ Implementado |
| `lib/presentation/blocs/sync/sync_bloc.dart` | Estado sync | ✅ Implementado |
| `lib/presentation/pages/*.dart` | UI completa | ✅ Implementado |
| `lib/generated/` | Código auto-generado | ❌ **NO EXISTE** |
| `lib/presentation/widgets/` | Widgets reutilizables | ❌ **VACÍO** |
| `lib/data/models/` | Modelos Freezed | ❌ **VACÍO** |

---

## Comandos rápidos de referencia

```bash
# Generar puente Flutter↔Rust
flutter_rust_bridge_codegen generate

# Compilar Rust
cd rust && cargo build --release

# Compilar Flutter Linux
flutter build linux --debug

# Compilar Flutter Windows  
flutter build windows --release

# Ejecutar tests Rust
cd rust && cargo test

# Ejecutar tests Flutter
flutter test

# Generar modelos Freezed
dart run build_runner build --delete-conflicting-outputs

# Ejecutar la app
cd build/linux/x64/debug/bundle && ./oxicloud_app
```
