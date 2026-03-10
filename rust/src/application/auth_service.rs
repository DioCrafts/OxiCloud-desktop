//! # Auth Service
//!
//! Authentication service for managing user sessions.

use chrono::Utc;
use std::sync::Arc;
use tokio::sync::RwLock;

use crate::api::AuthResult;
use crate::domain::entities::{AuthCredentials, AuthError, AuthSession, ServerInfo};
use crate::domain::ports::StoragePort;

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
        credentials
            .validate()
            .map_err(|_e| AuthError::InvalidCredentials)?;

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

        let login_response: LoginResponse = response
            .json()
            .await
            .map_err(|e| AuthError::NetworkError(format!("Invalid response: {}", e)))?;

        let user_id = login_response.user.id.clone();
        let username = login_response.user.username.clone();
        let quota_total = login_response.user.storage_quota_bytes;
        let quota_used = login_response.user.storage_used_bytes;

        // Compute expires_at from expires_in (seconds from now)
        let expires_at = login_response
            .expires_in
            .map(|secs| Utc::now() + chrono::Duration::seconds(secs));

        // Get server version info
        let server_info = self
            .fetch_server_info(
                &credentials.server_url,
                &login_response.access_token,
                quota_total,
                quota_used,
            )
            .await?;

        // Create session
        let session = AuthSession {
            user_id: user_id.clone(),
            username: username.clone(),
            access_token: login_response.access_token.clone(),
            refresh_token: login_response.refresh_token,
            expires_at,
            server_info: server_info.clone(),
            created_at: Utc::now(),
        };

        // Save session
        self.storage
            .save_session(&session)
            .await
            .map_err(|e| AuthError::StorageError(e.to_string()))?;

        *self.session.write().await = Some(session);

        Ok(AuthResult {
            success: true,
            user_id,
            username,
            server_info,
            access_token: login_response.access_token,
        })
    }

    /// Logout
    pub async fn logout(&self) {
        // Try to call server logout endpoint
        if let Some(session) = self.session.read().await.as_ref() {
            let client = reqwest::Client::new();
            client
                .post(format!("{}/api/auth/logout", session.server_info.url))
                .header("Authorization", format!("Bearer {}", session.access_token))
                .send()
                .await
                .ok();
        }

        self.storage.clear_session().await.ok();
        *self.session.write().await = None;

        tracing::info!("User logged out");
    }

    /// Check if user is logged in
    pub async fn is_logged_in(&self) -> bool {
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
        self.session
            .read()
            .await
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
        let refresh_token = session
            .refresh_token
            .as_ref()
            .ok_or_else(|| AuthError::RefreshFailed("No refresh token".to_string()))?;

        let client = reqwest::Client::new();

        // Server expects refresh_token in JSON body (not in Authorization header)
        let response = client
            .post(format!("{}/api/auth/refresh", session.server_info.url))
            .json(&serde_json::json!({
                "refresh_token": refresh_token,
            }))
            .send()
            .await
            .map_err(|e| AuthError::NetworkError(e.to_string()))?;

        if !response.status().is_success() {
            return Err(AuthError::RefreshFailed(
                "Refresh request failed".to_string(),
            ));
        }

        let refresh_response: RefreshResponse = response
            .json()
            .await
            .map_err(|e| AuthError::NetworkError(format!("Invalid response: {}", e)))?;

        let mut updated_session = session.clone();
        updated_session.access_token = refresh_response.access_token;
        if let Some(new_refresh) = refresh_response.refresh_token {
            updated_session.refresh_token = Some(new_refresh);
        }
        updated_session.expires_at = refresh_response
            .expires_in
            .map(|secs| Utc::now() + chrono::Duration::seconds(secs));

        self.storage
            .save_session(&updated_session)
            .await
            .map_err(|e| AuthError::StorageError(e.to_string()))?;

        *self.session.write().await = Some(updated_session);

        tracing::info!("Token refreshed successfully");
        Ok(())
    }

    /// Fetch server info by combining /api/version + quota from login response
    async fn fetch_server_info(
        &self,
        server_url: &str,
        token: &str,
        quota_total: u64,
        quota_used: u64,
    ) -> Result<ServerInfo, AuthError> {
        let client = reqwest::Client::new();

        // Get server version from /api/version (public endpoint)
        let version_response = client
            .get(format!("{}/api/version", server_url))
            .send()
            .await;

        let (version, name) = match version_response {
            Ok(resp) if resp.status().is_success() => {
                let info: VersionResponse = resp.json().await.unwrap_or(VersionResponse {
                    name: "OxiCloud".to_string(),
                    version: "unknown".to_string(),
                });
                (info.version, info.name)
            }
            _ => ("unknown".to_string(), "OxiCloud".to_string()),
        };

        // Check server capabilities via /api/uploads (HEAD) for chunked upload support
        let supports_chunked = client
            .head(format!("{}/api/uploads", server_url))
            .header("Authorization", format!("Bearer {}", token))
            .send()
            .await
            .map(|r| r.status() != reqwest::StatusCode::NOT_FOUND)
            .unwrap_or(true);

        Ok(ServerInfo {
            url: server_url.to_string(),
            version,
            name,
            webdav_url: format!("{}/webdav", server_url),
            quota_total,
            quota_used,
            supports_delta_sync: false,
            supports_chunked_upload: supports_chunked,
        })
    }
}

// ============================================================================
// API response types matching OxiCloud server format
// ============================================================================

/// User info in login response
#[derive(serde::Deserialize)]
#[allow(dead_code)]
struct LoginUserDto {
    id: String,
    username: String,
    #[serde(default)]
    email: String,
    #[serde(default)]
    role: String,
    #[serde(default)]
    storage_quota_bytes: u64,
    #[serde(default)]
    storage_used_bytes: u64,
}

/// Login response from POST /api/auth/login
#[derive(serde::Deserialize)]
#[allow(dead_code)]
struct LoginResponse {
    user: LoginUserDto,
    access_token: String,
    refresh_token: Option<String>,
    #[serde(default)]
    token_type: String,
    expires_in: Option<i64>,
}

/// Refresh response from POST /api/auth/refresh
#[derive(serde::Deserialize)]
struct RefreshResponse {
    access_token: String,
    refresh_token: Option<String>,
    expires_in: Option<i64>,
}

/// Version response from GET /api/version
#[derive(serde::Deserialize)]
struct VersionResponse {
    name: String,
    version: String,
}
