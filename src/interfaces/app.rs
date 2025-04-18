use dioxus::prelude::*;
// Import hooks directly from prelude
use dioxus_desktop::{Config, WindowBuilder};
use dioxus_router::prelude::*;
use std::sync::Arc;

use crate::application::ports::auth_port::AuthPort;
use crate::application::ports::file_port::FilePort;
use crate::application::ports::sync_port::SyncPort;
use crate::application::ports::encryption_port::EncryptionPort;
use crate::application::ports::config_port::ConfigPort;
use crate::infrastructure::di::ServiceProvider;
use crate::interfaces::pages;

/// Create type alias for Scope to avoid import issues
pub type ScopeDef<T = ()> = dioxus::core::ScopeState<T>;

/// Main application router defining page routes
#[derive(Routable, Clone)]
#[rustfmt::skip]
pub enum Route {
    #[route("/")]
    Home {},
    
    #[route("/login")]
    Login {},
    
    #[route("/files")]
    Files {},
    
    #[route("/settings")]
    Settings {},
    
    #[route("/encryption")]
    Encryption {},
    
    #[route("/recovery")]
    PasswordRecovery {},
}

/// Launch and run the desktop application
pub fn run() {
    // Initialize the service provider for dependency injection
    let service_provider = ServiceProvider::new();
    
    // Configure the app
    let config = Config::new()
        .with_window(
            WindowBuilder::new()
                .with_title("OxiCloud Desktop")
                .with_inner_size(dioxus_desktop::LogicalSize::new(1024.0, 768.0))
        )
        .with_custom_head("".into());

    // Launch the app
    dioxus_desktop::launch::launch(
        || app(AppProps {
            auth_service: service_provider.get_auth_service(),
            file_service: service_provider.get_file_service(),
            sync_service: service_provider.get_sync_service(),
            encryption_service: service_provider.get_encryption_service(),
            config_service: service_provider.get_config_service(),
        }), 
        config
    );
}

/// App properties
#[derive(Props, Clone)]
pub struct AppProps {
    pub auth_service: Arc<dyn AuthPort>,
    pub file_service: Arc<dyn FilePort>,
    pub sync_service: Arc<dyn SyncPort>,
    pub encryption_service: Arc<dyn EncryptionPort>,
    pub config_service: Arc<dyn ConfigPort>,
}

/// Root application component
pub fn app(cx: Box<ScopeState<AppProps>>) -> Element {
    // Get theme from config (fallback to light theme)
    let theme = use_state(cx, || "light".to_string());
    
    // Provide services to all child components
    let auth_service = cx.props.auth_service.clone();
    let file_service = cx.props.file_service.clone();
    let sync_service = cx.props.sync_service.clone();
    let encryption_service = cx.props.encryption_service.clone();
    let config_service = cx.props.config_service.clone();
    use_context_provider(cx, || auth_service);
    use_context_provider(cx, || file_service);
    use_context_provider(cx, || sync_service);
    use_context_provider(cx, || encryption_service);
    use_context_provider(cx, || config_service);
    
    // Load theme from config
    use_effect(cx, (), |_| {
        let theme_state = theme.clone();
        let config_svc = config_service.clone();
        
        async move {
            // Try to load theme from config
            match config_svc.get_theme().await {
                Ok(theme_setting) => {
                    let theme_value = match theme_setting {
                        crate::domain::entities::config::Theme::Light => "light",
                        crate::domain::entities::config::Theme::Dark => "dark",
                        crate::domain::entities::config::Theme::System => {
                            // For system theme, we would detect OS theme here
                            // For now, default to light
                            "light"
                        }
                    };
                    theme_state.set(theme_value.to_string());
                },
                Err(_) => {
                    // If config doesn't exist yet, use default light theme
                    theme_state.set("light".to_string());
                }
            }
        }
    });
    
    // Check if user is already authenticated
    let auth = cx.props.auth_service.clone();
    let navigator = use_navigator(cx);

    // Perform initial authentication check
    use_effect(cx, (), |_| {
        let nav = navigator.clone();
        let auth_svc = auth.clone();
        
        async move {
            // Check if we have a stored user
            if !auth_svc.is_authenticated().await {
                nav.push(Route::Login {});
            } else {
                nav.push(Route::Files {});
            }
        }
    });

    cx.render(rsx! {
        style { "{include_str!(\"../assets/css/app.css\")}" },
        div {
            class: "app {theme}",
            Router::<Route> {
                render: pages::pages
            }
        }
    })
}
