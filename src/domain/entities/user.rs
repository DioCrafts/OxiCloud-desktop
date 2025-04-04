use serde::{Serialize, Deserialize};
use thiserror::Error;
use chrono::{DateTime, Utc};

#[derive(Debug, Error)]
pub enum UserError {
    #[error("Invalid username: {0}")]
    InvalidUsername(String),
    
    #[error("Invalid password: {0}")]
    InvalidPassword(String),
    
    #[error("Authentication error: {0}")]
    AuthenticationError(String),
}

pub type UserResult<T> = Result<T, UserError>;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum UserRole {
    Admin,
    User,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct User {
    pub id: String,
    pub username: String,
    pub email: String,
    pub role: UserRole,
    pub storage_quota_bytes: i64,
    pub storage_used_bytes: i64,
    pub server_url: String,
    pub last_login_at: Option<DateTime<Utc>>,
    pub access_token: Option<String>,
    pub refresh_token: Option<String>,
}

impl User {
    pub fn new(id: String, username: String, email: String, role: UserRole, 
              storage_quota_bytes: i64, storage_used_bytes: i64, server_url: String) -> Self {
        Self {
            id,
            username,
            email,
            role,
            storage_quota_bytes,
            storage_used_bytes,
            server_url,
            last_login_at: None,
            access_token: None,
            refresh_token: None,
        }
    }
    
    pub fn quota_percentage(&self) -> f64 {
        if self.storage_quota_bytes <= 0 {
            return 0.0;
        }
        
        (self.storage_used_bytes as f64 / self.storage_quota_bytes as f64) * 100.0
    }
    
    pub fn set_tokens(&mut self, access_token: String, refresh_token: String) {
        self.access_token = Some(access_token);
        self.refresh_token = Some(refresh_token);
        self.last_login_at = Some(Utc::now());
    }
    
    pub fn clear_tokens(&mut self) {
        self.access_token = None;
        self.refresh_token = None;
    }
    
    pub fn is_authenticated(&self) -> bool {
        self.access_token.is_some() && self.refresh_token.is_some()
    }
}
