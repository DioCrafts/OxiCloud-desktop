use async_trait::async_trait;
use std::sync::Arc;
use std::path::Path;

use crate::application::dtos::file_dto::FileDto;
use crate::domain::entities::file::FileError;

pub type FileResult<T> = Result<T, FileError>;

#[async_trait]
pub trait FilePort: Send + Sync + 'static {
    // File browsing
    async fn get_file(&self, file_id: &str) -> FileResult<FileDto>;
    async fn list_files(&self, folder_id: Option<&str>) -> FileResult<Vec<FileDto>>;
    async fn get_file_content(&self, file_id: &str) -> FileResult<Vec<u8>>;
    
    // File operations
    async fn create_file(&self, name: &str, folder_id: Option<&str>, content: Vec<u8>) -> FileResult<FileDto>;
    async fn create_folder(&self, name: &str, parent_id: Option<&str>) -> FileResult<FileDto>;
    async fn rename_item(&self, item_id: &str, new_name: &str) -> FileResult<FileDto>;
    async fn move_item(&self, item_id: &str, target_folder_id: Option<&str>) -> FileResult<FileDto>;
    async fn delete_item(&self, item_id: &str) -> FileResult<()>;
    
    // Favorites
    async fn get_favorites(&self) -> FileResult<Vec<FileDto>>;
    async fn toggle_favorite(&self, file_id: &str) -> FileResult<FileDto>;
    
    // Search
    async fn search_files(&self, query: &str) -> FileResult<Vec<FileDto>>;
    
    // Local file system integration
    async fn upload_local_file(&self, path: &Path, parent_id: Option<&str>) -> FileResult<FileDto>;
    async fn download_file(&self, file_id: &str, target_path: &Path) -> FileResult<()>;
}

#[async_trait]
pub trait FileRemotePort: Send + Sync + 'static {
    async fn get_remote_file(&self, file_id: &str) -> FileResult<FileDto>;
    async fn list_remote_files(&self, folder_id: Option<&str>) -> FileResult<Vec<FileDto>>;
    async fn download_remote_file(&self, file_id: &str) -> FileResult<Vec<u8>>;
    async fn upload_file_to_remote(&self, name: &str, folder_id: Option<&str>, content: Vec<u8>) -> FileResult<FileDto>;
    async fn create_remote_folder(&self, name: &str, parent_id: Option<&str>) -> FileResult<FileDto>;
    async fn update_remote_file(&self, file_id: &str, new_name: Option<&str>, new_parent_id: Option<&str>, content: Option<Vec<u8>>) -> FileResult<FileDto>;
    async fn delete_remote_item(&self, item_id: &str) -> FileResult<()>;
    async fn get_remote_favorites(&self) -> FileResult<Vec<FileDto>>;
    async fn set_remote_favorite(&self, file_id: &str, is_favorite: bool) -> FileResult<FileDto>;
}

#[async_trait]
pub trait FileLocalPort: Send + Sync + 'static {
    async fn get_local_file(&self, file_id: &str) -> FileResult<FileDto>;
    async fn list_local_files(&self, folder_id: Option<&str>) -> FileResult<Vec<FileDto>>;
    async fn read_local_file(&self, file_id: &str) -> FileResult<Vec<u8>>;
    async fn write_local_file(&self, file: FileDto, content: Vec<u8>) -> FileResult<FileDto>;
    async fn create_local_folder(&self, folder: FileDto) -> FileResult<FileDto>;
    async fn update_local_file(&self, file: FileDto, content: Option<Vec<u8>>) -> FileResult<FileDto>;
    async fn delete_local_item(&self, file_id: &str) -> FileResult<()>;
    async fn scan_local_changes(&self, since: Option<chrono::DateTime<chrono::Utc>>) -> FileResult<Vec<FileDto>>;
}
