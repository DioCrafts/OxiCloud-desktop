use std::sync::Arc;

use anyhow::{Result, anyhow};
use log::debug;
use reqwest::Method;
use uuid::Uuid;

use crate::domain::models::folder::Folder;
use crate::domain::models::file::File;
use crate::infrastructure::adapters::http_client::HttpClient;
use crate::infrastructure::adapters::webdav_adapter::WebDavAdapter;

/// Adapter for folder operations with OxiCloud server
pub struct FolderAdapter {
    /// HTTP client for API requests
    http_client: Arc<HttpClient>,
    
    /// WebDAV adapter for file operations
    webdav_adapter: Arc<WebDavAdapter>,
}

impl FolderAdapter {
    /// Create a new folder adapter
    pub fn new(http_client: Arc<HttpClient>, webdav_adapter: Arc<WebDavAdapter>) -> Self {
        Self {
            http_client,
            webdav_adapter,
        }
    }
    
    /// Get a folder by its ID
    pub async fn get_folder(&self, id: &str) -> Result<Option<Folder>> {
        debug!("Getting folder with ID: {}", id);
        
        // For this example, we'll use WebDAV PROPFIND
        // In a real implementation, we might use a specialized API endpoint
        
        // Simplified implementation
        // Create a mock folder for demonstration
        let folder = Folder::new(
            id.to_string(),
            "Example Folder".to_string(),
            "/Example Folder".to_string(),
            Some("root".to_string()),
        );
        
        Ok(Some(folder))
    }
    
    /// Create a new folder
    pub async fn create_folder(&self, parent_id: &str, name: &str) -> Result<Folder> {
        debug!("Creating folder '{}' in parent '{}'", name, parent_id);
        
        // In WebDAV, we use MKCOL method to create collections (folders)
        let method = Method::from_bytes(b"MKCOL").expect("MKCOL is a valid HTTP method");
        
        // Determine the folder path
        let path = if parent_id == "root" {
            format!("/{}", name)
        } else {
            format!("/{}/{}", parent_id, name)
        };
        
        // Make the WebDAV request
        let request = self.http_client.request_raw(method, &path).await?;
        let response = request.send().await?;
        
        if response.status().is_success() {
            // Create and return the new folder
            let folder = Folder::new(
                Uuid::new_v4().to_string(), // Generate a new ID
                name.to_string(),
                path,
                Some(parent_id.to_string()),
            );
            
            return Ok(folder);
        }
        
        Err(anyhow!("Failed to create folder: {}", response.status()))
    }
    
    /// Delete a folder
    pub async fn delete_folder(&self, id: &str) -> Result<()> {
        debug!("Deleting folder with ID: {}", id);
        
        // Map ID to path
        let folder = self.get_folder(id).await?.ok_or_else(|| {
            anyhow!("Folder not found")
        })?;
        
        // Make the WebDAV DELETE request
        let request = self.http_client.request_raw(Method::DELETE, &folder.path).await?;
        let response = request.send().await?;
        
        if response.status().is_success() {
            return Ok(());
        }
        
        Err(anyhow!("Failed to delete folder: {}", response.status()))
    }
    
    /// Rename a folder
    pub async fn rename_folder(&self, id: &str, new_name: &str) -> Result<Folder> {
        debug!("Renaming folder '{}' to '{}'", id, new_name);
        
        // Map ID to path
        let folder = self.get_folder(id).await?.ok_or_else(|| {
            anyhow!("Folder not found")
        })?;
        
        // Determine the new path
        let parent_path = folder.path.rsplit_once('/').map(|(parent, _)| parent).unwrap_or("");
        let new_path = format!("{}/{}", parent_path, new_name);
        
        // WebDAV MOVE request
        let method = Method::from_bytes(b"MOVE").expect("MOVE is a valid HTTP method");
        let request = self.http_client.request_raw(method, &folder.path).await?;
        
        let request = request
            .header("Destination", &new_path)
            .header("Overwrite", "F");
        
        let response = request.send().await?;
        
        if response.status().is_success() {
            // Create a new folder object with updated properties
            let mut new_folder = folder.clone();
            new_folder.name = new_name.to_string();
            new_folder.path = new_path;
            
            return Ok(new_folder);
        }
        
        Err(anyhow!("Failed to rename folder: {}", response.status()))
    }
    
    /// Move a folder to a different parent
    pub async fn move_folder(&self, id: &str, new_parent_id: &str) -> Result<Folder> {
        debug!("Moving folder '{}' to parent '{}'", id, new_parent_id);
        
        // Map IDs to paths
        let folder = self.get_folder(id).await?.ok_or_else(|| {
            anyhow!("Folder not found")
        })?;
        
        let new_parent = self.get_folder(new_parent_id).await?.ok_or_else(|| {
            anyhow!("Parent folder not found")
        })?;
        
        // Determine the new path
        let new_path = format!("{}/{}", new_parent.path, folder.name);
        
        // WebDAV MOVE request
        let method = Method::from_bytes(b"MOVE").expect("MOVE is a valid HTTP method");
        let request = self.http_client.request_raw(method, &folder.path).await?;
        
        let request = request
            .header("Destination", &new_path)
            .header("Overwrite", "F");
        
        let response = request.send().await?;
        
        if response.status().is_success() {
            // Create a new folder object with updated properties
            let mut new_folder = folder.clone();
            new_folder.path = new_path;
            new_folder.parent_id = Some(new_parent_id.to_string());
            
            return Ok(new_folder);
        }
        
        Err(anyhow!("Failed to move folder: {}", response.status()))
    }
    
    /// Get the contents of a folder (files and subfolders)
    pub async fn get_folder_contents(&self, id: &str) -> Result<(Vec<File>, Vec<Folder>)> {
        debug!("Getting contents of folder: {}", id);
        
        // Map ID to path
        let _folder = self.get_folder(id).await?.ok_or_else(|| {
            anyhow!("Folder not found")
        })?;
        
        // Use WebDAV PROPFIND with depth 1 to get the folder contents
        // This is a simplified implementation
        
        // For this example, we'll return empty lists
        Ok((Vec::new(), Vec::new()))
    }
    
    /// Set a folder as favorite or not
    pub async fn set_favorite(&self, id: &str, is_favorite: bool) -> Result<Folder> {
        debug!("Setting favorite status to {} for folder {}", is_favorite, id);
        
        // Map ID to folder
        let mut folder = self.get_folder(id).await?.ok_or_else(|| {
            anyhow!("Folder not found")
        })?;
        
        // In OxiCloud, this would typically be a separate API endpoint
        // For this example, we'll just update the local object
        folder.is_favorite = is_favorite;
        
        Ok(folder)
    }
}