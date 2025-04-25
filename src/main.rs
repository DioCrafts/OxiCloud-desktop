mod app;
mod domain;
mod application;
mod infrastructure;
mod ui;

use eframe::NativeOptions;
use log::LevelFilter;

fn main() -> eframe::Result<()> {
    // Initialize logging
    env_logger::Builder::new()
        .filter_level(LevelFilter::Info)
        .init();
    
    // Create app options
    let options = NativeOptions {
        initial_window_size: Some(egui::vec2(1024.0, 768.0)),
        ..Default::default()
    };
    
    // Run app
    eframe::run_native(
        "OxiCloud",
        options,
        Box::new(|cc| Box::new(app::OxiCloudApp::new(cc)))
    )
}