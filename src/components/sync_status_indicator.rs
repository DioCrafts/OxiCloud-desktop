use dioxus::prelude::*;
use dioxus_free_icons::{
    icons::bootstrap_icons::{
        BsCloudCheckFill, BsCloudSlashFill, BsCloudUploadFill, BsPauseFill,
    },
    Icon,
};

use crate::SyncStatus;

#[derive(Props)]
pub struct SyncStatusIndicatorProps {
    status: SyncStatus,
    #[props(default)]
    compact: bool,
}

pub fn SyncStatusIndicator(cx: Scope<SyncStatusIndicatorProps>) -> Element {
    let status_class = match &cx.props.status {
        SyncStatus::Idle => "status-idle",
        SyncStatus::Syncing { .. } => "status-syncing",
        SyncStatus::Error { .. } => "status-error",
        SyncStatus::Paused => "status-paused",
    };
    
    let status_icon = match &cx.props.status {
        SyncStatus::Idle => rsx! { Icon { icon: BsCloudCheckFill, width: 16, height: 16 } },
        SyncStatus::Syncing { .. } => rsx! { Icon { icon: BsCloudUploadFill, width: 16, height: 16 } },
        SyncStatus::Error { .. } => rsx! { Icon { icon: BsCloudSlashFill, width: 16, height: 16 } },
        SyncStatus::Paused => rsx! { Icon { icon: BsPauseFill, width: 16, height: 16 } },
    };
    
    let status_text = match &cx.props.status {
        SyncStatus::Idle => "Sincronizado",
        SyncStatus::Syncing { progress, current_file } => if current_file.is_some() {
            "Sincronizando..."
        } else {
            "Sincronizando..."
        },
        SyncStatus::Error { message } => "Error de sincronización",
        SyncStatus::Paused => "Sincronización pausada",
    };
    
    if cx.props.compact {
        rsx! {
            div {
                class: "sync-indicator compact {status_class}",
                title: "{status_text}",
                {status_icon}
            }
        }
    } else {
        rsx! {
            div {
                class: "sync-indicator {status_class}",
                div {
                    class: "sync-icon",
                    {status_icon}
                }
                
                div {
                    class: "sync-details",
                    span { class: "sync-status-text", "{status_text}" }
                    
                    if let SyncStatus::Syncing { progress, current_file } = &cx.props.status {
                        rsx! {
                            div {
                                class: "sync-progress-container",
                                div {
                                    class: "sync-progress-bar",
                                    style: "width: {progress * 100.0}%"
                                }
                            }
                            
                            if let Some(file) = current_file {
                                span { class: "sync-current-file", "{file}" }
                            }
                        }
                    }
                    
                    if let SyncStatus::Error { message } = &cx.props.status {
                        rsx! {
                            span { class: "sync-error-message", "{message}" }
                        }
                    }
                }
            }
        }
    }
}