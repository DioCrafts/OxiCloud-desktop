use r2d2::Pool;
use r2d2_sqlite::SqliteConnectionManager;
use rusqlite::{params, Result as SqliteResult, Row};
use std::path::{Path, PathBuf};
use std::sync::Arc;
use std::fs;
use chrono::{DateTime, Utc};
use async_trait::async_trait;
use tokio::task;

use crate::domain::entities::file::{FileItem, FileType, SyncStatus, EncryptionStatus, FileError, FileResult};
use crate::domain::repositories::file_repository::{FileRepository, FileRepositoryFactory};

/// SQLite implementation of the FileRepository
pub struct SqliteFileRepository {
    pool: Pool<SqliteConnectionManager>,
}

impl SqliteFileRepository {
    pub fn new(pool: Pool<SqliteConnectionManager>) -> Self {
        Self { pool }
    }
    
    /// Convert a row from the database to a FileItem
    fn row_to_file_item(row: &Row) -> SqliteResult<FileItem> {
        let id: String = row.get(0)?;
        let name: String = row.get(1)?;
        let path: String = row.get(2)?;
        let file_type_str: String = row.get(3)?;
        let file_type = match file_type_str.as_str() {
            "Folder" => FileType::Folder,
            "Image" => FileType::Image,
            "Video" => FileType::Video,
            "Audio" => FileType::Audio,
            "Document" => FileType::Document,
            "Spreadsheet" => FileType::Spreadsheet,
            "Presentation" => FileType::Presentation,
            "File" => FileType::File,
            _ => FileType::Other,
        };
        
        let size: i64 = row.get(4)?;
        let mime_type: Option<String> = row.get(5)?;
        let parent_id: Option<String> = row.get(6)?;
        let created_at_str: String = row.get(7)?;
        let modified_at_str: String = row.get(8)?;
        let sync_status_str: String = row.get(9)?;
        let is_favorite: bool = row.get::<_, i64>(10)? != 0;
        let local_path: Option<String> = row.get(11)?;
        let encryption_status_str: String = row.get(12)?;
        let encryption_iv: Option<String> = row.get(13)?;
        let encryption_metadata: Option<String> = row.get(14)?;
        
        let created_at = DateTime::parse_from_rfc3339(&created_at_str)
            .map_err(|_| rusqlite::Error::InvalidParameterName(format!("Invalid created_at date: {}", created_at_str)))?
            .with_timezone(&Utc);
            
        let modified_at = DateTime::parse_from_rfc3339(&modified_at_str)
            .map_err(|_| rusqlite::Error::InvalidParameterName(format!("Invalid modified_at date: {}", modified_at_str)))?
            .with_timezone(&Utc);
        
        let sync_status = match sync_status_str.as_str() {
            "Synced" => SyncStatus::Synced,
            "Syncing" => SyncStatus::Syncing,
            "PendingUpload" => SyncStatus::PendingUpload,
            "PendingDownload" => SyncStatus::PendingDownload,
            "Error" => SyncStatus::Error,
            "Conflicted" => SyncStatus::Conflicted,
            "Ignored" => SyncStatus::Ignored,
            _ => SyncStatus::Synced,
        };
        
        let encryption_status = match encryption_status_str.as_str() {
            "Encrypted" => EncryptionStatus::Encrypted,
            "Encrypting" => EncryptionStatus::Encrypting,
            "Decrypting" => EncryptionStatus::Decrypting,
            "Error" => EncryptionStatus::Error,
            _ => EncryptionStatus::Unencrypted,
        };
        
        Ok(FileItem {
            id,
            name,
            path,
            file_type,
            size: size as u64,
            mime_type,
            parent_id,
            created_at,
            modified_at,
            sync_status,
            is_favorite,
            local_path,
            encryption_status,
            encryption_iv,
            encryption_metadata,
        })
    }
}

#[async_trait]
impl FileRepository for SqliteFileRepository {
    async fn get_file_by_id(&self, file_id: &str) -> FileResult<FileItem> {
        let pool = self.pool.clone();
        let file_id = file_id.to_string();
        
        let result = task::spawn_blocking(move || {
            let conn = pool.get().map_err(|e| FileError::IOError(e.to_string()))?;
            
            let file = conn.query_row(
                "SELECT id, name, path, file_type, size, mime_type, parent_id, 
                        created_at, modified_at, sync_status, is_favorite, local_path,
                        encryption_status, encryption_iv, encryption_metadata
                 FROM files WHERE id = ?",
                [&file_id],
                |row| Self::row_to_file_item(row),
            ).map_err(|e| FileError::NotFoundError(format!("File not found: {}, error: {}", file_id, e)))?;
            
            Ok(file)
        }).await.map_err(|e| FileError::OperationError(e.to_string()))?;
        
        result
    }
    
    async fn get_files_by_folder(&self, folder_id: Option<&str>) -> FileResult<Vec<FileItem>> {
        let pool = self.pool.clone();
        let folder_id = folder_id.map(|id| id.to_string());
        
        let result = task::spawn_blocking(move || {
            let conn = pool.get().map_err(|e| FileError::IOError(e.to_string()))?;
            
            let mut stmt = match folder_id {
                Some(ref id) => {
                    conn.prepare(
                        "SELECT id, name, path, file_type, size, mime_type, parent_id, 
                                created_at, modified_at, sync_status, is_favorite, local_path,
                                encryption_status, encryption_iv, encryption_metadata
                         FROM files WHERE parent_id = ? ORDER BY file_type DESC, name ASC"
                    ).map_err(|e| FileError::OperationError(e.to_string()))?
                },
                None => {
                    conn.prepare(
                        "SELECT id, name, path, file_type, size, mime_type, parent_id, 
                                created_at, modified_at, sync_status, is_favorite, local_path,
                                encryption_status, encryption_iv, encryption_metadata
                         FROM files WHERE parent_id IS NULL ORDER BY file_type DESC, name ASC"
                    ).map_err(|e| FileError::OperationError(e.to_string()))?
                }
            };
            
            let file_iter = match folder_id {
                Some(ref id) => stmt.query_map([id], |row| Self::row_to_file_item(row)),
                None => stmt.query_map([], |row| Self::row_to_file_item(row)),
            }.map_err(|e| FileError::OperationError(e.to_string()))?;
            
            let mut files = Vec::new();
            for file_result in file_iter {
                let file = file_result.map_err(|e| FileError::OperationError(e.to_string()))?;
                files.push(file);
            }
            
            Ok(files)
        }).await.map_err(|e| FileError::OperationError(e.to_string()))?;
        
        result
    }
    
    async fn get_file_content(&self, file_id: &str) -> FileResult<Vec<u8>> {
        let file = self.get_file_by_id(file_id).await?;
        
        match file.local_path {
            Some(local_path) => {
                let path = PathBuf::from(local_path);
                task::spawn_blocking(move || {
                    fs::read(&path).map_err(|e| FileError::IOError(e.to_string()))
                }).await.map_err(|e| FileError::OperationError(e.to_string()))?
            },
            None => Err(FileError::NotFoundError(format!("No local path for file: {}", file_id)))
        }
    }
    
    async fn create_file(&self, file: FileItem, content: Vec<u8>) -> FileResult<FileItem> {
        let pool = self.pool.clone();
        let file_copy = file.clone();
        
        // First save the file content to disk if there's a local path
        if let Some(local_path) = &file.local_path {
            let path = PathBuf::from(local_path);
            let content_copy = content.clone();
            
            task::spawn_blocking(move || {
                // Create parent directories if they don't exist
                if let Some(parent) = path.parent() {
                    fs::create_dir_all(parent).map_err(|e| FileError::IOError(e.to_string()))?;
                }
                
                // Write the file content
                fs::write(&path, content_copy).map_err(|e| FileError::IOError(e.to_string()))
            }).await.map_err(|e| FileError::OperationError(e.to_string()))?;
        }
        
        // Then save the file metadata to the database
        task::spawn_blocking(move || {
            let conn = pool.get().map_err(|e| FileError::IOError(e.to_string()))?;
            
            let file_type_str = match file_copy.file_type {
                FileType::Folder => "Folder",
                FileType::Image => "Image",
                FileType::Video => "Video",
                FileType::Audio => "Audio",
                FileType::Document => "Document",
                FileType::Spreadsheet => "Spreadsheet",
                FileType::Presentation => "Presentation",
                FileType::File => "File",
                FileType::Other => "Other",
            };
            
            let sync_status_str = match file_copy.sync_status {
                SyncStatus::Synced => "Synced",
                SyncStatus::Syncing => "Syncing",
                SyncStatus::PendingUpload => "PendingUpload",
                SyncStatus::PendingDownload => "PendingDownload",
                SyncStatus::Error => "Error",
                SyncStatus::Conflicted => "Conflicted",
                SyncStatus::Ignored => "Ignored",
            };
            
            let encryption_status_str = match file_copy.encryption_status {
                EncryptionStatus::Encrypted => "Encrypted",
                EncryptionStatus::Encrypting => "Encrypting",
                EncryptionStatus::Decrypting => "Decrypting",
                EncryptionStatus::Unencrypted => "Unencrypted",
                EncryptionStatus::Error => "Error",
            };
            
            conn.execute(
                "INSERT INTO files (
                    id, name, path, file_type, size, mime_type, parent_id,
                    created_at, modified_at, sync_status, is_favorite, local_path,
                    encryption_status, encryption_iv, encryption_metadata
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                params![
                    file_copy.id,
                    file_copy.name,
                    file_copy.path,
                    file_type_str,
                    file_copy.size as i64,
                    file_copy.mime_type,
                    file_copy.parent_id,
                    file_copy.created_at.to_rfc3339(),
                    file_copy.modified_at.to_rfc3339(),
                    sync_status_str,
                    file_copy.is_favorite as i64,
                    file_copy.local_path,
                    encryption_status_str,
                    file_copy.encryption_iv,
                    file_copy.encryption_metadata,
                ],
            ).map_err(|e| FileError::OperationError(e.to_string()))?;
            
            Ok(file_copy)
        }).await.map_err(|e| FileError::OperationError(e.to_string()))?
    }
    
    async fn update_file(&self, file: FileItem, content: Option<Vec<u8>>) -> FileResult<FileItem> {
        let pool = self.pool.clone();
        let file_copy = file.clone();
        let file_id = file.id.clone();
        
        // First update the file content if provided
        if let Some(content) = content {
            if let Some(local_path) = &file.local_path {
                let path = PathBuf::from(local_path);
                let content_copy = content.clone();
                
                task::spawn_blocking(move || {
                    // Create parent directories if they don't exist
                    if let Some(parent) = path.parent() {
                        fs::create_dir_all(parent).map_err(|e| FileError::IOError(e.to_string()))?;
                    }
                    
                    // Write the file content
                    fs::write(&path, content_copy).map_err(|e| FileError::IOError(e.to_string()))
                }).await.map_err(|e| FileError::OperationError(e.to_string()))?;
            }
        }
        
        // Then update the file metadata in the database
        task::spawn_blocking(move || {
            let conn = pool.get().map_err(|e| FileError::IOError(e.to_string()))?;
            
            let file_type_str = match file_copy.file_type {
                FileType::Folder => "Folder",
                FileType::Image => "Image",
                FileType::Video => "Video",
                FileType::Audio => "Audio",
                FileType::Document => "Document",
                FileType::Spreadsheet => "Spreadsheet",
                FileType::Presentation => "Presentation",
                FileType::File => "File",
                FileType::Other => "Other",
            };
            
            let sync_status_str = match file_copy.sync_status {
                SyncStatus::Synced => "Synced",
                SyncStatus::Syncing => "Syncing",
                SyncStatus::PendingUpload => "PendingUpload",
                SyncStatus::PendingDownload => "PendingDownload",
                SyncStatus::Error => "Error",
                SyncStatus::Conflicted => "Conflicted",
                SyncStatus::Ignored => "Ignored",
            };
            
            let encryption_status_str = match file_copy.encryption_status {
                EncryptionStatus::Encrypted => "Encrypted",
                EncryptionStatus::Encrypting => "Encrypting",
                EncryptionStatus::Decrypting => "Decrypting",
                EncryptionStatus::Unencrypted => "Unencrypted",
                EncryptionStatus::Error => "Error",
            };
            
            let result = conn.execute(
                "UPDATE files SET 
                    name = ?, path = ?, file_type = ?, size = ?, mime_type = ?, parent_id = ?,
                    created_at = ?, modified_at = ?, sync_status = ?, is_favorite = ?, local_path = ?,
                    encryption_status = ?, encryption_iv = ?, encryption_metadata = ?
                WHERE id = ?",
                params![
                    file_copy.name,
                    file_copy.path,
                    file_type_str,
                    file_copy.size as i64,
                    file_copy.mime_type,
                    file_copy.parent_id,
                    file_copy.created_at.to_rfc3339(),
                    file_copy.modified_at.to_rfc3339(),
                    sync_status_str,
                    file_copy.is_favorite as i64,
                    file_copy.local_path,
                    encryption_status_str,
                    file_copy.encryption_iv,
                    file_copy.encryption_metadata,
                    file_copy.id,
                ],
            ).map_err(|e| FileError::OperationError(e.to_string()))?;
            
            if result == 0 {
                return Err(FileError::NotFoundError(format!("File not found: {}", file_id)));
            }
            
            Ok(file_copy)
        }).await.map_err(|e| FileError::OperationError(e.to_string()))?
    }
    
    async fn delete_file(&self, file_id: &str) -> FileResult<()> {
        let pool = self.pool.clone();
        let file_id_clone = file_id.to_string();
        
        // Get the file first to check if it has a local path
        let file = self.get_file_by_id(file_id).await?;
        
        // Delete the file from the file system if it has a local path
        if let Some(local_path) = file.local_path {
            let path = PathBuf::from(local_path);
            
            task::spawn_blocking(move || {
                if path.exists() {
                    fs::remove_file(&path).map_err(|e| FileError::IOError(e.to_string()))?;
                }
                Ok(())
            }).await.map_err(|e| FileError::OperationError(e.to_string()))?;
        }
        
        // Then delete the file metadata from the database
        task::spawn_blocking(move || {
            let conn = pool.get().map_err(|e| FileError::IOError(e.to_string()))?;
            
            let result = conn.execute(
                "DELETE FROM files WHERE id = ?",
                [&file_id_clone],
            ).map_err(|e| FileError::OperationError(e.to_string()))?;
            
            if result == 0 {
                return Err(FileError::NotFoundError(format!("File not found: {}", file_id_clone)));
            }
            
            Ok(())
        }).await.map_err(|e| FileError::OperationError(e.to_string()))?
    }
    
    async fn create_folder(&self, folder: FileItem) -> FileResult<FileItem> {
        if folder.file_type != FileType::Folder {
            return Err(FileError::InvalidArgumentError("Item is not a folder".to_string()));
        }
        
        // Create the folder on the file system if it has a local path
        if let Some(local_path) = &folder.local_path {
            let path = PathBuf::from(local_path);
            
            task::spawn_blocking(move || {
                fs::create_dir_all(&path).map_err(|e| FileError::IOError(e.to_string()))
            }).await.map_err(|e| FileError::OperationError(e.to_string()))?;
        }
        
        // No content for folders
        self.create_file(folder, Vec::new()).await
    }
    
    async fn delete_folder(&self, folder_id: &str, recursive: bool) -> FileResult<()> {
        let folder = self.get_file_by_id(folder_id).await?;
        
        if folder.file_type != FileType::Folder {
            return Err(FileError::InvalidArgumentError("Item is not a folder".to_string()));
        }
        
        if recursive {
            // Delete all children first
            let children = self.get_files_by_folder(Some(folder_id)).await?;
            
            for child in children {
                if child.file_type == FileType::Folder {
                    self.delete_folder(&child.id, true).await?;
                } else {
                    self.delete_file(&child.id).await?;
                }
            }
        } else {
            // Check if the folder is empty
            let children = self.get_files_by_folder(Some(folder_id)).await?;
            
            if !children.is_empty() {
                return Err(FileError::OperationError("Cannot delete non-empty folder without recursive flag".to_string()));
            }
        }
        
        // Delete the folder on the file system if it has a local path
        if let Some(local_path) = folder.local_path {
            let path = PathBuf::from(local_path);
            
            task::spawn_blocking(move || {
                if path.exists() {
                    fs::remove_dir(&path).map_err(|e| FileError::IOError(e.to_string()))?;
                }
                Ok(())
            }).await.map_err(|e| FileError::OperationError(e.to_string()))?;
        }
        
        // Delete the folder metadata from the database
        let pool = self.pool.clone();
        let folder_id_clone = folder_id.to_string();
        
        task::spawn_blocking(move || {
            let conn = pool.get().map_err(|e| FileError::IOError(e.to_string()))?;
            
            let result = conn.execute(
                "DELETE FROM files WHERE id = ?",
                [&folder_id_clone],
            ).map_err(|e| FileError::OperationError(e.to_string()))?;
            
            if result == 0 {
                return Err(FileError::NotFoundError(format!("Folder not found: {}", folder_id_clone)));
            }
            
            Ok(())
        }).await.map_err(|e| FileError::OperationError(e.to_string()))?
    }
    
    async fn get_changed_files(&self, since: Option<chrono::DateTime<chrono::Utc>>) -> FileResult<Vec<FileItem>> {
        let pool = self.pool.clone();
        let since_str = since.map(|dt| dt.to_rfc3339());
        
        task::spawn_blocking(move || {
            let conn = pool.get().map_err(|e| FileError::IOError(e.to_string()))?;
            
            let mut files = Vec::new();
            
            if let Some(since_str) = since_str {
                let mut stmt = conn.prepare(
                    "SELECT id, name, path, file_type, size, mime_type, parent_id, 
                            created_at, modified_at, sync_status, is_favorite, local_path,
                            encryption_status, encryption_iv, encryption_metadata
                     FROM files 
                     WHERE modified_at > ? AND sync_status != 'Synced'
                     ORDER BY modified_at ASC"
                ).map_err(|e| FileError::OperationError(e.to_string()))?;
                
                let file_iter = stmt.query_map([since_str], |row| Self::row_to_file_item(row))
                    .map_err(|e| FileError::OperationError(e.to_string()))?;
                
                for file_result in file_iter {
                    let file = file_result.map_err(|e| FileError::OperationError(e.to_string()))?;
                    files.push(file);
                }
            } else {
                let mut stmt = conn.prepare(
                    "SELECT id, name, path, file_type, size, mime_type, parent_id, 
                            created_at, modified_at, sync_status, is_favorite, local_path,
                            encryption_status, encryption_iv, encryption_metadata
                     FROM files 
                     WHERE sync_status != 'Synced'
                     ORDER BY modified_at ASC"
                ).map_err(|e| FileError::OperationError(e.to_string()))?;
                
                let file_iter = stmt.query_map([], |row| Self::row_to_file_item(row))
                    .map_err(|e| FileError::OperationError(e.to_string()))?;
                
                for file_result in file_iter {
                    let file = file_result.map_err(|e| FileError::OperationError(e.to_string()))?;
                    files.push(file);
                }
            }
            
            Ok(files)
        }).await.map_err(|e| FileError::OperationError(e.to_string()))?
    }
    
    async fn get_files_by_sync_status(&self, status: crate::domain::entities::file::SyncStatus) -> FileResult<Vec<FileItem>> {
        let pool = self.pool.clone();
        
        let status_str = match status {
            SyncStatus::Synced => "Synced",
            SyncStatus::Syncing => "Syncing",
            SyncStatus::PendingUpload => "PendingUpload",
            SyncStatus::PendingDownload => "PendingDownload",
            SyncStatus::Error => "Error",
            SyncStatus::Conflicted => "Conflicted",
            SyncStatus::Ignored => "Ignored",
        };
        
        task::spawn_blocking(move || {
            let conn = pool.get().map_err(|e| FileError::IOError(e.to_string()))?;
            
            let mut stmt = conn.prepare(
                "SELECT id, name, path, file_type, size, mime_type, parent_id, 
                        created_at, modified_at, sync_status, is_favorite, local_path,
                        encryption_status, encryption_iv, encryption_metadata
                 FROM files 
                 WHERE sync_status = ?
                 ORDER BY modified_at ASC"
            ).map_err(|e| FileError::OperationError(e.to_string()))?;
            
            let file_iter = stmt.query_map([status_str], |row| Self::row_to_file_item(row))
                .map_err(|e| FileError::OperationError(e.to_string()))?;
            
            let mut files = Vec::new();
            for file_result in file_iter {
                let file = file_result.map_err(|e| FileError::OperationError(e.to_string()))?;
                files.push(file);
            }
            
            Ok(files)
        }).await.map_err(|e| FileError::OperationError(e.to_string()))?
    }
    
    async fn get_file_from_path(&self, path: &Path) -> FileResult<Option<FileItem>> {
        let pool = self.pool.clone();
        let path_str = path.to_string_lossy().to_string();
        
        task::spawn_blocking(move || {
            let conn = pool.get().map_err(|e| FileError::IOError(e.to_string()))?;
            
            let mut stmt = conn.prepare(
                "SELECT id, name, path, file_type, size, mime_type, parent_id, 
                        created_at, modified_at, sync_status, is_favorite, local_path,
                        encryption_status, encryption_iv, encryption_metadata
                 FROM files 
                 WHERE local_path = ?"
            ).map_err(|e| FileError::OperationError(e.to_string()))?;
            
            let result = stmt.query_row([&path_str], |row| Self::row_to_file_item(row));
            
            match result {
                Ok(file) => Ok(Some(file)),
                Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
                Err(e) => Err(FileError::OperationError(e.to_string())),
            }
        }).await.map_err(|e| FileError::OperationError(e.to_string()))?
    }
    
    async fn download_file_to_path(&self, file_id: &str, local_path: &Path) -> FileResult<()> {
        // Get the file first
        let mut file = self.get_file_by_id(file_id).await?;
        
        // If we already have a local copy, just make a new copy
        if let Some(existing_path) = &file.local_path {
            let src_path = PathBuf::from(existing_path);
            let dest_path = local_path.to_path_buf();
            
            task::spawn_blocking(move || {
                // Create parent directories if they don't exist
                if let Some(parent) = dest_path.parent() {
                    fs::create_dir_all(parent).map_err(|e| FileError::IOError(e.to_string()))?;
                }
                
                fs::copy(&src_path, &dest_path).map_err(|e| FileError::IOError(e.to_string()))?;
                
                Ok(())
            }).await.map_err(|e| FileError::OperationError(e.to_string()))?;
            
            return Ok(());
        }
        
        // Otherwise, we need to update the file record with the new local path
        file.local_path = Some(local_path.to_string_lossy().to_string());
        file.sync_status = SyncStatus::PendingDownload;
        
        // Update the file metadata
        self.update_file(file, None).await?;
        
        // We don't actually download the file here - that's handled by the sync service
        Ok(())
    }
    
    async fn upload_file_from_path(&self, local_path: &Path, parent_id: Option<&str>) -> FileResult<FileItem> {
        let path_str = local_path.to_string_lossy().to_string();
        
        // Check if the file already exists in our database
        if let Some(existing_file) = self.get_file_from_path(local_path).await? {
            return Ok(existing_file);
        }
        
        // Otherwise, create a new file record
        let metadata = task::spawn_blocking(move || {
            fs::metadata(&local_path).map_err(|e| FileError::IOError(e.to_string()))
        }).await.map_err(|e| FileError::OperationError(e.to_string()))?;
        
        let is_dir = metadata.is_dir();
        let size = if is_dir { 0 } else { metadata.len() };
        
        // Generate a new file ID
        let file_id = uuid::Uuid::new_v4().to_string();
        
        // Get the file name
        let name = local_path.file_name()
            .ok_or_else(|| FileError::InvalidArgumentError("Invalid file path".to_string()))?
            .to_string_lossy()
            .to_string();
        
        // Build the path string
        let mut path = String::new();
        if let Some(parent_id) = parent_id {
            // Get the parent folder
            let parent = self.get_file_by_id(parent_id).await?;
            path = format!("{}/{}", parent.path, name);
        } else {
            path = format!("/{}", name);
        }
        
        // Determine the file type
        let file_type = if is_dir {
            FileType::Folder
        } else {
            // Use the extension to guess the type
            let ext = local_path.extension()
                .map(|ext| ext.to_string_lossy().to_string().to_lowercase());
            
            match ext {
                Some(ext) if ["jpg", "jpeg", "png", "gif", "webp", "bmp", "svg"].contains(&ext.as_str()) => {
                    FileType::Image
                },
                Some(ext) if ["mp4", "avi", "mov", "wmv", "flv", "mkv", "webm"].contains(&ext.as_str()) => {
                    FileType::Video
                },
                Some(ext) if ["mp3", "wav", "ogg", "flac", "aac", "wma"].contains(&ext.as_str()) => {
                    FileType::Audio
                },
                Some(ext) if ["doc", "docx", "odt", "pdf", "txt", "rtf", "md"].contains(&ext.as_str()) => {
                    FileType::Document
                },
                Some(ext) if ["xls", "xlsx", "ods", "csv"].contains(&ext.as_str()) => {
                    FileType::Spreadsheet
                },
                Some(ext) if ["ppt", "pptx", "odp"].contains(&ext.as_str()) => {
                    FileType::Presentation
                },
                _ => FileType::File,
            }
        };
        
        // Determine MIME type
        let mime_type = if is_dir {
            None
        } else {
            mime_guess::from_path(local_path).first_raw().map(|s| s.to_string())
        };
        
        // Create the file item
        let file = FileItem {
            id: file_id,
            name,
            path,
            file_type,
            size,
            mime_type,
            parent_id: parent_id.map(|id| id.to_string()),
            created_at: Utc::now(),
            modified_at: Utc::now(),
            sync_status: SyncStatus::PendingUpload,
            is_favorite: false,
            local_path: Some(local_path.to_string_lossy().to_string()),
            encryption_status: EncryptionStatus::Unencrypted,
            encryption_iv: None,
            encryption_metadata: None,
        };
        
        // Save the file metadata
        if is_dir {
            self.create_folder(file).await
        } else {
            // Read the file content if it's not a directory
            let content = task::spawn_blocking(move || {
                fs::read(&local_path).map_err(|e| FileError::IOError(e.to_string()))
            }).await.map_err(|e| FileError::OperationError(e.to_string()))?;
            
            self.create_file(file, content).await
        }
    }
    
    async fn get_favorites(&self) -> FileResult<Vec<FileItem>> {
        let pool = self.pool.clone();
        
        task::spawn_blocking(move || {
            let conn = pool.get().map_err(|e| FileError::IOError(e.to_string()))?;
            
            let mut stmt = conn.prepare(
                "SELECT id, name, path, file_type, size, mime_type, parent_id, 
                        created_at, modified_at, sync_status, is_favorite, local_path,
                        encryption_status, encryption_iv, encryption_metadata
                 FROM files 
                 WHERE is_favorite = 1
                 ORDER BY name ASC"
            ).map_err(|e| FileError::OperationError(e.to_string()))?;
            
            let file_iter = stmt.query_map([], |row| Self::row_to_file_item(row))
                .map_err(|e| FileError::OperationError(e.to_string()))?;
            
            let mut files = Vec::new();
            for file_result in file_iter {
                let file = file_result.map_err(|e| FileError::OperationError(e.to_string()))?;
                files.push(file);
            }
            
            Ok(files)
        }).await.map_err(|e| FileError::OperationError(e.to_string()))?
    }
    
    async fn set_favorite(&self, file_id: &str, is_favorite: bool) -> FileResult<FileItem> {
        let mut file = self.get_file_by_id(file_id).await?;
        file.is_favorite = is_favorite;
        self.update_file(file, None).await
    }
}

/// Factory for creating SQLite file repositories
pub struct SqliteFileRepositoryFactory {
    pool: Pool<SqliteConnectionManager>,
}

impl SqliteFileRepositoryFactory {
    pub fn new(pool: Pool<SqliteConnectionManager>) -> Self {
        Self { pool }
    }
}

impl FileRepositoryFactory for SqliteFileRepositoryFactory {
    fn create_repository(&self) -> Arc<dyn FileRepository> {
        Arc::new(SqliteFileRepository::new(self.pool.clone()))
    }
}