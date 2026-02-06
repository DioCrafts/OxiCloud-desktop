//! # Auth Port
//!
//! Port interface for authentication operations.

use async_trait::async_trait;
use crate::domain::entities::{AuthCredentials, AuthSession, ServerInfo, AuthError};

/// Result type for auth operations
pub type AuthResult<T> = Result<T, AuthError>;

/// Port interface for authentication
#[async_trait]
pub trait AuthPort: Send + Sync {
    /// Login with credentials
    async fn login(&self, credentials: AuthCredentials) -> AuthResult<AuthSession>;
    
    /// Refresh access token
    async fn refresh_token(&self, session: &AuthSession) -> AuthResult<AuthSession>;
    
    /// Logout (invalidate token on server)
    async fn logout(&self, session: &AuthSession) -> AuthResult<()>;
    
    /// Get server information
    async fn get_server_info(&self, server_url: &str) -> AuthResult<ServerInfo>;
    
    /// Validate token is still valid
    async fn validate_token(&self, session: &AuthSession) -> AuthResult<bool>;
    
    /// Store credentials securely (using system keychain)
    async fn store_credentials(&self, server_url: &str, username: &str, password: &str) -> AuthResult<()>;
    
    /// Retrieve stored credentials
    async fn get_stored_credentials(&self, server_url: &str) -> AuthResult<Option<(String, String)>>;
    
    /// Delete stored credentials
    async fn delete_stored_credentials(&self, server_url: &str) -> AuthResult<()>;
}
