// OxiCloud Desktop Client - Aplicación principal
// Construido con Dioxus en Rust

// Módulos
mod components;
mod models;
mod pages;
mod services;
mod utils;

use dioxus::prelude::*;
use dioxus_desktop::{
    tao::menu::{MenuBar, MenuItem},
    Config, LogicalSize, WindowBuilder,
};
use dioxus_router::prelude::*;

// Importaciones de páginas
use pages::{
    account::AccountPage,
    files::FilesPage,
    login::LoginPage,
    settings::SettingsPage,
    sync_status::SyncStatusPage,
};

// Estado global de la aplicación
#[derive(Clone, Debug)]
pub struct AppState {
    logged_in: bool,
    server_url: String,
    username: String,
    token: Option<String>,
    sync_status: SyncStatus,
}

// Estado de sincronización
#[derive(Clone, Debug, PartialEq)]
pub enum SyncStatus {
    Idle,
    Syncing { progress: f32, current_file: Option<String> },
    Error { message: String },
    Paused,
}

// Rutas de la aplicación
#[derive(Clone, Routable)]
enum Route {
    #[route("/")]
    Home {},
    #[route("/files/:path")]
    Files { path: Option<String> },
    #[route("/account")]
    Account {},
    #[route("/settings")]
    Settings {},
    #[route("/status")]
    SyncStatus {},
    #[route("/login")]
    Login {},
}

fn main() {
    // Configuración del registro de eventos
    tracing_subscriber::fmt::init();
    
    // Preparación del menú de la aplicación
    let menu = MenuBar::new()
        .add_submenu(
            MenuBar::new()
                .add_native_item(MenuItem::About("OxiCloud Desktop".to_string()))
                .add_native_item(MenuItem::Separator)
                .add_native_item(MenuItem::Hide)
                .add_native_item(MenuItem::HideOthers)
                .add_native_item(MenuItem::ShowAll)
                .add_native_item(MenuItem::Separator)
                .add_native_item(MenuItem::Quit),
            "OxiCloud".to_string(),
        )
        .add_submenu(
            MenuBar::new()
                .add_item(MenuItem::new("Sincronizar ahora", false, None, None))
                .add_item(MenuItem::new("Pausar sincronización", false, None, None))
                .add_native_item(MenuItem::Separator)
                .add_item(MenuItem::new("Abrir carpeta de OxiCloud", false, None, None)),
            "Acciones".to_string(),
        );

    // Iniciar Dioxus Desktop
    dioxus_desktop::launch_cfg(
        app,
        Config::new()
            .with_window(
                WindowBuilder::new()
                    .with_title("OxiCloud Desktop")
                    .with_inner_size(LogicalSize::new(1000, 700))
                    .with_min_inner_size(LogicalSize::new(800, 600)),
            )
            .with_menu(menu),
    );
}

// Componente principal de la aplicación
fn app() -> Element {
    // Estado global
    let state = use_signal(|| AppState {
        logged_in: false,
        server_url: String::new(),
        username: String::new(),
        token: None,
        sync_status: SyncStatus::Idle,
    });

    rsx! {
        Router::<Route> {}
    }
}

// Implementación de Router
impl RoutingComponent for Route {
    fn render(self) -> Element {
        match self {
            Route::Home {} => rsx! {
                FilesPage { path: None }
            },
            Route::Files { path } => rsx! {
                FilesPage { path: path }
            },
            Route::Account {} => rsx! {
                AccountPage {}
            },
            Route::Settings {} => rsx! {
                SettingsPage {}
            },
            Route::SyncStatus {} => rsx! {
                SyncStatusPage {}
            },
            Route::Login {} => rsx! {
                LoginPage {}
            },
        }
    }
}