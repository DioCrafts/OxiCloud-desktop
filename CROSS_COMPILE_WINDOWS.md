# Compilación Cruzada de OxiCloud Desktop para Windows desde Linux/WSL

Este documento detalla los pasos para configurar y compilar la aplicación OxiCloud Desktop (basada en Rust/egui) para Windows desde un entorno Linux o WSL.

## 1. Prerequisitos

Instala las herramientas necesarias para compilación cruzada:

```bash
# Actualizar repositorios
sudo apt update

# Instalar compiladores y herramientas MinGW-w64 para Windows
sudo apt install -y mingw-w64 gcc-mingw-w64-x86-64

# También necesitarás estas herramientas para manejar dependencias nativas
sudo apt install -y pkg-config libssl-dev
```

## 2. Configurar Rust para compilación cruzada

```bash
# Agregar el target de Windows a rustup (si aún no está instalado)
rustup target add x86_64-pc-windows-gnu

# Verificar que el target se haya instalado correctamente
rustup target list | grep "windows"
```

## 3. Configurar el proyecto para compilación cruzada

Crea o modifica el archivo `.cargo/config.toml` en la raíz del proyecto:

```toml
[target.x86_64-pc-windows-gnu]
linker = "/usr/bin/x86_64-w64-mingw32-gcc"
ar = "/usr/bin/x86_64-w64-mingw32-ar"
```

## 4. Manejo de dependencias nativas

### SQLite (rusqlite)

La dependencia `rusqlite` usa `bundled` lo que facilita la compilación cruzada:

```toml
rusqlite = { version = "0.29.0", features = ["bundled"] }
```

### Keyring

Para `keyring` en Windows, necesitarás asegurarte que compile correctamente:

```bash
# Si hay problemas con la compilación de keyring, puedes usar esta configuración para Windows:
# Usando características específicas para Windows en cargo.toml
keyring = { version = "2.0.5", features = ["windows-local-credential-store"] }
```

### OpenSSL (via reqwest)

Nuestra configuración actual usa `rustls-tls` en lugar de OpenSSL nativo lo que facilita la compilación cruzada:

```toml
reqwest = { version = "0.11.20", features = ["json", "rustls-tls"] }
```

## 5. Compilación del proyecto

```bash
# Compilar para Windows (release)
cargo build --release --target x86_64-pc-windows-gnu

# El binario resultante estará en:
# target/x86_64-pc-windows-gnu/release/oxicloud-desktop-client.exe
```

## 6. Empaquetado para distribución

Para crear un paquete de distribución para usuarios Windows:

```bash
# Crear carpeta para distribución
mkdir -p dist/windows

# Copiar el binario
cp target/x86_64-pc-windows-gnu/release/oxicloud-desktop-client.exe dist/windows/

# Copiar cualquier recurso o archivo de configuración necesario
# cp -r assets/ dist/windows/

# Opcional: crear un archivo ZIP para distribución
cd dist
zip -r oxicloud-desktop-windows.zip windows/
```

## 7. Posibles problemas y soluciones

### Problema con recursos de la interfaz gráfica

Si necesitas incluir recursos gráficos para eframe/egui, asegúrate de empaquetarlos adecuadamente:

```rust
// En el código, usa rutas relativas para recursos
let image = include_bytes!("../assets/icon.png");
```

### Error de enlazado con bibliotecas de sistema de Windows

En algunos casos, puede ser necesario especificar bibliotecas de sistema adicionales:

```toml
# En .cargo/config.toml
[target.x86_64-pc-windows-gnu.dependencies]
advapi32-sys = "0.2.0"
winapi = { version = "0.3", features = ["winuser", "winbase"] }
```

### Problema con keyring en Windows

Si hay problemas con la biblioteca keyring:

```toml
# Modificar Cargo.toml para usar una implementación específica de Windows
[target.'cfg(windows)'.dependencies]
keyring = { version = "2.0.5", features = ["windows-local-credential-store"] }

[target.'cfg(not(windows))'.dependencies]
keyring = "2.0.5"
```

## 8. Pruebas

Es recomendable probar el binario Windows en una máquina virtual o con Wine antes de la distribución:

```bash
# Instalar Wine para pruebas (opcional)
sudo apt install wine64

# Probar la aplicación
wine target/x86_64-pc-windows-gnu/release/oxicloud-desktop-client.exe
```

## 9. Automatización con CI/CD

Para automatizar este proceso en un pipeline CI/CD, considera usar GitHub Actions con un workflow específico para compilación cruzada.

## Recursos adicionales

- [Documentación oficial de Rust sobre compilación cruzada](https://rust-lang.github.io/rustup/cross-compilation.html)
- [Documentación de egui/eframe](https://github.com/emilk/egui)
- [Guía de MinGW para Rust](https://rust-lang.github.io/rustup/concepts/toolchains.html)