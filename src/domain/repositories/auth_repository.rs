use anyhow::Result;
use async_trait::async_trait;

use crate::domain::models::user::{AuthToken, User};

/// Repository interface for authentication
#[async_trait]
pub trait AuthRepository: Send + Sync {
    /// Login to the server
    async fn login(&self, server_url: &str, username: &str, password: &str) -> Result<(AuthToken, User)>;
    
    /// Refresh the authentication token
    async fn refresh_token(&self, refresh_token: &str) -> Result<AuthToken>;
    
    /// Logout from the server
    async fn logout(&self) -> Result<()>;
    
    /// Get the current user profile
    async fn get_current_user(&self) -> Result<User>;
    
    /// Store the authentication token securely
    async fn store_token(&self, token: &AuthToken) -> Result<()>;
    
    /// Retrieve the stored authentication token
    async fn get_stored_token(&self) -> Result<Option<AuthToken>>;
    
    /// Clear the stored authentication token
    async fn clear_stored_token(&self) -> Result<()>;
}