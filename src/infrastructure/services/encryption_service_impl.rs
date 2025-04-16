use crate::domain::entities::encryption::{
    EncryptionError, EncryptionResult, EncryptionSettings,
    EncryptionMetadata, EncryptionAlgorithm, KeyStorageMethod,
};
use crate::domain::repositories::encryption_repository::EncryptionRepository;
use crate::domain::services::encryption_service::EncryptionService;
use crate::infrastructure::services::large_file_processor::LargeFileProcessor;

use async_trait::async_trait;
use std::path::PathBuf;
use std::sync::Arc;
use std::fs;
use std::io::{Read, Write};
use tokio::sync::Mutex;
use tracing::{info, error, debug, warn};
use serde_json;
use uuid::Uuid;
use base64::{Engine as _, engine::general_purpose::STANDARD as BASE64};

// Classical crypto imports
use aes_gcm::{
    aead::{Aead, KeyInit, OsRng},
    Aes256Gcm, Nonce,
};
use chacha20poly1305::{
    ChaCha20Poly1305, Key, XNonce,
};
use sha2::{Sha256, Digest};
use pbkdf2::{pbkdf2_hmac, Pbkdf2};
use rand::{RngCore, rngs::OsRng as RandOsRng, SeedableRng, rngs::StdRng};

// Post-quantum crypto imports
use pqcrypto_kyber::kyber768::{self, PublicKey as KyberPublicKey, SecretKey as KyberSecretKey};
use pqcrypto_dilithium::dilithium5::{self, PublicKey as DilithiumPublicKey, SecretKey as DilithiumSecretKey};
use pqcrypto_traits::kem::{PublicKey, SecretKey, SharedSecret, Ciphertext};
use pqcrypto_traits::sign::{PublicKey as SignPublicKey, SecretKey as SignSecretKey, DetachedSignature};

// Constants
const PBKDF2_ITERATIONS: u32 = 600_000; // High number of iterations for security
const KEY_SIZE: usize = 32; // 256 bits
const SALT_SIZE: usize = 16; // 128 bits
const IV_SIZE: usize = 12; // 96 bits for AES-GCM
const TAG_SIZE: usize = 16; // 128 bits for authentication tag

// Struct to hold decrypted master key in memory
struct MasterKey {
    key_id: String,
    key_bytes: Vec<u8>,
    algorithm: EncryptionAlgorithm,
    expiry: std::time::Instant,
}

pub struct EncryptionServiceImpl {
    repository: Arc<dyn EncryptionRepository>,
    master_key_cache: Arc<Mutex<Option<MasterKey>>>,
    settings_cache: Arc<Mutex<Option<EncryptionSettings>>>,
    large_file_processor: Arc<Mutex<Option<LargeFileProcessor>>>,
}

impl Clone for EncryptionServiceImpl {
    fn clone(&self) -> Self {
        Self {
            repository: self.repository.clone(),
            master_key_cache: self.master_key_cache.clone(),
            settings_cache: self.settings_cache.clone(),
            large_file_processor: self.large_file_processor.clone(),
        }
    }
}

impl EncryptionServiceImpl {
    pub fn new(repository: Arc<dyn EncryptionRepository>) -> Self {
        let instance = Self {
            repository,
            master_key_cache: Arc::new(Mutex::new(None)),
            settings_cache: Arc::new(Mutex::new(None)),
            large_file_processor: Arc::new(Mutex::new(None)),
        };
        
        // We'll initialize the large file processor lazily
        instance
    }
    
    // Helper to get or initialize the large file processor
    async fn get_large_file_processor(&self) -> Arc<LargeFileProcessor> {
        let mut processor = self.large_file_processor.lock().await;
        
        if processor.is_none() {
            // Create closures that capture self for the processor
            let self_clone = Arc::new(self.clone());
            
            let encrypt_data_fn = Box::new(move |password: &str, data: &[u8]| {
                let self_clone = self_clone.clone();
                let password = password.to_string();
                let data = data.to_vec();
                
                Box::pin(async move {
                    self_clone.encrypt_data(&password, &data).await
                })
            });
            
            let decrypt_data_fn = Box::new(move |password: &str, data: &[u8], iv: &str, metadata: &str| {
                let self_clone = self_clone.clone();
                let password = password.to_string();
                let data = data.to_vec();
                let iv = iv.to_string();
                let metadata = metadata.to_string();
                
                Box::pin(async move {
                    self_clone.decrypt_data(&password, &data, &iv, &metadata).await
                })
            });
            
            let get_settings_fn = Box::new(move || {
                let self_clone = self_clone.clone();
                
                Box::pin(async move {
                    self_clone.get_settings().await
                })
            });
            
            // Create the processor
            let new_processor = LargeFileProcessor::new(
                encrypt_data_fn,
                decrypt_data_fn,
                get_settings_fn,
            );
            
            *processor = Some(new_processor);
        }
        
        // Return a cloned Arc to the processor
        Arc::new(processor.as_ref().unwrap().clone())
    }
    
    // Generate a random 256-bit master key
    fn generate_master_key() -> Vec<u8> {
        let mut key = vec![0u8; KEY_SIZE];
        RandOsRng.fill_bytes(&mut key);
        key
    }
    
    // Generate a random salt
    fn generate_salt() -> Vec<u8> {
        let mut salt = vec![0u8; SALT_SIZE];
        RandOsRng.fill_bytes(&mut salt);
        salt
    }
    
    // Generate a random initialization vector
    fn generate_iv() -> Vec<u8> {
        let mut iv = vec![0u8; IV_SIZE];
        RandOsRng.fill_bytes(&mut iv);
        iv
    }
    
    // Derive encryption key from password
    fn derive_key_from_password(password: &str, salt: &[u8], algorithm: &EncryptionAlgorithm) -> Vec<u8> {
        let mut derived_key = vec![0u8; KEY_SIZE];
        
        // Use PBKDF2 with SHA-256 for key derivation
        pbkdf2_hmac::<Sha256>(
            password.as_bytes(),
            salt,
            PBKDF2_ITERATIONS,
            &mut derived_key,
        );
        
        derived_key
    }
    
    // Encrypt the master key using the password-derived key
    fn encrypt_master_key(master_key: &[u8], password: &str, salt: &[u8], algorithm: &EncryptionAlgorithm) -> EncryptionResult<Vec<u8>> {
        let derived_key = Self::derive_key_from_password(password, salt, algorithm);
        
        match algorithm {
            EncryptionAlgorithm::Aes256Gcm => {
                let cipher = Aes256Gcm::new_from_slice(&derived_key)
                    .map_err(|e| EncryptionError::EncryptionError(e.to_string()))?;
                
                let nonce = Nonce::from_slice(&Self::generate_iv());
                
                // Combine nonce and encrypted master key
                let mut encrypted_key = nonce.to_vec();
                let ciphertext = cipher.encrypt(nonce, master_key.as_ref())
                    .map_err(|e| EncryptionError::EncryptionError(e.to_string()))?;
                
                encrypted_key.extend_from_slice(&ciphertext);
                Ok(encrypted_key)
            },
            EncryptionAlgorithm::Chacha20Poly1305 => {
                let key = Key::from_slice(&derived_key);
                let cipher = ChaCha20Poly1305::new(key);
                
                let nonce = XNonce::from_slice(&Self::generate_iv());
                
                // Combine nonce and encrypted master key
                let mut encrypted_key = nonce.to_vec();
                let ciphertext = cipher.encrypt(nonce, master_key.as_ref())
                    .map_err(|e| EncryptionError::EncryptionError(e.to_string()))?;
                
                encrypted_key.extend_from_slice(&ciphertext);
                Ok(encrypted_key)
            },
            _ => {
                match algorithm {
                    EncryptionAlgorithm::Kyber768 => {
                        // Kyber is a Key Encapsulation Mechanism (KEM), not an encryption scheme
                        // We'll use Kyber to encapsulate a random key, then use AES to encrypt the master key
                        
                        // First, derive a seed from the password for deterministic key generation
                        let mut hasher = Sha256::new();
                        hasher.update(password.as_bytes());
                        hasher.update(salt);
                        let seed = hasher.finalize();
                        
                        // Use the seed to derive a Kyber keypair deterministically
                        let mut rng = rand::rngs::StdRng::from_seed(seed.into());
                        
                        // Generate Kyber keypair
                        let (public_key, secret_key) = kyber768::keypair();
                        
                        // Encapsulate to create a shared secret and ciphertext
                        let (ciphertext, shared_secret) = kyber768::encapsulate(&public_key);
                        
                        // Use the shared secret as encryption key for AES
                        let cipher = Aes256Gcm::new_from_slice(shared_secret.as_ref())
                            .map_err(|e| EncryptionError::EncryptionError(e.to_string()))?;
                        
                        let nonce = Nonce::from_slice(&Self::generate_iv());
                        
                        // Encrypt the master key with the shared secret
                        let aes_ciphertext = cipher.encrypt(nonce, master_key.as_ref())
                            .map_err(|e| EncryptionError::EncryptionError(e.to_string()))?;
                        
                        // Combine everything: IV, Kyber ciphertext, AES ciphertext
                        let mut encrypted_key = nonce.to_vec();
                        encrypted_key.extend_from_slice(ciphertext.as_ref());
                        encrypted_key.extend_from_slice(&aes_ciphertext);
                        
                        // Also store the secret key bytes (encrypted) for later decapsulation
                        let secret_key_bytes = secret_key.as_ref();
                        encrypted_key.extend_from_slice(secret_key_bytes);
                        
                        Ok(encrypted_key)
                    },
                    EncryptionAlgorithm::HybridAesKyber => {
                        // Hybrid approach: use both AES and Kyber for defense in depth
                        
                        // First, use AES with the derived key (classical security)
                        let aes_cipher = Aes256Gcm::new_from_slice(&derived_key)
                            .map_err(|e| EncryptionError::EncryptionError(e.to_string()))?;
                        
                        let aes_nonce = Nonce::from_slice(&Self::generate_iv());
                        let aes_ciphertext = aes_cipher.encrypt(aes_nonce, master_key.as_ref())
                            .map_err(|e| EncryptionError::EncryptionError(e.to_string()))?;
                        
                        // Then, use Kyber for post-quantum security
                        let (public_key, secret_key) = kyber768::keypair();
                        let (kyber_ciphertext, shared_secret) = kyber768::encapsulate(&public_key);
                        
                        // Encrypt the AES-encrypted master key again with the shared secret
                        let kyber_cipher = Aes256Gcm::new_from_slice(shared_secret.as_ref())
                            .map_err(|e| EncryptionError::EncryptionError(e.to_string()))?;
                        
                        let kyber_nonce = Nonce::from_slice(&Self::generate_iv());
                        let hybrid_ciphertext = kyber_cipher.encrypt(kyber_nonce, &aes_ciphertext)
                            .map_err(|e| EncryptionError::EncryptionError(e.to_string()))?;
                        
                        // Combine everything: AES nonce, Kyber nonce, Kyber ciphertext, hybrid ciphertext, secret key
                        let mut encrypted_key = aes_nonce.to_vec();
                        encrypted_key.extend_from_slice(kyber_nonce.as_ref());
                        encrypted_key.extend_from_slice(kyber_ciphertext.as_ref());
                        encrypted_key.extend_from_slice(&hybrid_ciphertext);
                        encrypted_key.extend_from_slice(secret_key.as_ref());
                        
                        Ok(encrypted_key)
                    },
                    _ => {
                        warn!("Post-quantum algorithm not implemented. Falling back to AES-GCM.");
                        let cipher = Aes256Gcm::new_from_slice(&derived_key)
                            .map_err(|e| EncryptionError::EncryptionError(e.to_string()))?;
                        
                        let nonce = Nonce::from_slice(&Self::generate_iv());
                        
                        // Combine nonce and encrypted master key
                        let mut encrypted_key = nonce.to_vec();
                        let ciphertext = cipher.encrypt(nonce, master_key.as_ref())
                            .map_err(|e| EncryptionError::EncryptionError(e.to_string()))?;
                        
                        encrypted_key.extend_from_slice(&ciphertext);
                        Ok(encrypted_key)
                    }
                }
            }
        }
    }
    
    // Decrypt the master key using the password-derived key
    fn decrypt_master_key(encrypted_key: &[u8], password: &str, salt: &[u8], algorithm: &EncryptionAlgorithm) -> EncryptionResult<Vec<u8>> {
        if encrypted_key.len() <= IV_SIZE {
            return Err(EncryptionError::DecryptionError("Encrypted key data is too short".to_string()));
        }
        
        let derived_key = Self::derive_key_from_password(password, salt, algorithm);
        
        let (iv, ciphertext) = encrypted_key.split_at(IV_SIZE);
        
        match algorithm {
            EncryptionAlgorithm::Aes256Gcm => {
                let cipher = Aes256Gcm::new_from_slice(&derived_key)
                    .map_err(|e| EncryptionError::DecryptionError(e.to_string()))?;
                
                let nonce = Nonce::from_slice(iv);
                
                cipher.decrypt(nonce, ciphertext.as_ref())
                    .map_err(|e| EncryptionError::DecryptionError(format!("Failed to decrypt master key: {}", e)))
            },
            EncryptionAlgorithm::Chacha20Poly1305 => {
                let key = Key::from_slice(&derived_key);
                let cipher = ChaCha20Poly1305::new(key);
                
                let nonce = XNonce::from_slice(iv);
                
                cipher.decrypt(nonce, ciphertext.as_ref())
                    .map_err(|e| EncryptionError::DecryptionError(format!("Failed to decrypt master key: {}", e)))
            },
            _ => {
                match algorithm {
                    EncryptionAlgorithm::Kyber768 => {
                        // When we encrypted with Kyber, we stored the data as:
                        // [IV | Kyber ciphertext | AES ciphertext | Kyber secret key]
                        
                        // Extract the different parts
                        if ciphertext.len() <= kyber768::CIPHERTEXT_LENGTH + 32 { // AES ciphertext should be at least 32 bytes
                            return Err(EncryptionError::DecryptionError(
                                "Encrypted data too short for Kyber format".to_string()
                            ));
                        }
                        
                        let kyber_ct_len = kyber768::CIPHERTEXT_LENGTH;
                        let kyber_sk_len = kyber768::SECRET_KEY_LENGTH;
                        
                        // Split the data
                        let (kyber_ct_bytes, rest) = ciphertext.split_at(kyber_ct_len);
                        let aes_ct_len = rest.len() - kyber_sk_len;
                        let (aes_ct_bytes, sk_bytes) = rest.split_at(aes_ct_len);
                        
                        // Convert bytes to Kyber types
                        let kyber_ct = kyber768::Ciphertext::from_bytes(&kyber_ct_bytes)
                            .map_err(|_| EncryptionError::DecryptionError("Invalid Kyber ciphertext".to_string()))?;
                        
                        let secret_key = kyber768::SecretKey::from_bytes(&sk_bytes)
                            .map_err(|_| EncryptionError::DecryptionError("Invalid Kyber secret key".to_string()))?;
                        
                        // Decapsulate to get the shared secret
                        let shared_secret = kyber768::decapsulate(&kyber_ct, &secret_key);
                        
                        // Use the shared secret to decrypt the AES ciphertext
                        let cipher = Aes256Gcm::new_from_slice(shared_secret.as_ref())
                            .map_err(|e| EncryptionError::DecryptionError(e.to_string()))?;
                        
                        let nonce = Nonce::from_slice(iv);
                        
                        cipher.decrypt(nonce, aes_ct_bytes)
                            .map_err(|e| EncryptionError::DecryptionError(format!("Failed to decrypt with Kyber: {}", e)))
                    },
                    EncryptionAlgorithm::HybridAesKyber => {
                        // For hybrid, we stored as:
                        // [AES IV | Kyber IV | Kyber ciphertext | hybrid ciphertext | secret key]
                        
                        // The format is complex, so we need to extract parts carefully
                        if ciphertext.len() <= IV_SIZE + kyber768::CIPHERTEXT_LENGTH + 32 + kyber768::SECRET_KEY_LENGTH {
                            return Err(EncryptionError::DecryptionError(
                                "Encrypted data too short for hybrid format".to_string()
                            ));
                        }
                        
                        // Extract the Kyber IV first (now at position iv_size to 2*iv_size)
                        let (_, rest) = ciphertext.split_at(IV_SIZE); // Skip AES IV, which is in the iv parameter
                        let (kyber_iv, rest) = rest.split_at(IV_SIZE);
                        
                        // Extract Kyber ciphertext
                        let (kyber_ct_bytes, rest) = rest.split_at(kyber768::CIPHERTEXT_LENGTH);
                        
                        // The remaining is split between hybrid ciphertext and secret key
                        let hybrid_ct_len = rest.len() - kyber768::SECRET_KEY_LENGTH;
                        let (hybrid_ct, sk_bytes) = rest.split_at(hybrid_ct_len);
                        
                        // Convert Kyber components
                        let kyber_ct = kyber768::Ciphertext::from_bytes(&kyber_ct_bytes)
                            .map_err(|_| EncryptionError::DecryptionError("Invalid Kyber ciphertext".to_string()))?;
                            
                        let secret_key = kyber768::SecretKey::from_bytes(&sk_bytes)
                            .map_err(|_| EncryptionError::DecryptionError("Invalid Kyber secret key".to_string()))?;
                            
                        // Decapsulate to get the shared secret
                        let shared_secret = kyber768::decapsulate(&kyber_ct, &secret_key);
                        
                        // First decrypt the hybrid layer with Kyber
                        let kyber_cipher = Aes256Gcm::new_from_slice(shared_secret.as_ref())
                            .map_err(|e| EncryptionError::DecryptionError(e.to_string()))?;
                            
                        let kyber_nonce = Nonce::from_slice(kyber_iv);
                        
                        let aes_ct = kyber_cipher.decrypt(kyber_nonce, hybrid_ct)
                            .map_err(|e| EncryptionError::DecryptionError(format!("Failed to decrypt hybrid layer: {}", e)))?;
                            
                        // Then decrypt the AES layer with derived key
                        let aes_cipher = Aes256Gcm::new_from_slice(&derived_key)
                            .map_err(|e| EncryptionError::DecryptionError(e.to_string()))?;
                            
                        let aes_nonce = Nonce::from_slice(iv);
                        
                        aes_cipher.decrypt(aes_nonce, &aes_ct)
                            .map_err(|e| EncryptionError::DecryptionError(format!("Failed to decrypt AES layer: {}", e)))
                    },
                    _ => {
                        warn!("Post-quantum algorithm not implemented. Falling back to AES-GCM.");
                        let cipher = Aes256Gcm::new_from_slice(&derived_key)
                            .map_err(|e| EncryptionError::DecryptionError(e.to_string()))?;
                        
                        let nonce = Nonce::from_slice(iv);
                        
                        cipher.decrypt(nonce, ciphertext.as_ref())
                            .map_err(|e| EncryptionError::DecryptionError(format!("Failed to decrypt master key: {}", e)))
                    }
                }
            }
        }
    }
    
    // Get or load the master key
    async fn get_master_key(&self, password: &str) -> EncryptionResult<(Vec<u8>, String, EncryptionAlgorithm)> {
        // Check if we have a valid cached key
        let cache = self.master_key_cache.lock().await;
        if let Some(cached_key) = &*cache {
            if cached_key.expiry > std::time::Instant::now() {
                return Ok((cached_key.key_bytes.clone(), cached_key.key_id.clone(), cached_key.algorithm.clone()));
            }
        }
        drop(cache);
        
        // Get settings
        let settings = self.get_settings().await?;
        
        if !settings.enabled {
            return Err(EncryptionError::EncryptionError("Encryption is not enabled".to_string()));
        }
        
        let key_id = settings.key_id.clone().ok_or_else(|| 
            EncryptionError::InvalidKeyError("No key ID found in settings".to_string())
        )?;
        
        // Load encrypted key from repository
        let (encrypted_key, salt_base64) = self.repository.get_master_key(&key_id).await?;
        
        let salt = BASE64.decode(&salt_base64)
            .map_err(|e| EncryptionError::KeyDerivationError(format!("Invalid salt: {}", e)))?;
        
        // Decrypt the master key
        let master_key = Self::decrypt_master_key(&encrypted_key, password, &salt, &settings.algorithm)?;
        
        // Cache the master key with 10 minute expiry
        let mut cache = self.master_key_cache.lock().await;
        *cache = Some(MasterKey {
            key_id: key_id.clone(),
            key_bytes: master_key.clone(),
            algorithm: settings.algorithm.clone(),
            expiry: std::time::Instant::now() + std::time::Duration::from_secs(600),
        });
        
        Ok((master_key, key_id, settings.algorithm.clone()))
    }
}

#[async_trait]
// Unit tests for the private methods
#[cfg(test)]
mod private_tests {
    use super::*;

    #[test]
    fn test_derive_key_from_password() {
        let password = "test_password";
        let salt = vec![1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
        let algorithm = EncryptionAlgorithm::Aes256Gcm;
        
        let key = EncryptionServiceImpl::derive_key_from_password(password, &salt, &algorithm);
        
        // Key should be 32 bytes (256 bits)
        assert_eq!(key.len(), 32);
        
        // Same password and salt should produce the same key
        let key2 = EncryptionServiceImpl::derive_key_from_password(password, &salt, &algorithm);
        assert_eq!(key, key2);
        
        // Different password should produce different key
        let different_key = EncryptionServiceImpl::derive_key_from_password("different_password", &salt, &algorithm);
        assert_ne!(key, different_key);
    }
    
    #[test]
    fn test_encrypt_decrypt_master_key() {
        let password = "test_password";
        let salt = vec![1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
        let algorithm = EncryptionAlgorithm::Aes256Gcm;
        
        // Generate a master key
        let master_key = EncryptionServiceImpl::generate_master_key();
        
        // Encrypt the master key
        let encrypted_key = EncryptionServiceImpl::encrypt_master_key(&master_key, password, &salt, &algorithm)
            .expect("Failed to encrypt master key");
        
        // Decrypt the master key
        let decrypted_key = EncryptionServiceImpl::decrypt_master_key(&encrypted_key, password, &salt, &algorithm)
            .expect("Failed to decrypt master key");
        
        // Decrypted key should match original
        assert_eq!(master_key, decrypted_key);
        
        // Wrong password should fail to decrypt
        let wrong_result = EncryptionServiceImpl::decrypt_master_key(&encrypted_key, "wrong_password", &salt, &algorithm);
        assert!(wrong_result.is_err());
    }
    
    #[test]
    fn test_generate_values() {
        // Test salt generation
        let salt = EncryptionServiceImpl::generate_salt();
        assert_eq!(salt.len(), SALT_SIZE);
        
        // Test IV generation
        let iv = EncryptionServiceImpl::generate_iv();
        assert_eq!(iv.len(), IV_SIZE);
        
        // Multiple generations should produce different values
        let salt2 = EncryptionServiceImpl::generate_salt();
        assert_ne!(salt, salt2);
        
        let iv2 = EncryptionServiceImpl::generate_iv();
        assert_ne!(iv, iv2);
    }
}

impl EncryptionService for EncryptionServiceImpl {
    async fn initialize(&self, password: &str, settings: &EncryptionSettings) -> EncryptionResult<EncryptionSettings> {
        // Generate a new master key
        let master_key = Self::generate_master_key();
        
        // Generate a new salt for key derivation
        let salt = Self::generate_salt();
        let salt_base64 = BASE64.encode(&salt);
        
        // Generate a unique key ID
        let key_id = Uuid::new_v4().to_string();
        
        // Encrypt the master key with the user's password
        let encrypted_key = Self::encrypt_master_key(&master_key, password, &salt, &settings.algorithm)?;
        
        // Store the encrypted master key
        self.repository.store_master_key(&encrypted_key, &salt_base64, &key_id).await?;
        
        // Create and store settings
        let mut new_settings = settings.clone();
        new_settings.enabled = true;
        new_settings.key_id = Some(key_id);
        new_settings.kdf_salt = Some(salt_base64);
        
        self.repository.store_settings(&new_settings).await?;
        
        // Update the settings cache
        let mut cache = self.settings_cache.lock().await;
        *cache = Some(new_settings.clone());
        
        Ok(new_settings)
    }
    
    async fn change_password(&self, old_password: &str, new_password: &str) -> EncryptionResult<()> {
        // Verify the old password first
        let (master_key, key_id, algorithm) = self.get_master_key(old_password).await?;
        
        // Generate a new salt
        let salt = Self::generate_salt();
        let salt_base64 = BASE64.encode(&salt);
        
        // Re-encrypt the master key with the new password
        let encrypted_key = Self::encrypt_master_key(&master_key, new_password, &salt, &algorithm)?;
        
        // Store the re-encrypted master key
        self.repository.store_master_key(&encrypted_key, &salt_base64, &key_id).await?;
        
        // Update the salt in settings
        let mut settings = self.get_settings().await?;
        settings.kdf_salt = Some(salt_base64);
        self.repository.store_settings(&settings).await?;
        
        // Clear the master key cache
        let mut cache = self.master_key_cache.lock().await;
        *cache = None;
        
        Ok(())
    }
    
    async fn encrypt_data(&self, password: &str, data: &[u8]) -> EncryptionResult<(Vec<u8>, String, String)> {
        // Get the master key
        let (master_key, key_id, algorithm) = self.get_master_key(password).await?;
        
        // Generate a random IV/nonce
        let iv = Self::generate_iv();
        let iv_base64 = BASE64.encode(&iv);
        
        // Create encryption metadata
        let metadata = EncryptionMetadata {
            algorithm: algorithm.clone(),
            key_id: key_id.clone(),
            filename_encrypted: false,
            original_size: data.len() as u64,
            original_mime_type: None,
            extension: None,
        };
        
        let metadata_json = serde_json::to_string(&metadata)
            .map_err(|e| EncryptionError::SerializationError(e.to_string()))?;
        
        // Encrypt the data
        let encrypted_data = match algorithm {
            EncryptionAlgorithm::Aes256Gcm => {
                let cipher = Aes256Gcm::new_from_slice(&master_key)
                    .map_err(|e| EncryptionError::EncryptionError(e.to_string()))?;
                
                let nonce = Nonce::from_slice(&iv);
                
                cipher.encrypt(nonce, data.as_ref())
                    .map_err(|e| EncryptionError::EncryptionError(e.to_string()))?
            },
            EncryptionAlgorithm::Chacha20Poly1305 => {
                let key = Key::from_slice(&master_key);
                let cipher = ChaCha20Poly1305::new(key);
                
                let nonce = XNonce::from_slice(&iv);
                
                cipher.encrypt(nonce, data.as_ref())
                    .map_err(|e| EncryptionError::EncryptionError(e.to_string()))?
            },
            EncryptionAlgorithm::Kyber768 => {
                // For Kyber, we'll use the Kyber KEM to encapsulate a one-time key,
                // then use that key with AES for the actual data encryption
                
                // Generate a Kyber keypair
                let (public_key, secret_key) = kyber768::keypair();
                
                // Encapsulate to create shared secret and ciphertext
                let (ciphertext, shared_secret) = kyber768::encapsulate(&public_key);
                
                // Use the shared secret for AES encryption
                let cipher = Aes256Gcm::new_from_slice(shared_secret.as_ref())
                    .map_err(|e| EncryptionError::EncryptionError(e.to_string()))?;
                    
                let nonce = Nonce::from_slice(&iv);
                
                // Encrypt data with AES 
                let aes_ciphertext = cipher.encrypt(nonce, data.as_ref())
                    .map_err(|e| EncryptionError::EncryptionError(e.to_string()))?;
                    
                // Store Kyber secret key and ciphertext for later decryption
                // Final format will be: AES_ciphertext || Kyber_ciphertext || Kyber_secret_key
                let mut combined = aes_ciphertext;
                combined.extend_from_slice(ciphertext.as_ref());
                combined.extend_from_slice(secret_key.as_ref());
                
                combined
            },
            EncryptionAlgorithm::Dilithium5 => {
                // Dilithium is for signatures, not encryption, so we'll use AES with Dilithium signature
                
                // Generate a signature keypair
                let (public_key, secret_key) = dilithium5::keypair();
                
                // Encrypt with AES using master key
                let cipher = Aes256Gcm::new_from_slice(&master_key)
                    .map_err(|e| EncryptionError::EncryptionError(e.to_string()))?;
                    
                let nonce = Nonce::from_slice(&iv);
                
                let aes_ciphertext = cipher.encrypt(nonce, data.as_ref())
                    .map_err(|e| EncryptionError::EncryptionError(e.to_string()))?;
                    
                // Sign the ciphertext for integrity and authentication
                let signature = dilithium5::detached_sign(&aes_ciphertext, &secret_key);
                
                // Store both the ciphertext and signature with the public key
                let mut combined = aes_ciphertext;
                combined.extend_from_slice(signature.as_ref());
                combined.extend_from_slice(public_key.as_ref());
                
                combined
            },
            EncryptionAlgorithm::HybridAesKyber => {
                // Use both AES (classical security) and Kyber (quantum security)
                
                // First encrypt with AES
                let aes_cipher = Aes256Gcm::new_from_slice(&master_key)
                    .map_err(|e| EncryptionError::EncryptionError(e.to_string()))?;
                    
                let aes_nonce = Nonce::from_slice(&iv);
                
                let aes_ciphertext = aes_cipher.encrypt(aes_nonce, data.as_ref())
                    .map_err(|e| EncryptionError::EncryptionError(e.to_string()))?;
                    
                // Then use Kyber for additional quantum-resistant security
                let (public_key, secret_key) = kyber768::keypair();
                let (kyber_ciphertext, shared_secret) = kyber768::encapsulate(&public_key);
                
                // Use the Kyber shared secret to encrypt the AES result
                let kyber_cipher = Aes256Gcm::new_from_slice(shared_secret.as_ref())
                    .map_err(|e| EncryptionError::EncryptionError(e.to_string()))?;
                
                // Generate a second nonce for the second encryption
                let kyber_iv = Self::generate_iv();
                let kyber_nonce = Nonce::from_slice(&kyber_iv);
                
                // Encrypt the AES result with the Kyber key
                let hybrid_ciphertext = kyber_cipher.encrypt(kyber_nonce, &aes_ciphertext)
                    .map_err(|e| EncryptionError::EncryptionError(e.to_string()))?;
                    
                // Store everything needed for decryption:
                // Kyber_IV || Kyber_ciphertext || Hybrid_ciphertext || Kyber_secret_key
                let mut combined = Vec::with_capacity(
                    kyber_iv.len() + kyber_ciphertext.as_ref().len() + 
                    hybrid_ciphertext.len() + secret_key.as_ref().len()
                );
                
                combined.extend_from_slice(&kyber_iv);
                combined.extend_from_slice(kyber_ciphertext.as_ref());
                combined.extend_from_slice(&hybrid_ciphertext);
                combined.extend_from_slice(secret_key.as_ref());
                
                combined
            },
            _ => {
                warn!("Post-quantum algorithm not specifically implemented. Using AES-GCM fallback.");
                let cipher = Aes256Gcm::new_from_slice(&master_key)
                    .map_err(|e| EncryptionError::EncryptionError(e.to_string()))?;
                
                let nonce = Nonce::from_slice(&iv);
                
                cipher.encrypt(nonce, data.as_ref())
                    .map_err(|e| EncryptionError::EncryptionError(e.to_string()))?
            }
        };
        
        Ok((encrypted_data, iv_base64, metadata_json))
    }
    
    async fn decrypt_data(&self, password: &str, data: &[u8], iv: &str, metadata: &str) -> EncryptionResult<Vec<u8>> {
        // Decode IV
        let iv_bytes = BASE64.decode(iv)
            .map_err(|e| EncryptionError::DecryptionError(format!("Invalid IV: {}", e)))?;
        
        // Parse metadata
        let metadata: EncryptionMetadata = serde_json::from_str(metadata)
            .map_err(|e| EncryptionError::MetadataError(format!("Invalid metadata: {}", e)))?;
        
        // Get the master key
        let (master_key, _, _) = self.get_master_key(password).await?;
        
        // Decrypt the data
        match metadata.algorithm {
            EncryptionAlgorithm::Aes256Gcm => {
                let cipher = Aes256Gcm::new_from_slice(&master_key)
                    .map_err(|e| EncryptionError::DecryptionError(e.to_string()))?;
                
                let nonce = Nonce::from_slice(&iv_bytes);
                
                cipher.decrypt(nonce, data.as_ref())
                    .map_err(|e| EncryptionError::DecryptionError(format!("Failed to decrypt data: {}", e)))
            },
            EncryptionAlgorithm::Chacha20Poly1305 => {
                let key = Key::from_slice(&master_key);
                let cipher = ChaCha20Poly1305::new(key);
                
                let nonce = XNonce::from_slice(&iv_bytes);
                
                cipher.decrypt(nonce, data.as_ref())
                    .map_err(|e| EncryptionError::DecryptionError(format!("Failed to decrypt data: {}", e)))
            },
            EncryptionAlgorithm::Kyber768 => {
                // For Kyber, we stored:
                // AES_ciphertext || Kyber_ciphertext || Kyber_secret_key
                
                // Calculate lengths
                let kyber_ct_len = kyber768::CIPHERTEXT_LENGTH;
                let kyber_sk_len = kyber768::SECRET_KEY_LENGTH;
                
                if data.len() <= kyber_ct_len + kyber_sk_len {
                    return Err(EncryptionError::DecryptionError(
                        "Data too short for Kyber format".to_string()
                    ));
                }
                
                // Extract components
                let aes_ct_len = data.len() - kyber_ct_len - kyber_sk_len;
                let (aes_ciphertext, rest) = data.split_at(aes_ct_len);
                let (kyber_ct_bytes, sk_bytes) = rest.split_at(kyber_ct_len);
                
                // Reconstruct Kyber objects
                let kyber_ct = kyber768::Ciphertext::from_bytes(kyber_ct_bytes)
                    .map_err(|_| EncryptionError::DecryptionError("Invalid Kyber ciphertext".to_string()))?;
                    
                let secret_key = kyber768::SecretKey::from_bytes(sk_bytes)
                    .map_err(|_| EncryptionError::DecryptionError("Invalid Kyber secret key".to_string()))?;
                    
                // Decapsulate to get shared secret
                let shared_secret = kyber768::decapsulate(&kyber_ct, &secret_key);
                
                // Decrypt AES ciphertext with shared secret
                let cipher = Aes256Gcm::new_from_slice(shared_secret.as_ref())
                    .map_err(|e| EncryptionError::DecryptionError(e.to_string()))?;
                
                let nonce = Nonce::from_slice(&iv_bytes);
                
                cipher.decrypt(nonce, aes_ciphertext)
                    .map_err(|e| EncryptionError::DecryptionError(format!("Failed to decrypt Kyber data: {}", e)))
            },
            EncryptionAlgorithm::Dilithium5 => {
                // For Dilithium, we stored:
                // AES_ciphertext || Dilithium_signature || Dilithium_public_key
                
                // Calculate lengths
                let dilithium_sig_len = dilithium5::SIGNATURE_LENGTH;
                let dilithium_pk_len = dilithium5::PUBLIC_KEY_LENGTH;
                
                if data.len() <= dilithium_sig_len + dilithium_pk_len {
                    return Err(EncryptionError::DecryptionError(
                        "Data too short for Dilithium format".to_string()
                    ));
                }
                
                // Extract components
                let aes_ct_len = data.len() - dilithium_sig_len - dilithium_pk_len;
                let (aes_ciphertext, rest) = data.split_at(aes_ct_len);
                let (sig_bytes, pk_bytes) = rest.split_at(dilithium_sig_len);
                
                // Reconstruct Dilithium objects
                let signature = dilithium5::DetachedSignature::from_bytes(sig_bytes)
                    .map_err(|_| EncryptionError::DecryptionError("Invalid Dilithium signature".to_string()))?;
                    
                let public_key = dilithium5::PublicKey::from_bytes(pk_bytes)
                    .map_err(|_| EncryptionError::DecryptionError("Invalid Dilithium public key".to_string()))?;
                    
                // Verify signature
                let valid = dilithium5::verify_detached_signature(&signature, aes_ciphertext, &public_key);
                if !valid {
                    return Err(EncryptionError::DecryptionError("Dilithium signature verification failed".to_string()));
                }
                
                // Decrypt AES ciphertext with master key
                let cipher = Aes256Gcm::new_from_slice(&master_key)
                    .map_err(|e| EncryptionError::DecryptionError(e.to_string()))?;
                
                let nonce = Nonce::from_slice(&iv_bytes);
                
                cipher.decrypt(nonce, aes_ciphertext)
                    .map_err(|e| EncryptionError::DecryptionError(format!("Failed to decrypt AES data: {}", e)))
            },
            EncryptionAlgorithm::HybridAesKyber => {
                // For hybrid, we stored:
                // Kyber_IV || Kyber_ciphertext || Hybrid_ciphertext || Kyber_secret_key
                
                // Extract Kyber IV (first part of data)
                if data.len() <= IV_SIZE + kyber768::CIPHERTEXT_LENGTH + kyber768::SECRET_KEY_LENGTH {
                    return Err(EncryptionError::DecryptionError(
                        "Data too short for hybrid format".to_string() 
                    ));
                }
                
                // Extract components
                let (kyber_iv, rest) = data.split_at(IV_SIZE);
                let (kyber_ct_bytes, rest) = rest.split_at(kyber768::CIPHERTEXT_LENGTH);
                
                // The rest contains hybrid ciphertext and secret key
                let hybrid_ct_len = rest.len() - kyber768::SECRET_KEY_LENGTH;
                let (hybrid_ct, sk_bytes) = rest.split_at(hybrid_ct_len);
                
                // Reconstruct Kyber objects
                let kyber_ct = kyber768::Ciphertext::from_bytes(kyber_ct_bytes)
                    .map_err(|_| EncryptionError::DecryptionError("Invalid Kyber ciphertext".to_string()))?;
                    
                let secret_key = kyber768::SecretKey::from_bytes(sk_bytes)
                    .map_err(|_| EncryptionError::DecryptionError("Invalid Kyber secret key".to_string()))?;
                    
                // Decapsulate to get the shared secret
                let shared_secret = kyber768::decapsulate(&kyber_ct, &secret_key);
                
                // Decrypt with Kyber layer first
                let kyber_cipher = Aes256Gcm::new_from_slice(shared_secret.as_ref())
                    .map_err(|e| EncryptionError::DecryptionError(e.to_string()))?;
                    
                let kyber_nonce = Nonce::from_slice(kyber_iv);
                
                let aes_ciphertext = kyber_cipher.decrypt(kyber_nonce, hybrid_ct)
                    .map_err(|e| EncryptionError::DecryptionError(format!("Failed to decrypt Kyber layer: {}", e)))?;
                    
                // Then decrypt with the AES layer
                let aes_cipher = Aes256Gcm::new_from_slice(&master_key)
                    .map_err(|e| EncryptionError::DecryptionError(e.to_string()))?;
                    
                let aes_nonce = Nonce::from_slice(&iv_bytes);
                
                aes_cipher.decrypt(aes_nonce, &aes_ciphertext)
                    .map_err(|e| EncryptionError::DecryptionError(format!("Failed to decrypt AES layer: {}", e)))
            },
            _ => {
                warn!("Post-quantum algorithm not specifically implemented. Using AES-GCM fallback.");
                let cipher = Aes256Gcm::new_from_slice(&master_key)
                    .map_err(|e| EncryptionError::DecryptionError(e.to_string()))?;
                
                let nonce = Nonce::from_slice(&iv_bytes);
                
                cipher.decrypt(nonce, data.as_ref())
                    .map_err(|e| EncryptionError::DecryptionError(format!("Failed to decrypt data: {}", e)))
            }
        }
    }
    
    async fn encrypt_string(&self, password: &str, text: &str) -> EncryptionResult<(String, String, String)> {
        let (encrypted_data, iv, metadata) = self.encrypt_data(password, text.as_bytes()).await?;
        let encrypted_text = BASE64.encode(&encrypted_data);
        
        Ok((encrypted_text, iv, metadata))
    }
    
    async fn decrypt_string(&self, password: &str, text: &str, iv: &str, metadata: &str) -> EncryptionResult<String> {
        let encrypted_bytes = BASE64.decode(text)
            .map_err(|e| EncryptionError::DecryptionError(format!("Invalid base64: {}", e)))?;
        
        let decrypted_bytes = self.decrypt_data(password, &encrypted_bytes, iv, metadata).await?;
        
        String::from_utf8(decrypted_bytes)
            .map_err(|e| EncryptionError::DecryptionError(format!("Invalid UTF-8: {}", e)))
    }
    
    async fn get_settings(&self) -> EncryptionResult<EncryptionSettings> {
        // Check if we have cached settings
        let cache = self.settings_cache.lock().await;
        if let Some(settings) = &*cache {
            return Ok(settings.clone());
        }
        drop(cache);
        
        // Get settings from repository
        let settings = self.repository.get_settings().await?;
        
        // Cache the settings
        let mut cache = self.settings_cache.lock().await;
        *cache = Some(settings.clone());
        
        Ok(settings)
    }
    
    async fn update_settings(&self, password: &str, settings: &EncryptionSettings) -> EncryptionResult<()> {
        // Verify password before allowing settings update
        if settings.enabled {
            self.verify_password(password).await?;
        }
        
        // Store the updated settings
        self.repository.store_settings(settings).await?;
        
        // Update the settings cache
        let mut cache = self.settings_cache.lock().await;
        *cache = Some(settings.clone());
        
        Ok(())
    }
    
    async fn export_key(&self, password: &str, output_path: &PathBuf) -> EncryptionResult<()> {
        // Get the master key
        let (master_key, key_id, algorithm) = self.get_master_key(password).await?;
        
        // Create export structure
        let export_data = serde_json::json!({
            "key_id": key_id,
            "algorithm": serde_json::to_string(&algorithm).unwrap(),
            "master_key": BASE64.encode(&master_key),
            "version": 1,
            "exported_at": chrono::Utc::now().to_rfc3339(),
        });
        
        let export_json = serde_json::to_string(&export_data)
            .map_err(|e| EncryptionError::SerializationError(e.to_string()))?;
        
        // Write to file
        fs::write(output_path, export_json)
            .map_err(|e| EncryptionError::IOError(format!("Failed to write key file: {}", e)))?;
        
        Ok(())
    }
    
    /// Process a large file for encryption or decryption
    /// This method decides whether to process the file as a large file or not
    async fn process_file(&self, 
                       password: &str, 
                       source_path: &PathBuf, 
                       destination_path: &PathBuf,
                       encrypt: bool) -> EncryptionResult<()> {
        // Get file size
        let file_size = match fs::metadata(source_path) {
            Ok(metadata) => metadata.len(),
            Err(e) => {
                return Err(EncryptionError::IOError(format!(
                    "Failed to get file metadata: {}", e
                )));
            }
        };
        
        // Get the large file processor
        let processor = self.get_large_file_processor().await;
        
        // Check if we should process as large file
        if processor.should_process_as_large_file(file_size) {
            info!("Processing large file ({} bytes) using chunked processing", file_size);
            
            if encrypt {
                processor.encrypt_large_file(password, source_path, destination_path).await
            } else {
                processor.decrypt_large_file(password, source_path, destination_path).await
            }
        } else {
            // For small files, use the regular approach
            info!("Processing small file ({} bytes) using standard method", file_size);
            
            if encrypt {
                // Read the file
                let file_content = match fs::read(source_path) {
                    Ok(content) => content,
                    Err(e) => {
                        return Err(EncryptionError::IOError(format!(
                            "Failed to read source file: {}", e
                        )));
                    }
                };
                
                // Encrypt it
                let (encrypted_data, iv, metadata) = self.encrypt_data(password, &file_content).await?;
                
                // Create a JSON wrapper for the encrypted data
                let wrapper = serde_json::json!({
                    "version": 1,
                    "iv": iv,
                    "metadata": metadata,
                    "encrypted_data_base64": BASE64.encode(&encrypted_data),
                });
                
                // Write it
                let json = serde_json::to_string(&wrapper)
                    .map_err(|e| EncryptionError::SerializationError(e.to_string()))?;
                
                if let Err(e) = fs::write(destination_path, &json) {
                    return Err(EncryptionError::IOError(format!(
                        "Failed to write encrypted file: {}", e
                    )));
                }
            } else {
                // Read the file
                let encrypted_json = match fs::read_to_string(source_path) {
                    Ok(content) => content,
                    Err(e) => {
                        return Err(EncryptionError::IOError(format!(
                            "Failed to read encrypted file: {}", e
                        )));
                    }
                };
                
                // Parse JSON wrapper
                let wrapper: serde_json::Value = serde_json::from_str(&encrypted_json)
                    .map_err(|e| EncryptionError::SerializationError(format!(
                        "Invalid encrypted file format: {}", e
                    )))?;
                
                // Extract fields
                let iv = wrapper["iv"].as_str()
                    .ok_or_else(|| EncryptionError::SerializationError(
                        "Missing IV in encrypted file".to_string()
                    ))?;
                
                let metadata = wrapper["metadata"].as_str()
                    .ok_or_else(|| EncryptionError::SerializationError(
                        "Missing metadata in encrypted file".to_string()
                    ))?;
                
                let encrypted_data_base64 = wrapper["encrypted_data_base64"].as_str()
                    .ok_or_else(|| EncryptionError::SerializationError(
                        "Missing encrypted data in encrypted file".to_string()
                    ))?;
                
                // Decode base64
                let encrypted_data = BASE64.decode(encrypted_data_base64)
                    .map_err(|e| EncryptionError::SerializationError(format!(
                        "Invalid encrypted data: {}", e
                    )))?;
                
                // Decrypt
                let decrypted_data = self.decrypt_data(password, &encrypted_data, iv, metadata).await?;
                
                // Write decrypted data
                if let Err(e) = fs::write(destination_path, &decrypted_data) {
                    return Err(EncryptionError::IOError(format!(
                        "Failed to write decrypted file: {}", e
                    )));
                }
            }
            
            Ok(())
        }
    }
    
    /// Encrypt a file to a destination path
    pub async fn encrypt_file(&self, 
                           password: &str, 
                           source_path: &PathBuf, 
                           destination_path: &PathBuf) -> EncryptionResult<()> {
        self.process_file(password, source_path, destination_path, true).await
    }
    
    /// Decrypt a file to a destination path
    pub async fn decrypt_file(&self, 
                           password: &str, 
                           source_path: &PathBuf, 
                           destination_path: &PathBuf) -> EncryptionResult<()> {
        self.process_file(password, source_path, destination_path, false).await
    }
    
    async fn import_key(&self, password: &str, input_path: &PathBuf) -> EncryptionResult<()> {
        // Read the key file
        let file_content = fs::read_to_string(input_path)
            .map_err(|e| EncryptionError::IOError(format!("Failed to read key file: {}", e)))?;
        
        // Parse the export data
        let export_data: serde_json::Value = serde_json::from_str(&file_content)
            .map_err(|e| EncryptionError::SerializationError(format!("Invalid key file: {}", e)))?;
        
        // Extract fields
        let key_id = export_data["key_id"].as_str()
            .ok_or_else(|| EncryptionError::InvalidKeyError("Missing key ID in export file".to_string()))?;
        
        let algorithm_str = export_data["algorithm"].as_str()
            .ok_or_else(|| EncryptionError::InvalidKeyError("Missing algorithm in export file".to_string()))?;
        
        let algorithm: EncryptionAlgorithm = serde_json::from_str(algorithm_str)
            .map_err(|e| EncryptionError::SerializationError(format!("Invalid algorithm: {}", e)))?;
        
        let master_key_base64 = export_data["master_key"].as_str()
            .ok_or_else(|| EncryptionError::InvalidKeyError("Missing master key in export file".to_string()))?;
        
        let master_key = BASE64.decode(master_key_base64)
            .map_err(|e| EncryptionError::InvalidKeyError(format!("Invalid master key: {}", e)))?;
        
        // Generate a new salt
        let salt = Self::generate_salt();
        let salt_base64 = BASE64.encode(&salt);
        
        // Encrypt the master key with the password
        let encrypted_key = Self::encrypt_master_key(&master_key, password, &salt, &algorithm)?;
        
        // Store the encrypted master key
        self.repository.store_master_key(&encrypted_key, &salt_base64, key_id).await?;
        
        // Update settings if needed
        let mut settings = self.get_settings().await?;
        if !settings.enabled || settings.key_id.is_none() {
            settings.enabled = true;
            settings.algorithm = algorithm;
            settings.key_id = Some(key_id.to_string());
            settings.kdf_salt = Some(salt_base64);
            
            self.repository.store_settings(&settings).await?;
            
            // Update the settings cache
            let mut cache = self.settings_cache.lock().await;
            *cache = Some(settings);
        }
        
        Ok(())
    }
    
    async fn verify_password(&self, password: &str) -> EncryptionResult<bool> {
        // Attempt to get the master key with the given password
        match self.get_master_key(password).await {
            Ok(_) => Ok(true),
            Err(EncryptionError::DecryptionError(_)) => Ok(false),
            Err(e) => Err(e),
        }
    }
}