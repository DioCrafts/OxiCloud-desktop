use dioxus::prelude::*;
use dioxus_free_icons::icons::bootstrap_icons::Bs;
use dioxus_free_icons::Icon;
use crate::application::dtos::file_dto::{FileDto, FileTypeDto};

// Define all possible menu actions
#[derive(PartialEq, Clone)]
pub enum FileAction {
    Open,
    Download,
    Rename,
    Move,
    Delete,
    Share,
    ToggleFavorite,
    CopyLink,
}

#[derive(Props)]
pub struct ContextMenuProps {
    show: bool,
    file: Option<FileDto>,
    position: (i32, i32),
    on_close: EventHandler<()>,
    on_action: EventHandler<(FileAction, String)>,
}

#[component]
pub fn ContextMenu(cx: Scope<ContextMenuProps>) -> Element {
    // Only render if menu is shown and file is provided
    if !cx.props.show || cx.props.file.is_none() {
        return None;
    }
    
    let file = cx.props.file.as_ref().unwrap();
    let is_directory = file.file_type == FileTypeDto::Directory;
    let is_favorite = file.is_favorite;
    let file_id = file.id.clone();
    let (x, y) = cx.props.position;
    
    // Style for positioning the menu
    let position_style = format!("left: {}px; top: {}px;", x, y);
    
    // Handle action click
    let on_item_click = |action: FileAction| {
        move |_| {
            cx.props.on_action.call((action.clone(), file_id.clone()));
            cx.props.on_close.call(());
        }
    };
    
    // Close menu when clicking outside
    let on_overlay_click = move |_| {
        cx.props.on_close.call(());
    };
    
    cx.render(rsx! {
        div { class: "context-menu-overlay", onclick: on_overlay_click,
            div {
                class: "context-menu",
                style: "{position_style}",
                onclick: move |evt| evt.stop_propagation(),
                
                div { class: "context-menu-header",
                    if is_directory {
                        Icon { icon: Bs::FolderFill }
                    } else {
                        Icon { icon: Bs::FileFill }
                    }
                    span { "{file.name}" }
                }
                
                ul { class: "context-menu-items",
                    li {
                        class: "context-menu-item",
                        onclick: on_item_click(FileAction::Open),
                        Icon { icon: if is_directory { Bs::FolderFill } else { Bs::FileEarmarkFill } }
                        span { if is_directory { "Open" } else { "Open" } }
                    }
                    
                    if !is_directory {
                        li {
                            class: "context-menu-item",
                            onclick: on_item_click(FileAction::Download),
                            Icon { icon: Bs::Download }
                            span { "Download" }
                        }
                    }
                    
                    li {
                        class: "context-menu-item",
                        onclick: on_item_click(FileAction::Rename),
                        Icon { icon: Bs::Pencil }
                        span { "Rename" }
                    }
                    
                    li {
                        class: "context-menu-item",
                        onclick: on_item_click(FileAction::Move),
                        Icon { icon: Bs::ArrowRight }
                        span { "Move" }
                    }
                    
                    li {
                        class: "context-menu-item danger",
                        onclick: on_item_click(FileAction::Delete),
                        Icon { icon: Bs::Trash }
                        span { "Delete" }
                    }
                    
                    div { class: "context-menu-divider" }
                    
                    li {
                        class: "context-menu-item",
                        onclick: on_item_click(FileAction::ToggleFavorite),
                        if is_favorite {
                            Icon { icon: Bs::StarFill }
                            span { "Remove from Favorites" }
                        } else {
                            Icon { icon: Bs::Star }
                            span { "Add to Favorites" }
                        }
                    }
                    
                    li {
                        class: "context-menu-item",
                        onclick: on_item_click(FileAction::Share),
                        Icon { icon: Bs::Share }
                        span { "Share" }
                    }
                    
                    li {
                        class: "context-menu-item",
                        onclick: on_item_click(FileAction::CopyLink),
                        Icon { icon: Bs::Link45deg }
                        span { "Copy Link" }
                    }
                }
            }
        }
    })
}