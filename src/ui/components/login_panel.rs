use std::sync::{Arc, Mutex};
use std::thread;
use std::sync::mpsc::{self, Sender, Receiver};

use eframe::egui;
use egui::{Ui, Vec2, Color32, Stroke, RichText, TextEdit, Frame, Rounding};
use log::{info, debug, error};
use tokio::runtime::Runtime;

use crate::domain::models::user::{AuthToken, User};
use crate::domain::repositories::auth_repository::AuthRepository;
use crate::ui::app_state::{AppState, UiState, AppView};
use crate::ui::theme::{OxiCloudColors, render_oxicloud_logo, widgets};

/// Message types for login results
enum LoginMessage {
    Success(AuthToken, User),
    Failure(String),
}

/// Panel for user authentication
pub struct LoginPanel {
    /// Authentication repository
    auth_repository: Arc<dyn AuthRepository>,
    
    /// Server URL
    server_url: String,
    
    /// Username for authentication
    username: String,
    
    /// Password for authentication
    password: String,
    
    /// Error message to display
    error_message: Option<String>,
    
    /// Whether login is in progress
    is_loading: bool,
    
    /// Channel receiver for login results
    login_receiver: Option<Receiver<LoginMessage>>,
    
    /// Handle to the tokio runtime
    runtime: Arc<Runtime>,
}

impl LoginPanel {
    /// Create a new login panel
    pub fn new(auth_repository: Arc<dyn AuthRepository>) -> Self {
        // Create tokio runtime for async operations
        let runtime = Arc::new(
            Runtime::new().expect("Failed to create Tokio runtime")
        );
        
        Self {
            auth_repository,
            server_url: "https://".to_string(),
            username: String::new(),
            password: String::new(),
            error_message: None,
            is_loading: false,
            login_receiver: None,
            runtime,
        }
    }
    
    /// Render the login panel
    pub fn render(&mut self, ui: &mut Ui, app_state: &mut AppState, ui_state: &mut UiState) -> bool {
        let mut authenticated = false;
        
        // Check for login response
        if let Some(receiver) = &self.login_receiver {
            if let Ok(message) = receiver.try_recv() {
                match message {
                    LoginMessage::Success(token, user) => {
                        debug!("Login successful: user {}", user.username);
                        app_state.is_authenticated = true;
                        app_state.server_url = self.server_url.clone();
                        app_state.username = self.username.clone();
                        ui_state.current_view = AppView::Files;
                        authenticated = true;
                        self.is_loading = false;
                        self.login_receiver = None;
                    },
                    LoginMessage::Failure(error) => {
                        debug!("Login failed: {}", error);
                        self.error_message = Some(error);
                        self.is_loading = false;
                        self.login_receiver = None;
                    }
                }
            }
        }
        
        let colors = OxiCloudColors::default();
        
        // Full screen container
        ui.vertical_centered(|ui| {
            ui.add_space(50.0);
            
            // Auth panel frame
            Frame::none()
                .fill(colors.card_background)
                .stroke(Stroke::new(1.0, Color32::from_gray(220)))
                .rounding(Rounding::same(10.0))
                .shadow(egui::epaint::Shadow::small_light())
                .inner_margin(30.0)
                .show(ui, |ui| {
                    ui.set_width(400.0);
                    
                    ui.vertical_centered(|ui| {
                        // Logo with cloud icon
                        render_oxicloud_logo(ui, 60.0);
                        
                        ui.add_space(20.0);
                        
                        ui.heading(RichText::new("Login to OxiCloud").color(colors.text_primary).size(20.0));
                        
                        ui.add_space(25.0);
                    });
                    
                    // Error message if any
                    if let Some(error) = &self.error_message {
                        ui.add(egui::Label::new(
                            RichText::new(error).color(colors.error)
                        ).wrap(true));
                        ui.add_space(10.0);
                    }
                    
                    // Login form
                    ui.vertical(|ui| {
                        // Server URL
                        ui.label(RichText::new("Server URL").color(colors.text_primary).size(14.0));
                        widgets::styled_text_input(ui, &mut self.server_url, "https://your-oxicloud-server.com");
                        ui.add_space(12.0);
                        
                        // Username
                        ui.label(RichText::new("Username").color(colors.text_primary).size(14.0));
                        widgets::styled_text_input(ui, &mut self.username, "username");
                        ui.add_space(12.0);
                        
                        // Password
                        ui.label(RichText::new("Password").color(colors.text_primary).size(14.0));
                        ui.style_mut().visuals.widgets.inactive.bg_fill = Color32::from_rgb(249, 250, 251); // #f9fafb
                        ui.style_mut().visuals.widgets.inactive.rounding = Rounding::same(8.0);
                        ui.add(TextEdit::singleline(&mut self.password)
                            .password(true)
                            .hint_text("password")
                            .desired_width(f32::INFINITY));
                        ui.reset_style();
                        
                        ui.add_space(20.0);
                        
                        // Login button (primary style)
                        let is_enabled = !self.is_loading && 
                            !self.server_url.is_empty() && 
                            !self.username.is_empty() && 
                            !self.password.is_empty();
                        
                        ui.set_enabled(is_enabled);
                        let login_button = widgets::primary_button(ui, if self.is_loading { "Logging in..." } else { "Login" });
                        ui.set_enabled(true);
                        
                        if login_button.clicked() {
                            self.handle_login();
                        }
                    });
                });
        });
        
        authenticated
    }
    
    /// Handle login attempt
    fn handle_login(&mut self) {
        debug!("Attempting login to {} as {}", self.server_url, self.username);
        
        self.is_loading = true;
        self.error_message = None;
        
        // Create channel for communication
        let (sender, receiver) = mpsc::channel();
        self.login_receiver = Some(receiver);
        
        // Clone data for the thread
        let auth_repository = Arc::clone(&self.auth_repository);
        let server_url = self.server_url.clone();
        let username = self.username.clone();
        let password = self.password.clone();
        let runtime = Arc::clone(&self.runtime);
        
        // Start background thread for login
        thread::spawn(move || {
            // Execute the async login in the runtime
            let login_result = runtime.block_on(async {
                auth_repository.login(&server_url, &username, &password).await
            });
            
            // Send result back to UI thread
            match login_result {
                Ok((token, user)) => {
                    let _ = sender.send(LoginMessage::Success(token, user));
                },
                Err(e) => {
                    let error_message = format!("Login failed: {}", e);
                    let _ = sender.send(LoginMessage::Failure(error_message));
                }
            }
        });
    }
    
    /// Actual login implementation (would be called from a background task)
    async fn perform_login(&self) -> Result<(AuthToken, User), anyhow::Error> {
        self.auth_repository.login(
            &self.server_url,
            &self.username,
            &self.password
        ).await
    }
}