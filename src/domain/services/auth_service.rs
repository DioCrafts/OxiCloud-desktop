use async_trait::async_trait;
use std::sync::Arc;

use crate::domain::entities::user::{User, UserResult};
use crate::domain::repositories::auth_repository::AuthRepository;

#[async_trait]
pub trait AuthService: Send + Sync + 'static {
    async fn login(&self, server_url: &str, username: &str, password: &str) -> UserResult<User>;
    async fn logout(&self) -> UserResult<()>;
    async fn refresh_token(&self) -> UserResult<()>;
    async fn get_current_user(&self) -> UserResult<Option<User>>;
    async fn is_authenticated(&self) -> bool;
    async fn get_storage_usage(&self) -> UserResult<(i64, i64)>; // (used, quota)
}

pub struct AuthServiceImpl {
    auth_repository: Arc<dyn AuthRepository>,
}

impl AuthServiceImpl {
    pub fn new(auth_repository: Arc<dyn AuthRepository>) -> Self {
        Self { auth_repository }
    }
}

#[async_trait]
impl AuthService for AuthServiceImpl {
    async fn login(&self, server_url: &str, username: &str, password: &str) -> UserResult<User> {
        let user = self.auth_repository.login(server_url, username, password).await?;
        self.auth_repository.save_user(&user).await?;
        Ok(user)
    }
    
    async fn logout(&self) -> UserResult<()> {
        if let Some(user) = self.auth_repository.get_current_user().await? {
            self.auth_repository.logout(&user).await?;
        }
        self.auth_repository.clear_saved_user().await
    }
    
    async fn refresh_token(&self) -> UserResult<()> {
        if let Some(mut user) = self.auth_repository.get_current_user().await? {
            let (access_token, refresh_token) = self.auth_repository.refresh_token(&user).await?;
            user.set_tokens(access_token, refresh_token);
            self.auth_repository.save_user(&user).await?;
        }
        Ok(())
    }
    
    async fn get_current_user(&self) -> UserResult<Option<User>> {
        self.auth_repository.get_current_user().await
    }
    
    async fn is_authenticated(&self) -> bool {
        match self.auth_repository.get_current_user().await {
            Ok(Some(user)) => user.is_authenticated(),
            _ => false,
        }
    }
    
    async fn get_storage_usage(&self) -> UserResult<(i64, i64)> {
        if let Some(user) = self.auth_repository.get_current_user().await? {
            let used = self.auth_repository.get_storage_usage(&user).await?;
            let quota = self.auth_repository.get_storage_quota(&user).await?;
            Ok((used, quota))
        } else {
            Ok((0, 0))
        }
    }
}
