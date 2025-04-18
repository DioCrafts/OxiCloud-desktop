use dioxus::prelude::*;
// Temporarily comment out icon imports until we can find the correct path
// use dioxus_free_icons::Icon;
// use dioxus_free_icons::bootstrap_icons as Bs;

use crate::application::dtos::file_dto::{FileDto, FileTypeDto, SyncStatusDto};

#[derive(Props)]
pub struct FileListProps {
    files: Vec<FileDto>,
    on_file_click: EventHandler<String>,
    on_folder_click: EventHandler<String>,
    #[props(optional)]
    on_favorite_toggle: Option<EventHandler<String>>,
    #[props(optional)]
    on_context_menu: Option<EventHandler<(String, MouseEvent)>>,
}

pub fn FileList(cx: ScopeState) -> Element {
    let hovered_file = use_state(cx, || None::<String>);
    
    cx.render(rsx! {
        div { class: "file-list-container",
            table { class: "file-list-table",
                thead {
                    tr {
                        th { "Name" }
                        th { "Size" }
                        th { "Modified" }
                        th { "Status" }
                        th { "Actions" }
                    }
                }
                tbody {
                    if cx.props.files.is_empty() {
                        tr {
                            td { colspan: "5", class: "empty-list",
                                "No files found"
                            }
                        }
                    } else {
                        for file in &cx.props.files {
                            tr {
                                key: "{file.id}",
                                class: if Some(file.id.clone()) == *hovered_file.get() {
                                    "file-item hovered"
                                } else {
                                    "file-item"
                                },
                                onmouseover: move |_| hovered_file.set(Some(file.id.clone())),
                                onmouseout: move |_| hovered_file.set(None),
                                oncontextmenu: move |evt| {
                                    if let Some(on_context_menu) = &cx.props.on_context_menu {
                                        on_context_menu.call((file.id.clone(), evt));
                                    }
                                },
                                
                                td { class: "file-name-cell",
                                    div {
                                        class: "file-name-wrapper",
                                        div { class: "file-icon",
                                            if file.is_directory() {
                                                // Icon { icon: Bs::FolderFill }
                                                "📁"
                                            } else {
                                                // {get_file_icon(file)}
                                                "📄"
                                            }
                                        }
                                        
                                        div { class: "file-info",
                                            div {
                                                class: "file-name",
                                                onclick: move |_| {
                                                    if file.is_directory() {
                                                        cx.props.on_folder_click.call(file.id.clone());
                                                    } else {
                                                        cx.props.on_file_click.call(file.id.clone());
                                                    }
                                                },
                                                span { "{file.name}" }
                                            }
                                        }
                                    }
                                }
                                
                                td { class: "file-size", "{file.formatted_size()}" }
                                td { class: "file-date", "{file.formatted_date()}" }
                                
                                td { class: "file-status",
                                    {get_sync_status_badge(file)}
                                }
                                
                                td { class: "file-actions",
                                    div { class: "action-buttons",
                                        if let Some(on_favorite_toggle) = &cx.props.on_favorite_toggle {
                                            button {
                                                class: "favorite-btn",
                                                onclick: move |_| on_favorite_toggle.call(file.id.clone()),
                                                if file.is_favorite {
                                                    // Icon { icon: Bs::StarFill, width: 16, height: 16 }
                                                    "⭐"
                                                } else {
                                                    // Icon { icon: Bs::Star, width: 16, height: 16 }
                                                    "☆"
                                                }
                                            }
                                        }
                                        
                                        button { class: "action-btn",
                                            // Icon { icon: Bs::ThreeDotsVertical, width: 16, height: 16 }
                                            "⋮"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    })
}

// Commented out until icons are fixed
/*
fn get_file_icon(file: &FileDto) -> Element {
    let ext = file.extension().unwrap_or("").to_lowercase();
    
    match ext.as_str() {
        "pdf" => rsx! { Icon { icon: Bs::FilePdfFill } },
        "doc" | "docx" => rsx! { Icon { icon: Bs::FileWordFill } },
        "xls" | "xlsx" => rsx! { Icon { icon: Bs::FileExcelFill } },
        "ppt" | "pptx" => rsx! { Icon { icon: Bs::FilePptFill } },
        "jpg" | "jpeg" | "png" | "gif" | "bmp" | "svg" => rsx! { Icon { icon: Bs::FileImageFill } },
        "mp3" | "wav" | "ogg" | "flac" => rsx! { Icon { icon: Bs::FileMusicFill } },
        "mp4" | "avi" | "mkv" | "mov" | "wmv" => rsx! { Icon { icon: Bs::FilePlayFill } },
        "zip" | "rar" | "7z" | "tar" | "gz" => rsx! { Icon { icon: Bs::FileZipFill } },
        "txt" | "md" | "rtf" => rsx! { Icon { icon: Bs::FileTextFill } },
        "html" | "css" | "js" | "ts" | "jsx" | "tsx" | "php" | "py" | "java" | "c" | "cpp" | "rs" |
        "go" | "rb" | "swift" | "kt" => rsx! { Icon { icon: Bs::FileCodeFill } },
        _ => rsx! { Icon { icon: Bs::FileFill } }
    }
}
*/

fn get_sync_status_badge(file: &FileDto) -> Element {
    match file.sync_status {
        SyncStatusDto::Synced => rsx! {
            span { class: "status-badge status-synced", 
                // Icon { icon: Bs::CheckCircleFill, width: 12, height: 12 }
                "✓ Synced"
            }
        },
        SyncStatusDto::Syncing => rsx! {
            span { class: "status-badge status-syncing",
                // Icon { icon: Bs::ArrowRepeat, width: 12, height: 12 }
                "↻ Syncing"
            }
        },
        SyncStatusDto::PendingUpload => rsx! {
            span { class: "status-badge status-pending",
                // Icon { icon: Bs::CloudUpload, width: 12, height: 12 }
                "↑ Pending Upload"
            }
        },
        SyncStatusDto::PendingDownload => rsx! {
            span { class: "status-badge status-pending",
                // Icon { icon: Bs::CloudDownload, width: 12, height: 12 }
                "↓ Pending Download"
            }
        },
        SyncStatusDto::Error => rsx! {
            span { class: "status-badge status-error",
                // Icon { icon: Bs::ExclamationTriangleFill, width: 12, height: 12 }
                "⚠ Error"
            }
        },
        SyncStatusDto::Conflicted => rsx! {
            span { class: "status-badge status-conflict",
                // Icon { icon: Bs::ExclamationCircleFill, width: 12, height: 12 }
                "! Conflict"
            }
        },
        SyncStatusDto::Ignored => rsx! {
            span { class: "status-badge status-ignored",
                // Icon { icon: Bs::SlashCircleFill, width: 12, height: 12 }
                "⌀ Ignored"
            }
        },
    }
}
