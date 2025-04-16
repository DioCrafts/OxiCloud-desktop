use crate::domain::entities::encryption::{
    EncryptionError, EncryptionResult, EncryptionSettings,
    EncryptionMetadata, EncryptionAlgorithm, KeyStorageMethod,
};
use crate::domain::repositories::encryption_repository::EncryptionRepository;
use crate::domain::services::encryption_service::EncryptionService;

use async_trait::async_trait;
use std::path::PathBuf;
use std::sync::Arc;
use std::fs;
use std::io::{Read, Write};
use tokio::sync::Mutex;
use rusqlite::{params, Connection, Result as SqlResult};
use r2d2::Pool;
use r2d2_sqlite::SqliteConnectionManager;
use tracing::{info, error, debug};
use serde_json;
use base64::{Engine as _, engine::general_purpose::STANDARD as BASE64};

// Crypto imports
use aes_gcm::{
    aead::{Aead, KeyInit, OsRng},
    Aes256Gcm, Nonce,
};
use chacha20poly1305::{
    ChaCha20Poly1305, Key, XNonce,
};
use sha2::{Sha256, Digest};
use pbkdf2::{pbkdf2_hmac, Pbkdf2};
use rand::{RngCore, rngs::OsRng as RandOsRng};

// Struct to store master key in memory
struct EncryptedMasterKey {
    key_id: String,
    encrypted_key: Vec<u8>,
    salt: String,
}

pub struct SqliteEncryptionRepository {
    pool: Pool<SqliteConnectionManager>,
    memory_cache: Arc<Mutex<Option<EncryptedMasterKey>>>,
}

impl SqliteEncryptionRepository {
    pub fn new(pool: Pool<SqliteConnectionManager>) -> Self {
        // Initialize encryption tables if they don't exist
        let conn = pool.get().expect("Failed to get SQLite connection");
        Self::init_tables(&conn).expect("Failed to initialize encryption tables");
        
        Self {
            pool,
            memory_cache: Arc::new(Mutex::new(None)),
        }
    }
    
    fn init_tables(conn: &Connection) -> SqlResult<()> {
        conn.execute(
            "CREATE TABLE IF NOT EXISTS encryption_settings (
                id INTEGER PRIMARY KEY,
                enabled BOOLEAN NOT NULL,
                algorithm TEXT NOT NULL,
                key_storage TEXT NOT NULL,
                encrypt_filenames BOOLEAN NOT NULL,
                encrypt_metadata BOOLEAN NOT NULL,
                kdf_salt TEXT,
                public_key TEXT,
                key_id TEXT,
                updated_at TEXT NOT NULL
            )",
            [],
        )?;
        
        conn.execute(
            "CREATE TABLE IF NOT EXISTS encryption_keys (
                key_id TEXT PRIMARY KEY,
                encrypted_key BLOB NOT NULL,
                salt TEXT NOT NULL,
                created_at TEXT NOT NULL
            )",
            [],
        )?;
        
        Ok(())
    }
}

#[async_trait]
impl EncryptionRepository for SqliteEncryptionRepository {
    async fn store_settings(&self, settings: &EncryptionSettings) -> EncryptionResult<()> {
        let conn = self.pool.get().map_err(|e| EncryptionError::StorageError(e.to_string()))?;
        
        // Serialize enum values
        let algorithm = serde_json::to_string(&settings.algorithm)
            .map_err(|e| EncryptionError::SerializationError(e.to_string()))?;
        let key_storage = serde_json::to_string(&settings.key_storage)
            .map_err(|e| EncryptionError::SerializationError(e.to_string()))?;
        
        // Delete old settings and insert new ones
        conn.execute("DELETE FROM encryption_settings", [])
            .map_err(|e| EncryptionError::StorageError(e.to_string()))?;
        
        conn.execute(
            "INSERT INTO encryption_settings 
            (enabled, algorithm, key_storage, encrypt_filenames, encrypt_metadata, 
             kdf_salt, public_key, key_id, updated_at) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))",
            params![
                settings.enabled,
                algorithm,
                key_storage,
                settings.encrypt_filenames,
                settings.encrypt_metadata,
                settings.kdf_salt,
                settings.public_key,
                settings.key_id,
            ],
        ).map_err(|e| EncryptionError::StorageError(e.to_string()))?;
        
        Ok(())
    }
    
    async fn get_settings(&self) -> EncryptionResult<EncryptionSettings> {
        let conn = self.pool.get().map_err(|e| EncryptionError::StorageError(e.to_string()))?;
        
        let row = conn.query_row(
            "SELECT enabled, algorithm, key_storage, encrypt_filenames, 
                    encrypt_metadata, kdf_salt, public_key, key_id 
             FROM encryption_settings 
             LIMIT 1",
            [],
            |row| {
                let enabled: bool = row.get(0)?;
                let algorithm_str: String = row.get(1)?;
                let key_storage_str: String = row.get(2)?;
                let encrypt_filenames: bool = row.get(3)?;
                let encrypt_metadata: bool = row.get(4)?;
                let kdf_salt: Option<String> = row.get(5)?;
                let public_key: Option<String> = row.get(6)?;
                let key_id: Option<String> = row.get(7)?;
                
                let algorithm: EncryptionAlgorithm = serde_json::from_str(&algorithm_str)
                    .map_err(|e| rusqlite::Error::FromSqlConversionFailure(
                        0, rusqlite::types::Type::Text, Box::new(e)
                    ))?;
                
                let key_storage: KeyStorageMethod = serde_json::from_str(&key_storage_str)
                    .map_err(|e| rusqlite::Error::FromSqlConversionFailure(
                        0, rusqlite::types::Type::Text, Box::new(e)
                    ))?;
                
                Ok(EncryptionSettings {
                    enabled,
                    algorithm,
                    key_storage,
                    encrypt_filenames,
                    encrypt_metadata,
                    kdf_salt,
                    public_key,
                    key_id,
                })
            },
        );
        
        match row {
            Ok(settings) => Ok(settings),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(EncryptionSettings::default()),
            Err(e) => Err(EncryptionError::StorageError(e.to_string())),
        }
    }
    
    async fn store_master_key(&self, encrypted_key: &[u8], salt: &str, key_id: &str) -> EncryptionResult<()> {
        let conn = self.pool.get().map_err(|e| EncryptionError::StorageError(e.to_string()))?;
        
        conn.execute(
            "INSERT OR REPLACE INTO encryption_keys (key_id, encrypted_key, salt, created_at)
             VALUES (?, ?, ?, datetime('now'))",
            params![
                key_id,
                encrypted_key,
                salt,
            ],
        ).map_err(|e| EncryptionError::StorageError(e.to_string()))?;
        
        // Update cache
        let mut cache = self.memory_cache.lock().await;
        *cache = Some(EncryptedMasterKey {
            key_id: key_id.to_string(),
            encrypted_key: encrypted_key.to_vec(),
            salt: salt.to_string(),
        });
        
        Ok(())
    }
    
    async fn get_master_key(&self, key_id: &str) -> EncryptionResult<(Vec<u8>, String)> {
        // Check memory cache first
        let cache = self.memory_cache.lock().await;
        if let Some(cached_key) = &*cache {
            if cached_key.key_id == key_id {
                return Ok((cached_key.encrypted_key.clone(), cached_key.salt.clone()));
            }
        }
        drop(cache);
        
        // Fall back to database
        let conn = self.pool.get().map_err(|e| EncryptionError::StorageError(e.to_string()))?;
        
        let result = conn.query_row(
            "SELECT encrypted_key, salt FROM encryption_keys WHERE key_id = ?",
            params![key_id],
            |row| {
                let encrypted_key: Vec<u8> = row.get(0)?;
                let salt: String = row.get(1)?;
                Ok((encrypted_key, salt))
            },
        ).map_err(|e| match e {
            rusqlite::Error::QueryReturnedNoRows => EncryptionError::InvalidKeyError(format!("Key ID not found: {}", key_id)),
            _ => EncryptionError::StorageError(e.to_string()),
        })?;
        
        // Update cache
        let mut cache = self.memory_cache.lock().await;
        *cache = Some(EncryptedMasterKey {
            key_id: key_id.to_string(),
            encrypted_key: result.0.clone(),
            salt: result.1.clone(),
        });
        
        Ok(result)
    }
    
    async fn list_keys(&self) -> EncryptionResult<Vec<String>> {
        let conn = self.pool.get().map_err(|e| EncryptionError::StorageError(e.to_string()))?;
        
        let mut stmt = conn.prepare("SELECT key_id FROM encryption_keys ORDER BY created_at DESC")
            .map_err(|e| EncryptionError::StorageError(e.to_string()))?;
        
        let key_ids = stmt.query_map([], |row| {
            let key_id: String = row.get(0)?;
            Ok(key_id)
        }).map_err(|e| EncryptionError::StorageError(e.to_string()))?;
        
        let mut result = Vec::new();
        for key_id in key_ids {
            result.push(key_id.map_err(|e| EncryptionError::StorageError(e.to_string()))?);
        }
        
        Ok(result)
    }
    
    async fn delete_key(&self, key_id: &str) -> EncryptionResult<()> {
        let conn = self.pool.get().map_err(|e| EncryptionError::StorageError(e.to_string()))?;
        
        conn.execute(
            "DELETE FROM encryption_keys WHERE key_id = ?",
            params![key_id],
        ).map_err(|e| EncryptionError::StorageError(e.to_string()))?;
        
        // Clear cache if it's the same key
        let mut cache = self.memory_cache.lock().await;
        if let Some(cached_key) = &*cache {
            if cached_key.key_id == key_id {
                *cache = None;
            }
        }
        
        Ok(())
    }
}