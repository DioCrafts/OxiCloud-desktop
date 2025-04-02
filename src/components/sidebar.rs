use dioxus::prelude::*;
use dioxus_router::prelude::*;
use dioxus_free_icons::{
    icons::bootstrap_icons::{
        BsCloudUpload, BsGear, BsHouseDoor, BsPerson, BsTrash,
    },
    Icon,
};

use crate::Route;
use crate::SyncStatus;

#[derive(Props)]
pub struct SidebarProps {
    active_route: Option<String>,
    sync_status: SyncStatus,
}

pub fn Sidebar(cx: Scope<SidebarProps>) -> Element {
    let navigator = use_navigator();
    
    rsx! {
        div { 
            class: "sidebar",
            div { 
                class: "sidebar-header",
                img { 
                    src: "../assets/oxicloud-logo.svg", 
                    alt: "OxiCloud Logo",
                    width: "150"
                }
            }
            
            div { 
                class: "sidebar-menu",
                button {
                    class: "sidebar-item {if cx.props.active_route == Some(String::from("/")) { "active" } else { "" }}",
                    onclick: move |_| navigator.push(Route::Home {}),
                    Icon { icon: BsHouseDoor, width: 20, height: 20 }
                    span { "Inicio" }
                }
                
                button {
                    class: "sidebar-item {if cx.props.active_route.as_ref().map_or(false, |r| r.starts_with("/files")) { "active" } else { "" }}",
                    onclick: move |_| navigator.push(Route::Files { path: None }),
                    Icon { icon: BsCloudUpload, width: 20, height: 20 }
                    span { "Archivos" }
                }
                
                button {
                    class: "sidebar-item {if cx.props.active_route == Some(String::from("/account")) { "active" } else { "" }}",
                    onclick: move |_| navigator.push(Route::Account {}),
                    Icon { icon: BsPerson, width: 20, height: 20 }
                    span { "Cuenta" }
                }
                
                button {
                    class: "sidebar-item {if cx.props.active_route == Some(String::from("/settings")) { "active" } else { "" }}",
                    onclick: move |_| navigator.push(Route::Settings {}),
                    Icon { icon: BsGear, width: 20, height: 20 }
                    span { "Configuración" }
                }
            }
            
            // Indicador de estado de sincronización
            div { 
                class: "sync-status",
                match &cx.props.sync_status {
                    SyncStatus::Idle => rsx! {
                        span { class: "status-badge idle", "Sincronizado" }
                    },
                    SyncStatus::Syncing { progress, current_file } => rsx! {
                        span { class: "status-badge syncing", 
                            "Sincronizando {progress * 100.0}%"
                            if let Some(file) = current_file {
                                span { class: "current-file", "{file}" }
                            }
                        }
                    },
                    SyncStatus::Error { message } => rsx! {
                        span { class: "status-badge error", "Error: {message}" }
                    },
                    SyncStatus::Paused => rsx! {
                        span { class: "status-badge paused", "Pausado" }
                    }
                }
                
                button {
                    class: "sync-button",
                    "Sincronizar ahora"
                }
            }
        }
    }
}