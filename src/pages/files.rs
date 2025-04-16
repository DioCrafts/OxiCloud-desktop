use dioxus::prelude::*;
use dioxus_router::prelude::*;
use dioxus_free_icons::icons::bootstrap_icons::Bs;
use dioxus_free_icons::Icon;
use std::sync::Arc;
use std::path::Path;
use web_sys::MouseEvent;

use crate::components::file_list::FileList;
use crate::components::sidebar::Sidebar;
use crate::components::sync_status_indicator::SyncStatusIndicator;
use crate::components::new_folder_modal::NewFolderModal;
use crate::components::context_menu::{ContextMenu, FileAction};
use crate::application::dtos::file_dto::FileDto;
use crate::application::ports::file_port::FilePort;

#[component]
pub fn FilesPage(cx: Scope) -> Element {
    // Get the file service from context
    let file_service = use_context::<Arc<dyn FilePort>>(cx)
        .expect("File service not found in context");
    
    // State for files
    let files = use_state(cx, Vec::new);
    let is_loading = use_state(cx, || true);
    let error = use_state(cx, || None::<String>);
    
    let current_path = use_state(cx, || "/".to_string());
    let current_folder_id = use_state(cx, || None::<String>);
    
    // Modal and context menu state
    let show_new_folder_modal = use_state(cx, || false);
    let show_context_menu = use_state(cx, || false);
    let context_menu_position = use_state(cx, || (0, 0));
    let selected_file = use_state(cx, || None::<FileDto>);
    let upload_input_ref = use_ref(cx, || None::<web_sys::HtmlInputElement>);
    
    // Load files when the component mounts or when the folder changes
    use_effect(cx, (current_folder_id.get().clone(),), |(folder_id,)| {
        let file_service = file_service.clone();
        let files_state = files.clone();
        let loading = is_loading.clone();
        let error_state = error.clone();
        
        async move {
            loading.set(true);
            error_state.set(None);
            
            let folder_id_ref = folder_id.as_deref();
            
            match file_service.list_files(folder_id_ref).await {
                Ok(file_list) => {
                    files_state.set(file_list);
                    loading.set(false);
                },
                Err(e) => {
                    error_state.set(Some(format!("Error loading files: {}", e)));
                    loading.set(false);
                }
            }
        }
    });
    
    // File and folder handlers
    let on_file_click = move |file_id: String| {
        let current_files = files.get();
        let file = current_files.iter().find(|f| f.id == file_id);
        
        if let Some(file) = file {
            tracing::info!("File clicked: {}", file.name);
            // For now just log, but here we would implement file opening logic
        }
    };
    
    let on_folder_click = move |folder_id: String| {
        let current_files = files.get();
        let folder = current_files.iter().find(|f| f.id == folder_id);
        
        if let Some(folder) = folder {
            tracing::info!("Folder clicked: {}", folder.name);
            current_folder_id.set(Some(folder_id.clone()));
            current_path.set(folder.path.clone());
        }
    };
    
    let on_favorite_toggle = move |file_id: String| {
        let file_svc = file_service.clone();
        
        cx.spawn(async move {
            match file_svc.toggle_favorite(&file_id).await {
                Ok(_) => {
                    // Refresh the file list
                    let folder_id = current_folder_id.get().clone();
                    let folder_id_ref = folder_id.as_deref();
                    
                    if let Ok(updated_files) = file_svc.list_files(folder_id_ref).await {
                        files.set(updated_files);
                    }
                },
                Err(e) => {
                    tracing::error!("Error toggling favorite: {}", e);
                }
            }
        });
    };
    
    // Context menu handlers
    let on_file_context_menu = move |file_id: String, event: MouseEvent| {
        event.prevent_default();
        
        let current_files = files.get();
        if let Some(file) = current_files.iter().find(|f| f.id == file_id) {
            selected_file.set(Some(file.clone()));
            context_menu_position.set((event.client_x(), event.client_y()));
            show_context_menu.set(true);
        }
    };
    
    let on_context_menu_close = move |_| {
        show_context_menu.set(false);
    };
    
    let on_context_menu_action = move |(action, file_id): (FileAction, String)| {
        let file_svc = file_service.clone();
        let folder_id = current_folder_id.get().clone();
        
        match action {
            FileAction::Open => {
                let current_files = files.get();
                if let Some(file) = current_files.iter().find(|f| f.id == file_id) {
                    if file.is_directory() {
                        current_folder_id.set(Some(file_id));
                        current_path.set(file.path.clone());
                    } else {
                        tracing::info!("Opening file: {}", file.name);
                        // TODO: Implement file opening logic
                    }
                }
            },
            FileAction::Download => {
                cx.spawn(async move {
                    // Open file dialog to select download location
                    // For now just log
                    tracing::info!("Downloading file: {}", file_id);
                });
            },
            FileAction::Rename => {
                // TODO: Show rename dialog
                tracing::info!("Renaming file: {}", file_id);
            },
            FileAction::Move => {
                // TODO: Show move dialog
                tracing::info!("Moving file: {}", file_id);
            },
            FileAction::Delete => {
                cx.spawn(async move {
                    if let Err(e) = file_svc.delete_item(&file_id).await {
                        tracing::error!("Error deleting item: {}", e);
                    } else {
                        // Refresh file list
                        let folder_id_ref = folder_id.as_deref();
                        if let Ok(updated_files) = file_svc.list_files(folder_id_ref).await {
                            files.set(updated_files);
                        }
                    }
                });
            },
            FileAction::ToggleFavorite => {
                cx.spawn(async move {
                    if let Err(e) = file_svc.toggle_favorite(&file_id).await {
                        tracing::error!("Error toggling favorite: {}", e);
                    } else {
                        // Refresh file list
                        let folder_id_ref = folder_id.as_deref();
                        if let Ok(updated_files) = file_svc.list_files(folder_id_ref).await {
                            files.set(updated_files);
                        }
                    }
                });
            },
            _ => {
                tracing::info!("Action not implemented: {:?} for file {}", action, file_id);
            }
        }
    };
    
    // New folder handlers
    let on_new_folder_click = move |_| {
        show_new_folder_modal.set(true);
    };
    
    let on_modal_close = move |_| {
        show_new_folder_modal.set(false);
    };
    
    let on_create_folder = move |name: String| {
        let file_svc = file_service.clone();
        let folder_id = current_folder_id.get().clone();
        
        cx.spawn(async move {
            let folder_id_ref = folder_id.as_deref();
            
            match file_svc.create_folder(&name, folder_id_ref).await {
                Ok(_) => {
                    // Refresh the file list
                    if let Ok(updated_files) = file_svc.list_files(folder_id_ref).await {
                        files.set(updated_files);
                    }
                },
                Err(e) => {
                    tracing::error!("Error creating folder: {}", e);
                }
            }
        });
    };
    
    // Upload handlers
    let on_upload_click = move |_| {
        if let Some(input) = &*upload_input_ref.read() {
            input.click();
        }
    };
    
    let on_files_selected = move |evt: Event<FormData>| {
        let file_svc = file_service.clone();
        let folder_id = current_folder_id.get().clone();
        
        // Get the FileList from the event
        if let Some(files_list) = evt.files() {
            for i in 0..files_list.length() {
                if let Some(file) = files_list.get(i) {
                    // For Web, we'd need to handle the file upload here
                    // In a desktop app with Dioxus, we'd need to use a different approach
                    // This is a placeholder for the actual implementation
                    tracing::info!("File selected: {}", file.name());
                    
                    // In a real implementation, we'd upload the file
                    cx.spawn({
                        let file_svc = file_svc.clone();
                        let folder_id = folder_id.clone();
                        
                        async move {
                            // Placeholder: in a real implementation we'd get the path
                            // and upload the file using the file service
                            let path = Path::new(&file.name());
                            
                            tracing::info!("Uploading file: {}", file.name());
                            
                            match file_svc.upload_local_file(path, folder_id.as_deref()).await {
                                Ok(_) => {
                                    // Refresh the file list
                                    let folder_id_ref = folder_id.as_deref();
                                    if let Ok(updated_files) = file_svc.list_files(folder_id_ref).await {
                                        files.set(updated_files);
                                    }
                                },
                                Err(e) => {
                                    tracing::error!("Error uploading file: {}", e);
                                }
                            }
                        }
                    });
                }
            }
        }
    };
    
    // Breadcrumb navigation
    let path_segments = current_path.split('/').filter(|s| !s.is_empty()).collect::<Vec<_>>();
    
    cx.render(rsx! {
        div { class: "app-container",
            Sidebar {}
            
            div { class: "main-content",
                div { class: "toolbar",
                    div { class: "breadcrumbs",
                        button {
                            class: "breadcrumb-item",
                            onclick: move |_| {
                                current_path.set("/".to_string());
                                current_folder_id.set(None);
                            },
                            Icon { icon: Bs::HouseFill }
                        }
                        
                        for (index, segment) in path_segments.iter().enumerate() {
                            span { class: "breadcrumb-separator", "/" }
                            button {
                                class: "breadcrumb-item",
                                onclick: move |_| {
                                    // Build the path up to this segment
                                    let path = "/".to_string() + &path_segments[0..=index].join("/");
                                    current_path.set(path.clone());
                                    
                                    // TODO: Find the folder ID based on the path in a real app
                                    // For now, go back to root
                                    if index == 0 {
                                        current_folder_id.set(None);
                                    }
                                },
                                "{segment}"
                            }
                        }
                    }
                    
                    div { class: "toolbar-actions",
                        div { class: "search-box",
                            input {
                                r#type: "text",
                                placeholder: "Search files...",
                                // TODO: Implement search functionality
                            }
                        }
                        
                        button {
                            class: "toolbar-btn",
                            onclick: on_upload_click,
                            Icon { icon: Bs::Upload }
                            span { "Upload" }
                        }
                        
                        // Hidden file input for uploads
                        input {
                            r#type: "file",
                            class: "upload-input",
                            multiple: true,
                            onchange: on_files_selected,
                            ref: move |el| {
                                if let Some(input_element) = el {
                                    *upload_input_ref.write() = Some(input_element.clone());
                                }
                            }
                        }
                        
                        button {
                            class: "toolbar-btn",
                            onclick: on_new_folder_click,
                            Icon { icon: Bs::FolderPlus }
                            span { "New Folder" }
                        }
                    }
                }
                
                if *is_loading.get() {
                    div { class: "loading-container",
                        Icon { icon: Bs::ArrowRepeat, class: "rotating" }
                        span { "Loading files..." }
                    }
                } else if let Some(err) = error.get() {
                    div { class: "error-container",
                        Icon { icon: Bs::ExclamationTriangleFill }
                        span { "{err}" }
                        button {
                            onclick: move |_| {
                                // Retry loading files
                                let folder_id = current_folder_id.get().clone();
                                current_folder_id.set(folder_id);
                            },
                            "Retry"
                        }
                    }
                } else if files.get().is_empty() {
                    div { class: "empty-container",
                        Icon { icon: Bs::Folder2Open }
                        span { "This folder is empty" }
                        
                        div { class: "empty-actions",
                            button {
                                onclick: on_upload_click,
                                Icon { icon: Bs::Upload }
                                " Upload Files"
                            }
                            
                            button {
                                onclick: on_new_folder_click,
                                Icon { icon: Bs::FolderPlus }
                                " New Folder"
                            }
                        }
                    }
                } else {
                    FileList {
                        files: files.get().clone(),
                        on_file_click: on_file_click,
                        on_folder_click: on_folder_click,
                        on_favorite_toggle: on_favorite_toggle,
                        on_context_menu: on_file_context_menu,
                    }
                }
            }
            
            // New folder modal
            NewFolderModal {
                show: *show_new_folder_modal.get(),
                on_close: on_modal_close,
                on_create: on_create_folder,
            }
            
            // Context menu for file actions
            ContextMenu {
                show: *show_context_menu.get(),
                file: selected_file.get().clone(),
                position: *context_menu_position.get(),
                on_close: on_context_menu_close,
                on_action: on_context_menu_action,
            }
        }
    })
}