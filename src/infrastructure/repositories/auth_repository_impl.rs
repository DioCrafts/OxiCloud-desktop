use std::sync::Arc;

use anyhow::{Result, anyhow};
use async_trait::async_trait;
use keyring::Entry;
use log::{info, debug, error};

use crate::domain::models::user::{AuthToken, User};
use crate::domain::repositories::auth_repository::AuthRepository;
use crate::infrastructure::adapters::auth_adapter::AuthAdapter;

const TOKEN_SERVICE: &str = "OxiCloud";
const TOKEN_KEY: &str = "auth_token";

/// Implementation of AuthRepository using OxiCloud API
pub struct AuthRepositoryImpl {
    /// Authentication adapter
    auth_adapter: Arc<AuthAdapter>,
    
    /// Server URL for keyring
    server_url: String,
}

impl AuthRepositoryImpl {
    /// Create a new authentication repository
    pub fn new(auth_adapter: Arc<AuthAdapter>, server_url: &str) -> Self {
        Self {
            auth_adapter,
            server_url: server_url.to_string(),
        }
    }
    
    /// Get the keyring entry for storing tokens
    fn get_keyring_entry(&self, username: &str) -> Result<Entry> {
        let entry = Entry::new(
            &format!("{}-{}", TOKEN_SERVICE, self.server_url), 
            username
        )?;
        
        Ok(entry)
    }
}

#[async_trait]
impl AuthRepository for AuthRepositoryImpl {
    async fn login(&self, server_url: &str, username: &str, password: &str) -> Result<(AuthToken, User)> {
        debug!("Logging in to {} as {}", server_url, username);
        
        let (token, user) = self.auth_adapter.login(server_url, username, password).await?;
        
        // Store the token
        self.store_token(&token).await?;
        
        Ok((token, user))
    }
    
    async fn refresh_token(&self, refresh_token: &str) -> Result<AuthToken> {
        debug!("Refreshing token");
        
        let token = self.auth_adapter.refresh_token(refresh_token).await?;
        
        // Update the stored token
        self.store_token(&token).await?;
        
        Ok(token)
    }
    
    async fn logout(&self) -> Result<()> {
        debug!("Logging out");
        
        // Attempt to logout from the server
        let _ = self.auth_adapter.logout().await;
        
        // Clear the stored token
        self.clear_stored_token().await?;
        
        Ok(())
    }
    
    async fn get_current_user(&self) -> Result<User> {
        debug!("Getting current user");
        
        let user = self.auth_adapter.get_current_user().await?;
        
        Ok(user)
    }
    
    async fn store_token(&self, token: &AuthToken) -> Result<()> {
        // Get the username from an existing token or use a default
        let username = if let Ok(Some(existing_token)) = self.get_stored_token().await {
            // Use the old username
            "default_user".to_string()
        } else {
            "default_user".to_string()
        };
        
        // Serialize the token to JSON
        let token_json = serde_json::to_string(token)?;
        
        // Store in the keyring
        let entry = self.get_keyring_entry(&username)?;
        entry.set_password(&token_json)?;
        
        debug!("Token stored successfully");
        Ok(())
    }
    
    async fn get_stored_token(&self) -> Result<Option<AuthToken>> {
        // Try with a default username
        let username = "default_user";
        
        // Get from the keyring
        let entry = self.get_keyring_entry(username)?;
        
        match entry.get_password() {
            Ok(token_json) => {
                // Deserialize the token
                let token: AuthToken = serde_json::from_str(&token_json)?;
                Ok(Some(token))
            }
            Err(_) => {
                // No token found
                Ok(None)
            }
        }
    }
    
    async fn clear_stored_token(&self) -> Result<()> {
        // Try with a default username
        let username = "default_user";
        
        // Delete from the keyring
        let entry = self.get_keyring_entry(username)?;
        
        // Ignore errors if the token doesn't exist
        let _ = entry.delete_password();
        
        debug!("Token cleared successfully");
        Ok(())
    }
}