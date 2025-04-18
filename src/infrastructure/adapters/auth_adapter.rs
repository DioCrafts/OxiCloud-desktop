use async_trait::async_trait;
use reqwest::{Client, StatusCode};
use std::sync::Arc;
use serde::{Serialize, Deserialize};
use tokio::sync::Mutex;
use keyring::Entry as Keyring;

use crate::domain::entities::user::{User, UserRole, UserResult, UserError};
use crate::domain::repositories::auth_repository::AuthRepository;
use crate::application::dtos::user_dto::UserDto;

#[derive(Serialize)]
struct LoginRequest {
    username: String,
    password: String,
}

#[derive(Deserialize)]
struct LoginResponse {
    access_token: String,
    refresh_token: String,
    user: UserDto,
}

#[derive(Serialize)]
struct RefreshTokenRequest {
    refresh_token: String,
}

#[derive(Deserialize)]
struct RefreshTokenResponse {
    access_token: String,
    refresh_token: String,
}

#[derive(Deserialize)]
struct ErrorResponse {
    message: String,
}

const SERVICE_NAME: &str = "OxiCloud";
const USER_KEY: &str = "current_user";

pub struct AuthHttpAdapter {
    client: Client,
    current_user: Arc<Mutex<Option<User>>>,
}

impl AuthHttpAdapter {
    pub fn new() -> Self {
        Self {
            client: Client::new(),
            current_user: Arc::new(Mutex::new(None)),
        }
    }

    async fn load_user_from_secure_storage(&self) -> UserResult<Option<User>> {
        let keyring = Keyring::new(SERVICE_NAME, USER_KEY).map_err(|e| {
            UserError::AuthenticationError(format!("Failed to access secure storage: {}", e))
        })?;

        match keyring.get_password() {
            Ok(user_json) => {
                let user: User = serde_json::from_str(&user_json).map_err(|e| {
                    UserError::AuthenticationError(format!("Failed to parse stored user: {}", e))
                })?;
                Ok(Some(user))
            }
            Err(_) => Ok(None), // No user stored
        }
    }

    async fn save_user_to_secure_storage(&self, user: &User) -> UserResult<()> {
        let user_json = serde_json::to_string(user).map_err(|e| {
            UserError::AuthenticationError(format!("Failed to serialize user: {}", e))
        })?;

        let keyring = Keyring::new(SERVICE_NAME, USER_KEY).map_err(|e| {
            UserError::AuthenticationError(format!("Failed to access secure storage: {}", e))
        })?;

        keyring.set_password(&user_json).map_err(|e| {
            UserError::AuthenticationError(format!("Failed to save user to secure storage: {}", e))
        })?;

        Ok(())
    }

    async fn delete_user_from_secure_storage(&self) -> UserResult<()> {
        let keyring = Keyring::new(SERVICE_NAME, USER_KEY).map_err(|e| {
            UserError::AuthenticationError(format!("Failed to access secure storage: {}", e))
        })?;

        // If there's no password, that's fine - just ignore the error
        let _ = keyring.delete_password();
        
        Ok(())
    }

    fn parse_role(role_str: &str) -> UserRole {
        match role_str.to_lowercase().as_str() {
            "admin" => UserRole::Admin,
            _ => UserRole::User,
        }
    }
}

#[async_trait]
impl AuthRepository for AuthHttpAdapter {
    async fn login(&self, server_url: &str, username: &str, password: &str) -> UserResult<User> {
        let api_url = format!("{}/api/auth/login", server_url.trim_end_matches('/'));

        let request_body = LoginRequest {
            username: username.to_string(),
            password: password.to_string(),
        };

        let response = self.client
            .post(&api_url)
            .json(&request_body)
            .send()
            .await
            .map_err(|e| UserError::AuthenticationError(format!("Network error: {}", e)))?;

        if response.status() != StatusCode::OK {
            let status = response.status();
            let error_message = match response.json::<ErrorResponse>().await {
                Ok(error) => error.message,
                Err(_) => format!("Server error: {}", status),
            };
            return Err(UserError::AuthenticationError(error_message));
        }

        let login_response = response
            .json::<LoginResponse>()
            .await
            .map_err(|e| UserError::AuthenticationError(format!("Failed to parse response: {}", e)))?;

        let user_dto = login_response.user;
        let mut user = User::new(
            user_dto.id,
            user_dto.username,
            user_dto.email,
            Self::parse_role(&user_dto.role),
            user_dto.storage_quota_bytes,
            user_dto.storage_used_bytes,
            server_url.to_string(),
        );

        user.set_tokens(
            login_response.access_token,
            login_response.refresh_token,
        );

        // Cache the user
        let mut current_user = self.current_user.lock().await;
        *current_user = Some(user.clone());
        
        // Store user in secure storage
        self.save_user_to_secure_storage(&user).await?;

        Ok(user)
    }

    async fn logout(&self, user: &User) -> UserResult<()> {
        if let Some(token) = &user.access_token {
            let api_url = format!("{}/api/auth/logout", user.server_url.trim_end_matches('/'));
            
            // Best effort to logout from server, but don't fail if server is unreachable
            let _ = self.client
                .post(&api_url)
                .header("Authorization", format!("Bearer {}", token))
                .send()
                .await;
        }
        
        // Clear local cache
        let mut current_user = self.current_user.lock().await;
        *current_user = None;
        
        // Remove from secure storage
        self.delete_user_from_secure_storage().await
    }

    async fn refresh_token(&self, user: &User) -> UserResult<(String, String)> {
        let refresh_token = user.refresh_token.clone().ok_or_else(|| 
            UserError::AuthenticationError("No refresh token available".to_string())
        )?;

        let api_url = format!("{}/api/auth/refresh", user.server_url.trim_end_matches('/'));

        let request_body = RefreshTokenRequest {
            refresh_token,
        };

        let response = self.client
            .post(&api_url)
            .json(&request_body)
            .send()
            .await
            .map_err(|e| UserError::AuthenticationError(format!("Network error: {}", e)))?;

        if response.status() != StatusCode::OK {
            let status = response.status();
            let error_message = match response.json::<ErrorResponse>().await {
                Ok(error) => error.message,
                Err(_) => format!("Server error: {}", status),
            };
            return Err(UserError::AuthenticationError(error_message));
        }

        let refresh_response = response
            .json::<RefreshTokenResponse>()
            .await
            .map_err(|e| UserError::AuthenticationError(format!("Failed to parse response: {}", e)))?;

        Ok((refresh_response.access_token, refresh_response.refresh_token))
    }

    async fn get_current_user(&self) -> UserResult<Option<User>> {
        // First check in-memory cache
        let current_user = self.current_user.lock().await;
        if let Some(user) = current_user.clone() {
            return Ok(Some(user));
        }
        
        // If not in memory, try to load from secure storage
        drop(current_user); // Release the lock before calling another async function
        
        if let Some(user) = self.load_user_from_secure_storage().await? {
            // Update in-memory cache
            let mut current_user = self.current_user.lock().await;
            *current_user = Some(user.clone());
            return Ok(Some(user));
        }
        
        Ok(None)
    }

    async fn save_user(&self, user: &User) -> UserResult<()> {
        // Update in-memory cache
        let mut current_user = self.current_user.lock().await;
        *current_user = Some(user.clone());
        
        // Store in secure storage
        drop(current_user); // Release the lock
        self.save_user_to_secure_storage(user).await
    }

    async fn clear_saved_user(&self) -> UserResult<()> {
        // Clear in-memory cache
        let mut current_user = self.current_user.lock().await;
        *current_user = None;
        
        // Clear from secure storage
        drop(current_user);
        self.delete_user_from_secure_storage().await
    }

    async fn get_storage_usage(&self, user: &User) -> UserResult<i64> {
        let token = user.access_token.clone().ok_or_else(|| 
            UserError::AuthenticationError("No access token available".to_string())
        )?;
        
        let api_url = format!("{}/api/user/storage", user.server_url.trim_end_matches('/'));
        
        let response = self.client
            .get(&api_url)
            .header("Authorization", format!("Bearer {}", token))
            .send()
            .await
            .map_err(|e| UserError::AuthenticationError(format!("Network error: {}", e)))?;

        if response.status() != StatusCode::OK {
            return Err(UserError::AuthenticationError("Failed to get storage info".to_string()));
        }

        #[derive(Deserialize)]
        struct StorageResponse {
            used_bytes: i64,
        }

        let storage_info = response
            .json::<StorageResponse>()
            .await
            .map_err(|e| UserError::AuthenticationError(format!("Failed to parse response: {}", e)))?;

        Ok(storage_info.used_bytes)
    }

    async fn get_storage_quota(&self, user: &User) -> UserResult<i64> {
        let token = user.access_token.clone().ok_or_else(|| 
            UserError::AuthenticationError("No access token available".to_string())
        )?;
        
        let api_url = format!("{}/api/user/quota", user.server_url.trim_end_matches('/'));
        
        let response = self.client
            .get(&api_url)
            .header("Authorization", format!("Bearer {}", token))
            .send()
            .await
            .map_err(|e| UserError::AuthenticationError(format!("Network error: {}", e)))?;

        if response.status() != StatusCode::OK {
            return Err(UserError::AuthenticationError("Failed to get quota info".to_string()));
        }

        #[derive(Deserialize)]
        struct QuotaResponse {
            quota_bytes: i64,
        }

        let quota_info = response
            .json::<QuotaResponse>()
            .await
            .map_err(|e| UserError::AuthenticationError(format!("Failed to parse response: {}", e)))?;

        Ok(quota_info.quota_bytes)
    }
}

pub struct AuthAdapterFactory {}

impl AuthAdapterFactory {
    pub fn new() -> Self {
        Self {}
    }
}

impl crate::domain::repositories::auth_repository::AuthRepositoryFactory for AuthAdapterFactory {
    fn create_repository(&self) -> Arc<dyn AuthRepository> {
        Arc::new(AuthHttpAdapter::new())
    }
}