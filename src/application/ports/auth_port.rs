use async_trait::async_trait;
use std::sync::Arc;

use crate::application::dtos::user_dto::UserDto;
use crate::domain::entities::user::UserError;

pub type AuthResult<T> = Result<T, UserError>;

#[async_trait]
pub trait AuthPort: Send + Sync + 'static {
    async fn login(&self, server_url: &str, username: &str, password: &str) -> AuthResult<UserDto>;
    async fn logout(&self) -> AuthResult<()>;
    async fn get_current_user(&self) -> AuthResult<Option<UserDto>>;
    async fn is_authenticated(&self) -> bool;
    async fn get_storage_info(&self) -> AuthResult<(i64, i64, f64)>; // (used, quota, percentage)
}

#[async_trait]
pub trait AuthServerPort: Send + Sync + 'static {
    async fn authenticate(&self, server_url: &str, username: &str, password: &str) -> AuthResult<(String, String)>;
    async fn refresh_token(&self, refresh_token: &str) -> AuthResult<(String, String)>;
    async fn revoke_token(&self, access_token: &str) -> AuthResult<()>;
    async fn get_user_info(&self, access_token: &str) -> AuthResult<UserDto>;
}
