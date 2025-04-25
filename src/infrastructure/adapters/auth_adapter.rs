use std::sync::Arc;

use anyhow::{Result, anyhow};
use log::{info, debug, error};
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc, Duration};

use crate::domain::models::user::{AuthToken, User};
use crate::infrastructure::adapters::http_client::HttpClient;

/// Request for login
#[derive(Serialize)]
struct LoginRequest {
    username: String,
    password: String,
}

/// Response from login
#[derive(Deserialize)]
struct LoginResponse {
    access_token: String,
    refresh_token: String,
    expires_in: i64,
    token_type: String,
    user: UserResponse,
}

/// User data in response
#[derive(Deserialize)]
struct UserResponse {
    id: String,
    username: String,
    display_name: String,
    email: String,
    storage_used: u64,
    storage_quota: u64,
}

/// Request for refreshing token
#[derive(Serialize)]
struct RefreshRequest {
    refresh_token: String,
}

/// Adapter for authentication with OxiCloud server
pub struct AuthAdapter {
    /// HTTP client for API requests
    http_client: Arc<HttpClient>,
}

impl AuthAdapter {
    /// Create a new authentication adapter
    pub fn new(http_client: Arc<HttpClient>) -> Self {
        Self {
            http_client,
        }
    }
    
    /// Convert login response to domain token
    fn create_token_from_response(
        access_token: String,
        refresh_token: String,
        expires_in: i64,
        token_type: String
    ) -> AuthToken {
        let expires_at = Utc::now() + Duration::seconds(expires_in);
        
        AuthToken {
            access_token,
            refresh_token,
            expires_at,
            token_type,
        }
    }
    
    /// Convert user response to domain model
    fn convert_to_domain_user(response: UserResponse) -> User {
        User {
            id: response.id,
            username: response.username,
            display_name: response.display_name,
            email: response.email,
            created_at: Utc::now(), // Not provided in response
            storage_used: response.storage_used,
            storage_quota: response.storage_quota,
        }
    }
    
    /// Login to the server
    pub async fn login(&self, server_url: &str, username: &str, password: &str) -> Result<(AuthToken, User)> {
        debug!("Attempting login for user: {} to server: {}", username, server_url);
        
        // Update the base URL before login
        self.http_client.set_base_url(server_url);
        
        let request = LoginRequest {
            username: username.to_string(),
            password: password.to_string(),
        };
        
        let response: LoginResponse = self.http_client.post("/auth/login", &request).await?;
        
        // Convert the response to domain objects
        let token = AuthToken {
            access_token: response.access_token,
            refresh_token: response.refresh_token,
            expires_at: Utc::now() + Duration::seconds(response.expires_in),
            token_type: response.token_type,
        };
        
        let user = Self::convert_to_domain_user(response.user);
        
        // Update the HTTP client with the new token
        self.http_client.set_auth_token(token.clone());
        
        Ok((token, user))
    }
    
    /// Refresh the authentication token
    pub async fn refresh_token(&self, refresh_token: &str) -> Result<AuthToken> {
        debug!("Refreshing authentication token");
        
        let request = RefreshRequest {
            refresh_token: refresh_token.to_string(),
        };
        
        let response: LoginResponse = self.http_client.post("/auth/refresh", &request).await?;
        
        let token = Self::create_token_from_response(
            response.access_token,
            response.refresh_token,
            response.expires_in,
            response.token_type,
        );
        
        // Update the HTTP client with the new token
        self.http_client.set_auth_token(token.clone());
        
        Ok(token)
    }
    
    /// Logout from the server
    pub async fn logout(&self) -> Result<()> {
        debug!("Logging out");
        
        let response: () = self.http_client.post("/auth/logout", &()).await?;
        
        Ok(())
    }
    
    /// Get the current user profile
    pub async fn get_current_user(&self) -> Result<User> {
        debug!("Getting current user profile");
        
        let response: UserResponse = self.http_client.get("/users/me").await?;
        let user = Self::convert_to_domain_user(response);
        
        Ok(user)
    }
}