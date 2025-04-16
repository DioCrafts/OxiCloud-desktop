use async_trait::async_trait;
use std::sync::Arc;

use crate::application::dtos::user_dto::UserDto;
use crate::application::ports::auth_port::{AuthPort, AuthResult};
use crate::domain::entities::user::{User, UserRole, UserError};
use crate::domain::services::auth_service::AuthService;

pub struct AuthApplicationService {
    auth_service: Arc<dyn AuthService>,
}

impl AuthApplicationService {
    pub fn new(auth_service: Arc<dyn AuthService>) -> Self {
        Self { auth_service }
    }

    fn map_user_to_dto(user: &User) -> UserDto {
        UserDto::new(
            user.id.clone(),
            user.username.clone(),
            user.email.clone(),
            match user.role {
                UserRole::Admin => "admin".to_string(),
                UserRole::User => "user".to_string(),
            },
            user.storage_quota_bytes,
            user.storage_used_bytes,
            user.server_url.clone(),
            user.last_login_at,
        )
    }
}

#[async_trait]
impl AuthPort for AuthApplicationService {
    async fn login(&self, server_url: &str, username: &str, password: &str) -> AuthResult<UserDto> {
        let user = self.auth_service.login(server_url, username, password).await?;
        Ok(Self::map_user_to_dto(&user))
    }

    async fn logout(&self) -> AuthResult<()> {
        self.auth_service.logout().await
    }

    async fn get_current_user(&self) -> AuthResult<Option<UserDto>> {
        let user_option = self.auth_service.get_current_user().await?;
        
        match user_option {
            Some(user) => Ok(Some(Self::map_user_to_dto(&user))),
            None => Ok(None),
        }
    }

    async fn is_authenticated(&self) -> bool {
        self.auth_service.is_authenticated().await
    }

    async fn get_storage_info(&self) -> AuthResult<(i64, i64, f64)> {
        let (used, quota) = self.auth_service.get_storage_usage().await?;
        
        let percentage = if quota <= 0 {
            0.0
        } else {
            (used as f64 / quota as f64) * 100.0
        };
        
        Ok((used, quota, percentage))
    }
}