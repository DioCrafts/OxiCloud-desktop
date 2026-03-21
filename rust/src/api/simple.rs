#[flutter_rust_bridge::frb(sync)] // Synchronous mode for simplicity of the demo
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Install a panic hook that logs to a file instead of crashing silently.
    // On Windows, release builds have no console, so panics would vanish.
    std::panic::set_hook(Box::new(|info| {
        let msg = format!("RUST PANIC: {info}");
        eprintln!("{msg}");

        // Best-effort: write to a log file next to the executable
        if let Ok(exe) = std::env::current_exe() {
            if let Some(dir) = exe.parent() {
                let log_path = dir.join("oxicloud_rust_panic.log");
                let timestamp = chrono::Utc::now().to_rfc3339();
                let entry = format!("[{timestamp}] {msg}\n");
                let _ = std::fs::OpenOptions::new()
                    .create(true)
                    .append(true)
                    .open(&log_path)
                    .and_then(|mut f| std::io::Write::write_all(&mut f, entry.as_bytes()));
            }
        }
    }));

    // Initialize tracing (logs) so Rust-side diagnostic messages are visible
    let _ = tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| tracing_subscriber::EnvFilter::new("info")),
        )
        .try_init();

    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}
