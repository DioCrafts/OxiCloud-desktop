use dioxus::prelude::*;
use dioxus_free_icons::{
    icons::bootstrap_icons::{
        BsFileEarmark, BsFolder, BsDownload, BsShare, BsThreeDotsVertical, BsStar, BsStarFill,
    },
    Icon,
};
use human_size::{Size, SpecificSize};

use crate::models::file::{FileItem, FileType};

#[derive(Props)]
pub struct FileListProps {
    files: Vec<FileItem>,
    current_path: String,
    #[props(default)]
    loading: bool,
    on_file_click: EventHandler<FileItem>,
    on_download_click: EventHandler<FileItem>,
    on_share_click: EventHandler<FileItem>,
    on_favorite_toggle: EventHandler<FileItem>,
}

pub fn FileList(cx: Scope<FileListProps>) -> Element {
    // Función para formatear el tamaño de manera legible
    let format_size = |size: u64| -> String {
        let size = Size::from_bytes(size);
        let specific_size = SpecificSize::new(size, human_size::Kibibyte).unwrap();
        specific_size.to_string()
    };

    // Estado para seguir el elemento sobre el que está el ratón
    let hover_item = use_state(cx, || None::<String>);
    
    // Renderizar un elemento de tipo archivo o carpeta
    let render_file_item = |file: &FileItem| {
        let file_id = file.id.clone();
        let is_hovered = hover_item.current() == Some(file_id.clone());
        
        rsx! {
            tr {
                key: "{file.id}",
                class: "file-item {if is_hovered { "hovered" } else { "" }}",
                onmouseenter: move |_| hover_item.set(Some(file_id.clone())),
                onmouseleave: move |_| hover_item.set(None),
                
                // Icono de tipo de archivo
                td {
                    class: "file-icon",
                    match file.file_type {
                        FileType::Directory => rsx! { Icon { icon: BsFolder, width: 20, height: 20 } },
                        FileType::File => rsx! { Icon { icon: BsFileEarmark, width: 20, height: 20 } },
                    }
                }
                
                // Nombre del archivo
                td {
                    class: "file-name",
                    onclick: move |_| cx.props.on_file_click.call(file.clone()),
                    span {
                        "{file.name}"
                    }
                }
                
                // Favorito
                td {
                    class: "file-favorite",
                    button {
                        class: "favorite-btn",
                        onclick: move |_| cx.props.on_favorite_toggle.call(file.clone()),
                        if file.is_favorite {
                            rsx! { Icon { icon: BsStarFill, width: 16, height: 16 } }
                        } else {
                            rsx! { Icon { icon: BsStar, width: 16, height: 16 } }
                        }
                    }
                }
                
                // Tamaño
                td {
                    class: "file-size",
                    if file.file_type == FileType::File {
                        "{format_size(file.size)}"
                    }
                }
                
                // Fecha de modificación
                td {
                    class: "file-date",
                    "{file.modified.format("%d/%m/%Y %H:%M")}"
                }
                
                // Acciones
                td {
                    class: "file-actions",
                    if is_hovered {
                        rsx! {
                            div {
                                class: "action-buttons",
                                if file.file_type == FileType::File {
                                    rsx! {
                                        button {
                                            class: "action-btn download-btn",
                                            onclick: move |_| cx.props.on_download_click.call(file.clone()),
                                            Icon { icon: BsDownload, width: 16, height: 16 }
                                        }
                                    }
                                }
                                
                                button {
                                    class: "action-btn share-btn",
                                    onclick: move |_| cx.props.on_share_click.call(file.clone()),
                                    Icon { icon: BsShare, width: 16, height: 16 }
                                }
                                
                                button {
                                    class: "action-btn menu-btn",
                                    Icon { icon: BsThreeDotsVertical, width: 16, height: 16 }
                                }
                            }
                        }
                    }
                }
            }
        }
    };

    rsx! {
        div {
            class: "file-list-container",
            
            // Ruta actual
            div {
                class: "path-breadcrumb",
                span { "{cx.props.current_path}" }
            }
            
            if cx.props.loading {
                div {
                    class: "loading-indicator",
                    span { "Cargando..." }
                    // Se podría agregar una animación aquí
                }
            } else if cx.props.files.is_empty() {
                div {
                    class: "empty-directory",
                    "Esta carpeta está vacía"
                }
            } else {
                table {
                    class: "file-list-table",
                    thead {
                        tr {
                            th { "" } // Icono
                            th { "Nombre" }
                            th { "" } // Favorito
                            th { "Tamaño" }
                            th { "Modificado" }
                            th { "Acciones" }
                        }
                    }
                    tbody {
                        // Primero mostrar carpetas y luego archivos
                        cx.props.files.iter()
                            .filter(|f| f.file_type == FileType::Directory)
                            .map(render_file_item)
                        
                        cx.props.files.iter()
                            .filter(|f| f.file_type == FileType::File)
                            .map(render_file_item)
                    }
                }
            }
        }
    }
}