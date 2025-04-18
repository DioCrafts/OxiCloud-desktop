use dioxus::prelude::*;
// Temporarily comment out icon imports until we can find the correct path
// use dioxus_free_icons::Icon;
// use dioxus_free_icons::bootstrap_icons as Bs;
use std::sync::Arc;

use crate::application::dtos::sync_dto::{SyncStateDto, SyncStatusDto};
use crate::application::ports::sync_port::SyncPort;

pub fn SyncStatusIndicator(cx: Scope) -> Element {
    // Get the sync service from context
    let sync_service = use_context::<Arc<dyn SyncPort>>(cx)
        .expect("Sync service not found in context");
        
    // State for the sync status
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
    
    // Subscribe to sync events
    use_effect(cx, (), |_| {
        let sync_service = sync_service.clone();
        let sync_status = sync_status.clone();
        
        async move {
            let mut event_receiver = sync_service.subscribe_to_events().await;
            
            // Spawn a task to listen for events
            tokio::spawn(async move {
                while let Ok(event) = event_receiver.recv().await {
                    match event {
                        crate::application::dtos::sync_dto::SyncEventDto::Progress(status) => {
                            // Update status
                            sync_status.set(status);
                        },
                        crate::application::dtos::sync_dto::SyncEventDto::Started => {
                            // Update state to syncing
                            sync_status.with_mut(|s| s.state = SyncStateDto::Syncing);
                        },
                        crate::application::dtos::sync_dto::SyncEventDto::Completed => {
                            // Update state to idle
                            sync_status.with_mut(|s| {
                                s.state = SyncStateDto::Idle;
                                s.last_sync = Some(chrono::Utc::now());
                            });
                        },
                        crate::application::dtos::sync_dto::SyncEventDto::Paused => {
                            // Update state to paused
                            sync_status.with_mut(|s| s.state = SyncStateDto::Paused);
                        },
                        crate::application::dtos::sync_dto::SyncEventDto::Resumed => {
                            // Update state to syncing
                            sync_status.with_mut(|s| s.state = SyncStateDto::Syncing);
                        },
                        crate::application::dtos::sync_dto::SyncEventDto::Error(msg) => {
                            // Update state to error
                            sync_status.with_mut(|s| {
                                s.state = SyncStateDto::Error;
                                s.error_message = Some(msg);
                            });
                        },
                        _ => {},
                    }
                }
            });
        }
    });
    
    // Get initial sync status
    use_effect(cx, (), |_| {
        let sync_service = sync_service.clone();
        let sync_status = sync_status.clone();
        
        async move {
            if let Ok(status) = sync_service.get_sync_status().await {
                sync_status.set(status);
            }
        }
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
                    SyncStateDto::Idle => rsx! { span { "✓" } },
                    SyncStateDto::Syncing => rsx! { span { class: "rotating", "↻" } },
                    SyncStateDto::Paused => rsx! { span { "⏸" } },
                    SyncStateDto::Error => rsx! { span { "⚠" } },
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