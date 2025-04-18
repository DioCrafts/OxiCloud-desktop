use crate::domain::entities::encryption::{
    EncryptionError, EncryptionResult, EncryptionMetadata, EncryptionAlgorithm
};
use crate::domain::entities::file::{FileError, FileResult, FileItem, EncryptionStatus};
use crate::domain::services::encryption_service::EncryptionService;

use std::path::PathBuf;
use std::sync::Arc;
use std::fs::File;
use std::io::{BufReader, BufWriter, Read, Write, Seek, SeekFrom};
use tokio::sync::{Mutex, Semaphore};
use tokio::task;
use tokio::fs;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::sync::mpsc;
use async_trait::async_trait;
use tracing::{info, error, warn, debug, instrument};
use futures::stream::{self, StreamExt};
use uuid::Uuid;
use serde::{Serialize, Deserialize};
use base64::{Engine as _, engine::general_purpose::STANDARD as BASE64};

// Constants for optimization
const CHUNK_SIZE: usize = 4 * 1024 * 1024; // 4 MB chunks
const MAX_PARALLEL_CHUNKS: usize = 8;      // Process up to 8 chunks in parallel
const BUFFER_SIZE: usize = 16 * 1024;      // 16 KB buffer size for IO operations
const QUEUE_SIZE: usize = 16;              // Size of channel queue for processed chunks

// Chunk processing status
#[derive(Debug, Clone, PartialEq, Eq)]
enum ChunkStatus {
    Pending,
    Processing,
    Complete,
    Failed(String),
}

// Metadata for a chunk
#[derive(Debug, Clone, Serialize, Deserialize)]
struct ChunkMetadata {
    chunk_index: usize,
    original_size: usize,
    encrypted_size: usize,
    iv: String,
    algorithm: EncryptionAlgorithm,
    offset: u64,
}

// Metadata for the entire file
#[derive(Debug, Clone, Serialize, Deserialize)]
struct LargeFileMetadata {
    version: u8,
    file_id: String,
    total_chunks: usize,
    original_size: u64,
    chunks: Vec<ChunkMetadata>,
    algorithm: EncryptionAlgorithm,
    key_id: String,
    filename_encrypted: bool,
    original_filename: Option<String>,
    mime_type: Option<String>,
    created_at: String,
}

/// Encryption settings structure to match EncryptionSettings
#[derive(Debug, Clone, Serialize, Deserialize)]
struct EncryptionSettings {
    algorithm: EncryptionAlgorithm,
    key_id: Option<String>,
    encrypt_filenames: bool,
    encrypt_metadata: bool,
}

/// Service for optimized processing of large files
// Use a type alias to reference EncryptionService method signatures directly
// This avoids circular dependency with EncryptionService trait
type EncryptDataFn = Box<dyn Fn(&str, &[u8]) -> std::pin::Pin<Box<dyn std::future::Future<Output = EncryptionResult<(Vec<u8>, String, String)>> + Send>> + Send + Sync>;
type DecryptDataFn = Box<dyn Fn(&str, &[u8], &str, &str) -> std::pin::Pin<Box<dyn std::future::Future<Output = EncryptionResult<Vec<u8>>> + Send>> + Send + Sync>;
type GetSettingsFn = Box<dyn Fn() -> std::pin::Pin<Box<dyn std::future::Future<Output = EncryptionResult<EncryptionSettings>> + Send>> + Send + Sync>;

pub struct LargeFileProcessor {
    // Function callbacks instead of direct service reference
    encrypt_data_fn: EncryptDataFn,
    decrypt_data_fn: DecryptDataFn,
    get_settings_fn: GetSettingsFn,
    max_parallel_chunks: usize,
    chunk_size: usize,
    parallel_limiter: Semaphore,
}

impl LargeFileProcessor {
    pub fn new(
        encrypt_data_fn: EncryptDataFn,
        decrypt_data_fn: DecryptDataFn,
        get_settings_fn: GetSettingsFn,
    ) -> Self {
        Self {
            encrypt_data_fn,
            decrypt_data_fn,
            get_settings_fn,
            max_parallel_chunks: MAX_PARALLEL_CHUNKS,
            chunk_size: CHUNK_SIZE,
            parallel_limiter: Semaphore::new(MAX_PARALLEL_CHUNKS),
        }
    }
    
    /// Set the chunk size for file processing
    pub fn with_chunk_size(mut self, chunk_size: usize) -> Self {
        self.chunk_size = chunk_size;
        self
    }
    
    /// Set the maximum number of parallel chunks
    pub fn with_max_parallel_chunks(mut self, max_parallel_chunks: usize) -> Self {
        self.max_parallel_chunks = max_parallel_chunks;
        self.parallel_limiter = Semaphore::new(max_parallel_chunks);
        self
    }
    
    /// Check if a file should be processed as large file
    pub fn should_process_as_large_file(&self, file_size: u64) -> bool {
        // Process as large file if it's bigger than 2 chunks
        file_size > (self.chunk_size * 2) as u64
    }
    
    /// Split a file size into chunks for parallel processing
    fn get_chunks(&self, file_size: u64) -> Vec<(u64, usize)> {
        let mut chunks = Vec::new();
        let mut offset = 0;
        
        while offset < file_size {
            let remain = file_size - offset;
            let chunk_size = if remain < self.chunk_size as u64 {
                remain as usize
            } else {
                self.chunk_size
            };
            
            chunks.push((offset, chunk_size));
            offset += chunk_size as u64;
        }
        
        chunks
    }
    
    /// Create metadata header for large file encryption
    async fn create_large_file_metadata(
        &self,
        original_size: u64,
        chunks: Vec<ChunkMetadata>,
        password: &str,
        file_path: &PathBuf,
    ) -> EncryptionResult<LargeFileMetadata> {
        // Get encryption settings
        let settings = (self.get_settings_fn)().await?;
        
        // Original filename from path
        let original_filename = file_path.file_name()
            .and_then(|name| name.to_str())
            .map(|name| name.to_string());
            
        // Mime type from extension
        let mime_type = file_path.extension()
            .and_then(|ext| ext.to_str())
            .map(|ext| mime_guess::from_path(file_path).first_or_octet_stream().to_string());
        
        // Validate that all chunks are present and sorted properly
        if chunks.len() == 0 {
            return Err(EncryptionError::EncryptionError(
                "No chunks processed for file metadata".to_string()
            ));
        }
        
        // Check for duplicate chunk indices
        let mut seen_indices = std::collections::HashSet::new();
        for chunk in &chunks {
            if !seen_indices.insert(chunk.chunk_index) {
                return Err(EncryptionError::EncryptionError(
                    format!("Duplicate chunk index: {}", chunk.chunk_index)
                ));
            }
        }
            
        let metadata = LargeFileMetadata {
            version: 1,
            file_id: Uuid::new_v4().to_string(),
            total_chunks: chunks.len(),
            original_size,
            chunks,
            algorithm: settings.algorithm.clone(),
            key_id: settings.key_id.clone().unwrap_or_else(|| "default".to_string()),
            filename_encrypted: settings.encrypt_filenames,
            original_filename,
            mime_type,
            created_at: chrono::Utc::now().to_rfc3339(),
        };
        
        Ok(metadata)
    }
    
    /// Encrypt a large file in chunks with parallel processing
    #[instrument(skip(self, password), fields(file_size, chunks), err)]
    pub async fn encrypt_large_file(
        &self,
        password: &str,
        source_path: &PathBuf,
        destination_path: &PathBuf,
    ) -> EncryptionResult<()> {
        // Get file size
        let file_size = match fs::metadata(source_path).await {
            Ok(metadata) => metadata.len(),
            Err(e) => {
                return Err(EncryptionError::IOError(format!(
                    "Failed to get file metadata: {}", e
                )));
            }
        };
        
        info!("Starting large file encryption for {:?} ({} bytes)", source_path, file_size);
        
        // Split into chunks
        let chunks = self.get_chunks(file_size);
        let total_chunks = chunks.len();
        info!("File will be processed in {} chunks", total_chunks);
        
        // Progress tracking
        let processed_chunks = Arc::new(Mutex::new(0));
        let chunk_statuses = Arc::new(Mutex::new(
            vec![ChunkStatus::Pending; total_chunks]
        ));
        
        // Prepare destination file
        if destination_path.exists() {
            match fs::remove_file(destination_path).await {
                Ok(_) => debug!("Removed existing destination file"),
                Err(e) => {
                    return Err(EncryptionError::IOError(format!(
                        "Failed to remove existing destination file: {}", e
                    )));
                }
            }
        }
        
        // Create destination file
        let destination_file = match fs::File::create(destination_path).await {
            Ok(file) => file,
            Err(e) => {
                return Err(EncryptionError::IOError(format!(
                    "Failed to create destination file: {}", e
                )));
            }
        };
        let destination_file = Arc::new(Mutex::new(destination_file));
        
        // Reserve space for metadata at the beginning (we'll write it later)
        let metadata_placeholder = serde_json::json!({
            "placeholder": "This will be replaced with actual metadata after processing"
        });
        let metadata_json = serde_json::to_string(&metadata_placeholder)?;
        let metadata_size = metadata_json.len() + 8; // 8 bytes for size header
        
        {
            let mut dest_file = destination_file.lock().await;
            
            // Write placeholder metadata size
            dest_file.write_u64_le(metadata_size as u64).await?;
            
            // Write placeholder metadata
            dest_file.write_all(metadata_json.as_bytes()).await?;
        }
        
        // Setup chunk metadata collection
        let chunk_metadatas = Arc::new(Mutex::new(Vec::with_capacity(total_chunks)));
        
        // Setup channel for encrypted chunks
        let (tx, mut rx) = mpsc::channel(QUEUE_SIZE);
        
        // Process each chunk in parallel
        let process_tasks = stream::iter(chunks.into_iter().enumerate())
            .map(|(chunk_index, (offset, chunk_size))| {
                let encrypt_fn = self.encrypt_data_fn.clone();
                let source_path = source_path.clone();
                let password = password.to_string();
                let processed_chunks = processed_chunks.clone();
                let chunk_statuses = chunk_statuses.clone();
                let tx = tx.clone();
                let chunk_metadatas = chunk_metadatas.clone();
                let _permit = self.parallel_limiter.clone().acquire_owned();
                
                async move {
                    // Update status to processing
                    {
                        let mut statuses = chunk_statuses.lock().await;
                        statuses[chunk_index] = ChunkStatus::Processing;
                    }
                    
                    debug!("Processing chunk {} (offset={}, size={})", chunk_index, offset, chunk_size);
                    
                    // Open source file and seek to chunk position
                    let mut source_file = match fs::File::open(&source_path).await {
                        Ok(file) => file,
                        Err(e) => {
                            error!("Failed to open source file for chunk {}: {}", chunk_index, e);
                            
                            // Update status to failed
                            let mut statuses = chunk_statuses.lock().await;
                            statuses[chunk_index] = ChunkStatus::Failed(format!("Failed to open source file: {}", e));
                            
                            return Err(EncryptionError::IOError(format!(
                                "Failed to open source file for chunk {}: {}", chunk_index, e
                            )));
                        }
                    };
                    
                    // Seek to chunk offset
                    if let Err(e) = source_file.seek(tokio::io::SeekFrom::Start(offset)).await {
                        error!("Failed to seek in source file for chunk {}: {}", chunk_index, e);
                        
                        // Update status to failed
                        let mut statuses = chunk_statuses.lock().await;
                        statuses[chunk_index] = ChunkStatus::Failed(format!("Failed to seek in source file: {}", e));
                        
                        return Err(EncryptionError::IOError(format!(
                            "Failed to seek in source file for chunk {}: {}", chunk_index, e
                        )));
                    }
                    
                    // Read chunk data
                    let mut chunk_data = vec![0; chunk_size];
                    match source_file.read_exact(&mut chunk_data).await {
                        Ok(_) => {},
                        Err(e) => {
                            error!("Failed to read chunk {} from source file: {}", chunk_index, e);
                            
                            // Update status to failed
                            let mut statuses = chunk_statuses.lock().await;
                            statuses[chunk_index] = ChunkStatus::Failed(format!(
                                "Failed to read from source file: {}", e
                            ));
                            
                            return Err(EncryptionError::IOError(format!(
                                "Failed to read chunk {} from source file: {}", chunk_index, e
                            )));
                        }
                    }
                    
                    // Encrypt chunk data
                    let encrypt_fn = self.encrypt_data_fn.clone();
                    let (encrypted_data, iv, metadata) = match encrypt_fn(&password, &chunk_data).await {
                        Ok(result) => result,
                        Err(e) => {
                            error!("Failed to encrypt chunk {}: {}", chunk_index, e);
                            
                            // Update status to failed
                            let mut statuses = chunk_statuses.lock().await;
                            statuses[chunk_index] = ChunkStatus::Failed(format!(
                                "Failed to encrypt: {}", e
                            ));
                            
                            return Err(e);
                        }
                    };
                    
                    debug!("Chunk {} encrypted successfully", chunk_index);
                    
                    // Parse the metadata string back to get algorithm
                    let encryption_metadata: EncryptionMetadata = serde_json::from_str(&metadata)?;
                    
                    // Create chunk metadata
                    let chunk_metadata = ChunkMetadata {
                        chunk_index,
                        original_size: chunk_size,
                        encrypted_size: encrypted_data.len(),
                        iv,
                        algorithm: encryption_metadata.algorithm,
                        offset: 0, // Will be set after writing to file
                    };
                    
                    // Send encrypted chunk to writer task
                    if let Err(e) = tx.send((chunk_index, encrypted_data, chunk_metadata.clone())).await {
                        error!("Failed to send encrypted chunk {} to writer: {}", chunk_index, e);
                        
                        // Update status to failed
                        let mut statuses = chunk_statuses.lock().await;
                        statuses[chunk_index] = ChunkStatus::Failed(format!(
                            "Failed to send to writer: {}", e
                        ));
                        
                        return Err(EncryptionError::IOError(format!(
                            "Writer channel failure for chunk {}: {}", chunk_index, e
                        )));
                    }
                    
                    // Update processed count and status
                    {
                        let mut processed = processed_chunks.lock().await;
                        *processed += 1;
                        debug!("Progress: {}/{} chunks processed", processed, total_chunks);
                        
                        // Update status to complete
                        let mut statuses = chunk_statuses.lock().await;
                        statuses[chunk_index] = ChunkStatus::Complete;
                    }
                    
                    Ok(())
                }
            })
            .buffer_unordered(self.max_parallel_chunks)
            .collect::<Vec<EncryptionResult<()>>>();
            
        // Start a background task to write encrypted chunks to file in order
        let writer_task = {
            let destination_file = destination_file.clone();
            let chunk_metadatas = chunk_metadatas.clone();
            let total_chunks = total_chunks;
            
            async move {
                // We're starting after the metadata header
                let mut current_offset = metadata_size as u64;
                let mut next_chunk_index = 0;
                let mut pending_chunks = std::collections::HashMap::new();
                
                while let Some((chunk_index, encrypted_data, mut chunk_metadata)) = rx.recv().await {
                    // Store the actual offset where this chunk will be written
                    chunk_metadata.offset = current_offset;
                    
                    // If this is the next chunk we're expecting, write it and any pending chunks
                    if chunk_index == next_chunk_index {
                        // Lock the file only once for all sequential writes
                        let mut dest_file = destination_file.lock().await;
                        
                        // Seek to current offset
                        if let Err(e) = dest_file.seek(SeekFrom::Start(current_offset)).await {
                            error!("Failed to seek in destination file: {}", e);
                            break;
                        }
                        
                        // Write this chunk
                        if let Err(e) = dest_file.write_all(&encrypted_data).await {
                            error!("Failed to write chunk {} to destination file: {}", chunk_index, e);
                            break;
                        }
                        
                        // Update metrics
                        current_offset += encrypted_data.len() as u64;
                        next_chunk_index += 1;
                        
                        // Store metadata for this chunk
                        {
                            let mut metadatas = chunk_metadatas.lock().await;
                            metadatas.push(chunk_metadata);
                        }
                        
                        // Check if we have any pending chunks that can now be written
                        while let Some((data, metadata)) = pending_chunks.remove(&next_chunk_index) {
                            // Write the pending chunk
                            if let Err(e) = dest_file.write_all(&data).await {
                                error!("Failed to write pending chunk {} to destination file: {}", next_chunk_index, e);
                                break;
                            }
                            
                            // Update metrics
                            current_offset += data.len() as u64;
                            next_chunk_index += 1;
                            
                            // Store metadata for this chunk
                            {
                                let mut metadatas = chunk_metadatas.lock().await;
                                metadatas.push(metadata);
                            }
                        }
                        
                        // Sync file to ensure data is written to disk
                        if let Err(e) = dest_file.sync_all().await {
                            error!("Failed to sync file after writing chunks: {}", e);
                        }
                    } else {
                        // Store this chunk for later processing
                        pending_chunks.insert(chunk_index, (encrypted_data, chunk_metadata));
                    }
                    
                    // Check if we're done
                    let processed = {
                        let metadatas = chunk_metadatas.lock().await;
                        metadatas.len()
                    };
                    
                    if processed >= total_chunks {
                        debug!("All chunks processed and written");
                        break;
                    }
                }
                
                // Sort the chunk metadatas by index
                {
                    let mut metadatas = chunk_metadatas.lock().await;
                    metadatas.sort_by_key(|m| m.chunk_index);
                }
            }
        };
        
        // Run the writer task and process tasks concurrently
        let (process_results, _) = tokio::join!(process_tasks, writer_task);
        
        // Check for errors in the process tasks
        for result in process_results {
            if let Err(e) = result {
                error!("Error processing chunk: {}", e);
                // We continue to collect all errors, but we'll return only the first one
                // If we wanted to be more detailed, we could collect all errors
            }
        }
        
        // Get all chunk metadatas
        let metadatas = chunk_metadatas.lock().await.clone();
        
        // Check if we processed all chunks successfully
        let processed = processed_chunks.lock().await;
        if *processed < total_chunks {
            // Get the status of failed chunks for better error reporting
            let statuses = chunk_statuses.lock().await;
            let failed_chunks: Vec<(usize, &str)> = statuses.iter().enumerate()
                .filter_map(|(i, status)| {
                    if let ChunkStatus::Failed(msg) = status {
                        Some((i, msg.as_str()))
                    } else {
                        None
                    }
                })
                .collect();
            
            let error_msg = if failed_chunks.is_empty() {
                format!("Not all chunks were processed successfully. Processed: {}/{}", *processed, total_chunks)
            } else {
                let failures = failed_chunks.iter()
                    .map(|(i, msg)| format!("Chunk {}: {}", i, msg))
                    .collect::<Vec<_>>()
                    .join("; ");
                    
                format!("Not all chunks were processed successfully. Processed: {}/{}. Failures: {}", 
                    *processed, total_chunks, failures)
            };
            
            return Err(EncryptionError::EncryptionError(error_msg));
        }
        
        // Create large file metadata
        let large_file_metadata = self.create_large_file_metadata(
            file_size,
            metadatas,
            password,
            source_path,
        ).await?;
        
        // Serialize metadata
        let metadata_json = serde_json::to_string(&large_file_metadata)?;
        
        // Write metadata at the beginning of the file
        {
            let mut dest_file = destination_file.lock().await;
            
            // Seek to beginning
            dest_file.seek(SeekFrom::Start(0)).await?;
            
            // Write metadata size
            dest_file.write_u64_le(metadata_json.len() as u64).await?;
            
            // Write metadata
            dest_file.write_all(metadata_json.as_bytes()).await?;
            
            // Sync file to ensure metadata is written to disk
            dest_file.sync_all().await?;
        }
        
        info!("Large file encryption completed successfully");
        Ok(())
    }
    
    /// Decrypt a large file in chunks with parallel processing
    #[instrument(skip(self, password), fields(total_chunks), err)]
    pub async fn decrypt_large_file(
        &self,
        password: &str,
        source_path: &PathBuf,
        destination_path: &PathBuf,
    ) -> EncryptionResult<()> {
        info!("Starting large file decryption for {:?}", source_path);
        
        // Open source file
        let mut source_file = match fs::File::open(source_path).await {
            Ok(file) => file,
            Err(e) => {
                return Err(EncryptionError::IOError(format!(
                    "Failed to open source file: {}", e
                )));
            }
        };
        
        // Read metadata size
        let metadata_size = source_file.read_u64_le().await?;
        
        // Read metadata
        let mut metadata_bytes = vec![0; metadata_size as usize];
        source_file.read_exact(&mut metadata_bytes).await?;
        
        // Parse metadata
        let metadata: LargeFileMetadata = match serde_json::from_str(&String::from_utf8_lossy(&metadata_bytes)) {
            Ok(metadata) => metadata,
            Err(e) => {
                return Err(EncryptionError::SerializationError(format!(
                    "Failed to parse file metadata: {}", e
                )));
            }
        };
        
        let total_chunks = metadata.total_chunks;
        info!("File has {} chunks to decrypt", total_chunks);
        
        // Progress tracking
        let processed_chunks = Arc::new(Mutex::new(0));
        let chunk_statuses = Arc::new(Mutex::new(
            vec![ChunkStatus::Pending; total_chunks]
        ));
        
        // Prepare destination file
        if destination_path.exists() {
            match fs::remove_file(destination_path).await {
                Ok(_) => debug!("Removed existing destination file"),
                Err(e) => {
                    return Err(EncryptionError::IOError(format!(
                        "Failed to remove existing destination file: {}", e
                    )));
                }
            }
        }
        
        // Create destination file
        let destination_file = match fs::File::create(destination_path).await {
            Ok(file) => file,
            Err(e) => {
                return Err(EncryptionError::IOError(format!(
                    "Failed to create destination file: {}", e
                )));
            }
        };
        let destination_file = Arc::new(Mutex::new(destination_file));
        
        // Setup channel for decrypted chunks
        let (tx, mut rx) = mpsc::channel(QUEUE_SIZE);
        
        // Process each chunk in parallel
        let process_tasks = stream::iter(metadata.chunks.into_iter().enumerate())
            .map(|(i, chunk_metadata)| {
                let decrypt_fn = self.decrypt_data_fn.clone();
                let source_path = source_path.clone();
                let password = password.to_string();
                let processed_chunks = processed_chunks.clone();
                let chunk_statuses = chunk_statuses.clone();
                let tx = tx.clone();
                let _permit = self.parallel_limiter.clone().acquire_owned();
                
                async move {
                    let chunk_index = chunk_metadata.chunk_index;
                    
                    // Update status to processing
                    {
                        let mut statuses = chunk_statuses.lock().await;
                        statuses[chunk_index] = ChunkStatus::Processing;
                    }
                    
                    debug!("Decrypting chunk {} (offset={}, size={})", 
                        chunk_index, chunk_metadata.offset, chunk_metadata.encrypted_size);
                    
                    // Open source file and seek to chunk position
                    let mut source_file = match fs::File::open(&source_path).await {
                        Ok(file) => file,
                        Err(e) => {
                            error!("Failed to open source file for chunk {}: {}", chunk_index, e);
                            
                            // Update status to failed
                            let mut statuses = chunk_statuses.lock().await;
                            statuses[chunk_index] = ChunkStatus::Failed(format!("Failed to open source file: {}", e));
                            
                            return Err(EncryptionError::IOError(format!(
                                "Failed to open source file for chunk {}: {}", chunk_index, e
                            )));
                        }
                    };
                    
                    // Seek to chunk offset
                    if let Err(e) = source_file.seek(tokio::io::SeekFrom::Start(chunk_metadata.offset)).await {
                        error!("Failed to seek in source file for chunk {}: {}", chunk_index, e);
                        
                        // Update status to failed
                        let mut statuses = chunk_statuses.lock().await;
                        statuses[chunk_index] = ChunkStatus::Failed(format!("Failed to seek in source file: {}", e));
                        
                        return Err(EncryptionError::IOError(format!(
                            "Failed to seek in source file for chunk {}: {}", chunk_index, e
                        )));
                    }
                    
                    // Read encrypted chunk data
                    let mut encrypted_data = vec![0; chunk_metadata.encrypted_size];
                    match source_file.read_exact(&mut encrypted_data).await {
                        Ok(_) => {},
                        Err(e) => {
                            error!("Failed to read chunk {} from source file: {}", chunk_index, e);
                            
                            // Update status to failed
                            let mut statuses = chunk_statuses.lock().await;
                            statuses[chunk_index] = ChunkStatus::Failed(format!(
                                "Failed to read from source file: {}", e
                            ));
                            
                            return Err(EncryptionError::IOError(format!(
                                "Failed to read chunk {} from source file: {}", chunk_index, e
                            )));
                        }
                    }
                    
                    // Create metadata for decryption
                    let encryption_metadata = EncryptionMetadata {
                        algorithm: chunk_metadata.algorithm.clone(),
                        key_id: metadata.key_id.clone(),
                        filename_encrypted: metadata.filename_encrypted,
                        original_size: chunk_metadata.original_size as u64,
                        original_mime_type: metadata.mime_type.clone(),
                        extension: metadata.original_filename.clone()
                            .and_then(|name| name.split('.').last().map(String::from)),
                    };
                    
                    let metadata_json = serde_json::to_string(&encryption_metadata)?;
                    
                    // Decrypt chunk data
                    let decrypt_fn = self.decrypt_data_fn.clone();
                    let decrypted_data = match decrypt_fn(
                        &password, 
                        &encrypted_data, 
                        &chunk_metadata.iv, 
                        &metadata_json
                    ).await {
                        Ok(result) => result,
                        Err(e) => {
                            error!("Failed to decrypt chunk {}: {}", chunk_index, e);
                            
                            // Update status to failed
                            let mut statuses = chunk_statuses.lock().await;
                            statuses[chunk_index] = ChunkStatus::Failed(format!(
                                "Failed to decrypt: {}", e
                            ));
                            
                            return Err(e);
                        }
                    };
                    
                    debug!("Chunk {} decrypted successfully", chunk_index);
                    
                    // Send decrypted chunk to writer task
                    if let Err(e) = tx.send((chunk_index, decrypted_data)).await {
                        error!("Failed to send decrypted chunk {} to writer: {}", chunk_index, e);
                        
                        // Update status to failed
                        let mut statuses = chunk_statuses.lock().await;
                        statuses[chunk_index] = ChunkStatus::Failed(format!(
                            "Failed to send to writer: {}", e
                        ));
                        
                        return Err(EncryptionError::IOError(format!(
                            "Writer channel failure for chunk {}: {}", chunk_index, e
                        )));
                    }
                    
                    // Update processed count and status
                    {
                        let mut processed = processed_chunks.lock().await;
                        *processed += 1;
                        debug!("Progress: {}/{} chunks processed", processed, total_chunks);
                        
                        // Update status to complete
                        let mut statuses = chunk_statuses.lock().await;
                        statuses[chunk_index] = ChunkStatus::Complete;
                    }
                    
                    Ok(())
                }
            })
            .buffer_unordered(self.max_parallel_chunks)
            .collect::<Vec<EncryptionResult<()>>>();
            
        // Start a background task to write decrypted chunks to file in order
        let writer_task = {
            let destination_file = destination_file.clone();
            let total_chunks = total_chunks;
            
            async move {
                let mut next_chunk_index = 0;
                let mut pending_chunks = std::collections::HashMap::new();
                
                while let Some((chunk_index, decrypted_data)) = rx.recv().await {
                    // If this is the next chunk we're expecting, write it and any pending chunks
                    if chunk_index == next_chunk_index {
                        // Lock the file only once for all sequential writes
                        let mut dest_file = destination_file.lock().await;
                        
                        // Write this chunk
                        if let Err(e) = dest_file.write_all(&decrypted_data).await {
                            error!("Failed to write chunk {} to destination file: {}", chunk_index, e);
                            break;
                        }
                        
                        // Update next expected chunk
                        next_chunk_index += 1;
                        
                        // Check if we have any pending chunks that can now be written
                        while let Some(data) = pending_chunks.remove(&next_chunk_index) {
                            // Write the pending chunk
                            if let Err(e) = dest_file.write_all(&data).await {
                                error!("Failed to write pending chunk {} to destination file: {}", next_chunk_index, e);
                                break;
                            }
                            
                            // Update next expected chunk
                            next_chunk_index += 1;
                        }
                        
                        // Sync file to ensure data is written to disk
                        if let Err(e) = dest_file.sync_all().await {
                            error!("Failed to sync file after writing chunks: {}", e);
                        }
                    } else {
                        // Store this chunk for later processing
                        pending_chunks.insert(chunk_index, decrypted_data);
                    }
                    
                    // Check if we're done
                    let processed = {
                        let processed = processed_chunks.lock().await;
                        *processed
                    };
                    
                    if processed >= total_chunks {
                        debug!("All chunks processed and written");
                        break;
                    }
                }
            }
        };
        
        // Run the writer task and process tasks concurrently
        let (process_results, _) = tokio::join!(process_tasks, writer_task);
        
        // Check for errors in the process tasks
        for result in process_results {
            if let Err(e) = result {
                error!("Error processing chunk: {}", e);
                // We continue to collect all errors, but we'll return only the first one
            }
        }
        
        // Check if we processed all chunks successfully
        let processed = processed_chunks.lock().await;
        if *processed < total_chunks {
            // Get the status of failed chunks for better error reporting
            let statuses = chunk_statuses.lock().await;
            let failed_chunks: Vec<(usize, &str)> = statuses.iter().enumerate()
                .filter_map(|(i, status)| {
                    if let ChunkStatus::Failed(msg) = status {
                        Some((i, msg.as_str()))
                    } else {
                        None
                    }
                })
                .collect();
            
            let error_msg = if failed_chunks.is_empty() {
                format!("Not all chunks were processed successfully. Processed: {}/{}", *processed, total_chunks)
            } else {
                let failures = failed_chunks.iter()
                    .map(|(i, msg)| format!("Chunk {}: {}", i, msg))
                    .collect::<Vec<_>>()
                    .join("; ");
                    
                format!("Not all chunks were processed successfully. Processed: {}/{}. Failures: {}", 
                    *processed, total_chunks, failures)
            };
            
            return Err(EncryptionError::DecryptionError(error_msg));
        }
        
        info!("Large file decryption completed successfully");
        Ok(())
    }
}

/// Extension trait to add little-endian u64 read/write methods to AsyncReadExt/AsyncWriteExt
#[async_trait]
trait AsyncLEU64ReadWrite {
    async fn read_u64_le(&mut self) -> std::io::Result<u64>;
    async fn write_u64_le(&mut self, value: u64) -> std::io::Result<()>;
}

#[async_trait]
impl AsyncLEU64ReadWrite for tokio::fs::File {
    async fn read_u64_le(&mut self) -> std::io::Result<u64> {
        let mut buffer = [0u8; 8];
        self.read_exact(&mut buffer).await?;
        Ok(u64::from_le_bytes(buffer))
    }
    
    async fn write_u64_le(&mut self, value: u64) -> std::io::Result<()> {
        self.write_all(&value.to_le_bytes()).await
    }
}