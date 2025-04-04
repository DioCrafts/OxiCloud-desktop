use dioxus::prelude::*;
use dioxus_desktop::{Config, WindowBuilder};
use dioxus_router::prelude::*;

use crate::interfaces::pages;

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
}

/// Launch and run the desktop application
pub fn run() {
    // Configure the app
    let config = Config::new()
        .with_window(
            WindowBuilder::new()
                .with_title("OxiCloud Desktop")
                .with_inner_size(dioxus_desktop::LogicalSize::new(1024.0, 768.0))
        )
        .with_custom_head("".into());

    // Launch the app
    dioxus_desktop::launch_with_props(
        app,
        AppProps {}, 
        config
    );
}

/// App properties
#[derive(Props, Clone, PartialEq)]
pub struct AppProps {}

/// Root application component
pub fn app(cx: Scope<AppProps>) -> Element {
    // Set up the theme (maybe from settings in the future)
    let theme = "light".to_string();

    cx.render(rsx! {
        style { include_str!("../assets/css/app.css") },
        div {
            class: "app {theme}",
            Router::<Route> {}
        }
    })
}
