use dioxus::prelude::*;
use dioxus_router::prelude::*;
use crate::domain::entities::encryption::{EncryptionSettings, EncryptionAlgorithm, KeyStorageMethod};
use crate::application::ports::encryption_port::EncryptionPort;
use std::sync::Arc;
use tracing::{info, error};

pub fn EncryptionPage(cx: Scope) -> Element {
    let encryption_service = use_context::<Arc<dyn EncryptionPort>>(cx).unwrap();
    
    let settings = use_state(cx, || EncryptionSettings::default());
    let password = use_state(cx, String::new);
    let confirm_password = use_state(cx, String::new);
    let is_loading = use_state(cx, || false);
    let error_message = use_state(cx, || None::<String>);
    let success_message = use_state(cx, || None::<String>);
    
    // Load settings on first render
    use_effect(cx, (), |_| {
        let encryption_service = encryption_service.clone();
        let settings = settings.clone();
        let error_message = error_message.clone();
        async move {
            match encryption_service.get_encryption_settings().await {
                Ok(loaded_settings) => {
                    settings.set(loaded_settings);
                },
                Err(e) => {
                    error!("Failed to load encryption settings: {}", e);
                    error_message.set(Some(format!("Failed to load settings: {}", e)));
                }
            }
        }
    });
    
    let on_toggle_enabled = move |_| {
        settings.with_mut(|s| s.enabled = !s.enabled);
    };
    
    let on_algorithm_change = move |evt: Event<FormData>| {
        let algorithm = match evt.value.as_str() {
            "aes" => EncryptionAlgorithm::Aes256Gcm,
            "chacha" => EncryptionAlgorithm::Chacha20Poly1305,
            "kyber" => EncryptionAlgorithm::Kyber768,
            "dilithium" => EncryptionAlgorithm::Dilithium5,
            "hybrid" => EncryptionAlgorithm::HybridAesKyber,
            _ => EncryptionAlgorithm::default(),
        };
        settings.with_mut(|s| s.algorithm = algorithm);
    };
    
    let on_storage_change = move |evt: Event<FormData>| {
        let storage = match evt.value.as_str() {
            "password" => KeyStorageMethod::Password,
            "keychain" => KeyStorageMethod::SystemKeychain,
            "file" => KeyStorageMethod::KeyFile(std::path::PathBuf::from("./key.oxikey")),
            _ => KeyStorageMethod::default(),
        };
        settings.with_mut(|s| s.key_storage = storage);
    };
    
    let on_encrypt_filenames_change = move |_| {
        settings.with_mut(|s| s.encrypt_filenames = !s.encrypt_filenames);
    };
    
    let on_encrypt_metadata_change = move |_| {
        settings.with_mut(|s| s.encrypt_metadata = !s.encrypt_metadata);
    };
    
    let save_settings = move |_| {
        let encryption_service = encryption_service.clone();
        let settings = settings.clone();
        let password = password.clone();
        let confirm_password = confirm_password.clone();
        let is_loading = is_loading.clone();
        let error_message = error_message.clone();
        let success_message = success_message.clone();
        
        cx.spawn(async move {
            if password.get().is_empty() {
                error_message.set(Some("Password is required".to_string()));
                return;
            }
            
            if settings.get().enabled && password.get() != confirm_password.get() {
                error_message.set(Some("Passwords do not match".to_string()));
                return;
            }
            
            is_loading.set(true);
            error_message.set(None);
            success_message.set(None);
            
            let current_settings = settings.get().clone();
            
            let result = if current_settings.enabled && !current_settings.key_id.is_some() {
                // Initialize encryption (first-time setup)
                encryption_service
                    .initialize_encryption(&password.get(), &current_settings)
                    .await
            } else {
                // Update existing settings
                encryption_service
                    .update_encryption_settings(&password.get(), &current_settings)
                    .await
                    .map(|_| current_settings)
            };
            
            match result {
                Ok(updated_settings) => {
                    info!("Encryption settings saved successfully");
                    settings.set(updated_settings);
                    success_message.set(Some("Settings saved successfully".to_string()));
                    password.set("".to_string());
                    confirm_password.set("".to_string());
                },
                Err(e) => {
                    error!("Failed to save encryption settings: {}", e);
                    error_message.set(Some(format!("Failed to save settings: {}", e)));
                }
            }
            
            is_loading.set(false);
        });
    };
    
    cx.render(rsx! {
        div { class: "container mx-auto p-4",
            h1 { class: "text-2xl font-bold mb-4", "End-to-End Encryption Settings" }
            
            if let Some(error) = error_message.get() {
                div { class: "bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4",
                    p { "{error}" }
                }
            }
            
            if let Some(success) = success_message.get() {
                div { class: "bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4",
                    p { "{success}" }
                }
            }
            
            div { class: "mb-4",
                label { class: "flex items-center",
                    input {
                        class: "mr-2",
                        r#type: "checkbox",
                        checked: settings.get().enabled,
                        onclick: on_toggle_enabled
                    }
                    span { "Enable End-to-End Encryption" }
                }
            }
            
            if settings.get().enabled {
                div { class: "mb-4",
                    label { class: "block mb-2", "Encryption Algorithm" }
                    select {
                        class: "w-full p-2 border rounded",
                        value: match settings.get().algorithm {
                            EncryptionAlgorithm::Aes256Gcm => "aes",
                            EncryptionAlgorithm::Chacha20Poly1305 => "chacha",
                            EncryptionAlgorithm::Kyber768 => "kyber",
                            EncryptionAlgorithm::Dilithium5 => "dilithium",
                            EncryptionAlgorithm::HybridAesKyber => "hybrid",
                        },
                        onchange: on_algorithm_change,
                        option { value: "aes", "AES-256-GCM (Standard)" }
                        option { value: "chacha", "ChaCha20-Poly1305 (Alternative)" }
                        option { value: "kyber", "KYBER-768 (Post-Quantum)" }
                        option { value: "dilithium", "DILITHIUM-5 (Post-Quantum Signatures)" }
                        option { value: "hybrid", "Hybrid: AES + KYBER (Recommended)" }
                    }
                }
                
                div { class: "mb-4",
                    label { class: "block mb-2", "Key Storage Method" }
                    select {
                        class: "w-full p-2 border rounded",
                        value: match settings.get().key_storage {
                            KeyStorageMethod::Password => "password",
                            KeyStorageMethod::SystemKeychain => "keychain",
                            KeyStorageMethod::KeyFile(_) => "file",
                            _ => "password",
                        },
                        onchange: on_storage_change,
                        option { value: "password", "Derive from Password" }
                        option { value: "keychain", "System Keychain" }
                        option { value: "file", "Key File" }
                    }
                }
                
                div { class: "mb-4",
                    label { class: "flex items-center",
                        input {
                            class: "mr-2",
                            r#type: "checkbox",
                            checked: settings.get().encrypt_filenames,
                            onclick: on_encrypt_filenames_change
                        }
                        span { "Encrypt File Names" }
                    }
                }
                
                div { class: "mb-4",
                    label { class: "flex items-center",
                        input {
                            class: "mr-2",
                            r#type: "checkbox",
                            checked: settings.get().encrypt_metadata,
                            onclick: on_encrypt_metadata_change
                        }
                        span { "Encrypt File Metadata" }
                    }
                }
                
                div { class: "mb-4",
                    label { class: "block mb-2", "Password" }
                    input {
                        class: "w-full p-2 border rounded",
                        r#type: "password",
                        placeholder: "Enter your encryption password",
                        value: password.get(),
                        oninput: move |evt| password.set(evt.value.clone())
                    }
                }
                
                div { class: "mb-4",
                    label { class: "block mb-2", "Confirm Password" }
                    input {
                        class: "w-full p-2 border rounded",
                        r#type: "password",
                        placeholder: "Confirm your encryption password",
                        value: confirm_password.get(),
                        oninput: move |evt| confirm_password.set(evt.value.clone())
                    }
                }
            }
            
            div { class: "flex justify-between",
                button {
                    class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded",
                    disabled: is_loading.get(),
                    onclick: save_settings,
                    if *is_loading.get() {
                        "Saving..."
                    } else {
                        "Save Settings"
                    }
                }
                
                // Add recovery link
                a {
                    class: "text-blue-500 hover:text-blue-700 self-center ml-4",
                    href: "#",
                    onclick: move |_| {
                        let navigator = use_navigator(cx);
                        navigator.push(crate::interfaces::app::Route::PasswordRecovery {});
                    },
                    "Forgot Password?"
                }
            }
        }
    })
}