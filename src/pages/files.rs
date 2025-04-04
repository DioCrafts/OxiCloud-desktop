use dioxus::prelude::*;
use dioxus_router::prelude::*;
use dioxus_free_icons::icons::bootstrap_icons::Bs;
use dioxus_free_icons::Icon;

use crate::components::file_list::FileList;
use crate::components::sidebar::Sidebar;
use crate::application::dtos::file_dto::{FileDto, FileTypeDto, SyncStatusDto};

#[component]
pub fn FilesPage(cx: Scope) -> Element {
    // In a real app, this would be fetched from a service
    let files = use_state(cx, || vec![
        FileDto {
            id: "1".to_string(),
            name: "Documents".to_string(),
            path: "/Documents".to_string(),
            file_type: FileTypeDto::Directory,
            size: 0,
            mime_type: None,
            parent_id: None,
            created_at: chrono::Utc::now(),
            modified_at: chrono::Utc::now(),
            sync_status: SyncStatusDto::Synced,
            is_favorite: false,
            local_path: Some("/home/user/OxiCloud/Documents".to_string()),
        },
        FileDto {
            id: "2".to_string(),
            name: "Project Report.pdf".to_string(),
            path: "/Project Report.pdf".to_string(),
            file_type: FileTypeDto::File,
            size: 1024 * 1024 * 2, // 2MB
            mime_type: Some("application/pdf".to_string()),
            parent_id: None,
            created_at: chrono::Utc::now(),
            modified_at: chrono::Utc::now(),
            sync_status: SyncStatusDto::Synced,
            is_favorite: true,
            local_path: Some("/home/user/OxiCloud/Project Report.pdf".to_string()),
        },
        FileDto {
            id: "3".to_string(),
            name: "Presentation.pptx".to_string(),
            path: "/Presentation.pptx".to_string(),
            file_type: FileTypeDto::File,
            size: 1024 * 1024 * 5, // 5MB
            mime_type: Some("application/vnd.openxmlformats-officedocument.presentationml.presentation".to_string()),
            parent_id: None,
            created_at: chrono::Utc::now(),
            modified_at: chrono::Utc::now(),
            sync_status: SyncStatusDto::PendingUpload,
            is_favorite: false,
            local_path: Some("/home/user/OxiCloud/Presentation.pptx".to_string()),
        },
    ]);
    
    let current_path = use_state(cx, || "/".to_string());
    let current_folder_id = use_state(cx, || None::<String>);
    
    // Breadcrumb navigation
    let path_segments = current_path.split('/').filter(|s| !s.is_empty()).collect::<Vec<_>>();
    
    // Event handlers
    let on_file_click = move |file_id: String| {
        log::info!("File clicked: {}", file_id);
        // TODO: Implement file opening logic
    };
    
    let on_folder_click = move |folder_id: String| {
        log::info!("Folder clicked: {}", folder_id);
        // In a real app, this would fetch contents of the clicked folder
        current_folder_id.set(Some(folder_id));
        
        // Example: Update path to simulate navigation
        for file in files.get() {
            if file.id == folder_id && file.is_directory() {
                current_path.set(file.path.clone());
                break;
            }
        }
    };
    
    let on_favorite_toggle = move |file_id: String| {
        log::info!("Favorite toggled: {}", file_id);
        
        // Update the file's favorite status
        let mut updated_files = files.get().clone();
        for file in &mut updated_files {
            if file.id == file_id {
                file.is_favorite = !file.is_favorite;
                break;
            }
        }
        files.set(updated_files);
    };
    
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
                                    let path = "/".to_string() + &path_segments[0..=index].join("/");
                                    current_path.set(path);
                                    // In a real app, we would also set the folder_id based on the path
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
                        
                        button { class: "toolbar-btn",
                            Icon { icon: Bs::Upload }
                            span { "Upload" }
                        }
                        
                        button { class: "toolbar-btn",
                            Icon { icon: Bs::FolderPlus }
                            span { "New Folder" }
                        }
                    }
                }
                
                FileList {
                    files: files.get().clone(),
                    on_file_click: on_file_click,
                    on_folder_click: on_folder_click,
                    on_favorite_toggle: on_favorite_toggle,
                }
            }
        }
    })
}