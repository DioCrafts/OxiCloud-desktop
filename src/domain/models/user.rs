use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

/// Represents a user in the system
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct User {
    /// Unique identifier for the user
    pub id: String,
    
    /// Username for login
    pub username: String,
    
    /// Display name
    pub display_name: String,
    
    /// Email address
    pub email: String,
    
    /// When the user was created
    pub created_at: DateTime<Utc>,
    
    /// Used storage space in bytes
    pub storage_used: u64,
    
    /// Total storage quota in bytes
    pub storage_quota: u64,
}

impl User {
    /// Create a new user instance
    pub fn new(id: String, username: String, display_name: String, email: String) -> Self {
        Self {
            id,
            username,
            display_name,
            email,
            created_at: Utc::now(),
            storage_used: 0,
            storage_quota: 5_368_709_120, // 5GB default
        }
    }
    
    /// Calculate storage usage percentage
    pub fn storage_usage_percent(&self) -> f64 {
        if self.storage_quota == 0 {
            return 0.0;
        }
        
        (self.storage_used as f64 / self.storage_quota as f64) * 100.0
    }
}

/// Authentication token data
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuthToken {
    /// Access token for API requests
    pub access_token: String,
    
    /// Refresh token for getting new access tokens
    pub refresh_token: String,
    
    /// When the access token expires
    pub expires_at: DateTime<Utc>,
    
    /// Token type (usually "Bearer")
    pub token_type: String,
}

impl AuthToken {
    /// Check if the access token is expired
    pub fn is_expired(&self) -> bool {
        Utc::now() > self.expires_at
    }
    
    /// Format the authorization header value
    pub fn authorization_header(&self) -> String {
        format!("{} {}", self.token_type, self.access_token)
    }
}