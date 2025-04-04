# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build/Run Commands
- Build: `cargo build`
- Run development mode: `cargo run`
- Release build: `cargo build --release`
- Run tests: `cargo test` (or `cargo test <test_name>` for a specific test)
- Lint: `cargo clippy`
- Format: `cargo fmt`

## Code Style Guidelines
- Indentation: 4 spaces
- Line length: ~100 characters
- Naming: snake_case for variables/functions, PascalCase for types/structs
- Imports: Group by external crates first, then internal modules
- Error handling: Use Option/Result types with thiserror for custom errors
- Documentation: Use /// for doc comments on public items
- Components: Use Dioxus patterns with #[derive(Props)] and hooks
- State: Leverage Dioxus state management (use_state, use_ref)

When contributing, follow existing patterns in similar files and run `cargo fmt` and `cargo clippy` before submitting changes.