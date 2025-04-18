use dioxus::prelude::*;
use dioxus_router::prelude::*;
// Temporarily comment out icon imports until we can find the correct path
// use dioxus_free_icons::bootstrap_icons as Bs;
// use dioxus_free_icons::Icon;
use std::sync::Arc;

use crate::interfaces::app::Route;
use crate::application::ports::auth_port::AuthPort;
use crate::domain::entities::user::UserError;

pub fn LoginPage(cx: Scope) -> Element {
    let navigator = use_navigator(cx);
    let server_url = use_state(cx, || String::from("http://localhost:3000"));
    let username = use_state(cx, || String::from(""));
    let password = use_state(cx, || String::from(""));
    let error = use_state(cx, || None::<String>);
    let loading = use_state(cx, || false);
    
    // Get auth service from context (will be provided by the app)
    let auth_service = use_context::<Arc<dyn AuthPort>>(cx)
        .expect("Auth service not found in context");
    
    // Form validation
    let is_valid = !server_url.is_empty() && !username.is_empty() && !password.is_empty();
    
    let handle_login = move |_| {
        loading.set(true);
        error.set(None);
        
        let auth_service = auth_service.clone();
        let server = server_url.get().clone();
        let user = username.get().clone();
        let pass = password.get().clone();
        let nav = navigator.clone();
        
        cx.spawn(async move {
            match auth_service.login(&server, &user, &pass).await {
                Ok(_) => {
                    // Login successful
                    nav.push(Route::Files {});
                },
                Err(e) => {
                    // Login failed
                    let error_message = match e {
                        UserError::InvalidUsername(msg) => msg,
                        UserError::InvalidPassword(msg) => msg,
                        UserError::AuthenticationError(msg) => msg,
                    };
                    error.set(Some(error_message));
                }
            }
            loading.set(false);
        });
    };
    
    cx.render(rsx! {
        div { class: "login-container",
            div { class: "login-box",
                div { class: "login-header",
                    h1 { "OxiCloud Desktop" }
                    p { "Secure cloud synchronization client" }
                }
                
                if let Some(err) = error.get() {
                    div { class: "error-message",
                        // Icon { icon: Bs::ExclamationTriangleFill }
                        span { "⚠ {err}" }
                    }
                }
                
                form { class: "login-form",
                    onsubmit: move |evt| {
                        evt.prevent_default();
                        if is_valid {
                            handle_login(());
                        }
                    },
                    
                    div { class: "form-group",
                        label { "Server URL" }
                        input {
                            r#type: "text",
                            placeholder: "https://your-oxicloud-server.com",
                            value: server_url.get(),
                            oninput: move |evt| server_url.set(evt.value.clone()),
                            disabled: *loading.get(),
                        }
                    }
                    
                    div { class: "form-group",
                        label { "Username" }
                        input {
                            r#type: "text",
                            placeholder: "Username",
                            value: username.get(),
                            oninput: move |evt| username.set(evt.value.clone()),
                            disabled: *loading.get(),
                        }
                    }
                    
                    div { class: "form-group",
                        label { "Password" }
                        input {
                            r#type: "password",
                            placeholder: "Password",
                            value: password.get(),
                            oninput: move |evt| password.set(evt.value.clone()),
                            disabled: *loading.get(),
                        }
                    }
                    
                    button {
                        class: "btn btn-primary login-button",
                        r#type: "submit",
                        disabled: !is_valid || *loading.get(),
                        
                        if *loading.get() {
                            // Icon { icon: Bs::ArrowRepeat, class: "rotating" }
                            "↻ Logging in..."
                        } else {
                            // Icon { icon: Bs::BoxArrowInRight }
                            "➡️ Login"
                        }
                    }
                }
                
                div { class: "login-footer",
                    span { "OxiCloud Desktop v0.1.0" }
                }
            }
        }
    })
}
