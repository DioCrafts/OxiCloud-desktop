use dioxus::prelude::*;
use std::path::PathBuf;
use std::sync::Arc;

use crate::application::ports::config_port::ConfigPort;
use crate::domain::entities::config::{Theme, SyncMode, UpdateCheck};

#[derive(Props)]
pub struct SettingsPageProps {
    #[props(optional)]
    on_save: Option<Callback<()>>,
}

/// Settings page component
pub fn SettingsPage(cx: Scope<SettingsPageProps>) -> Element {
    let config_service = use_context::<Arc<dyn ConfigPort>>(cx).unwrap();
    
    // State for settings form
    let active_tab = use_state(cx, || "general");
    let theme = use_state(cx, || Theme::Light);
    let start_minimized = use_state(cx, || false);
    let minimize_to_tray = use_state(cx, || true);
    let notifications = use_state(cx, || true);
    let binary_sizes = use_state(cx, || true);
    let update_check = use_state(cx, || UpdateCheck::Daily);

    // Network settings
    let upload_limit = use_state(cx, || 0);
    let download_limit = use_state(cx, || 0);
    let rate_limiting = use_state(cx, || false);
    let proxy_url = use_state(cx, || String::new());

    // Sync settings
    let sync_enabled = use_state(cx, || true);
    let sync_interval = use_state(cx, || 300);
    let sync_mode = use_state(cx, || SyncMode::Automatic);
    let pause_on_metered = use_state(cx, || true);
    let sync_folder = use_state(cx, || None::<PathBuf>);
    let selective_sync = use_state(cx, || false);
    let max_file_size = use_state(cx, || 0);

    // Performance settings
    let upload_threads = use_state(cx, || 4u8);
    let download_threads = use_state(cx, || 4u8);
    let chunk_size = use_state(cx, || 4u32);
    let parallel_encryption = use_state(cx, || true);
    let max_parallel_encryption = use_state(cx, || 8u8);

    // Advanced settings
    let debug_logging = use_state(cx, || false);
    let log_file_size = use_state(cx, || 10u32);
    let log_file_count = use_state(cx, || 5u32);
    let crash_reporting = use_state(cx, || true);
    let usage_statistics = use_state(cx, || false);

    // Load config when component mounts
    use_effect(cx, (), |_| {
        let config_svc = config_service.clone();
        
        // State setters
        let theme_setter = theme.clone();
        let start_minimized_setter = start_minimized.clone();
        let minimize_to_tray_setter = minimize_to_tray.clone();
        let notifications_setter = notifications.clone();
        let binary_sizes_setter = binary_sizes.clone();
        let update_check_setter = update_check.clone();
        
        let upload_limit_setter = upload_limit.clone();
        let download_limit_setter = download_limit.clone();
        let rate_limiting_setter = rate_limiting.clone();
        let proxy_url_setter = proxy_url.clone();
        
        let sync_enabled_setter = sync_enabled.clone();
        let sync_interval_setter = sync_interval.clone();
        let sync_mode_setter = sync_mode.clone();
        let pause_on_metered_setter = pause_on_metered.clone();
        let sync_folder_setter = sync_folder.clone();
        let selective_sync_setter = selective_sync.clone();
        let max_file_size_setter = max_file_size.clone();
        
        let upload_threads_setter = upload_threads.clone();
        let download_threads_setter = download_threads.clone();
        let chunk_size_setter = chunk_size.clone();
        let parallel_encryption_setter = parallel_encryption.clone();
        let max_parallel_encryption_setter = max_parallel_encryption.clone();
        
        let debug_logging_setter = debug_logging.clone();
        let log_file_size_setter = log_file_size.clone();
        let log_file_count_setter = log_file_count.clone();
        let crash_reporting_setter = crash_reporting.clone();
        let usage_statistics_setter = usage_statistics.clone();
        
        async move {
            // Load configuration
            if let Ok(config) = config_svc.get_config().await {
                // Set UI settings
                theme_setter.set(config.ui.theme);
                start_minimized_setter.set(config.ui.start_minimized);
                minimize_to_tray_setter.set(config.ui.minimize_to_tray);
                notifications_setter.set(config.ui.notifications);
                binary_sizes_setter.set(config.ui.binary_sizes);
                update_check_setter.set(config.ui.update_check);
                
                // Set network settings
                upload_limit_setter.set(config.network.upload_limit);
                download_limit_setter.set(config.network.download_limit);
                rate_limiting_setter.set(config.network.rate_limiting);
                if let Some(url) = config.network.proxy_url {
                    proxy_url_setter.set(url);
                }
                
                // Set sync settings
                sync_enabled_setter.set(config.sync.enabled);
                sync_interval_setter.set(config.sync.interval);
                sync_mode_setter.set(config.sync.mode);
                pause_on_metered_setter.set(config.sync.pause_on_metered);
                sync_folder_setter.set(config.sync.sync_folder);
                selective_sync_setter.set(config.sync.selective_sync);
                max_file_size_setter.set(config.sync.max_file_size);
                
                // Set performance settings
                upload_threads_setter.set(config.performance.upload_threads);
                download_threads_setter.set(config.performance.download_threads);
                chunk_size_setter.set(config.performance.chunk_size);
                parallel_encryption_setter.set(config.performance.parallel_encryption);
                max_parallel_encryption_setter.set(config.performance.max_parallel_encryption);
                
                // Set advanced settings
                debug_logging_setter.set(config.advanced.debug_logging);
                log_file_size_setter.set(config.advanced.log_file_size);
                log_file_count_setter.set(config.advanced.log_file_count);
                crash_reporting_setter.set(config.advanced.crash_reporting);
                usage_statistics_setter.set(config.advanced.usage_statistics);
            }
        }
    });

    // Handle saving changes
    let save_changes = move |_| {
        let config_svc = config_service.clone();
        
        // Current state values
        let theme_value = *theme.get();
        let start_minimized_value = *start_minimized.get();
        let minimize_to_tray_value = *minimize_to_tray.get();
        let notifications_value = *notifications.get();
        let binary_sizes_value = *binary_sizes.get();
        let update_check_value = *update_check.get();
        
        let upload_limit_value = *upload_limit.get();
        let download_limit_value = *download_limit.get();
        let rate_limiting_value = *rate_limiting.get();
        let proxy_url_value = proxy_url.get().clone();
        
        let sync_enabled_value = *sync_enabled.get();
        let sync_interval_value = *sync_interval.get();
        let sync_mode_value = *sync_mode.get();
        let pause_on_metered_value = *pause_on_metered.get();
        let sync_folder_value = sync_folder.get().clone();
        let selective_sync_value = *selective_sync.get();
        let max_file_size_value = *max_file_size.get();
        
        let upload_threads_value = *upload_threads.get();
        let download_threads_value = *download_threads.get();
        let chunk_size_value = *chunk_size.get();
        let parallel_encryption_value = *parallel_encryption.get();
        let max_parallel_encryption_value = *max_parallel_encryption.get();
        
        let debug_logging_value = *debug_logging.get();
        let log_file_size_value = *log_file_size.get();
        let log_file_count_value = *log_file_count.get();
        let crash_reporting_value = *crash_reporting.get();
        let usage_statistics_value = *usage_statistics.get();
        
        let on_save_callback = cx.props.on_save.clone();
        
        async move {
            // Get current config
            if let Ok(mut config) = config_svc.get_config().await {
                // Update UI settings
                config.ui.theme = theme_value;
                config.ui.start_minimized = start_minimized_value;
                config.ui.minimize_to_tray = minimize_to_tray_value;
                config.ui.notifications = notifications_value;
                config.ui.binary_sizes = binary_sizes_value;
                config.ui.update_check = update_check_value;
                
                // Update network settings
                config.network.upload_limit = upload_limit_value;
                config.network.download_limit = download_limit_value;
                config.network.rate_limiting = rate_limiting_value;
                config.network.proxy_url = if proxy_url_value.trim().is_empty() {
                    None
                } else {
                    Some(proxy_url_value)
                };
                
                // Update sync settings
                config.sync.enabled = sync_enabled_value;
                config.sync.interval = sync_interval_value;
                config.sync.mode = sync_mode_value;
                config.sync.pause_on_metered = pause_on_metered_value;
                config.sync.sync_folder = sync_folder_value;
                config.sync.selective_sync = selective_sync_value;
                config.sync.max_file_size = max_file_size_value;
                
                // Update performance settings
                config.performance.upload_threads = upload_threads_value;
                config.performance.download_threads = download_threads_value;
                config.performance.chunk_size = chunk_size_value;
                config.performance.parallel_encryption = parallel_encryption_value;
                config.performance.max_parallel_encryption = max_parallel_encryption_value;
                
                // Update advanced settings
                config.advanced.debug_logging = debug_logging_value;
                config.advanced.log_file_size = log_file_size_value;
                config.advanced.log_file_count = log_file_count_value;
                config.advanced.crash_reporting = crash_reporting_value;
                config.advanced.usage_statistics = usage_statistics_value;
                
                // Save updated config
                let _ = config_svc.save_config(&config).await;
                
                // Call on_save callback if provided
                if let Some(callback) = on_save_callback {
                    callback.call(());
                }
            }
        }
    };

    // Choose sync folder
    let choose_sync_folder = move |_| {
        let sync_folder_setter = sync_folder.clone();
        
        async move {
            // This is a placeholder - in a real application, we would open a native file dialog
            // For this example, we'll just set it to a default path
            let default_path = dirs::home_dir().unwrap_or_default().join("OxiCloud");
            sync_folder_setter.set(Some(default_path));
        }
    };

    cx.render(rsx! {
        div { class: "settings-page",
            h1 { class: "page-title", "Settings" }
            
            // Settings tabs
            div { class: "settings-tabs",
                button {
                    class: if *active_tab.get() == "general" { "tab-active" } else { "" },
                    onclick: move |_| active_tab.set("general"),
                    "General"
                }
                button {
                    class: if *active_tab.get() == "network" { "tab-active" } else { "" },
                    onclick: move |_| active_tab.set("network"),
                    "Network"
                }
                button {
                    class: if *active_tab.get() == "sync" { "tab-active" } else { "" },
                    onclick: move |_| active_tab.set("sync"),
                    "Synchronization"
                }
                button {
                    class: if *active_tab.get() == "performance" { "tab-active" } else { "" },
                    onclick: move |_| active_tab.set("performance"),
                    "Performance"
                }
                button {
                    class: if *active_tab.get() == "advanced" { "tab-active" } else { "" },
                    onclick: move |_| active_tab.set("advanced"),
                    "Advanced"
                }
            }
            
            // Settings content
            div { class: "settings-content",
                // General settings
                div { 
                    class: if *active_tab.get() == "general" { "tab-panel active" } else { "tab-panel" },
                    div { class: "setting-group",
                        h3 { "Theme" }
                        div { class: "setting-option",
                            select { 
                                value: match *theme.get() {
                                    Theme::Light => "light",
                                    Theme::Dark => "dark",
                                    Theme::System => "system",
                                },
                                oninput: move |evt| {
                                    match evt.value.as_str() {
                                        "light" => theme.set(Theme::Light),
                                        "dark" => theme.set(Theme::Dark),
                                        "system" => theme.set(Theme::System),
                                        _ => {},
                                    }
                                },
                                option { value: "light", "Light" }
                                option { value: "dark", "Dark" }
                                option { value: "system", "System" }
                            }
                        }
                    }
                    
                    div { class: "setting-group",
                        h3 { "Application Behavior" }
                        div { class: "setting-option",
                            label {
                                input {
                                    r#type: "checkbox",
                                    checked: *start_minimized.get(),
                                    oninput: move |evt| start_minimized.set(evt.value.parse().unwrap_or(false)),
                                }
                                "Start application minimized"
                            }
                        }
                        div { class: "setting-option",
                            label {
                                input {
                                    r#type: "checkbox",
                                    checked: *minimize_to_tray.get(),
                                    oninput: move |evt| minimize_to_tray.set(evt.value.parse().unwrap_or(true)),
                                }
                                "Minimize to tray when closed"
                            }
                        }
                        div { class: "setting-option",
                            label {
                                input {
                                    r#type: "checkbox",
                                    checked: *notifications.get(),
                                    oninput: move |evt| notifications.set(evt.value.parse().unwrap_or(true)),
                                }
                                "Show notifications"
                            }
                        }
                    }
                    
                    div { class: "setting-group",
                        h3 { "Display" }
                        div { class: "setting-option",
                            label {
                                input {
                                    r#type: "checkbox",
                                    checked: *binary_sizes.get(),
                                    oninput: move |evt| binary_sizes.set(evt.value.parse().unwrap_or(true)),
                                }
                                "Display file sizes in binary format (KiB, MiB)"
                            }
                        }
                    }
                    
                    div { class: "setting-group",
                        h3 { "Updates" }
                        div { class: "setting-option",
                            label { "Check for updates:" }
                            select {
                                value: match *update_check.get() {
                                    UpdateCheck::Never => "never",
                                    UpdateCheck::Daily => "daily",
                                    UpdateCheck::Weekly => "weekly",
                                    UpdateCheck::Monthly => "monthly",
                                },
                                oninput: move |evt| {
                                    match evt.value.as_str() {
                                        "never" => update_check.set(UpdateCheck::Never),
                                        "daily" => update_check.set(UpdateCheck::Daily),
                                        "weekly" => update_check.set(UpdateCheck::Weekly),
                                        "monthly" => update_check.set(UpdateCheck::Monthly),
                                        _ => {},
                                    }
                                },
                                option { value: "never", "Never" }
                                option { value: "daily", "Daily" }
                                option { value: "weekly", "Weekly" }
                                option { value: "monthly", "Monthly" }
                            }
                        }
                    }
                }
                
                // Network settings
                div {
                    class: if *active_tab.get() == "network" { "tab-panel active" } else { "tab-panel" },
                    div { class: "setting-group",
                        h3 { "Bandwidth Limits" }
                        div { class: "setting-option",
                            label {
                                input {
                                    r#type: "checkbox",
                                    checked: *rate_limiting.get(),
                                    oninput: move |evt| rate_limiting.set(evt.value.parse().unwrap_or(false)),
                                }
                                "Enable rate limiting"
                            }
                        }
                        div { class: "setting-option",
                            label { "Upload limit (KB/s, 0 = unlimited):" }
                            input {
                                r#type: "number",
                                value: "{upload_limit}",
                                min: "0",
                                disabled: !*rate_limiting.get(),
                                oninput: move |evt| upload_limit.set(evt.value.parse().unwrap_or(0)),
                            }
                        }
                        div { class: "setting-option",
                            label { "Download limit (KB/s, 0 = unlimited):" }
                            input {
                                r#type: "number",
                                value: "{download_limit}",
                                min: "0",
                                disabled: !*rate_limiting.get(),
                                oninput: move |evt| download_limit.set(evt.value.parse().unwrap_or(0)),
                            }
                        }
                    }
                    
                    div { class: "setting-group",
                        h3 { "Proxy" }
                        div { class: "setting-option",
                            label { "Proxy URL (leave empty for no proxy):" }
                            input {
                                r#type: "text",
                                value: "{proxy_url}",
                                placeholder: "http://proxy.example.com:8080",
                                oninput: move |evt| proxy_url.set(evt.value.clone()),
                            }
                        }
                    }
                }
                
                // Sync settings
                div {
                    class: if *active_tab.get() == "sync" { "tab-panel active" } else { "tab-panel" },
                    div { class: "setting-group",
                        h3 { "Synchronization" }
                        div { class: "setting-option",
                            label {
                                input {
                                    r#type: "checkbox",
                                    checked: *sync_enabled.get(),
                                    oninput: move |evt| sync_enabled.set(evt.value.parse().unwrap_or(true)),
                                }
                                "Enable synchronization"
                            }
                        }
                        div { class: "setting-option",
                            label { "Synchronization mode:" }
                            select {
                                value: match *sync_mode.get() {
                                    SyncMode::Automatic => "automatic",
                                    SyncMode::Manual => "manual",
                                    SyncMode::Scheduled => "scheduled",
                                },
                                disabled: !*sync_enabled.get(),
                                oninput: move |evt| {
                                    match evt.value.as_str() {
                                        "automatic" => sync_mode.set(SyncMode::Automatic),
                                        "manual" => sync_mode.set(SyncMode::Manual),
                                        "scheduled" => sync_mode.set(SyncMode::Scheduled),
                                        _ => {},
                                    }
                                },
                                option { value: "automatic", "Automatic" }
                                option { value: "manual", "Manual" }
                                option { value: "scheduled", "Scheduled" }
                            }
                        }
                        div { class: "setting-option",
                            label { "Sync interval (seconds):" }
                            input {
                                r#type: "number",
                                value: "{sync_interval}",
                                min: "30",
                                disabled: !*sync_enabled.get() || *sync_mode.get() != SyncMode::Automatic,
                                oninput: move |evt| sync_interval.set(evt.value.parse().unwrap_or(300)),
                            }
                        }
                        div { class: "setting-option",
                            label {
                                input {
                                    r#type: "checkbox",
                                    checked: *pause_on_metered.get(),
                                    disabled: !*sync_enabled.get(),
                                    oninput: move |evt| pause_on_metered.set(evt.value.parse().unwrap_or(true)),
                                }
                                "Pause sync on metered connections"
                            }
                        }
                    }
                    
                    div { class: "setting-group",
                        h3 { "Sync Folder" }
                        div { class: "setting-option",
                            div { class: "sync-folder-display",
                                if let Some(folder) = sync_folder.get() {
                                    p { "{folder.display()}" }
                                } else {
                                    p { "No sync folder selected" }
                                }
                                button {
                                    onclick: choose_sync_folder,
                                    disabled: !*sync_enabled.get(),
                                    "Choose Folder"
                                }
                            }
                        }
                        div { class: "setting-option",
                            label {
                                input {
                                    r#type: "checkbox",
                                    checked: *selective_sync.get(),
                                    disabled: !*sync_enabled.get(),
                                    oninput: move |evt| selective_sync.set(evt.value.parse().unwrap_or(false)),
                                }
                                "Enable selective sync"
                            }
                        }
                        div { class: "setting-option",
                            label { "Max file size for sync (MB, 0 = unlimited):" }
                            input {
                                r#type: "number",
                                value: "{max_file_size}",
                                min: "0",
                                disabled: !*sync_enabled.get(),
                                oninput: move |evt| max_file_size.set(evt.value.parse().unwrap_or(0)),
                            }
                        }
                    }
                }
                
                // Performance settings
                div {
                    class: if *active_tab.get() == "performance" { "tab-panel active" } else { "tab-panel" },
                    div { class: "setting-group",
                        h3 { "Thread Settings" }
                        div { class: "setting-option",
                            label { "Upload threads:" }
                            input {
                                r#type: "number",
                                value: "{upload_threads}",
                                min: "1",
                                max: "16",
                                oninput: move |evt| upload_threads.set(evt.value.parse().unwrap_or(4)),
                            }
                        }
                        div { class: "setting-option",
                            label { "Download threads:" }
                            input {
                                r#type: "number",
                                value: "{download_threads}",
                                min: "1",
                                max: "16",
                                oninput: move |evt| download_threads.set(evt.value.parse().unwrap_or(4)),
                            }
                        }
                    }
                    
                    div { class: "setting-group",
                        h3 { "File Processing" }
                        div { class: "setting-option",
                            label { "Chunk size for large files (MB):" }
                            input {
                                r#type: "number",
                                value: "{chunk_size}",
                                min: "1",
                                max: "64",
                                oninput: move |evt| chunk_size.set(evt.value.parse().unwrap_or(4)),
                            }
                        }
                    }
                    
                    div { class: "setting-group",
                        h3 { "Encryption" }
                        div { class: "setting-option",
                            label {
                                input {
                                    r#type: "checkbox",
                                    checked: *parallel_encryption.get(),
                                    oninput: move |evt| parallel_encryption.set(evt.value.parse().unwrap_or(true)),
                                }
                                "Enable parallel encryption/decryption"
                            }
                        }
                        div { class: "setting-option",
                            label { "Max parallel encryption operations:" }
                            input {
                                r#type: "number",
                                value: "{max_parallel_encryption}",
                                min: "1",
                                max: "32",
                                disabled: !*parallel_encryption.get(),
                                oninput: move |evt| max_parallel_encryption.set(evt.value.parse().unwrap_or(8)),
                            }
                        }
                    }
                }
                
                // Advanced settings
                div {
                    class: if *active_tab.get() == "advanced" { "tab-panel active" } else { "tab-panel" },
                    div { class: "setting-group",
                        h3 { "Logging" }
                        div { class: "setting-option",
                            label {
                                input {
                                    r#type: "checkbox",
                                    checked: *debug_logging.get(),
                                    oninput: move |evt| debug_logging.set(evt.value.parse().unwrap_or(false)),
                                }
                                "Enable debug logging"
                            }
                        }
                        div { class: "setting-option",
                            label { "Max log file size (MB):" }
                            input {
                                r#type: "number",
                                value: "{log_file_size}",
                                min: "1",
                                max: "100",
                                oninput: move |evt| log_file_size.set(evt.value.parse().unwrap_or(10)),
                            }
                        }
                        div { class: "setting-option",
                            label { "Number of log files to keep:" }
                            input {
                                r#type: "number",
                                value: "{log_file_count}",
                                min: "1",
                                max: "20",
                                oninput: move |evt| log_file_count.set(evt.value.parse().unwrap_or(5)),
                            }
                        }
                    }
                    
                    div { class: "setting-group",
                        h3 { "Privacy" }
                        div { class: "setting-option",
                            label {
                                input {
                                    r#type: "checkbox",
                                    checked: *crash_reporting.get(),
                                    oninput: move |evt| crash_reporting.set(evt.value.parse().unwrap_or(true)),
                                }
                                "Enable crash reporting"
                            }
                        }
                        div { class: "setting-option",
                            label {
                                input {
                                    r#type: "checkbox",
                                    checked: *usage_statistics.get(),
                                    oninput: move |evt| usage_statistics.set(evt.value.parse().unwrap_or(false)),
                                }
                                "Enable anonymous usage statistics"
                            }
                        }
                    }
                }
            }
            
            // Save button
            div { class: "settings-actions",
                button {
                    class: "primary-button",
                    onclick: save_changes,
                    "Save Changes"
                }
            }
        }
    })
}