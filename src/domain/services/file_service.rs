use async_trait::async_trait;
use std::path::Path;
use std::sync::Arc;

use crate::domain::entities::file::{FileItem, FileResult, FileType, SyncStatus};
use crate::domain::repositories::file_repository::FileRepository;

#[async_trait]
pub trait FileService: Send + Sync + 'static {
    // File browsing
    async fn get_file(&self, file_id: &str) -> FileResult<FileItem>;
    async fn list_files(&self, folder_id: Option<&str>) -> FileResult<Vec<FileItem>>;
    async fn get_file_content(&self, file_id: &str) -> FileResult<Vec<u8>>;
    
    // File operations
    async fn create_file(&self, name: &str, folder_id: Option<&str>, content: Vec<u8>) -> FileResult<FileItem>;
    async fn create_folder(&self, name: &str, parent_id: Option<&str>) -> FileResult<FileItem>;
    async fn update_file(&self, file_id: &str, content: Vec<u8>) -> FileResult<FileItem>;
    async fn rename_item(&self, item_id: &str, new_name: &str) -> FileResult<FileItem>;
    async fn move_item(&self, item_id: &str, new_parent_id: Option<&str>) -> FileResult<FileItem>;
    async fn delete_item(&self, item_id: &str) -> FileResult<()>;
    
    // Favorites
    async fn get_favorites(&self) -> FileResult<Vec<FileItem>>;
    async fn toggle_favorite(&self, file_id: &str) -> FileResult<FileItem>;
    
    // Search
    async fn search_files(&self, query: &str) -> FileResult<Vec<FileItem>>;
    
    // Local file system integration
    async fn upload_from_path(&self, local_path: &Path, parent_id: Option<&str>) -> FileResult<FileItem>;
    async fn download_to_path(&self, file_id: &str, local_path: &Path) -> FileResult<()>;
}

pub struct FileServiceImpl {
    file_repository: Arc<dyn FileRepository>,
}

impl FileServiceImpl {
    pub fn new(file_repository: Arc<dyn FileRepository>) -> Self {
        Self { file_repository }
    }
    
    // Helper for generating unique IDs
    fn generate_id(&self) -> String {
        uuid::Uuid::new_v4().to_string()
    }
}

#[async_trait]
impl FileService for FileServiceImpl {
    async fn get_file(&self, file_id: &str) -> FileResult<FileItem> {
        self.file_repository.get_file_by_id(file_id).await
    }
    
    async fn list_files(&self, folder_id: Option<&str>) -> FileResult<Vec<FileItem>> {
        self.file_repository.get_files_by_folder(folder_id).await
    }
    
    async fn get_file_content(&self, file_id: &str) -> FileResult<Vec<u8>> {
        self.file_repository.get_file_content(file_id).await
    }
    
    async fn create_file(&self, name: &str, folder_id: Option<&str>, content: Vec<u8>) -> FileResult<FileItem> {
        // TODO: Generate a proper path based on folder_id and name
        let path = match folder_id {
            Some(id) => format!("/folder_{}/{}", id, name),
            None => format!("/{}" , name),
        };
        
        let file = FileItem::new_file(
            self.generate_id(),
            name.to_string(),
            path,
            content.len() as u64,
            Some(mime_guess::from_path(name).first_or_octet_stream().to_string()),
            folder_id.map(|s| s.to_string()),
            None, // local_path will be set by repository
        );
        
        self.file_repository.create_file(file, content).await
    }
    
    async fn create_folder(&self, name: &str, parent_id: Option<&str>) -> FileResult<FileItem> {
        // TODO: Generate a proper path based on parent_id and name
        let path = match parent_id {
            Some(id) => format!("/folder_{}/{}", id, name),
            None => format!("/{}" , name),
        };
        
        let folder = FileItem::new_directory(
            self.generate_id(),
            name.to_string(),
            path,
            parent_id.map(|s| s.to_string()),
            None, // local_path will be set by repository
        );
        
        self.file_repository.create_folder(folder).await
    }
    
    async fn update_file(&self, file_id: &str, content: Vec<u8>) -> FileResult<FileItem> {
        let mut file = self.file_repository.get_file_by_id(file_id).await?;
        let new_size = content.len() as u64;
        
        // Only update if it's a file, not a directory
        if file.file_type != FileType::File {
            return Err(crate::domain::entities::file::FileError::OperationError(
                "Cannot update content of a directory".to_string()))
        }
        
        file.size = new_size;
        file.modified_at = chrono::Utc::now();
        file.update_sync_status(SyncStatus::PendingUpload);
        
        self.file_repository.update_file(file, Some(content)).await
    }
    
    async fn rename_item(&self, item_id: &str, new_name: &str) -> FileResult<FileItem> {
        let mut item = self.file_repository.get_file_by_id(item_id).await?;
        
        // Update the name and path
        // TODO: Properly update the path based on parent directory
        let path_parts: Vec<&str> = item.path.rsplitn(2, '/').collect();
        let new_path = if path_parts.len() > 1 {
            format!("{}/{}", path_parts[1], new_name)
        } else {
            format!("/{}" , new_name)
        };
        
        item.name = new_name.to_string();
        item.path = new_path;
        item.modified_at = chrono::Utc::now();
        item.update_sync_status(SyncStatus::PendingUpload);
        
        self.file_repository.update_file(item, None).await
    }
    
    async fn move_item(&self, item_id: &str, new_parent_id: Option<&str>) -> FileResult<FileItem> {
        let mut item = self.file_repository.get_file_by_id(item_id).await?;
        
        // Get new parent path if needed
        let parent_path = if let Some(parent_id) = new_parent_id {
            let parent = self.file_repository.get_file_by_id(parent_id).await?;
            if parent.file_type != FileType::Directory {
                return Err(crate::domain::entities::file::FileError::OperationError(
                    "Target is not a directory".to_string()))
            }
            parent.path
        } else {
            "/".to_string()
        };
        
        // Update the path and parent ID
        let new_path = if parent_path.ends_with('/') {
            format!("{}{}", parent_path, item.name)
        } else {
            format!("{}/{}", parent_path, item.name)
        };
        
        item.path = new_path;
        item.parent_id = new_parent_id.map(|s| s.to_string());
        item.modified_at = chrono::Utc::now();
        item.update_sync_status(SyncStatus::PendingUpload);
        
        self.file_repository.update_file(item, None).await
    }
    
    async fn delete_item(&self, item_id: &str) -> FileResult<()> {
        let item = self.file_repository.get_file_by_id(item_id).await?;
        
        match item.file_type {
            FileType::File => self.file_repository.delete_file(item_id).await,
            FileType::Directory => self.file_repository.delete_folder(item_id, true).await,
        }
    }
    
    async fn get_favorites(&self) -> FileResult<Vec<FileItem>> {
        self.file_repository.get_favorites().await
    }
    
    async fn toggle_favorite(&self, file_id: &str) -> FileResult<FileItem> {
        let file = self.file_repository.get_file_by_id(file_id).await?;
        self.file_repository.set_favorite(file_id, !file.is_favorite).await
    }
    
    async fn search_files(&self, query: &str) -> FileResult<Vec<FileItem>> {
        // TODO: Implement search functionality
        // For now return empty results
        Ok(Vec::new())
    }
    
    async fn upload_from_path(&self, local_path: &Path, parent_id: Option<&str>) -> FileResult<FileItem> {
        self.file_repository.upload_file_from_path(local_path, parent_id).await
    }
    
    async fn download_to_path(&self, file_id: &str, local_path: &Path) -> FileResult<()> {
        self.file_repository.download_file_to_path(file_id, local_path).await
    }
}
