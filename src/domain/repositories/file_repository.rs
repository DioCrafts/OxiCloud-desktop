use std::path::Path;

use anyhow::Result;
use async_trait::async_trait;

use crate::domain::models::file::File;

/// Repository interface for file operations
#[async_trait::async_trait]
pub trait FileRepository: Send + Sync {
    /// Get a file by its ID
    async fn get_file_by_id(&self, id: &str) -> Result<Option<File>>;
    
    /// Get a file by its path
    async fn get_file_by_path(&self, path: &str) -> Result<Option<File>>;
    
    /// Get all files in a folder
    async fn get_files_in_folder(&self, folder_id: &str) -> Result<Vec<File>>;
    
    /// Create a new file
    async fn create_file(&self, file: &File, content: &[u8]) -> Result<File>;
    
    /// Update file metadata
    async fn update_file(&self, file: &File) -> Result<File>;
    
    /// Delete a file
    async fn delete_file(&self, id: &str) -> Result<()>;
    
    /// Download file content
    async fn download_file(&self, id: &str) -> Result<Vec<u8>>;
    
    /// Upload file content
    async fn upload_file(&self, id: &str, content: &[u8]) -> Result<File>;
    
    /// Move a file to a different folder
    async fn move_file(&self, id: &str, new_parent_id: &str, new_name: Option<&str>) -> Result<File>;
    
    /// Copy a file to a different folder
    async fn copy_file(&self, id: &str, new_parent_id: &str, new_name: Option<&str>) -> Result<File>;
    
    /// Get favorite files
    async fn get_favorite_files(&self) -> Result<Vec<File>>;
    
    /// Set file as favorite or not
    async fn set_favorite(&self, id: &str, is_favorite: bool) -> Result<File>;
    
    /// Get recently modified files
    async fn get_recent_files(&self, limit: usize) -> Result<Vec<File>>;
    
    /// Create a file from a local path
    async fn import_file_from_path(&self, local_path: &Path, parent_id: &str) -> Result<File>;
    
    /// Export a file to a local path
    async fn export_file_to_path(&self, id: &str, local_path: &Path) -> Result<()>;
    
    /// Search for files by name
    async fn search_files(&self, query: &str) -> Result<Vec<File>>;
}