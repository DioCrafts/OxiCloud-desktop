use dioxus::prelude::*;
use dioxus_router::prelude::*;
use dioxus_free_icons::icons::bootstrap_icons::Bs;
use dioxus_free_icons::Icon;

use crate::interfaces::app::Route;
use crate::components::sync_status_indicator::SyncStatusIndicator;

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
            }
            
            div { class: "sidebar-footer",
                SyncStatusIndicator {}
                
                button {
                    class: "btn btn-outline sync-button",
                    onclick: move |_| {
                        // TODO: Implement sync start/pause logic
                    },
                    "Sync Now"
                }

                button {
                    class: "btn btn-outline logout-button",
                    onclick: move |_| {
                        // TODO: Implement logout logic
                        navigator.push(Route::Login {});
                    },
                    Icon { icon: Bs::BoxArrowRight }
                    span { "Logout" }
                }
            }
        }
    })
}