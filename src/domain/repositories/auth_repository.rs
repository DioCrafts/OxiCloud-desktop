use async_trait::async_trait;
use std::sync::Arc;

use crate::domain::entities::user::{User, UserResult};

#[async_trait]
pub trait AuthRepository: Send + Sync + 'static {
    // Authentication operations
    async fn login(&self, server_url: &str, username: &str, password: &str) -> UserResult<User>;
    async fn logout(&self, user: &User) -> UserResult<()>;
    async fn refresh_token(&self, user: &User) -> UserResult<(String, String)>;
    
    // User profile operations
    async fn get_current_user(&self) -> UserResult<Option<User>>;
    async fn save_user(&self, user: &User) -> UserResult<()>;
    async fn clear_saved_user(&self) -> UserResult<()>;
    
    // User storage operations
    async fn get_storage_usage(&self, user: &User) -> UserResult<i64>;
    async fn get_storage_quota(&self, user: &User) -> UserResult<i64>;
}

pub trait AuthRepositoryFactory: Send + Sync + 'static {
    fn create_repository(&self) -> Arc<dyn AuthRepository>;
}
