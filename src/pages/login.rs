use dioxus::prelude::*;
use dioxus_router::prelude::*;
use dioxus_free_icons::icons::bootstrap_icons::Bs;
use dioxus_free_icons::Icon;

use crate::interfaces::app::Route;

#[component]
pub fn LoginPage(cx: Scope) -> Element {
    let navigator = use_navigator(cx);
    let server_url = use_state(cx, || String::from(""));
    let username = use_state(cx, || String::from(""));
    let password = use_state(cx, || String::from(""));
    let error = use_state(cx, || None::<String>);
    let loading = use_state(cx, || false);
    
    // Form validation
    let is_valid = !server_url.is_empty() && !username.is_empty() && !password.is_empty();
    
    let handle_login = move |_| {
        loading.set(true);
        error.set(None);
        
        // TODO: Implement the actual login logic with API service
        // Simulating a login for now
        cx.spawn(async move {
            // Simulate API call delay
            tokio::time::sleep(tokio::time::Duration::from_millis(1000)).await;
            
            // Simulate success for now
            loading.set(false);
            navigator.push(Route::Files {});
            
            // Error simulation example:
            // error.set(Some("Invalid credentials".to_string()));
            // loading.set(false);
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
                        Icon { icon: Bs::ExclamationTriangleFill }
                        span { "{err}" }
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
                            Icon { icon: Bs::ArrowRepeat, class: "rotating" }
                            " Logging in..."
                        } else {
                            Icon { icon: Bs::BoxArrowInRight }
                            " Login"
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
