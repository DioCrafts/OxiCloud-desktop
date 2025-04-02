use dioxus::prelude::*;
use dioxus_free_icons::{
    icons::bootstrap_icons::{
        BsCloudUpload, BsFolderPlus, BsUpload,
    },
    Icon,
};

use crate::components::sidebar::Sidebar;
use crate::components::file_list::FileList;
use crate::models::file::{FileItem, FileType};
use crate::SyncStatus;

#[derive(Props)]
pub struct FilesPageProps {
    path: Option<String>,
}

pub fn FilesPage(cx: Scope<FilesPageProps>) -> Element {
    // Estado para cargar archivos
    let loading = use_state(cx, || true);
    let files = use_state(cx, Vec::new);
    let current_path = use_state(cx, || cx.props.path.clone().unwrap_or_else(|| "/".to_string()));
    
    // Estado de sincronización
    let sync_status = use_state(cx, || SyncStatus::Idle);
    
    // Simulación de carga de archivos (en una implementación real, esto sería una llamada a la API)
    use_effect(cx, (), |_| {
        to_owned![loading, files, current_path];
        async move {
            // Simular tiempo de carga
            tokio::time::sleep(tokio::time::Duration::from_millis(800)).await;
            
            // Datos de prueba
            let mut test_files = vec![
                FileItem {
                    id: "1".to_string(),
                    name: "Documentos".to_string(),
                    path: format!("{}/Documentos", current_path.get()),
                    file_type: FileType::Directory,
                    size: 0,
                    created: chrono::Utc::now(),
                    modified: chrono::Utc::now(),
                    is_favorite: true,
                    is_shared: false,
                    sync_status: crate::models::file::FileSyncStatus::Synced,
                    etag: Some("abc123".to_string()),
                },
                FileItem {
                    id: "2".to_string(),
                    name: "Fotos".to_string(),
                    path: format!("{}/Fotos", current_path.get()),
                    file_type: FileType::Directory,
                    size: 0,
                    created: chrono::Utc::now(),
                    modified: chrono::Utc::now(),
                    is_favorite: false,
                    is_shared: true,
                    sync_status: crate::models::file::FileSyncStatus::Synced,
                    etag: Some("def456".to_string()),
                },
                FileItem {
                    id: "3".to_string(),
                    name: "informe.pdf".to_string(),
                    path: format!("{}/informe.pdf", current_path.get()),
                    file_type: FileType::File,
                    size: 1024 * 1024 * 2, // 2MB
                    created: chrono::Utc::now(),
                    modified: chrono::Utc::now(),
                    is_favorite: false,
                    is_shared: false,
                    sync_status: crate::models::file::FileSyncStatus::Synced,
                    etag: Some("ghi789".to_string()),
                },
                FileItem {
                    id: "4".to_string(),
                    name: "presentacion.pptx".to_string(),
                    path: format!("{}/presentacion.pptx", current_path.get()),
                    file_type: FileType::File,
                    size: 1024 * 1024 * 5, // 5MB
                    created: chrono::Utc::now(),
                    modified: chrono::Utc::now(),
                    is_favorite: true,
                    is_shared: true,
                    sync_status: crate::models::file::FileSyncStatus::Synced,
                    etag: Some("jkl012".to_string()),
                },
            ];
            
            // Ordenar: primero carpetas, luego archivos
            test_files.sort_by(|a, b| {
                if a.file_type == b.file_type {
                    a.name.cmp(&b.name)
                } else if a.file_type == FileType::Directory {
                    std::cmp::Ordering::Less
                } else {
                    std::cmp::Ordering::Greater
                }
            });
            
            files.set(test_files);
            loading.set(false);
        }
    });
    
    // Manejadores de eventos
    let handle_file_click = |file: FileItem| {
        if file.file_type == FileType::Directory {
            loading.set(true);
            current_path.set(file.path);
        } else {
            // Abrir archivo
            println!("Abrir archivo: {}", file.name);
        }
    };
    
    let handle_download = |file: FileItem| {
        println!("Descargar archivo: {}", file.name);
    };
    
    let handle_share = |file: FileItem| {
        println!("Compartir: {}", file.name);
    };
    
    let handle_favorite_toggle = |file: FileItem| {
        println!("Alternar favorito: {}", file.name);
    };
    
    rsx! {
        div { 
            class: "app-container",
            
            // Barra lateral
            Sidebar {
                active_route: Some(format!("/files/{}", current_path.get())),
                sync_status: (*sync_status.get()).clone()
            }
            
            // Contenido principal
            div { 
                class: "main-content",
                
                // Barra de herramientas
                div { 
                    class: "toolbar",
                    
                    // Botones de acción
                    div {
                        class: "toolbar-actions",
                        button {
                            class: "toolbar-btn",
                            Icon { icon: BsFolderPlus, width: 18, height: 18 }
                            span { "Nueva carpeta" }
                        }
                        
                        button {
                            class: "toolbar-btn",
                            Icon { icon: BsUpload, width: 18, height: 18 }
                            span { "Subir archivos" }
                        }
                        
                        button {
                            class: "toolbar-btn",
                            Icon { icon: BsCloudUpload, width: 18, height: 18 }
                            span { "Sincronizar" }
                        }
                    }
                    
                    // Buscador
                    div {
                        class: "search-box",
                        input {
                            r#type: "text",
                            placeholder: "Buscar archivos...",
                        }
                    }
                }
                
                // Lista de archivos
                FileList {
                    files: files.get().clone(),
                    current_path: current_path.get().clone(),
                    loading: *loading.get(),
                    on_file_click: handle_file_click,
                    on_download_click: handle_download,
                    on_share_click: handle_share,
                    on_favorite_toggle: handle_favorite_toggle,
                }
            }
        }
    }
}