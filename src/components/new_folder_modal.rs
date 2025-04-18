use dioxus::prelude::*;
// Temporarily comment out icon imports until we can find the correct path
// use dioxus_free_icons::bootstrap_icons as Bs;
// use dioxus_free_icons::Icon;

#[derive(Props)]
pub struct NewFolderModalProps {
    #[props(optional)]
    show: bool,
    on_close: EventHandler<()>,
    on_create: EventHandler<String>,
}

pub fn NewFolderModal(cx: Scope<NewFolderModalProps>) -> Element {
    let folder_name = use_state(cx, || String::new());
    let error = use_state(cx, || None::<String>);
    
    // Reset state when modal is opened
    use_effect(cx, (cx.props.show,), |(show,)| {
        if *show {
            folder_name.set(String::new());
            error.set(None);
        }
        async {}
    });
    
    // Handler for folder name input
    let on_input_change = move |evt: FormEvent| {
        folder_name.set(evt.value.clone());
        // Clear error when typing
        if error.get().is_some() {
            error.set(None);
        }
    };
    
    // Handler for form submission
    let on_submit = move |evt: FormEvent| {
        evt.prevent_default();
        
        // Validate folder name
        let name = folder_name.get().trim();
        if name.is_empty() {
            error.set(Some("Folder name cannot be empty".into()));
            return;
        }
        
        if name.contains('/') || name.contains('\\') {
            error.set(Some("Folder name cannot contain / or \\".into()));
            return;
        }
        
        // Call the create handler with the folder name
        cx.props.on_create.call(name.to_string());
        
        // Reset and close
        folder_name.set(String::new());
        cx.props.on_close.call(());
    };
    
    // Only render if modal is shown
    if !cx.props.show {
        return None;
    }
    
    cx.render(rsx! {
        div { class: "modal-overlay",
            onclick: move |_| cx.props.on_close.call(()),
            
            div { class: "modal",
                onclick: move |evt| evt.stop_propagation(),
                
                div { class: "modal-header",
                    h3 { "Create New Folder" }
                    button {
                        class: "close-btn",
                        onclick: move |_| cx.props.on_close.call(()),
                        // Icon { icon: Bs::X }
                        "✖"
                    }
                }
                
                div { class: "modal-body",
                    form {
                        onsubmit: on_submit,
                        
                        div { class: "form-group",
                            label { r#for: "folder-name", "Folder Name" }
                            input {
                                id: "folder-name",
                                r#type: "text",
                                value: "{folder_name}",
                                oninput: on_input_change,
                                placeholder: "Enter folder name",
                                autofocus: "true",
                            }
                            
                            if let Some(err) = error.get() {
                                div { class: "form-error", "{err}" }
                            }
                        }
                        
                        div { class: "modal-footer",
                            button {
                                r#type: "button",
                                class: "btn btn-secondary",
                                onclick: move |_| cx.props.on_close.call(()),
                                "Cancel"
                            }
                            
                            button {
                                r#type: "submit",
                                class: "btn btn-primary",
                                disabled: folder_name.get().trim().is_empty(),
                                "Create Folder"
                            }
                        }
                    }
                }
            }
        }
    })
}