use std::sync::Arc;
use crate::domain::entities::config::{ConfigRepository, ApplicationConfig};

/// Factory trait for creating config repositories
pub trait ConfigRepositoryFactory {
    /// Create a new repository instance
    fn create_repository(&self) -> Arc<dyn ConfigRepository>;
}