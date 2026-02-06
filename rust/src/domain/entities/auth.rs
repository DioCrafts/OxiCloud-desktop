//! # Authentication Entities
//!
//! Authentication-related domain entities.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use flutter_rust_bridge::frb;

/// User credentials for authentication
#[frb]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuthCredentials {
    /// Server URL (e.g., https://cloud.example.com)
    pub server_url: String,
    
    /// Username
    pub username: String,
    
    /// Password (only used during login, not stored)
    pub password: String,
}

impl AuthCredentials {
    /// Validate credentials format
    pub fn validate(&self) -> Result<(), String> {
        if self.server_url.is_empty() {
            return Err("Server URL is required".to_string());
        }
        
        if !self.server_url.starts_with("http://") && !self.server_url.starts_with("https://") {
            return Err("Server URL must start with http:// or https://".to_string());
        }
        
        if self.username.is_empty() {
            return Err("Username is required".to_string());
        }
        
        if self.password.is_empty() {
            return Err("Password is required".to_string());
        }
        
        Ok(())
    }
    
    /// Get WebDAV base URL
    pub fn webdav_url(&self) -> String {
        format!("{}/dav/files/{}", self.server_url.trim_end_matches('/'), self.username)
    }
}

/// Server information
#[frb]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServerInfo {
    /// Server URL
    pub url: String,
    
    /// Server version
    pub version: String,
    
    /// Server name
    pub name: String,
    
    /// WebDAV endpoint
    pub webdav_url: String,
    
    /// User storage quota (bytes)
    pub quota_total: u64,
    
    /// Used storage (bytes)
    pub quota_used: u64,
    
    /// Whether the server supports delta sync
    pub supports_delta_sync: bool,
    
    /// Whether the server supports chunked uploads
    pub supports_chunked_upload: bool,
}

impl ServerInfo {
    /// Get available storage in bytes
    pub fn quota_available(&self) -> u64 {
        self.quota_total.saturating_sub(self.quota_used)
    }
    
    /// Get quota usage percentage
    pub fn quota_percent(&self) -> f32 {
        if self.quota_total == 0 {
            return 0.0;
        }
        (self.quota_used as f64 / self.quota_total as f64 * 100.0) as f32
    }
}

/// Authenticated session
#[frb]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuthSession {
    /// User ID
    pub user_id: String,
    
    /// Username
    pub username: String,
    
    /// Access token
    pub access_token: String,
    
    /// Refresh token
    pub refresh_token: Option<String>,
    
    /// Token expiration time
    pub expires_at: Option<DateTime<Utc>>,
    
    /// Server info
    pub server_info: ServerInfo,
    
    /// Session creation time
    pub created_at: DateTime<Utc>,
}

impl AuthSession {
    /// Check if session is expired
    pub fn is_expired(&self) -> bool {
        match self.expires_at {
            Some(expires) => Utc::now() >= expires,
            None => false, // No expiration set
        }
    }
    
    /// Check if session needs refresh (expires within 5 minutes)
    pub fn needs_refresh(&self) -> bool {
        match self.expires_at {
            Some(expires) => {
                let buffer = chrono::Duration::minutes(5);
                Utc::now() >= (expires - buffer)
            }
            None => false,
        }
    }
}

/// Authentication error types
#[derive(Debug, Clone, thiserror::Error)]
pub enum AuthError {
    #[error("Invalid credentials")]
    InvalidCredentials,
    
    #[error("Server unreachable: {0}")]
    ServerUnreachable(String),
    
    #[error("Session expired")]
    SessionExpired,
    
    #[error("Token refresh failed: {0}")]
    RefreshFailed(String),
    
    #[error("Network error: {0}")]
    NetworkError(String),
    
    #[error("Storage error: {0}")]
    StorageError(String),
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_credentials_validation() {
        let valid = AuthCredentials {
            server_url: "https://cloud.example.com".to_string(),
            username: "user".to_string(),
            password: "pass".to_string(),
        };
        assert!(valid.validate().is_ok());
        
        let invalid = AuthCredentials {
            server_url: "not-a-url".to_string(),
            username: "user".to_string(),
            password: "pass".to_string(),
        };
        assert!(invalid.validate().is_err());
    }
    
    #[test]
    fn test_webdav_url() {
        let creds = AuthCredentials {
            server_url: "https://cloud.example.com".to_string(),
            username: "john".to_string(),
            password: "pass".to_string(),
        };
        
        assert_eq!(creds.webdav_url(), "https://cloud.example.com/dav/files/john");
    }
    
    #[test]
    fn test_quota_calculations() {
        let info = ServerInfo {
            url: "https://cloud.example.com".to_string(),
            version: "1.0".to_string(),
            name: "OxiCloud".to_string(),
            webdav_url: "https://cloud.example.com/dav".to_string(),
            quota_total: 10 * 1024 * 1024 * 1024, // 10GB
            quota_used: 3 * 1024 * 1024 * 1024,   // 3GB
            supports_delta_sync: true,
            supports_chunked_upload: true,
        };
        
        assert_eq!(info.quota_available(), 7 * 1024 * 1024 * 1024);
        assert!((info.quota_percent() - 30.0).abs() < 0.1);
    }
}
