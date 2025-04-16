use std::sync::Arc;

use crate::application::ports::auth_port::AuthPort;
use crate::application::ports::file_port::FilePort;
use crate::application::ports::sync_port::SyncPort;
use crate::application::ports::encryption_port::EncryptionPort;
use crate::application::ports::config_port::ConfigPort;
use crate::application::services::auth_service::AuthApplicationService;
use crate::application::services::file_service::FileApplicationService;
use crate::application::services::sync_service::SyncApplicationService;
use crate::application::services::encryption_service::EncryptionApplicationService;
use crate::application::services::config_service::ConfigApplicationService;
use crate::domain::repositories::auth_repository::AuthRepositoryFactory;
use crate::domain::repositories::file_repository::FileRepositoryFactory;
use crate::domain::repositories::sync_repository::SyncRepositoryFactory;
use crate::domain::repositories::encryption_repository::EncryptionRepository;
use crate::domain::repositories::config_repository::ConfigRepositoryFactory;
use crate::domain::services::auth_service::{AuthService, AuthServiceImpl};
use crate::domain::services::file_service::{FileService, FileServiceImpl};
use crate::domain::services::sync_service::{SyncService, SyncServiceImpl};
use crate::domain::services::encryption_service::EncryptionService;
use crate::domain::services::config_service::{ConfigService, ConfigServiceImpl};
use crate::infrastructure::adapters::auth_adapter::AuthAdapterFactory;
use crate::infrastructure::adapters::file_adapter::WebDAVAdapterFactory;
use crate::infrastructure::adapters::fs_adapter::FileSystemAdapterFactory;
use crate::infrastructure::adapters::sync_adapter::SyncSqliteAdapterFactory;
use crate::infrastructure::adapters::encryption_adapter::SqliteEncryptionRepository;
use crate::infrastructure::adapters::config_adapter::JsonConfigRepositoryFactory;
use crate::infrastructure::services::encryption_service_impl::EncryptionServiceImpl;
use crate::infrastructure::repositories::sqlite_repository::create_connection_pool;

/// Dependency injection container for the application.
/// This provides all services required by the UI layer.
pub struct ServiceProvider {
    auth_service: Arc<dyn AuthPort>,
    file_service: Arc<dyn FilePort>,
    sync_service: Arc<dyn SyncPort>,
    encryption_service: Arc<dyn EncryptionPort>,
    config_service: Arc<dyn ConfigPort>,
}

impl ServiceProvider {
    pub fn new() -> Self {
        // Create SQLite connection pool
        let db_pool = create_connection_pool("oxicloud.db").expect("Failed to create database pool");
        
        // Create the auth repository
        let auth_repository_factory = AuthAdapterFactory::new();
        let auth_repository = auth_repository_factory.create_repository();
        
        // Create the auth domain service
        let auth_domain_service: Arc<dyn AuthService> = Arc::new(AuthServiceImpl::new(auth_repository.clone()));
        
        // Create the auth application service
        let auth_application_service: Arc<dyn AuthPort> = Arc::new(AuthApplicationService::new(auth_domain_service));
        
        // Create the remote file repository (WebDAV)
        let remote_repository_factory = WebDAVAdapterFactory::new(auth_repository.clone());
        let remote_repository = remote_repository_factory.create_repository();
        
        // Create the local file repository
        let local_repository_factory = FileSystemAdapterFactory::new(auth_repository.clone());
        let local_repository = local_repository_factory.create_repository();
        
        // Create the sync repository
        let sync_repository_factory = SyncSqliteAdapterFactory::new(db_pool);
        let sync_repository = sync_repository_factory.create_repository();
        
        // Create the file domain service
        let file_domain_service: Arc<dyn FileService> = Arc::new(FileServiceImpl::new(remote_repository.clone()));
        
        // Create the file repository factory
        let file_repository_factory = crate::infrastructure::repositories::file_sqlite_repository::SqliteFileRepositoryFactory::new(db_pool.clone());
        let file_repository = file_repository_factory.create_repository();
        
        // Create the encryption repository
        let encryption_repository: Arc<dyn EncryptionRepository> = Arc::new(SqliteEncryptionRepository::new(db_pool.clone()));
        
        // Create the encryption domain service
        let encryption_domain_service: Arc<dyn EncryptionService> = Arc::new(EncryptionServiceImpl::new(encryption_repository));
        
        // Create the config repository
        let config_repository_factory = JsonConfigRepositoryFactory::new();
        let config_repository = config_repository_factory.create_repository();
        
        // Create the config domain service
        let config_domain_service: Arc<dyn ConfigService> = Arc::new(ConfigServiceImpl::new(config_repository));
        
        // Create the sync domain service
        let sync_domain_service: Arc<dyn SyncService> = Arc::new(SyncServiceImpl::new(
            sync_repository.clone(),
            local_repository.clone(),
            Some(encryption_domain_service.clone()),
        ));
        
        // Create the sync engine
        let sync_engine = Arc::new(crate::infrastructure::services::sync_engine::SyncEngine::new(
            local_repository.clone(),
            remote_repository.clone(),
            sync_repository.clone(),
            sync_domain_service.clone(),
        ));
        
        // Create the application services
        let file_application_service: Arc<dyn FilePort> = Arc::new(FileApplicationService::new(file_domain_service));
        let sync_application_service: Arc<dyn SyncPort> = Arc::new(SyncApplicationService::new(sync_domain_service));
        let encryption_application_service: Arc<dyn EncryptionPort> = Arc::new(EncryptionApplicationService::new(encryption_domain_service));
        let config_application_service: Arc<dyn ConfigPort> = Arc::new(ConfigApplicationService::new(config_domain_service));
        
        // Get the sync directory
        let config = config_domain_service.get_config().expect("Failed to get config");
        let sync_dir = match &config.sync.sync_folder {
            Some(dir) => dir.clone(),
            None => {
                // Use the default home directory + OxiCloud
                let home = dirs::home_dir().expect("Failed to get home directory");
                home.join("OxiCloud")
            }
        };
        
        // Create the sync directory if it doesn't exist
        std::fs::create_dir_all(&sync_dir).expect("Failed to create sync directory");
        
        // Create the file watcher
        let file_watcher = Arc::new(crate::infrastructure::services::file_watcher::FileWatcher::new(
            sync_dir.clone(),
            file_repository.clone(),
            sync_repository.clone(),
            sync_domain_service.clone(),
        ));
        
        // Start the sync engine and file watcher if enabled
        if config.sync.enabled {
            let sync_engine_clone = sync_engine.clone();
            tokio::spawn(async move {
                match sync_engine_clone.start().await {
                    Ok(_) => tracing::info!("Sync engine started successfully"),
                    Err(e) => tracing::error!("Failed to start sync engine: {:?}", e),
                }
            });
            
            let file_watcher_clone = file_watcher.clone();
            tokio::spawn(async move {
                match file_watcher_clone.start().await {
                    Ok(_) => tracing::info!("File watcher started successfully"),
                    Err(e) => tracing::error!("Failed to start file watcher: {:?}", e),
                }
            });
        }

        Self {
            auth_service: auth_application_service,
            file_service: file_application_service,
            sync_service: sync_application_service,
            encryption_service: encryption_application_service,
            config_service: config_application_service,
        }
    }
    
    pub fn get_auth_service(&self) -> Arc<dyn AuthPort> {
        self.auth_service.clone()
    }
    
    pub fn get_file_service(&self) -> Arc<dyn FilePort> {
        self.file_service.clone()
    }
    
    pub fn get_sync_service(&self) -> Arc<dyn SyncPort> {
        self.sync_service.clone()
    }
    
    pub fn get_encryption_service(&self) -> Arc<dyn EncryptionPort> {
        self.encryption_service.clone()
    }
    
    pub fn get_config_service(&self) -> Arc<dyn ConfigPort> {
        self.config_service.clone()
    }
}