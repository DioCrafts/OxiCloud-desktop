use std::collections::HashMap;

/// Main application state
#[derive(Default)]
pub struct AppState {
    /// Whether the user is authenticated
    pub is_authenticated: bool,
    
    /// Current server URL
    pub server_url: String,
    
    /// Username for authentication
    pub username: String,
    
    /// Current working directory path
    pub current_path: String,
    
    /// Map of file IDs to selection state
    pub selected_files: HashMap<String, bool>,
}

/// Available application views
#[derive(PartialEq, Eq, Clone, Copy)]
pub enum AppView {
    Login,
    Files,
    SyncStatus,
    Settings,
}

/// UI state used for controlling the interface
#[derive(Default)]
pub struct UiState {
    /// Current application view
    pub current_view: AppView,
    
    /// Whether a modal dialog is open
    pub modal_open: bool,
    
    /// Search query text
    pub search_query: String,
    
    /// Whether file operations are in progress
    pub is_loading: bool,
}

impl Default for AppView {
    fn default() -> Self {
        AppView::Login
    }
}