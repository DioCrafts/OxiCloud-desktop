use std::sync::Arc;
use std::path::PathBuf;

use eframe::{App, Frame};
use egui::{Context, CentralPanel, TopBottomPanel, SidePanel, Ui};
use log::info;

use crate::domain::repositories::auth_repository::AuthRepository;
use crate::domain::repositories::file_repository::FileRepository;
use crate::domain::repositories::folder_repository::FolderRepository;
use crate::infrastructure::repositories::auth_repository_impl::AuthRepositoryImpl;
use crate::infrastructure::repositories::file_repository_impl::FileRepositoryImpl;
use crate::infrastructure::repositories::folder_repository_impl::FolderRepositoryImpl;
use crate::infrastructure::adapters::http_client::HttpClient;
use crate::infrastructure::adapters::auth_adapter::AuthAdapter;
use crate::infrastructure::adapters::webdav_adapter::WebDavAdapter;
use crate::infrastructure::adapters::folder_adapter::FolderAdapter;
use crate::ui::app_state::{AppState, UiState, AppView};
use crate::ui::components::login_panel::LoginPanel;
use crate::ui::components::file_browser::FileBrowser;
use crate::ui::components::sync_manager::SyncManager;

/// Main application struct
pub struct OxiCloudApp {
    /// Application state
    state: AppState,
    
    /// Repository for authentication
    auth_repository: Arc<dyn AuthRepository>,
    
    /// Repository for file operations
    file_repository: Arc<dyn FileRepository>,
    
    /// Repository for folder operations
    folder_repository: Arc<dyn FolderRepository>,
    
    /// UI state
    ui_state: UiState,
    
    /// Login panel
    login_panel: LoginPanel,
    
    /// File browser panel
    file_browser: FileBrowser,
    
    /// Sync manager
    sync_manager: SyncManager,
}

impl OxiCloudApp {
    /// Create a new application instance
    pub fn new(cc: &eframe::CreationContext<'_>) -> Self {
        // Set up custom fonts if needed
        setup_custom_fonts(&cc.egui_ctx);
        
        info!("Initializing OxiCloud Desktop Client");
        
        // Create app state
        let state = AppState::default();
        
        // Initialize HTTP client
        let http_client = Arc::new(HttpClient::new("https://localhost:8080".to_string()));
        
        // Initialize adapters
        let auth_adapter = Arc::new(AuthAdapter::new(Arc::clone(&http_client)));
        let webdav_adapter = Arc::new(WebDavAdapter::new(Arc::clone(&http_client), "/webdav"));
        let folder_adapter = Arc::new(FolderAdapter::new(
            Arc::clone(&http_client),
            Arc::clone(&webdav_adapter)
        ));
        
        // Initialize repositories
        let auth_repository: Arc<dyn AuthRepository> = Arc::new(AuthRepositoryImpl::new(
            Arc::clone(&auth_adapter),
            "https://localhost:8080"
        ));
        
        let file_repository: Arc<dyn FileRepository> = Arc::new(FileRepositoryImpl::new(
            Arc::clone(&webdav_adapter)
        ));
        
        let folder_repository: Arc<dyn FolderRepository> = Arc::new(FolderRepositoryImpl::new(
            Arc::clone(&folder_adapter),
            Arc::clone(&webdav_adapter)
        ));
        
        // Create UI state
        let ui_state = UiState {
            current_view: AppView::Login,
            ..Default::default()
        };
        
        // Create UI components
        let login_panel = LoginPanel::new(Arc::clone(&auth_repository));
        let file_browser = FileBrowser::new(
            Arc::clone(&file_repository),
            Arc::clone(&folder_repository)
        );
        
        // Local sync directory
        let local_sync_dir = dirs::home_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("OxiCloud");
            
        let sync_manager = SyncManager::new(
            Arc::clone(&file_repository),
            Arc::clone(&folder_repository),
            local_sync_dir
        );
        
        Self {
            state,
            auth_repository,
            file_repository,
            folder_repository,
            ui_state,
            login_panel,
            file_browser,
            sync_manager,
        }
    }
    
    /// Render the login view
    fn render_login_view(&mut self, ctx: &Context) {
        CentralPanel::default().show(ctx, |ui| {
            if self.login_panel.render(ui, &mut self.state, &mut self.ui_state) {
                // Successfully authenticated
                self.ui_state.current_view = AppView::Files;
            }
        });
    }
    
    /// Render the top navigation bar
    fn render_top_bar(&mut self, ui: &mut Ui) {
        ui.horizontal(|ui| {
            ui.heading("OxiCloud");
            ui.add_space(16.0);
            
            if ui.button("Files").clicked() {
                self.ui_state.current_view = AppView::Files;
            }
            
            if ui.button("Sync Status").clicked() {
                self.ui_state.current_view = AppView::SyncStatus;
            }
            
            if ui.button("Settings").clicked() {
                self.ui_state.current_view = AppView::Settings;
            }
            
            ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                if ui.button("Logout").clicked() {
                    self.ui_state.current_view = AppView::Login;
                    self.state.is_authenticated = false;
                }
            });
        });
    }
    
    /// Render the file browser view
    fn render_file_browser_view(&mut self, ctx: &Context) {
        // Top bar
        TopBottomPanel::top("top_panel").show(ctx, |ui| {
            self.render_top_bar(ui);
        });
        
        // Left panel (folder tree)
        SidePanel::left("folder_tree").resizable(true).min_width(200.0).show(ctx, |ui| {
            ui.heading("Folders");
            ui.separator();
            self.file_browser.render_folder_tree(ui);
        });
        
        // Main panel (file list)
        CentralPanel::default().show(ctx, |ui| {
            self.file_browser.render_file_list(ui, &self.state);
        });
    }
    
    /// Render the sync status view
    fn render_sync_status(&mut self, ctx: &Context) {
        // Top bar
        TopBottomPanel::top("top_panel").show(ctx, |ui| {
            self.render_top_bar(ui);
        });
        
        // Main panel
        CentralPanel::default().show(ctx, |ui| {
            self.sync_manager.render_sync_status(ui);
        });
    }
    
    /// Render the settings view
    fn render_settings(&mut self, ctx: &Context) {
        // Top bar
        TopBottomPanel::top("top_panel").show(ctx, |ui| {
            self.render_top_bar(ui);
        });
        
        // Main panel
        CentralPanel::default().show(ctx, |ui| {
            ui.heading("Settings");
            ui.separator();
            
            // Settings will be implemented later
            ui.label("Settings placeholder");
        });
    }
    
    /// Process background tasks
    fn process_background_tasks(&mut self, ctx: &Context) {
        // Update sync status to simulate progress
        self.sync_manager.update_sync_status();
        
        // Request repaint to keep UI responsive
        ctx.request_repaint_after(std::time::Duration::from_secs(1));
    }
}

impl App for OxiCloudApp {
    fn update(&mut self, ctx: &Context, _frame: &mut Frame) {
        // Check authentication status
        if !self.state.is_authenticated {
            self.render_login_view(ctx);
            return;
        }
        
        // Render the current view
        match self.ui_state.current_view {
            AppView::Files => self.render_file_browser_view(ctx),
            AppView::SyncStatus => self.render_sync_status(ctx),
            AppView::Settings => self.render_settings(ctx),
            _ => self.render_login_view(ctx),
        }
        
        // Handle background tasks
        self.process_background_tasks(ctx);
    }
}

/// Set up custom fonts for the application
fn setup_custom_fonts(_ctx: &Context) {
    // Custom font setup would go here
}