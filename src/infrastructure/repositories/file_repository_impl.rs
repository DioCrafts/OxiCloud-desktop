use std::path::Path;
use std::sync::Arc;

use anyhow::{Result, anyhow};
use async_trait::async_trait;
use log::{info, debug, error};

use crate::domain::models::file::File;
use crate::domain::repositories::file_repository::FileRepository;
use crate::infrastructure::adapters::webdav_adapter::WebDavAdapter;

/// Implementation of FileRepository using OxiCloud WebDAV
pub struct FileRepositoryImpl {
    /// WebDAV adapter for file operations
    webdav_adapter: Arc<WebDavAdapter>,
}

impl FileRepositoryImpl {
    /// Create a new file repository
    pub fn new(webdav_adapter: Arc<WebDavAdapter>) -> Self {
        Self {
            webdav_adapter,
        }
    }
}

#[async_trait]
impl FileRepository for FileRepositoryImpl {
    async fn get_file_by_id(&self, id: &str) -> Result<Option<File>> {
        debug!("Getting file by ID: {}", id);
        
        self.webdav_adapter.get_file_by_id(id).await
    }
    
    async fn get_file_by_path(&self, path: &str) -> Result<Option<File>> {
        debug!("Getting file by path: {}", path);
        
        self.webdav_adapter.get_file_by_path(path).await
    }
    
    async fn get_files_in_folder(&self, folder_id: &str) -> Result<Vec<File>> {
        debug!("Getting files in folder: {}", folder_id);
        
        self.webdav_adapter.get_files_in_folder(folder_id).await
    }
    
    async fn create_file(&self, file: &File, content: &[u8]) -> Result<File> {
        debug!("Creating file: {}", file.path);
        
        self.webdav_adapter.create_file(file, content).await
    }
    
    async fn update_file(&self, file: &File) -> Result<File> {
        debug!("Updating file metadata: {}", file.id);
        
        self.webdav_adapter.update_file(file).await
    }
    
    async fn delete_file(&self, id: &str) -> Result<()> {
        debug!("Deleting file: {}", id);
        
        self.webdav_adapter.delete_file(id).await
    }
    
    async fn download_file(&self, id: &str) -> Result<Vec<u8>> {
        debug!("Downloading file: {}", id);
        
        self.webdav_adapter.download_file(id).await
    }
    
    async fn upload_file(&self, id: &str, content: &[u8]) -> Result<File> {
        debug!("Uploading file: {}", id);
        
        self.webdav_adapter.upload_file(id, content).await
    }
    
    async fn move_file(&self, id: &str, new_parent_id: &str, new_name: Option<&str>) -> Result<File> {
        debug!("Moving file {} to folder {}", id, new_parent_id);
        
        self.webdav_adapter.move_file(id, new_parent_id, new_name).await
    }
    
    async fn copy_file(&self, id: &str, new_parent_id: &str, new_name: Option<&str>) -> Result<File> {
        debug!("Copying file {} to folder {}", id, new_parent_id);
        
        self.webdav_adapter.copy_file(id, new_parent_id, new_name).await
    }
    
    async fn get_favorite_files(&self) -> Result<Vec<File>> {
        debug!("Getting favorite files");
        
        self.webdav_adapter.get_favorite_files().await
    }
    
    async fn set_favorite(&self, id: &str, is_favorite: bool) -> Result<File> {
        debug!("Setting favorite status to {} for file {}", is_favorite, id);
        
        self.webdav_adapter.set_favorite(id, is_favorite).await
    }
    
    async fn get_recent_files(&self, limit: usize) -> Result<Vec<File>> {
        debug!("Getting {} recent files", limit);
        
        self.webdav_adapter.get_recent_files(limit).await
    }
    
    async fn import_file_from_path(&self, local_path: &Path, parent_id: &str) -> Result<File> {
        debug!("Importing file from {} to folder {}", local_path.display(), parent_id);
        
        self.webdav_adapter.import_file_from_path(local_path, parent_id).await
    }
    
    async fn export_file_to_path(&self, id: &str, local_path: &Path) -> Result<()> {
        debug!("Exporting file {} to {}", id, local_path.display());
        
        self.webdav_adapter.export_file_to_path(id, local_path).await
    }
    
    async fn search_files(&self, query: &str) -> Result<Vec<File>> {
        debug!("Searching for files with query: {}", query);
        
        self.webdav_adapter.search_files(query).await
    }
}