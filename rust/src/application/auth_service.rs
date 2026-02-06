//! # Auth Service
//!
//! Authentication service for managing user sessions.

use std::sync::Arc;
use tokio::sync::RwLock;
use chrono::Utc;

use crate::domain::entities::{AuthCredentials, AuthSession, ServerInfo, AuthError};
use crate::domain::ports::{StoragePort, AuthPort};
use crate::api::AuthResult;

/// Authentication service
pub struct AuthService {
    storage: Arc<dyn StoragePort>,
    session: Arc<RwLock<Option<AuthSession>>>,
}

impl AuthService {
    /// Create a new auth service
    pub fn new(storage: Arc<dyn StoragePort>) -> Self {
        Self {
            storage,
            session: Arc::new(RwLock::new(None)),
        }
    }
    
    /// Login with credentials
    pub async fn login(&self, credentials: AuthCredentials) -> Result<AuthResult, AuthError> {
        // Validate credentials
        credentials.validate()
            .map_err(|e| AuthError::InvalidCredentials)?;
        
        // Make login request to server
        let client = reqwest::Client::new();
        
        let response = client
            .post(format!("{}/api/auth/login", credentials.server_url))
            .json(&serde_json::json!({
                "username": credentials.username,
                "password": credentials.password,
            }))
            .send()
            .await
            .map_err(|e| AuthError::NetworkError(e.to_string()))?;
        
        if !response.status().is_success() {
            return Err(AuthError::InvalidCredentials);
        }
        
        let login_response: LoginResponse = response.json().await
            .map_err(|e| AuthError::NetworkError(format!("Invalid response: {}", e)))?;
        
        // Get server info
        let server_info = self.fetch_server_info(&credentials.server_url, &login_response.access_token).await?;
        
        // Create session
        let session = AuthSession {
            user_id: login_response.user_id.clone(),
            username: credentials.username.clone(),
            access_token: login_response.access_token.clone(),
            refresh_token: login_response.refresh_token,
            expires_at: login_response.expires_at.map(|ts| {
                chrono::DateTime::from_timestamp(ts, 0)
                    .unwrap_or_else(|| Utc::now())
            }),
            server_info: server_info.clone(),
            created_at: Utc::now(),
        };
        
        // Save session
        self.storage.save_session(&session).await
            .map_err(|e| AuthError::StorageError(e.to_string()))?;
        
        *self.session.write().await = Some(session);
        
        Ok(AuthResult {
            success: true,
            user_id: login_response.user_id,
            username: credentials.username,
            server_info,
            access_token: login_response.access_token,
        })
    }
    
    /// Logout
    pub async fn logout(&self) {
        // Clear stored session
        self.storage.clear_session().await.ok();
        *self.session.write().await = None;
        
        tracing::info!("User logged out");
    }
    
    /// Check if user is logged in
    pub async fn is_logged_in(&self) -> bool {
        // Try to load session from storage if not in memory
        if self.session.read().await.is_none() {
            if let Ok(Some(session)) = self.storage.load_session().await {
                if !session.is_expired() {
                    *self.session.write().await = Some(session);
                    return true;
                }
            }
            return false;
        }
        
        let session = self.session.read().await;
        session.as_ref().map(|s| !s.is_expired()).unwrap_or(false)
    }
    
    /// Get current server info
    pub async fn get_server_info(&self) -> Option<ServerInfo> {
        self.session.read().await
            .as_ref()
            .map(|s| s.server_info.clone())
    }
    
    /// Get current session
    pub async fn get_session(&self) -> Option<AuthSession> {
        self.session.read().await.clone()
    }
    
    /// Refresh token if needed
    pub async fn refresh_if_needed(&self) -> Result<(), AuthError> {
        let session = self.session.read().await.clone();
        
        if let Some(session) = session {
            if session.needs_refresh() {
                self.refresh_token(&session).await?;
            }
        }
        
        Ok(())
    }
    
    /// Refresh the access token
    async fn refresh_token(&self, session: &AuthSession) -> Result<(), AuthError> {
        let refresh_token = session.refresh_token.as_ref()
            .ok_or_else(|| AuthError::RefreshFailed("No refresh token".to_string()))?;
        
        let client = reqwest::Client::new();
        
        let response = client
            .post(format!("{}/api/auth/refresh", session.server_info.url))
            .header("Authorization", format!("Bearer {}", refresh_token))
            .send()
            .await
            .map_err(|e| AuthError::NetworkError(e.to_string()))?;
        
        if !response.status().is_success() {
            return Err(AuthError::RefreshFailed("Refresh request failed".to_string()));
        }
        
        let refresh_response: RefreshResponse = response.json().await
            .map_err(|e| AuthError::NetworkError(format!("Invalid response: {}", e)))?;
        
        // Update session
        let mut updated_session = session.clone();
        updated_session.access_token = refresh_response.access_token;
        if let Some(new_refresh) = refresh_response.refresh_token {
            updated_session.refresh_token = Some(new_refresh);
        }
        updated_session.expires_at = refresh_response.expires_at.map(|ts| {
            chrono::DateTime::from_timestamp(ts, 0)
                .unwrap_or_else(|| Utc::now())
        });
        
        // Save updated session
        self.storage.save_session(&updated_session).await
            .map_err(|e| AuthError::StorageError(e.to_string()))?;
        
        *self.session.write().await = Some(updated_session);
        
        tracing::info!("Token refreshed successfully");
        Ok(())
    }
    
    /// Fetch server info
    async fn fetch_server_info(&self, server_url: &str, token: &str) -> Result<ServerInfo, AuthError> {
        let client = reqwest::Client::new();
        
        let response = client
            .get(format!("{}/api/server/info", server_url))
            .header("Authorization", format!("Bearer {}", token))
            .send()
            .await
            .map_err(|e| AuthError::NetworkError(e.to_string()))?;
        
        if !response.status().is_success() {
            // Return default info if endpoint doesn't exist
            return Ok(ServerInfo {
                url: server_url.to_string(),
                version: "unknown".to_string(),
                name: "OxiCloud".to_string(),
                webdav_url: format!("{}/dav", server_url),
                quota_total: 10 * 1024 * 1024 * 1024, // 10GB default
                quota_used: 0,
                supports_delta_sync: false,
                supports_chunked_upload: true,
            });
        }
        
        let info: ServerInfoResponse = response.json().await
            .map_err(|e| AuthError::NetworkError(format!("Invalid response: {}", e)))?;
        
        Ok(ServerInfo {
            url: server_url.to_string(),
            version: info.version,
            name: info.name,
            webdav_url: info.webdav_url.unwrap_or_else(|| format!("{}/dav", server_url)),
            quota_total: info.quota_total,
            quota_used: info.quota_used,
            supports_delta_sync: info.supports_delta_sync.unwrap_or(false),
            supports_chunked_upload: info.supports_chunked_upload.unwrap_or(true),
        })
    }
}

// API response types

#[derive(serde::Deserialize)]
struct LoginResponse {
    user_id: String,
    access_token: String,
    refresh_token: Option<String>,
    expires_at: Option<i64>,
}

#[derive(serde::Deserialize)]
struct RefreshResponse {
    access_token: String,
    refresh_token: Option<String>,
    expires_at: Option<i64>,
}

#[derive(serde::Deserialize)]
struct ServerInfoResponse {
    version: String,
    name: String,
    webdav_url: Option<String>,
    quota_total: u64,
    quota_used: u64,
    supports_delta_sync: Option<bool>,
    supports_chunked_upload: Option<bool>,
}
