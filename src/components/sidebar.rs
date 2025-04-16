use dioxus::prelude::*;
use dioxus_router::prelude::*;
use dioxus_free_icons::icons::bootstrap_icons::Bs;
use dioxus_free_icons::Icon;
use std::sync::Arc;

use crate::interfaces::app::Route;
use crate::components::sync_status_indicator::SyncStatusIndicator;
use crate::application::ports::sync_port::SyncPort;
use crate::application::ports::auth_port::AuthPort;

#[component]
pub fn Sidebar(cx: Scope) -> Element {
    let navigator = use_navigator(cx);
    let current_route = use_route::<Route>(cx);
    
    cx.render(rsx! {
        aside { class: "sidebar",
            div { class: "sidebar-header",
                h1 { class: "app-title", "OxiCloud" }
            }
            
            nav { class: "sidebar-menu",
                Link {
                    to: Route::Files {},
                    class: if matches!(current_route, Route::Files{}) { "nav-item active" } else { "nav-item" },
                    Icon { class: "nav-item-icon", icon: Bs::FolderFill }
                    span { "Files" }
                }
                
                Link {
                    to: Route::Settings {},
                    class: if matches!(current_route, Route::Settings{}) { "nav-item active" } else { "nav-item" },
                    Icon { class: "nav-item-icon", icon: Bs::GearFill }
                    span { "Settings" }
                }
                
                Link {
                    to: Route::Encryption {},
                    class: if matches!(current_route, Route::Encryption{}) { "nav-item active" } else { "nav-item" },
                    Icon { class: "nav-item-icon", icon: Bs::ShieldLockFill }
                    span { "Encryption" }
                }
            }
            
            div { class: "sidebar-footer",
                SyncStatusIndicator {}
                
                button {
                    class: "btn btn-outline sync-button",
                    onclick: move |_| {
                        let sync_service = use_context::<Arc<dyn crate::application::ports::sync_port::SyncPort>>(cx)
                            .expect("Sync service not found in context");
                            
                        cx.spawn(async move {
                            let _ = sync_service.start_sync().await;
                        });
                    },
                    "Sync Now"
                }

                button {
                    class: "btn btn-outline logout-button",
                    onclick: move |_| {
                        let auth_service = use_context::<Arc<dyn AuthPort>>(cx)
                            .expect("Auth service not found in context");
                        let navigator = navigator.clone();
                            
                        cx.spawn(async move {
                            if let Ok(_) = auth_service.logout().await {
                                navigator.push(Route::Login {});
                            }
                        });
                    },
                    Icon { icon: Bs::BoxArrowRight }
                    span { "Logout" }
                }
            }
        }
    })
}