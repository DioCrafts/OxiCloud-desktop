# OxiCloud Desktop — TODO

> **Estado actual:** App Flutter + Rust FFI compilando en las 5 plataformas
> (Linux, Windows, macOS, Android, iOS). El bridge FFI está operativo con
> flutter_rust_bridge 2.11.1. Las dependencias Rust están actualizadas a
> las últimas versiones estables.

---

## Fase 1: Funcionalidad Core ✅

- [x] Estructura Clean Architecture (Flutter + Rust)
- [x] Bridge FFI operativo (flutter_rust_bridge 2.11.1)
- [x] WebDAV client compatible con OxiCloud server
- [x] SQLite storage para estado de sincronización
- [x] File watcher con notify
- [x] Soporte multiplataforma (desktop + mobile)

## Fase 2: Integración End-to-End

- [ ] Test de conexión real con servidor OxiCloud
- [ ] Flujo completo de login → sync → display
- [ ] Manejo de errores de red con retry exponencial
- [ ] Persistencia de sesión entre reinicios

## Fase 3: Sincronización Avanzada

- [ ] Delta sync (solo cambios incrementales)
- [ ] Resolución de conflictos interactiva en UI
- [ ] Sincronización selectiva de carpetas
- [ ] Throttling de ancho de banda configurable
- [ ] Cola de operaciones con priorización

## Fase 4: UX & Plataforma

- [ ] System tray con indicador de estado (desktop)
- [ ] Notificaciones nativas (sync completada, conflictos)
- [ ] Background sync service (mobile)
- [ ] Soporte offline completo
- [ ] Dark mode / themes

## Fase 5: Producción

- [ ] CI/CD pipeline (GitHub Actions)
- [ ] Firma de código (code signing) para todas las plataformas
- [ ] Auto-update mechanism (desktop)
- [ ] Crash reporting (Sentry)
- [ ] Telemetría opt-in
- [ ] Internacionalización (i18n)

## Fase 6: Testing

- [ ] Unit tests — Rust core (>80% coverage)
- [ ] Unit tests — Dart BLoCs
- [ ] Integration tests — Flutter
- [ ] E2E tests contra servidor real
