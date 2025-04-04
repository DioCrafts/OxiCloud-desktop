use dioxus::prelude::*;
use dioxus_free_icons::icons::bootstrap_icons::Bs;
use dioxus_free_icons::Icon;

use crate::application::dtos::sync_dto::{SyncStateDto, SyncStatusDto};

#[component]
pub fn SyncStatusIndicator(cx: Scope) -> Element {
    // In a real implementation, this would come from a state manager or service
    let sync_status = use_state(cx, || SyncStatusDto {
        state: SyncStateDto::Idle,
        last_sync: None,
        current_operation: None,
        current_file: None,
        total_files: 0,
        processed_files: 0,
        total_bytes: 0,
        processed_bytes: 0,
        error_message: None,
    });
    
    let status_class = match sync_status.get().state {
        SyncStateDto::Idle => "status-idle",
        SyncStateDto::Syncing => "status-syncing",
        SyncStateDto::Paused => "status-paused",
        SyncStateDto::Error => "status-error",
    };
    
    cx.render(rsx! {
        div { class: "sync-indicator {status_class}",
            div { class: "sync-icon",
                match sync_status.get().state {
                    SyncStateDto::Idle => rsx! { Icon { icon: Bs::CheckCircleFill } },
                    SyncStateDto::Syncing => rsx! { Icon { icon: Bs::ArrowRepeat, class: "rotating" } },
                    SyncStateDto::Paused => rsx! { Icon { icon: Bs::PauseFill } },
                    SyncStateDto::Error => rsx! { Icon { icon: Bs::ExclamationTriangleFill } },
                }
            }
            
            div { class: "sync-details",
                span { class: "sync-status-text",
                    match sync_status.get().state {
                        SyncStateDto::Idle => "All files in sync",
                        SyncStateDto::Syncing => "Syncing files...",
                        SyncStateDto::Paused => "Sync paused",
                        SyncStateDto::Error => "Sync error",
                    }
                }
                
                if let Some(current_file) = &sync_status.get().current_file {
                    span { class: "sync-current-file", "{current_file}" }
                }
                
                if sync_status.get().state == SyncStateDto::Syncing {
                    div { class: "sync-progress-container",
                        div {
                            class: "sync-progress-bar",
                            style: "width: {sync_status.get().progress_percentage()}%"
                        }
                    }
                    
                    span { class: "sync-progress-text",
                        "{sync_status.get().processed_files}/{sync_status.get().total_files} files"
                    }
                }
                
                if let Some(error) = &sync_status.get().error_message {
                    span { class: "sync-error-message", "{error}" }
                }
            }
        }
    })
}