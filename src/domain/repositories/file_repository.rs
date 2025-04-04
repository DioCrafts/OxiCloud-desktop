use async_trait::async_trait;
use std::path::Path;
use std::sync::Arc;

use crate::domain::entities::file::{FileItem, FileResult};

#[async_trait]
pub trait FileRepository: Send + Sync + 'static {
    // File retrieval operations
    async fn get_file_by_id(&self, file_id: &str) -> FileResult<FileItem>;
    async fn get_files_by_folder(&self, folder_id: Option<&str>) -> FileResult<Vec<FileItem>>;
    async fn get_file_content(&self, file_id: &str) -> FileResult<Vec<u8>>;
    
    // File manipulation operations
    async fn create_file(&self, file: FileItem, content: Vec<u8>) -> FileResult<FileItem>;
    async fn update_file(&self, file: FileItem, content: Option<Vec<u8>>) -> FileResult<FileItem>;
    async fn delete_file(&self, file_id: &str) -> FileResult<()>;
    
    // Folder operations
    async fn create_folder(&self, folder: FileItem) -> FileResult<FileItem>;
    async fn delete_folder(&self, folder_id: &str, recursive: bool) -> FileResult<()>;
    
    // Sync-related operations
    async fn get_changed_files(&self, since: Option<chrono::DateTime<chrono::Utc>>) -> FileResult<Vec<FileItem>>;
    async fn get_files_by_sync_status(&self, status: crate::domain::entities::file::SyncStatus) -> FileResult<Vec<FileItem>>;
    
    // File system operations
    async fn get_file_from_path(&self, path: &Path) -> FileResult<Option<FileItem>>;
    async fn download_file_to_path(&self, file_id: &str, local_path: &Path) -> FileResult<()>;
    async fn upload_file_from_path(&self, local_path: &Path, parent_id: Option<&str>) -> FileResult<FileItem>;
    
    // Favorite operations
    async fn get_favorites(&self) -> FileResult<Vec<FileItem>>;
    async fn set_favorite(&self, file_id: &str, is_favorite: bool) -> FileResult<FileItem>;
}

// Factory for creating repository instances
pub trait FileRepositoryFactory: Send + Sync + 'static {
    fn create_repository(&self) -> Arc<dyn FileRepository>;
}
