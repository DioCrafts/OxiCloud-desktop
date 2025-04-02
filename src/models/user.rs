use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct User {
    pub id: String,
    pub username: String,
    pub display_name: String,
    pub email: String,
    pub quota: UserQuota,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserQuota {
    pub used: u64,
    pub total: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Credentials {
    pub username: String,
    pub password: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuthToken {
    pub token: String,
    pub expiration: Option<i64>,
}

impl User {
    pub fn quota_percentage(&self) -> f32 {
        if self.quota.total == 0 {
            return 0.0;
        }
        
        (self.quota.used as f32 / self.quota.total as f32) * 100.0
    }
    
    pub fn quota_color(&self) -> &'static str {
        let percentage = self.quota_percentage();
        
        if percentage < 70.0 {
            "#4caf50" // Verde
        } else if percentage < 90.0 {
            "#ff9800" // Naranja
        } else {
            "#f44336" // Rojo
        }
    }
}