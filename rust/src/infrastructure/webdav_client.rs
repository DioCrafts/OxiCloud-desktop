//! # WebDAV Client
//!
//! WebDAV protocol implementation for remote file operations.

use std::sync::Arc;
use async_trait::async_trait;
use tokio::sync::RwLock;
use reqwest::{Client, StatusCode};
use quick_xml::{Reader, events::Event};
use chrono::{DateTime, Utc};

use crate::domain::ports::{SyncPort, SyncResult, SyncError, RemoteItem};

/// WebDAV client implementation
pub struct WebDavClient {
    client: Client,
    config: Arc<RwLock<Option<WebDavConfig>>>,
}

#[derive(Clone)]
struct WebDavConfig {
    base_url: String,
    username: String,
    access_token: String,
}

impl WebDavClient {
    /// Create a new WebDAV client
    pub fn new() -> Self {
        Self {
            client: Client::builder()
                .timeout(std::time::Duration::from_secs(30))
                .build()
                .expect("Failed to create HTTP client"),
            config: Arc::new(RwLock::new(None)),
        }
    }
    
    /// Build request with authentication
    async fn request(&self, method: reqwest::Method, path: &str) -> SyncResult<reqwest::RequestBuilder> {
        let config = self.config.read().await;
        let config = config.as_ref()
            .ok_or_else(|| SyncError::AuthenticationFailed("Not configured".to_string()))?;
        
        let url = format!("{}{}", config.base_url, path);
        
        Ok(self.client
            .request(method, &url)
            .header("Authorization", format!("Bearer {}", config.access_token)))
    }
    
    /// Parse WebDAV multistatus response
    fn parse_multistatus(&self, xml: &str) -> SyncResult<Vec<RemoteItem>> {
        let mut reader = Reader::from_str(xml);
        reader.trim_text(true);
        
        let mut items = Vec::new();
        let mut current_item: Option<PartialRemoteItem> = None;
        let mut current_tag = String::new();
        let mut buf = Vec::new();
        
        loop {
            match reader.read_event_into(&mut buf) {
                Ok(Event::Start(ref e)) => {
                    let tag = String::from_utf8_lossy(e.name().as_ref()).to_string();
                    current_tag = tag.clone();
                    
                    if tag.ends_with("response") {
                        current_item = Some(PartialRemoteItem::default());
                    }
                }
                Ok(Event::Text(e)) => {
                    if let Some(ref mut item) = current_item {
                        let text = e.unescape().unwrap_or_default().to_string();
                        
                        if current_tag.ends_with("href") {
                            item.path = Some(text);
                        } else if current_tag.ends_with("displayname") {
                            item.name = Some(text);
                        } else if current_tag.ends_with("getcontentlength") {
                            item.size = text.parse().ok();
                        } else if current_tag.ends_with("getlastmodified") {
                            item.modified = DateTime::parse_from_rfc2822(&text)
                                .ok()
                                .map(|dt| dt.with_timezone(&Utc));
                        } else if current_tag.ends_with("getetag") {
                            item.etag = Some(text.trim_matches('"').to_string());
                        } else if current_tag.ends_with("getcontenttype") {
                            item.mime_type = Some(text);
                        }
                    }
                }
                Ok(Event::Empty(ref e)) => {
                    if let Some(ref mut item) = current_item {
                        let tag = String::from_utf8_lossy(e.name().as_ref()).to_string();
                        if tag.ends_with("collection") {
                            item.is_directory = true;
                        }
                    }
                }
                Ok(Event::End(ref e)) => {
                    let tag = String::from_utf8_lossy(e.name().as_ref()).to_string();
                    
                    if tag.ends_with("response") {
                        if let Some(item) = current_item.take() {
                            if let Some(remote_item) = item.into_remote_item() {
                                items.push(remote_item);
                            }
                        }
                    }
                }
                Ok(Event::Eof) => break,
                Err(e) => return Err(SyncError::ParseError(format!("XML parse error: {}", e))),
                _ => {}
            }
            buf.clear();
        }
        
        Ok(items)
    }
}

#[async_trait]
impl SyncPort for WebDavClient {
    async fn configure(&self, server_url: &str, username: &str, access_token: &str) -> SyncResult<()> {
        let config = WebDavConfig {
            base_url: format!("{}/dav/files/{}", server_url.trim_end_matches('/'), username),
            username: username.to_string(),
            access_token: access_token.to_string(),
        };
        
        *self.config.write().await = Some(config);
        
        tracing::info!("WebDAV client configured for {}", server_url);
        Ok(())
    }
    
    async fn list_directory(&self, path: &str) -> SyncResult<Vec<RemoteItem>> {
        let propfind_body = r#"<?xml version="1.0" encoding="UTF-8"?>
<d:propfind xmlns:d="DAV:">
    <d:prop>
        <d:displayname/>
        <d:getcontentlength/>
        <d:getlastmodified/>
        <d:getetag/>
        <d:getcontenttype/>
        <d:resourcetype/>
    </d:prop>
</d:propfind>"#;
        
        let response = self.request(reqwest::Method::from_bytes(b"PROPFIND").unwrap(), path)
            .await?
            .header("Depth", "1")
            .header("Content-Type", "application/xml")
            .body(propfind_body)
            .send()
            .await
            .map_err(|e| SyncError::NetworkError(e.to_string()))?;
        
        if response.status() == StatusCode::UNAUTHORIZED {
            return Err(SyncError::AuthenticationFailed("Invalid token".to_string()));
        }
        
        if !response.status().is_success() && response.status() != StatusCode::MULTI_STATUS {
            return Err(SyncError::ServerError(format!("PROPFIND failed: {}", response.status())));
        }
        
        let xml = response.text().await
            .map_err(|e| SyncError::NetworkError(e.to_string()))?;
        
        self.parse_multistatus(&xml)
    }
    
    async fn get_item(&self, path: &str) -> SyncResult<RemoteItem> {
        let items = self.list_directory(path).await?;
        items.into_iter().next()
            .ok_or_else(|| SyncError::NotFound(path.to_string()))
    }
    
    async fn download(
        &self,
        remote_path: &str,
        local_path: &str,
        progress_callback: Option<Box<dyn Fn(u64, u64) + Send + Sync>>,
    ) -> SyncResult<()> {
        let response = self.request(reqwest::Method::GET, remote_path)
            .await?
            .send()
            .await
            .map_err(|e| SyncError::NetworkError(e.to_string()))?;
        
        if response.status() == StatusCode::NOT_FOUND {
            return Err(SyncError::NotFound(remote_path.to_string()));
        }
        
        if !response.status().is_success() {
            return Err(SyncError::ServerError(format!("Download failed: {}", response.status())));
        }
        
        let total_size = response.content_length().unwrap_or(0);
        let mut downloaded = 0u64;
        
        // Create parent directories
        if let Some(parent) = std::path::Path::new(local_path).parent() {
            std::fs::create_dir_all(parent)
                .map_err(|e| SyncError::IoError(e.to_string()))?;
        }
        
        let mut file = tokio::fs::File::create(local_path).await
            .map_err(|e| SyncError::IoError(e.to_string()))?;
        
        let mut stream = response.bytes_stream();
        use futures::StreamExt;
        use tokio::io::AsyncWriteExt;
        
        while let Some(chunk) = stream.next().await {
            let chunk = chunk.map_err(|e| SyncError::NetworkError(e.to_string()))?;
            
            file.write_all(&chunk).await
                .map_err(|e| SyncError::IoError(e.to_string()))?;
            
            downloaded += chunk.len() as u64;
            
            if let Some(ref callback) = progress_callback {
                callback(downloaded, total_size);
            }
        }
        
        file.flush().await
            .map_err(|e| SyncError::IoError(e.to_string()))?;
        
        tracing::info!("Downloaded {} -> {}", remote_path, local_path);
        Ok(())
    }
    
    async fn upload(
        &self,
        local_path: &str,
        remote_path: &str,
        progress_callback: Option<Box<dyn Fn(u64, u64) + Send + Sync>>,
    ) -> SyncResult<String> {
        let file_data = tokio::fs::read(local_path).await
            .map_err(|e| SyncError::IoError(e.to_string()))?;
        
        let total_size = file_data.len() as u64;
        
        if let Some(ref callback) = progress_callback {
            callback(0, total_size);
        }
        
        let response = self.request(reqwest::Method::PUT, remote_path)
            .await?
            .body(file_data)
            .send()
            .await
            .map_err(|e| SyncError::NetworkError(e.to_string()))?;
        
        if response.status() == StatusCode::INSUFFICIENT_STORAGE {
            return Err(SyncError::QuotaExceeded);
        }
        
        if !response.status().is_success() && response.status() != StatusCode::CREATED {
            return Err(SyncError::ServerError(format!("Upload failed: {}", response.status())));
        }
        
        if let Some(ref callback) = progress_callback {
            callback(total_size, total_size);
        }
        
        // Get ETag from response
        let etag = response.headers()
            .get("etag")
            .and_then(|v| v.to_str().ok())
            .map(|s| s.trim_matches('"').to_string())
            .unwrap_or_else(|| uuid::Uuid::new_v4().to_string());
        
        tracing::info!("Uploaded {} -> {}", local_path, remote_path);
        Ok(etag)
    }
    
    async fn create_directory(&self, path: &str) -> SyncResult<()> {
        let response = self.request(reqwest::Method::from_bytes(b"MKCOL").unwrap(), path)
            .await?
            .send()
            .await
            .map_err(|e| SyncError::NetworkError(e.to_string()))?;
        
        if !response.status().is_success() && response.status() != StatusCode::CREATED {
            return Err(SyncError::ServerError(format!("MKCOL failed: {}", response.status())));
        }
        
        Ok(())
    }
    
    async fn delete(&self, path: &str) -> SyncResult<()> {
        let response = self.request(reqwest::Method::DELETE, path)
            .await?
            .send()
            .await
            .map_err(|e| SyncError::NetworkError(e.to_string()))?;
        
        if response.status() == StatusCode::NOT_FOUND {
            return Ok(()); // Already deleted
        }
        
        if !response.status().is_success() && response.status() != StatusCode::NO_CONTENT {
            return Err(SyncError::ServerError(format!("DELETE failed: {}", response.status())));
        }
        
        Ok(())
    }
    
    async fn move_item(&self, from_path: &str, to_path: &str) -> SyncResult<()> {
        let config = self.config.read().await;
        let config = config.as_ref()
            .ok_or_else(|| SyncError::AuthenticationFailed("Not configured".to_string()))?;
        
        let destination = format!("{}{}", config.base_url, to_path);
        
        let response = self.request(reqwest::Method::from_bytes(b"MOVE").unwrap(), from_path)
            .await?
            .header("Destination", destination)
            .header("Overwrite", "F")
            .send()
            .await
            .map_err(|e| SyncError::NetworkError(e.to_string()))?;
        
        if !response.status().is_success() && response.status() != StatusCode::CREATED {
            return Err(SyncError::ServerError(format!("MOVE failed: {}", response.status())));
        }
        
        Ok(())
    }
    
    async fn copy(&self, from_path: &str, to_path: &str) -> SyncResult<()> {
        let config = self.config.read().await;
        let config = config.as_ref()
            .ok_or_else(|| SyncError::AuthenticationFailed("Not configured".to_string()))?;
        
        let destination = format!("{}{}", config.base_url, to_path);
        
        let response = self.request(reqwest::Method::from_bytes(b"COPY").unwrap(), from_path)
            .await?
            .header("Destination", destination)
            .header("Overwrite", "F")
            .send()
            .await
            .map_err(|e| SyncError::NetworkError(e.to_string()))?;
        
        if !response.status().is_success() && response.status() != StatusCode::CREATED {
            return Err(SyncError::ServerError(format!("COPY failed: {}", response.status())));
        }
        
        Ok(())
    }
    
    async fn exists(&self, path: &str) -> SyncResult<bool> {
        let response = self.request(reqwest::Method::HEAD, path)
            .await?
            .send()
            .await
            .map_err(|e| SyncError::NetworkError(e.to_string()))?;
        
        Ok(response.status().is_success())
    }
    
    async fn get_quota(&self) -> SyncResult<(u64, u64)> {
        // PROPFIND on root with quota properties
        let propfind_body = r#"<?xml version="1.0" encoding="UTF-8"?>
<d:propfind xmlns:d="DAV:">
    <d:prop>
        <d:quota-available-bytes/>
        <d:quota-used-bytes/>
    </d:prop>
</d:propfind>"#;
        
        let response = self.request(reqwest::Method::from_bytes(b"PROPFIND").unwrap(), "/")
            .await?
            .header("Depth", "0")
            .header("Content-Type", "application/xml")
            .body(propfind_body)
            .send()
            .await
            .map_err(|e| SyncError::NetworkError(e.to_string()))?;
        
        // Parse quota from response... (simplified)
        Ok((0, 10 * 1024 * 1024 * 1024)) // 10GB default
    }
    
    async fn supports_delta_sync(&self) -> bool {
        false // TODO: Check server capabilities
    }
    
    async fn upload_delta(
        &self,
        _local_path: &str,
        _remote_path: &str,
        _base_checksum: &str,
    ) -> SyncResult<String> {
        Err(SyncError::ServerError("Delta sync not supported".to_string()))
    }
}

/// Partial remote item during parsing
#[derive(Default)]
struct PartialRemoteItem {
    path: Option<String>,
    name: Option<String>,
    size: Option<u64>,
    modified: Option<DateTime<Utc>>,
    etag: Option<String>,
    mime_type: Option<String>,
    is_directory: bool,
}

impl PartialRemoteItem {
    fn into_remote_item(self) -> Option<RemoteItem> {
        let path = self.path?;
        let name = self.name.unwrap_or_else(|| {
            path.rsplit('/').next().unwrap_or(&path).to_string()
        });
        
        Some(RemoteItem {
            id: uuid::Uuid::new_v4().to_string(),
            path,
            name,
            is_directory: self.is_directory,
            size: self.size.unwrap_or(0),
            modified: self.modified.unwrap_or_else(Utc::now),
            etag: self.etag,
            mime_type: self.mime_type,
        })
    }
}
