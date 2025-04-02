use dioxus::prelude::*;
use dioxus_router::prelude::*;

use crate::Route;

pub fn LoginPage(cx: Scope) -> Element {
    let server_url = use_state(cx, || "https://".to_string());
    let username = use_state(cx, || String::new());
    let password = use_state(cx, || String::new());
    let error = use_state(cx, || None::<String>);
    let loading = use_state(cx, || false);
    
    let navigator = use_navigator();
    
    let handle_login = move |_| {
        to_owned![server_url, username, password, error, loading, navigator];
        
        cx.spawn(async move {
            loading.set(true);
            error.set(None);
            
            // Validar entradas
            if server_url.is_empty() || !server_url.starts_with("http") {
                error.set(Some("Por favor, introduce una URL de servidor válida".to_string()));
                loading.set(false);
                return;
            }
            
            if username.is_empty() {
                error.set(Some("Por favor, introduce un nombre de usuario".to_string()));
                loading.set(false);
                return;
            }
            
            if password.is_empty() {
                error.set(Some("Por favor, introduce una contraseña".to_string()));
                loading.set(false);
                return;
            }
            
            // Simular inicio de sesión (en una implementación real, esto sería una llamada a la API)
            tokio::time::sleep(tokio::time::Duration::from_secs(2)).await;
            
            // En este ejemplo, siempre iniciamos sesión correctamente
            loading.set(false);
            
            // Redirigir a la página de archivos
            navigator.push(Route::Home {});
        });
    };
    
    rsx! {
        div { 
            class: "login-container",
            
            div { 
                class: "login-box",
                
                div { 
                    class: "login-header",
                    img { 
                        src: "../assets/oxicloud-logo.svg", 
                        alt: "OxiCloud Logo",
                        width: "200"
                    }
                    h2 { "Iniciar sesión en OxiCloud" }
                }
                
                if let Some(err) = error.get() {
                    div { 
                        class: "error-message",
                        "{err}"
                    }
                }
                
                form { 
                    class: "login-form",
                    onsubmit: move |evt| {
                        evt.prevent_default();
                        handle_login(evt);
                    },
                    
                    div { 
                        class: "form-group",
                        label { r#for: "server", "URL del servidor" }
                        input {
                            id: "server",
                            r#type: "text",
                            value: "{server_url}",
                            placeholder: "https://tu-servidor.com",
                            oninput: move |evt| server_url.set(evt.value.clone()),
                            disabled: *loading.get()
                        }
                    }
                    
                    div { 
                        class: "form-group",
                        label { r#for: "username", "Nombre de usuario" }
                        input {
                            id: "username",
                            r#type: "text",
                            value: "{username}",
                            placeholder: "usuario",
                            oninput: move |evt| username.set(evt.value.clone()),
                            disabled: *loading.get()
                        }
                    }
                    
                    div { 
                        class: "form-group",
                        label { r#for: "password", "Contraseña" }
                        input {
                            id: "password",
                            r#type: "password",
                            value: "{password}",
                            placeholder: "••••••••",
                            oninput: move |evt| password.set(evt.value.clone()),
                            disabled: *loading.get()
                        }
                    }
                    
                    button { 
                        r#type: "submit",
                        class: "login-button",
                        disabled: *loading.get(),
                        
                        if *loading.get() {
                            "Iniciando sesión..."
                        } else {
                            "Iniciar sesión"
                        }
                    }
                }
                
                div { 
                    class: "login-footer",
                    p { "¿Primera vez con OxiCloud? " }
                    a { 
                        href: "#",
                        "Aprende más"
                    }
                }
            }
            
            div { 
                class: "login-version",
                "OxiCloud Desktop v0.1.0"
            }
        }
    }
}