use std::sync::{Arc, Mutex};
use std::thread;
use std::sync::mpsc::{self, Sender, Receiver};

use eframe::egui;
use egui::{Ui, Vec2, Color32, Stroke, RichText, TextEdit};
use log::{info, debug, error};
use tokio::runtime::Runtime;

use crate::domain::models::user::{AuthToken, User};
use crate::domain::repositories::auth_repository::AuthRepository;
use crate::ui::app_state::{AppState, UiState, AppView};

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
        
        ui.vertical_centered(|ui| {
            ui.add_space(50.0);
            
            // Logo
            ui.label(RichText::new("OxiCloud").size(32.0).strong());
            
            ui.add_space(30.0);
            
            // Form
            egui::Frame::none()
                .fill(Color32::from_rgb(245, 245, 245))
                .stroke(Stroke::new(1.0, Color32::from_gray(220)))
                .rounding(8.0)
                .inner_margin(20.0)
                .show(ui, |ui| {
                    ui.set_width(300.0);
                    
                    ui.vertical_centered_justified(|ui| {
                        ui.heading("Login");
                        ui.add_space(16.0);
                        
                        ui.label("Server URL");
                        ui.add(TextEdit::singleline(&mut self.server_url)
                            .hint_text("https://your-oxicloud-server.com")
                            .desired_width(f32::INFINITY));
                        
                        ui.add_space(8.0);
                        
                        ui.label("Username");
                        ui.add(TextEdit::singleline(&mut self.username)
                            .hint_text("username")
                            .desired_width(f32::INFINITY));
                        
                        ui.add_space(8.0);
                        
                        ui.label("Password");
                        ui.add(TextEdit::singleline(&mut self.password)
                            .password(true)
                            .hint_text("password")
                            .desired_width(f32::INFINITY));
                        
                        ui.add_space(16.0);
                        
                        // Error message
                        if let Some(error) = &self.error_message {
                            ui.colored_label(Color32::RED, error);
                            ui.add_space(8.0);
                        }
                        
                        // Login button
                        let login_button = ui.add_enabled(
                            !self.is_loading && 
                            !self.server_url.is_empty() && 
                            !self.username.is_empty() && 
                            !self.password.is_empty(),
                            egui::Button::new(
                                if self.is_loading { "Logging in..." } else { "Login" }
                            ).min_size(Vec2::new(100.0, 36.0))
                        );
                        
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