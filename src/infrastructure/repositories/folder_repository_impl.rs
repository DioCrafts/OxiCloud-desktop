use std::sync::Arc;

use anyhow::{Result, anyhow};
use async_trait::async_trait;
use log::{info, debug, error};

use crate::domain::models::folder::Folder;
use crate::domain::models::file::File;
use crate::domain::repositories::folder_repository::FolderRepository;
use crate::infrastructure::adapters::folder_adapter::FolderAdapter;
use crate::infrastructure::adapters::webdav_adapter::WebDavAdapter;

/// Implementation of FolderRepository using OxiCloud API and WebDAV
pub struct FolderRepositoryImpl {
    /// Folder adapter for API operations
    folder_adapter: Arc<FolderAdapter>,
    
    /// WebDAV adapter for file operations
    webdav_adapter: Arc<WebDavAdapter>,
}

impl FolderRepositoryImpl {
    /// Create a new folder repository
    pub fn new(folder_adapter: Arc<FolderAdapter>, webdav_adapter: Arc<WebDavAdapter>) -> Self {
        Self {
            folder_adapter,
            webdav_adapter,
        }
    }
}

#[async_trait]
impl FolderRepository for FolderRepositoryImpl {
    async fn get_folder_by_id(&self, id: &str) -> Result<Option<Folder>> {
        debug!("Getting folder by ID: {}", id);
        
        self.folder_adapter.get_folder(id).await
    }
    
    async fn get_folder_by_path(&self, path: &str) -> Result<Option<Folder>> {
        debug!("Getting folder by path: {}", path);
        
        // In a real implementation, we would have a lookup by path
        // For this example, we'll just return a mock folder
        let folder = Folder::new(
            "path_based_id".to_string(),
            path.rsplit('/').next().unwrap_or(path).to_string(),
            path.to_string(),
            Some("root".to_string()),
        );
        
        Ok(Some(folder))
    }
    
    async fn create_folder(&self, parent_id: &str, name: &str) -> Result<Folder> {
        debug!("Creating folder '{}' in parent '{}'", name, parent_id);
        
        self.folder_adapter.create_folder(parent_id, name).await
    }
    
    async fn update_folder(&self, folder: &Folder) -> Result<Folder> {
        debug!("Updating folder: {}", folder.id);
        
        // In WebDAV, updating metadata typically involves PROPPATCH
        // For simplicity, we'll just return the folder as-is
        
        Ok(folder.clone())
    }
    
    async fn delete_folder(&self, id: &str) -> Result<()> {
        debug!("Deleting folder: {}", id);
        
        self.folder_adapter.delete_folder(id).await
    }
    
    async fn get_root_folder(&self) -> Result<Folder> {
        debug!("Getting root folder");
        
        // Create a root folder object
        let root_folder = Folder::new(
            "root".to_string(),
            "Root".to_string(),
            "/".to_string(),
            None, // No parent for root
        );
        
        Ok(root_folder)
    }
    
    async fn get_subfolders(&self, folder_id: &str) -> Result<Vec<Folder>> {
        debug!("Getting subfolders of folder: {}", folder_id);
        
        let (_, folders) = self.get_folder_contents(folder_id).await?;
        
        Ok(folders)
    }
    
    async fn get_files_in_folder(&self, folder_id: &str) -> Result<Vec<File>> {
        debug!("Getting files in folder: {}", folder_id);
        
        let (files, _) = self.get_folder_contents(folder_id).await?;
        
        Ok(files)
    }
    
    async fn get_folder_contents(&self, folder_id: &str) -> Result<(Vec<File>, Vec<Folder>)> {
        debug!("Getting contents of folder: {}", folder_id);
        
        self.folder_adapter.get_folder_contents(folder_id).await
    }
    
    async fn move_folder(&self, id: &str, new_parent_id: &str) -> Result<Folder> {
        debug!("Moving folder '{}' to parent '{}'", id, new_parent_id);
        
        self.folder_adapter.move_folder(id, new_parent_id).await
    }
    
    async fn rename_folder(&self, id: &str, new_name: &str) -> Result<Folder> {
        debug!("Renaming folder '{}' to '{}'", id, new_name);
        
        self.folder_adapter.rename_folder(id, new_name).await
    }
    
    async fn set_favorite(&self, id: &str, is_favorite: bool) -> Result<Folder> {
        debug!("Setting favorite status to {} for folder {}", is_favorite, id);
        
        self.folder_adapter.set_favorite(id, is_favorite).await
    }
}