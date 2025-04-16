use async_trait::async_trait;
use chrono::{DateTime, Utc};
use reqwest::{Client, RequestBuilder, Response, StatusCode};
use std::path::Path;
use std::sync::Arc;
use tokio::fs::{self, File};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::sync::Mutex;
use uuid::Uuid;
use tracing::{debug, error, info, warn};
use mime_guess::from_path;
use serde::{Serialize, Deserialize};

use crate::domain::entities::file::{FileError, FileItem, FileResult, FileType, SyncStatus};
use crate::domain::repositories::auth_repository::AuthRepository;
use crate::domain::repositories::file_repository::FileRepository;

/// WebDAV adapter for file operations
pub struct WebDAVAdapter {
    /// WebDAV client
    client: Client,
    /// Base WebDAV URL
    base_url: String,
    /// Authentication repository for user credentials
    auth_repository: Arc<dyn AuthRepository>,
    /// Cache of files
    files_cache: Arc<Mutex<Vec<FileItem>>>,
}

impl WebDAVAdapter {
    pub fn new(auth_repository: Arc<dyn AuthRepository>) -> Self {
        Self {
            client: Client::builder()
                .build()
                .expect("Failed to create HTTP client"),
            base_url: String::new(), // Will be set after login
            auth_repository: auth_repository,
            files_cache: Arc::new(Mutex::new(Vec::new())),
        }
    }
    
    /// Get current server URL from authenticated user
    async fn get_server_url(&self) -> FileResult<String> {
        let user = self.auth_repository.get_current_user().await
            .map_err(|e| FileError::AuthenticationError(e.to_string()))?
            .ok_or(FileError::AuthenticationError("Not logged in".to_string()))?;
        
        Ok(user.server_url.clone())
    }
    
    /// Get authentication token
    async fn get_auth_token(&self) -> FileResult<String> {
        let user = self.auth_repository.get_current_user().await
            .map_err(|e| FileError::AuthenticationError(e.to_string()))?
            .ok_or(FileError::AuthenticationError("Not logged in".to_string()))?;
        
        user.access_token.clone()
            .ok_or(FileError::AuthenticationError("No access token available".to_string()))
    }
    
    /// Create an authenticated WebDAV request
    async fn create_webdav_request(&self, method: reqwest::Method, path: &str) -> FileResult<RequestBuilder> {
        let token = self.get_auth_token().await?;
        let server_url = self.get_server_url().await?;
        let url = format!("{}/webdav/{}", server_url.trim_end_matches('/'), path.trim_start_matches('/'));
        
        let request = self.client.request(method, &url)
            .header("Authorization", format!("Bearer {}", token));
            
        Ok(request)
    }
    
    /// Handle WebDAV response errors
    async fn handle_response_error(&self, response: Response) -> FileError {
        let status = response.status();
        let body = response.text().await.unwrap_or_default();
        
        match status {
            StatusCode::UNAUTHORIZED => {
                FileError::AuthenticationError("Authentication failed".to_string())
            },
            StatusCode::FORBIDDEN => {
                FileError::PermissionError("Access denied".to_string())
            },
            StatusCode::NOT_FOUND => {
                FileError::NotFoundError("File not found".to_string())
            },
            _ => {
                FileError::ServerError(format!("Server error ({}): {}", status, body))
            }
        }
    }
    
    /// Parse WebDAV PROPFIND response XML
    fn parse_propfind_response(&self, xml: &str, parent_path: &str) -> FileResult<Vec<FileItem>> {
        // For a real implementation, this would use an XML parser
        // This is a simplified version that just extracts basic file info
        
        let mut files = Vec::new();
        
        // Simple XML parsing using regex
        let re_href = regex::Regex::new(r"<d:href>(.*?)</d:href>").unwrap();
        let re_displayname = regex::Regex::new(r"<d:displayname>(.*?)</d:displayname>").unwrap();
        let re_getlastmodified = regex::Regex::new(r"<d:getlastmodified>(.*?)</d:getlastmodified>").unwrap();
        let re_getcontentlength = regex::Regex::new(r"<d:getcontentlength>(.*?)</d:getcontentlength>").unwrap();
        let re_resourcetype = regex::Regex::new(r"<d:resourcetype>(.*?)</d:resourcetype>").unwrap();
        let re_getcontenttype = regex::Regex::new(r"<d:getcontenttype>(.*?)</d:getcontenttype>").unwrap();
        
        // Split by response element
        let responses: Vec<&str> = xml.split("<d:response>").collect();
        
        for response in responses.iter().skip(1) { // Skip the first empty part
            let href = re_href.captures(response)
                .and_then(|cap| cap.get(1))
                .map(|m| m.as_str().to_string())
                .unwrap_or_default();
                
            if href.is_empty() || href == parent_path { 
                continue; // Skip the parent directory
            }
            
            let name = re_displayname.captures(response)
                .and_then(|cap| cap.get(1))
                .map(|m| m.as_str().to_string())
                .unwrap_or_else(|| {
                    // Extract name from href
                    href.split('/')
                        .filter(|s| !s.is_empty())
                        .last()
                        .unwrap_or("")
                        .to_string()
                });
                
            let modified_str = re_getlastmodified.captures(response)
                .and_then(|cap| cap.get(1))
                .map(|m| m.as_str().to_string())
                .unwrap_or_default();
                
            let modified_at = if !modified_str.is_empty() {
                // Parse HTTP date format
                httpdate::parse_http_date(&modified_str)
                    .map(|time| DateTime::<Utc>::from(time))
                    .unwrap_or_else(|_| Utc::now())
            } else {
                Utc::now()
            };
                
            let size_str = re_getcontentlength.captures(response)
                .and_then(|cap| cap.get(1))
                .map(|m| m.as_str().to_string())
                .unwrap_or_default();
                
            let size = size_str.parse::<u64>().unwrap_or(0);
            
            let is_directory = re_resourcetype.captures(response)
                .and_then(|cap| cap.get(1))
                .map(|m| m.as_str().contains("<d:collection/>"))
                .unwrap_or(false);
                
            let content_type = re_getcontenttype.captures(response)
                .and_then(|cap| cap.get(1))
                .map(|m| m.as_str().to_string());
                
            // Normalize paths
            let clean_href = href.trim_start_matches("/webdav/")
                .trim_end_matches('/')
                .to_string();
                
            // Determine parent ID (from parent path)
            let parent_id = if let Some(parent) = Path::new(&clean_href).parent() {
                if parent.to_string_lossy() != "." {
                    // In a real implementation, you'd look up the parent ID
                    // For now, just use the path as an identifier
                    Some(parent.to_string_lossy().to_string())
                } else {
                    None
                }
            } else {
                None
            };
            
            let file_item = FileItem {
                id: Uuid::new_v4().to_string(), // Generate a unique ID
                name,
                path: clean_href.clone(),
                file_type: if is_directory { FileType::Directory } else { FileType::File },
                size,
                mime_type: content_type,
                parent_id,
                created_at: modified_at, // WebDAV doesn't typically expose creation time
                modified_at,
                sync_status: SyncStatus::Synced,
                is_favorite: false,
                local_path: None,
            };
            
            files.push(file_item);
        }
        
        Ok(files)
    }
    
    /// Check if a WebDAV item exists
    async fn item_exists(&self, path: &str) -> FileResult<bool> {
        let request = self.create_webdav_request(reqwest::Method::HEAD, path).await?;
        let response = request.send().await
            .map_err(|e| FileError::NetworkError(e.to_string()))?;
        
        Ok(response.status() == StatusCode::OK)
    }
}

#[async_trait]
impl FileRepository for WebDAVAdapter {
    async fn get_file_by_id(&self, file_id: &str) -> FileResult<FileItem> {
        // First check in cache
        let files = self.files_cache.lock().await;
        if let Some(file) = files.iter().find(|f| f.id == file_id) {
            return Ok(file.clone());
        }
        
        // If not in cache, we need to find the file
        // For WebDAV, we'd typically need to know the path
        // This is challenging with just an ID, but we can search for it
        Err(FileError::NotFoundError(format!("File not found: {}", file_id)))
    }
    
    async fn get_files_by_folder(&self, folder_id: Option<&str>) -> FileResult<Vec<FileItem>> {
        let path = match folder_id {
            Some(id) => {
                // Look up the path from the ID
                let files = self.files_cache.lock().await;
                let folder = files.iter().find(|f| f.id == id)
                    .ok_or_else(|| FileError::NotFoundError(format!("Folder not found: {}", id)))?;
                folder.path.clone()
            },
            None => "".to_string(), // Root folder
        };
        
        // WebDAV PROPFIND request
        let request = self.create_webdav_request(reqwest::Method::from_bytes(b"PROPFIND").unwrap(), &path).await?
            .header("Depth", "1")
            .header("Content-Type", "application/xml")
            .body(r#"<?xml version="1.0" encoding="utf-8" ?>
                <d:propfind xmlns:d="DAV:">
                    <d:prop>
                        <d:displayname/>
                        <d:getcontentlength/>
                        <d:getlastmodified/>
                        <d:resourcetype/>
                        <d:getcontenttype/>
                    </d:prop>
                </d:propfind>"#);
        
        let response = request.send().await
            .map_err(|e| FileError::NetworkError(e.to_string()))?;
            
        if !response.status().is_success() {
            return Err(self.handle_response_error(response).await);
        }
        
        let xml = response.text().await
            .map_err(|e| FileError::FormatError(e.to_string()))?;
            
        let files = self.parse_propfind_response(&xml, &path)?;
        
        // Update cache
        let mut cache = self.files_cache.lock().await;
        
        // Remove files from this folder
        cache.retain(|f| f.parent_id.as_deref() != folder_id);
        
        // Add the new files
        cache.extend(files.clone());
        
        Ok(files)
    }
    
    async fn get_file_content(&self, file_id: &str) -> FileResult<Vec<u8>> {
        // Get file info
        let file = self.get_file_by_id(file_id).await?;
        
        // WebDAV GET request
        let request = self.create_webdav_request(reqwest::Method::GET, &file.path).await?;
        let response = request.send().await
            .map_err(|e| FileError::NetworkError(e.to_string()))?;
            
        if !response.status().is_success() {
            return Err(self.handle_response_error(response).await);
        }
        
        let bytes = response.bytes().await
            .map_err(|e| FileError::NetworkError(e.to_string()))?;
            
        Ok(bytes.to_vec())
    }
    
    async fn create_file(&self, file: FileItem, content: Vec<u8>) -> FileResult<FileItem> {
        // Ensure parent folder exists
        if let Some(parent_id) = &file.parent_id {
            let parent = self.get_file_by_id(parent_id).await?;
            
            // Check if parent folder exists on server
            let parent_exists = self.item_exists(&parent.path).await?;
            if !parent_exists {
                return Err(FileError::NotFoundError(format!("Parent folder not found: {}", parent_id)));
            }
        }
        
        // Create path for new file
        let path = match &file.parent_id {
            Some(parent_id) => {
                let parent = self.get_file_by_id(parent_id).await?;
                format!("{}/{}", parent.path, file.name)
            },
            None => {
                file.name.clone()
            }
        };
        
        // WebDAV PUT request
        let request = self.create_webdav_request(reqwest::Method::PUT, &path).await?
            .body(content);
            
        let response = request.send().await
            .map_err(|e| FileError::NetworkError(e.to_string()))?;
            
        if !response.status().is_success() {
            return Err(self.handle_response_error(response).await);
        }
        
        // Get updated file info
        // WebDAV PROPFIND request for the new file
        let request = self.create_webdav_request(reqwest::Method::from_bytes(b"PROPFIND").unwrap(), &path).await?
            .header("Depth", "0")
            .header("Content-Type", "application/xml")
            .body(r#"<?xml version="1.0" encoding="utf-8" ?>
                <d:propfind xmlns:d="DAV:">
                    <d:prop>
                        <d:displayname/>
                        <d:getcontentlength/>
                        <d:getlastmodified/>
                        <d:resourcetype/>
                        <d:getcontenttype/>
                    </d:prop>
                </d:propfind>"#);
                
        let response = request.send().await
            .map_err(|e| FileError::NetworkError(e.to_string()))?;
            
        if !response.status().is_success() {
            // If we can't get the file info, return a basic file
            let new_file = FileItem {
                id: Uuid::new_v4().to_string(),
                name: file.name,
                path,
                file_type: FileType::File,
                size: content.len() as u64,
                mime_type: file.mime_type,
                parent_id: file.parent_id,
                created_at: Utc::now(),
                modified_at: Utc::now(),
                sync_status: SyncStatus::Synced,
                is_favorite: false,
                local_path: None,
            };
            
            // Update cache
            let mut cache = self.files_cache.lock().await;
            cache.push(new_file.clone());
            
            return Ok(new_file);
        }
        
        let xml = response.text().await
            .map_err(|e| FileError::FormatError(e.to_string()))?;
            
        let files = self.parse_propfind_response(&xml, "")?;
        if files.is_empty() {
            return Err(FileError::OperationError("Failed to get file info after creation".to_string()));
        }
        
        let new_file = files[0].clone();
        
        // Update cache
        let mut cache = self.files_cache.lock().await;
        cache.push(new_file.clone());
        
        Ok(new_file)
    }
    
    async fn update_file(&self, file: FileItem, content: Option<Vec<u8>>) -> FileResult<FileItem> {
        // Get current file to get the path
        let current_file = self.get_file_by_id(&file.id).await?;
        
        // If the name or parent changed, we need to move the file
        if current_file.name != file.name || current_file.parent_id != file.parent_id {
            // Create new path
            let new_path = match &file.parent_id {
                Some(parent_id) => {
                    let parent = self.get_file_by_id(parent_id).await?;
                    format!("{}/{}", parent.path, file.name)
                },
                None => {
                    file.name.clone()
                }
            };
            
            // WebDAV MOVE request
            let request = self.create_webdav_request(reqwest::Method::from_bytes(b"MOVE").unwrap(), &current_file.path).await?
                .header("Destination", format!("/webdav/{}", new_path))
                .header("Overwrite", "T");
                
            let response = request.send().await
                .map_err(|e| FileError::NetworkError(e.to_string()))?;
                
            if !response.status().is_success() {
                return Err(self.handle_response_error(response).await);
            }
            
            // If we have content to update
            if let Some(data) = content {
                // WebDAV PUT request to update content
                let request = self.create_webdav_request(reqwest::Method::PUT, &new_path).await?
                    .body(data);
                    
                let response = request.send().await
                    .map_err(|e| FileError::NetworkError(e.to_string()))?;
                    
                if !response.status().is_success() {
                    return Err(self.handle_response_error(response).await);
                }
            }
            
            // Get updated file info
            // Update cache
            let mut cache = self.files_cache.lock().await;
            for stored_file in cache.iter_mut() {
                if stored_file.id == file.id {
                    stored_file.name = file.name.clone();
                    stored_file.path = new_path.clone();
                    stored_file.parent_id = file.parent_id.clone();
                    stored_file.modified_at = Utc::now();
                    if let Some(ref data) = content {
                        stored_file.size = data.len() as u64;
                    }
                    return Ok(stored_file.clone());
                }
            }
            
            // If not found in cache, return the updated file
            let updated_file = FileItem {
                id: file.id,
                name: file.name,
                path: new_path,
                file_type: file.file_type,
                size: if let Some(ref data) = content { data.len() as u64 } else { file.size },
                mime_type: file.mime_type,
                parent_id: file.parent_id,
                created_at: file.created_at,
                modified_at: Utc::now(),
                sync_status: SyncStatus::Synced,
                is_favorite: file.is_favorite,
                local_path: file.local_path,
            };
            
            cache.push(updated_file.clone());
            
            Ok(updated_file)
        } else if let Some(data) = content {
            // Just content update
            // WebDAV PUT request
            let request = self.create_webdav_request(reqwest::Method::PUT, &current_file.path).await?
                .body(data.clone());
                
            let response = request.send().await
                .map_err(|e| FileError::NetworkError(e.to_string()))?;
                
            if !response.status().is_success() {
                return Err(self.handle_response_error(response).await);
            }
            
            // Update cache
            let mut cache = self.files_cache.lock().await;
            for stored_file in cache.iter_mut() {
                if stored_file.id == file.id {
                    stored_file.modified_at = Utc::now();
                    stored_file.size = data.len() as u64;
                    return Ok(stored_file.clone());
                }
            }
            
            // If not found in cache, return the updated file
            let updated_file = FileItem {
                id: file.id,
                name: file.name,
                path: current_file.path,
                file_type: file.file_type,
                size: data.len() as u64,
                mime_type: file.mime_type,
                parent_id: file.parent_id,
                created_at: file.created_at,
                modified_at: Utc::now(),
                sync_status: SyncStatus::Synced,
                is_favorite: file.is_favorite,
                local_path: file.local_path,
            };
            
            cache.push(updated_file.clone());
            
            Ok(updated_file)
        } else {
            // No changes needed
            Ok(current_file)
        }
    }
    
    async fn delete_file(&self, file_id: &str) -> FileResult<()> {
        // Get file to get the path
        let file = self.get_file_by_id(file_id).await?;
        
        // WebDAV DELETE request
        let request = self.create_webdav_request(reqwest::Method::DELETE, &file.path).await?;
        let response = request.send().await
            .map_err(|e| FileError::NetworkError(e.to_string()))?;
            
        if !response.status().is_success() {
            return Err(self.handle_response_error(response).await);
        }
        
        // Update cache
        let mut cache = self.files_cache.lock().await;
        cache.retain(|f| f.id != file_id);
        
        Ok(())
    }
    
    async fn create_folder(&self, folder: FileItem) -> FileResult<FileItem> {
        // Create path for new folder
        let path = match &folder.parent_id {
            Some(parent_id) => {
                let parent = self.get_file_by_id(parent_id).await?;
                format!("{}/{}", parent.path, folder.name)
            },
            None => {
                folder.name.clone()
            }
        };
        
        // WebDAV MKCOL request
        let request = self.create_webdav_request(reqwest::Method::from_bytes(b"MKCOL").unwrap(), &path).await?;
        let response = request.send().await
            .map_err(|e| FileError::NetworkError(e.to_string()))?;
            
        if !response.status().is_success() {
            return Err(self.handle_response_error(response).await);
        }
        
        // Get updated folder info
        // WebDAV PROPFIND request for the new folder
        let request = self.create_webdav_request(reqwest::Method::from_bytes(b"PROPFIND").unwrap(), &path).await?
            .header("Depth", "0")
            .header("Content-Type", "application/xml")
            .body(r#"<?xml version="1.0" encoding="utf-8" ?>
                <d:propfind xmlns:d="DAV:">
                    <d:prop>
                        <d:displayname/>
                        <d:getcontentlength/>
                        <d:getlastmodified/>
                        <d:resourcetype/>
                    </d:prop>
                </d:propfind>"#);
                
        let response = request.send().await
            .map_err(|e| FileError::NetworkError(e.to_string()))?;
            
        if !response.status().is_success() {
            // If we can't get the folder info, return a basic folder
            let new_folder = FileItem {
                id: Uuid::new_v4().to_string(),
                name: folder.name,
                path,
                file_type: FileType::Directory,
                size: 0,
                mime_type: Some("application/directory".to_string()),
                parent_id: folder.parent_id,
                created_at: Utc::now(),
                modified_at: Utc::now(),
                sync_status: SyncStatus::Synced,
                is_favorite: false,
                local_path: None,
            };
            
            // Update cache
            let mut cache = self.files_cache.lock().await;
            cache.push(new_folder.clone());
            
            return Ok(new_folder);
        }
        
        let xml = response.text().await
            .map_err(|e| FileError::FormatError(e.to_string()))?;
            
        let folders = self.parse_propfind_response(&xml, "")?;
        if folders.is_empty() {
            return Err(FileError::OperationError("Failed to get folder info after creation".to_string()));
        }
        
        let new_folder = folders[0].clone();
        
        // Update cache
        let mut cache = self.files_cache.lock().await;
        cache.push(new_folder.clone());
        
        Ok(new_folder)
    }
    
    async fn delete_folder(&self, folder_id: &str, recursive: bool) -> FileResult<()> {
        // Get folder to get the path
        let folder = self.get_file_by_id(folder_id).await?;
        
        if !recursive {
            // Check if folder is empty
            let request = self.create_webdav_request(reqwest::Method::from_bytes(b"PROPFIND").unwrap(), &folder.path).await?
                .header("Depth", "1")
                .header("Content-Type", "application/xml")
                .body(r#"<?xml version="1.0" encoding="utf-8" ?>
                    <d:propfind xmlns:d="DAV:">
                        <d:prop>
                            <d:displayname/>
                        </d:prop>
                    </d:propfind>"#);
                    
            let response = request.send().await
                .map_err(|e| FileError::NetworkError(e.to_string()))?;
                
            if !response.status().is_success() {
                return Err(self.handle_response_error(response).await);
            }
            
            let xml = response.text().await
                .map_err(|e| FileError::FormatError(e.to_string()))?;
                
            let files = self.parse_propfind_response(&xml, &folder.path)?;
            if !files.is_empty() {
                return Err(FileError::OperationError("Folder is not empty".to_string()));
            }
        }
        
        // WebDAV DELETE request
        let request = self.create_webdav_request(reqwest::Method::DELETE, &folder.path).await?;
        let response = request.send().await
            .map_err(|e| FileError::NetworkError(e.to_string()))?;
            
        if !response.status().is_success() {
            return Err(self.handle_response_error(response).await);
        }
        
        // Update cache
        let mut cache = self.files_cache.lock().await;
        
        // Remove folder itself
        cache.retain(|f| f.id != folder_id);
        
        // Remove files within the folder if recursive
        if recursive {
            cache.retain(|f| !f.path.starts_with(&folder.path));
        }
        
        Ok(())
    }
    
    async fn get_changed_files(&self, since: Option<DateTime<Utc>>) -> FileResult<Vec<FileItem>> {
        // WebDAV doesn't have a standard way to get changed files
        // We could do a full recursive PROPFIND and filter by modification time
        // For simplicity in this example, let's just get files from root and filter
        
        let request = self.create_webdav_request(reqwest::Method::from_bytes(b"PROPFIND").unwrap(), "").await?
            .header("Depth", "infinity") // Note: This could be expensive on large collections
            .header("Content-Type", "application/xml")
            .body(r#"<?xml version="1.0" encoding="utf-8" ?>
                <d:propfind xmlns:d="DAV:">
                    <d:prop>
                        <d:displayname/>
                        <d:getcontentlength/>
                        <d:getlastmodified/>
                        <d:resourcetype/>
                        <d:getcontenttype/>
                    </d:prop>
                </d:propfind>"#);
                
        let response = request.send().await
            .map_err(|e| FileError::NetworkError(e.to_string()))?;
            
        if !response.status().is_success() {
            return Err(self.handle_response_error(response).await);
        }
        
        let xml = response.text().await
            .map_err(|e| FileError::FormatError(e.to_string()))?;
            
        let files = self.parse_propfind_response(&xml, "")?;
        
        // Filter by modification time if since provided
        let filtered_files = if let Some(time) = since {
            files.into_iter()
                .filter(|f| f.modified_at > time)
                .collect()
        } else {
            files
        };
        
        // Update cache with all files
        let mut cache = self.files_cache.lock().await;
        *cache = filtered_files.clone();
        
        Ok(filtered_files)
    }
    
    async fn get_files_by_sync_status(&self, status: SyncStatus) -> FileResult<Vec<FileItem>> {
        // WebDAV doesn't track sync status - that's client-side logic
        // Just return files from cache with the requested status
        let cache = self.files_cache.lock().await;
        let matching_files = cache.iter()
            .filter(|f| f.sync_status == status)
            .cloned()
            .collect();
            
        Ok(matching_files)
    }
    
    async fn get_file_from_path(&self, path: &Path) -> FileResult<Option<FileItem>> {
        let path_str = path.to_string_lossy().to_string();
        
        // Check cache first
        let cache = self.files_cache.lock().await;
        if let Some(file) = cache.iter().find(|f| f.path == path_str) {
            return Ok(Some(file.clone()));
        }
        
        // If not in cache, try to get from server
        let request = self.create_webdav_request(reqwest::Method::from_bytes(b"PROPFIND").unwrap(), &path_str).await?
            .header("Depth", "0")
            .header("Content-Type", "application/xml")
            .body(r#"<?xml version="1.0" encoding="utf-8" ?>
                <d:propfind xmlns:d="DAV:">
                    <d:prop>
                        <d:displayname/>
                        <d:getcontentlength/>
                        <d:getlastmodified/>
                        <d:resourcetype/>
                        <d:getcontenttype/>
                    </d:prop>
                </d:propfind>"#);
                
        let response = request.send().await
            .map_err(|e| FileError::NetworkError(e.to_string()))?;
            
        if response.status() == StatusCode::NOT_FOUND {
            return Ok(None);
        }
        
        if !response.status().is_success() {
            return Err(self.handle_response_error(response).await);
        }
        
        let xml = response.text().await
            .map_err(|e| FileError::FormatError(e.to_string()))?;
            
        let files = self.parse_propfind_response(&xml, "")?;
        
        if files.is_empty() {
            return Ok(None);
        }
        
        // Update cache
        drop(cache);
        let mut cache = self.files_cache.lock().await;
        
        // Remove existing entry if any
        cache.retain(|f| f.path != path_str);
        
        // Add new one
        cache.push(files[0].clone());
        
        Ok(Some(files[0].clone()))
    }
    
    async fn download_file_to_path(&self, file_id: &str, local_path: &Path) -> FileResult<()> {
        // Get file content
        let content = self.get_file_content(file_id).await?;
        
        // Ensure parent directories exist
        if let Some(parent) = local_path.parent() {
            fs::create_dir_all(parent).await
                .map_err(|e| FileError::IOError(format!("Failed to create directories: {}", e)))?;
        }
        
        // Write to file
        let mut file = File::create(local_path).await
            .map_err(|e| FileError::IOError(format!("Failed to create file: {}", e)))?;
            
        file.write_all(&content).await
            .map_err(|e| FileError::IOError(format!("Failed to write file: {}", e)))?;
            
        Ok(())
    }
    
    async fn upload_file_from_path(&self, local_path: &Path, parent_id: Option<&str>) -> FileResult<FileItem> {
        // Read file
        let mut file = File::open(local_path).await
            .map_err(|e| FileError::IOError(format!("Failed to open file: {}", e)))?;
            
        let mut content = Vec::new();
        file.read_to_end(&mut content).await
            .map_err(|e| FileError::IOError(format!("Failed to read file: {}", e)))?;
            
        // Get file name
        let name = local_path.file_name()
            .ok_or_else(|| FileError::InvalidArgumentError("Invalid path".to_string()))?
            .to_string_lossy()
            .to_string();
            
        // Get mime type
        let mime = from_path(local_path).first_or_octet_stream().to_string();
        
        // Create file item
        let file_item = FileItem {
            id: Uuid::new_v4().to_string(),
            name,
            path: String::new(), // Will be set by create_file
            file_type: FileType::File,
            size: content.len() as u64,
            mime_type: Some(mime),
            parent_id: parent_id.map(|s| s.to_string()),
            created_at: Utc::now(),
            modified_at: Utc::now(),
            sync_status: SyncStatus::Synced,
            is_favorite: false,
            local_path: Some(local_path.to_string_lossy().to_string()),
        };
        
        // Create file on server
        self.create_file(file_item, content).await
    }
    
    async fn get_favorites(&self) -> FileResult<Vec<FileItem>> {
        // WebDAV doesn't have a standard concept of favorites
        // This would typically be implemented with a custom property
        // For simplicity, we'll just return files from cache that are marked as favorites
        let cache = self.files_cache.lock().await;
        let matching_files = cache.iter()
            .filter(|f| f.is_favorite)
            .cloned()
            .collect();
            
        Ok(matching_files)
    }
    
    async fn set_favorite(&self, file_id: &str, is_favorite: bool) -> FileResult<FileItem> {
        // Get the file
        let file = self.get_file_by_id(file_id).await?;
        
        // WebDAV PROPPATCH request to set custom property
        // This is a simplified version; many WebDAV servers may not support this
        let property_xml = format!(r#"<?xml version="1.0" encoding="utf-8" ?>
            <d:propertyupdate xmlns:d="DAV:" xmlns:oc="http://owncloud.org/ns">
                <d:set>
                    <d:prop>
                        <oc:favorite>{}</oc:favorite>
                    </d:prop>
                </d:set>
            </d:propertyupdate>"#, if is_favorite { "1" } else { "0" });
            
        let request = self.create_webdav_request(reqwest::Method::from_bytes(b"PROPPATCH").unwrap(), &file.path).await?
            .header("Content-Type", "application/xml")
            .body(property_xml);
            
        let response = request.send().await
            .map_err(|e| FileError::NetworkError(e.to_string()))?;
            
        // We'll consider it successful even if the server doesn't support favorites
        
        // Update cache
        let mut cache = self.files_cache.lock().await;
        for stored_file in cache.iter_mut() {
            if stored_file.id == file_id {
                stored_file.is_favorite = is_favorite;
                return Ok(stored_file.clone());
            }
        }
        
        // If not in cache, update the original file
        let mut updated_file = file.clone();
        updated_file.is_favorite = is_favorite;
        
        // Add to cache
        cache.push(updated_file.clone());
        
        Ok(updated_file)
    }
}

/// Factory for creating WebDAVAdapter
pub struct WebDAVAdapterFactory {
    auth_repository: Arc<dyn AuthRepository>,
}

impl WebDAVAdapterFactory {
    pub fn new(auth_repository: Arc<dyn AuthRepository>) -> Self {
        Self { auth_repository }
    }
}

impl crate::domain::repositories::file_repository::FileRepositoryFactory for WebDAVAdapterFactory {
    fn create_repository(&self) -> Arc<dyn FileRepository> {
        Arc::new(WebDAVAdapter::new(self.auth_repository.clone()))
    }
}