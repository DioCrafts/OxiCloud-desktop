use anyhow::Result;
use async_trait::async_trait;

use crate::domain::models::folder::Folder;
use crate::domain::models::file::File;

/// Repository interface for folder operations
#[async_trait]
pub trait FolderRepository: Send + Sync {
    /// Get a folder by its ID
    async fn get_folder_by_id(&self, id: &str) -> Result<Option<Folder>>;
    
    /// Get a folder by its path
    async fn get_folder_by_path(&self, path: &str) -> Result<Option<Folder>>;
    
    /// Create a new folder
    async fn create_folder(&self, parent_id: &str, name: &str) -> Result<Folder>;
    
    /// Update folder metadata
    async fn update_folder(&self, folder: &Folder) -> Result<Folder>;
    
    /// Delete a folder
    async fn delete_folder(&self, id: &str) -> Result<()>;
    
    /// Get the root folder
    async fn get_root_folder(&self) -> Result<Folder>;
    
    /// Get all subfolders of a folder
    async fn get_subfolders(&self, folder_id: &str) -> Result<Vec<Folder>>;
    
    /// Get all files in a folder
    async fn get_files_in_folder(&self, folder_id: &str) -> Result<Vec<File>>;
    
    /// Get the contents of a folder (files and subfolders)
    async fn get_folder_contents(&self, folder_id: &str) -> Result<(Vec<File>, Vec<Folder>)>;
    
    /// Move a folder to a different parent
    async fn move_folder(&self, id: &str, new_parent_id: &str) -> Result<Folder>;
    
    /// Rename a folder
    async fn rename_folder(&self, id: &str, new_name: &str) -> Result<Folder>;
    
    /// Set folder as favorite or not
    async fn set_favorite(&self, id: &str, is_favorite: bool) -> Result<Folder>;
}