use std::path::{Path, PathBuf};
use std::sync::Arc;

use tokio::sync::{broadcast, Mutex, RwLock};
use dioxus_desktop::{Config, SystemTrayEvent, WindowBuilder};
use dioxus_desktop::tray::{Icon, MenuBuilder, MenuItemBuilder, TrayIconBuilder};
use tracing::{debug, error, info, warn};
use notify_rust::Notification;

use crate::domain::services::sync_service::{SyncEvent, SyncService};
use crate::domain::entities::sync::{SyncState, SyncStatus};
use crate::domain::entities::config::{ApplicationConfig, ConfigService};

/// System integration service handles integration with OS features like
/// system tray, notifications, and autostart
pub struct SystemIntegration {
    /// Sync service
    sync_service: Arc<dyn SyncService>,
    /// Config service
    config_service: Arc<dyn ConfigService>,
    /// Application config
    config: Arc<RwLock<ApplicationConfig>>,
    /// System tray icon
    tray_icon: Arc<Mutex<Option<Icon>>>,
    /// Event subscriber
    event_subscriber: Arc<Mutex<Option<broadcast::Receiver<SyncEvent>>>>,
    /// Running flag
    running: Arc<RwLock<bool>>,
}

impl SystemIntegration {
    pub fn new(
        sync_service: Arc<dyn SyncService>,
        config_service: Arc<dyn ConfigService>,
    ) -> Self {
        Self {
            sync_service,
            config_service,
            config: Arc::new(RwLock::new(ApplicationConfig::default())),
            tray_icon: Arc::new(Mutex::new(None)),
            event_subscriber: Arc::new(Mutex::new(None)),
            running: Arc::new(RwLock::new(false)),
        }
    }
    
    /// Start the system integration
    pub async fn start(&self) -> Result<(), String> {
        // Check if already running
        if *self.running.read().await {
            return Err("System integration already running".to_string());
        }
        
        // Load the config
        let config = self.config_service.get_config().await
            .map_err(|e| format!("Failed to get config: {}", e))?;
            
        *self.config.write().await = config.clone();
        
        // Subscribe to sync events
        let event_sub = self.sync_service.subscribe_to_events().await;
        *self.event_subscriber.lock().await = Some(event_sub);
        
        // Initialize the system tray
        self.init_system_tray().await?;
        
        // Start the event processor
        self.start_event_processor().await;
        
        // Set the running flag
        *self.running.write().await = true;
        
        Ok(())
    }
    
    /// Initialize the system tray
    async fn init_system_tray(&self) -> Result<(), String> {
        // Create the tray menu
        let menu = MenuBuilder::new()
            .item("Open", "open")
            .separator()
            .item("Start Sync", "start_sync")
            .item("Pause Sync", "pause_sync")
            .separator()
            .item("Settings", "settings")
            .separator()
            .item("Quit", "quit")
            .build();
            
        // Get the icon path
        let icon_path = Self::get_app_icon_path()?;
        
        // Create the tray icon
        let icon = TrayIconBuilder::new()
            .menu(&menu)
            .tooltip("OxiCloud Desktop")
            .icon_from_path(&icon_path)
            .build()
            .map_err(|e| format!("Failed to create tray icon: {}", e))?;
            
        // Store the icon
        *self.tray_icon.lock().await = Some(icon);
        
        Ok(())
    }
    
    /// Start the event processor
    async fn start_event_processor(&self) {
        let running = self.running.clone();
        let sync_service = self.sync_service.clone();
        let config = self.config.clone();
        
        // Get the event subscriber
        let mut subscriber = self.event_subscriber.lock().await.take()
            .expect("Event subscriber not initialized");
            
        // Launch the event processor in a background task
        tokio::spawn(async move {
            info!("Event processor started");
            
            while !*running.read().await {
                // Process events
                if let Ok(event) = subscriber.recv().await {
                    match event {
                        SyncEvent::Started => {
                            // Sync started
                            debug!("Sync started");
                            
                            // Show notification if enabled
                            if config.read().await.ui.notifications {
                                Self::show_notification(
                                    "OxiCloud Sync",
                                    "Sync started",
                                    None,
                                ).await;
                            }
                        },
                        SyncEvent::Progress(status) => {
                            // Sync progress - we don't show notifications for this
                            // but could update a progress indicator in the UI
                        },
                        SyncEvent::Completed => {
                            // Sync completed
                            debug!("Sync completed");
                            
                            // Show notification if enabled
                            if config.read().await.ui.notifications {
                                Self::show_notification(
                                    "OxiCloud Sync",
                                    "Sync completed successfully",
                                    None,
                                ).await;
                            }
                        },
                        SyncEvent::Error(error) => {
                            // Sync error
                            error!("Sync error: {}", error);
                            
                            // Show notification if enabled
                            if config.read().await.ui.notifications {
                                Self::show_notification(
                                    "OxiCloud Sync Error",
                                    &error,
                                    Some("error"),
                                ).await;
                            }
                        },
                        SyncEvent::FileChanged(file) => {
                            // File changed - for now we don't show notifications for this
                            // as it could get very noisy, but we could add an option for it
                        },
                        _ => {
                            // Ignore other events
                        }
                    }
                }
                
                // Sleep a bit to avoid high CPU usage
                tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
            }
            
            info!("Event processor stopped");
        });
    }
    
    /// Handle system tray events
    pub async fn handle_tray_event(&self, event: SystemTrayEvent) {
        match event {
            SystemTrayEvent::MenuItemClick(id) => {
                match id.as_str() {
                    "open" => {
                        // Open the main window
                        // This would be handled by the UI layer
                        info!("Open main window");
                    },
                    "start_sync" => {
                        // Start sync
                        if let Err(e) = self.sync_service.start_sync().await {
                            error!("Failed to start sync: {}", e);
                        }
                    },
                    "pause_sync" => {
                        // Pause sync
                        if let Err(e) = self.sync_service.pause_sync().await {
                            error!("Failed to pause sync: {}", e);
                        }
                    },
                    "settings" => {
                        // Open settings
                        // This would be handled by the UI layer
                        info!("Open settings");
                    },
                    "quit" => {
                        // Quit the application
                        // This would be handled by the UI layer
                        info!("Quit application");
                    },
                    _ => {}
                }
            },
            _ => {}
        }
    }
    
    /// Show a notification
    pub async fn show_notification(title: &str, body: &str, icon_type: Option<&str>) {
        tokio::task::spawn_blocking(move || {
            let mut notification = Notification::new();
            notification.summary(title).body(body).appname("OxiCloud");
            
            if let Some(icon) = icon_type {
                if icon == "error" {
                    notification.icon("dialog-error");
                } else if icon == "warning" {
                    notification.icon("dialog-warning");
                } else if icon == "info" {
                    notification.icon("dialog-information");
                }
            }
            
            // Show the notification
            if let Err(e) = notification.show() {
                error!("Failed to show notification: {}", e);
            }
        });
    }
    
    /// Configure autostart
    pub async fn configure_autostart(&self, enabled: bool) -> Result<(), String> {
        #[cfg(target_os = "windows")]
        {
            use winreg::enums::*;
            use winreg::RegKey;
            
            let path = std::env::current_exe()
                .map_err(|e| format!("Failed to get executable path: {}", e))?;
                
            let hkcu = RegKey::predef(HKEY_CURRENT_USER);
            let key = hkcu.open_subkey_with_flags(
                r"Software\Microsoft\Windows\CurrentVersion\Run",
                KEY_WRITE,
            ).map_err(|e| format!("Failed to open registry key: {}", e))?;
            
            if enabled {
                key.set_value("OxiCloud", &path.to_string_lossy().to_string())
                    .map_err(|e| format!("Failed to set registry value: {}", e))?;
            } else {
                key.delete_value("OxiCloud")
                    .map_err(|e| format!("Failed to delete registry value: {}", e))?;
            }
        }
        
        #[cfg(target_os = "macos")]
        {
            let home = dirs::home_dir()
                .ok_or_else(|| "Failed to get home directory".to_string())?;
                
            let launch_agents = home.join("Library/LaunchAgents");
            std::fs::create_dir_all(&launch_agents)
                .map_err(|e| format!("Failed to create LaunchAgents directory: {}", e))?;
                
            let plist_path = launch_agents.join("com.oxicloud.desktop.plist");
            
            if enabled {
                let path = std::env::current_exe()
                    .map_err(|e| format!("Failed to get executable path: {}", e))?;
                    
                let plist = format!(
                    r#"<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.oxicloud.desktop</string>
    <key>ProgramArguments</key>
    <array>
        <string>{}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>"#,
                    path.to_string_lossy()
                );
                
                std::fs::write(&plist_path, plist)
                    .map_err(|e| format!("Failed to write plist file: {}", e))?;
            } else {
                if plist_path.exists() {
                    std::fs::remove_file(&plist_path)
                        .map_err(|e| format!("Failed to remove plist file: {}", e))?;
                }
            }
        }
        
        #[cfg(target_os = "linux")]
        {
            let home = dirs::home_dir()
                .ok_or_else(|| "Failed to get home directory".to_string())?;
                
            let autostart = home.join(".config/autostart");
            std::fs::create_dir_all(&autostart)
                .map_err(|e| format!("Failed to create autostart directory: {}", e))?;
                
            let desktop_path = autostart.join("oxicloud.desktop");
            
            if enabled {
                let path = std::env::current_exe()
                    .map_err(|e| format!("Failed to get executable path: {}", e))?;
                    
                let desktop = format!(
                    r#"[Desktop Entry]
Type=Application
Name=OxiCloud Desktop
Exec={}
Icon=oxicloud
Comment=OxiCloud Desktop Sync Client
Categories=Network;
Terminal=false
StartupNotify=false
X-GNOME-Autostart-enabled=true
"#,
                    path.to_string_lossy()
                );
                
                std::fs::write(&desktop_path, desktop)
                    .map_err(|e| format!("Failed to write desktop file: {}", e))?;
            } else {
                if desktop_path.exists() {
                    std::fs::remove_file(&desktop_path)
                        .map_err(|e| format!("Failed to remove desktop file: {}", e))?;
                }
            }
        }
        
        Ok(())
    }
    
    /// Get the app icon path
    fn get_app_icon_path() -> Result<String, String> {
        #[cfg(target_os = "windows")]
        {
            let exe_path = std::env::current_exe()
                .map_err(|e| format!("Failed to get executable path: {}", e))?;
                
            Ok(exe_path.to_string_lossy().to_string())
        }
        
        #[cfg(target_os = "macos")]
        {
            let exe_path = std::env::current_exe()
                .map_err(|e| format!("Failed to get executable path: {}", e))?;
                
            // On macOS, the app icon is in the Resources directory
            let app_bundle = exe_path.parent().unwrap()
                .parent().unwrap()
                .parent().unwrap();
                
            let icon_path = app_bundle.join("Resources/AppIcon.icns");
            
            if icon_path.exists() {
                Ok(icon_path.to_string_lossy().to_string())
            } else {
                // Fallback to a default icon
                Ok("".to_string())
            }
        }
        
        #[cfg(target_os = "linux")]
        {
            // Try to find the icon in standard locations
            let icon_paths = [
                "/usr/share/icons/hicolor/256x256/apps/oxicloud.png",
                "/usr/share/pixmaps/oxicloud.png",
            ];
            
            for path in &icon_paths {
                if std::path::Path::new(path).exists() {
                    return Ok(path.to_string());
                }
            }
            
            // Fallback to a default icon
            Ok("".to_string())
        }
        
        #[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
        {
            // Fallback for other platforms
            Ok("".to_string())
        }
    }
}