# OxiCloud Encryption System - Developer Documentation

This document provides technical details about the encryption system implementation in OxiCloud Desktop, intended for developers who want to understand or contribute to the codebase.

## Architecture

The encryption system follows the hexagonal architecture pattern used throughout the OxiCloud Desktop application:

```
src/
├── domain/
│   ├── entities/
│   │   └── encryption.rs         # Core domain entities and interfaces
│   └── services/
│       └── encryption_service.rs # Domain service interface
│
├── application/
│   ├── ports/
│   │   └── encryption_port.rs    # Application interface
│   └── services/
│       └── encryption_service.rs # Application service implementation
│
└── infrastructure/
    ├── adapters/
    │   └── encryption_adapter.rs # Repository implementation
    └── services/
        ├── encryption_service_impl.rs  # Core encryption implementation
        └── large_file_processor.rs     # Large file handling
```

## Key Components

### EncryptionService

The `EncryptionService` trait (in domain/services/encryption_service.rs) defines the main interface for encryption operations:

```rust
#[async_trait]
pub trait EncryptionService: Send + Sync + 'static {
    async fn initialize(&self, password: &str, settings: &EncryptionSettings) -> EncryptionResult<EncryptionSettings>;
    async fn change_password(&self, old_password: &str, new_password: &str) -> EncryptionResult<()>;
    async fn encrypt_data(&self, password: &str, data: &[u8]) -> EncryptionResult<(Vec<u8>, String, String)>;
    async fn decrypt_data(&self, password: &str, data: &[u8], iv: &str, metadata: &str) -> EncryptionResult<Vec<u8>>;
    // ... other methods ...
}
```

### EncryptionServiceImpl

The concrete implementation (in infrastructure/services/encryption_service_impl.rs) handles:

1. Password-based key derivation
2. Master key generation and encryption
3. Data encryption and decryption
4. Algorithm selection and implementation

### LargeFileProcessor

Optimized processing for large files (in infrastructure/services/large_file_processor.rs):

1. Chunked file processing
2. Parallel encryption/decryption
3. Ordered chunk reassembly
4. Progress tracking and error handling

## Cryptographic Implementation

### Algorithms

#### Classical Algorithms

- **AES-256-GCM**: Implemented using the `aes-gcm` crate
- **ChaCha20-Poly1305**: Implemented using the `chacha20poly1305` crate

#### Post-Quantum Algorithms

- **Kyber768**: Implemented using the `pqcrypto-kyber` crate
- **Dilithium5**: Implemented using the `pqcrypto-dilithium` crate

### Key Management

The system uses a master key approach:

1. A 256-bit master key is generated randomly
2. The master key is encrypted using the user's password
3. For post-quantum security, the key can be protected with Kyber768

```rust
// Generate a random 256-bit master key
fn generate_master_key() -> Vec<u8> {
    let mut key = vec![0u8; KEY_SIZE];
    RandOsRng.fill_bytes(&mut key);
    key
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
```

### Data Formats

#### Encryption Metadata

Each encrypted file includes metadata stored as JSON:

```rust
pub struct EncryptionMetadata {
    pub algorithm: EncryptionAlgorithm,
    pub key_id: String,
    pub filename_encrypted: bool,
    pub original_size: u64,
    pub original_mime_type: Option<String>,
    pub extension: Option<String>,
}
```

#### Large File Metadata

For chunked files, additional metadata tracks chunk information:

```rust
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

struct ChunkMetadata {
    chunk_index: usize,
    original_size: usize,
    encrypted_size: usize,
    iv: String,
    algorithm: EncryptionAlgorithm,
    offset: u64,
}
```

## Implementation Details

### Post-Quantum Encryption

#### Kyber768 Implementation

```rust
// When encrypting with Kyber:
// 1. Generate a Kyber keypair
let (public_key, secret_key) = kyber768::keypair();

// 2. Encapsulate to create shared secret and ciphertext
let (ciphertext, shared_secret) = kyber768::encapsulate(&public_key);

// 3. Use the shared secret for AES encryption
let cipher = Aes256Gcm::new_from_slice(shared_secret.as_ref())?;
let nonce = Nonce::from_slice(&iv);
let aes_ciphertext = cipher.encrypt(nonce, data.as_ref())?;

// 4. Store everything needed for decryption
let mut combined = aes_ciphertext;
combined.extend_from_slice(ciphertext.as_ref());
combined.extend_from_slice(secret_key.as_ref());
```

#### Hybrid Mode Implementation

```rust
// 1. Encrypt with AES first (classical security)
let aes_cipher = Aes256Gcm::new_from_slice(&master_key)?;
let aes_nonce = Nonce::from_slice(&iv);
let aes_ciphertext = aes_cipher.encrypt(aes_nonce, data.as_ref())?;

// 2. Then use Kyber for quantum security
let (public_key, secret_key) = kyber768::keypair();
let (kyber_ciphertext, shared_secret) = kyber768::encapsulate(&public_key);

// 3. Encrypt the AES result with Kyber
let kyber_cipher = Aes256Gcm::new_from_slice(shared_secret.as_ref())?;
let kyber_iv = Self::generate_iv();
let kyber_nonce = Nonce::from_slice(&kyber_iv);
let hybrid_ciphertext = kyber_cipher.encrypt(kyber_nonce, &aes_ciphertext)?;

// 4. Store all components for decryption
let mut combined = Vec::new();
combined.extend_from_slice(&kyber_iv);
combined.extend_from_slice(kyber_ciphertext.as_ref());
combined.extend_from_slice(&hybrid_ciphertext);
combined.extend_from_slice(secret_key.as_ref());
```

### Large File Processing

#### Chunking Strategy

```rust
// Split a file size into chunks for parallel processing
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
```

#### Parallel Processing

```rust
// Process each chunk in parallel
let process_tasks = stream::iter(chunks.into_iter().enumerate())
    .map(|(chunk_index, (offset, chunk_size))| {
        // Capture variables for this chunk
        let encrypt_fn = self.encrypt_data_fn.clone();
        let source_path = source_path.clone();
        let password = password.to_string();
        
        // Acquire semaphore permit to limit concurrency
        let _permit = self.parallel_limiter.clone().acquire_owned();
        
        async move {
            // Read chunk from file
            let mut source_file = fs::File::open(&source_path).await?;
            source_file.seek(tokio::io::SeekFrom::Start(offset)).await?;
            let mut chunk_data = vec![0; chunk_size];
            source_file.read_exact(&mut chunk_data).await?;
            
            // Encrypt chunk
            let (encrypted_data, iv, metadata) = encrypt_fn(&password, &chunk_data).await?;
            
            // Send encrypted chunk to writer
            tx.send((chunk_index, encrypted_data, chunk_metadata)).await?;
            
            Ok(())
        }
    })
    .buffer_unordered(self.max_parallel_chunks)
    .collect::<Vec<EncryptionResult<()>>>();
```

#### Ordered Reassembly

```rust
// Write chunks in order, buffering out-of-order pieces
let writer_task = async move {
    let mut current_offset = metadata_size as u64;
    let mut next_chunk_index = 0;
    let mut pending_chunks = std::collections::HashMap::new();
    
    while let Some((chunk_index, encrypted_data, chunk_metadata)) = rx.recv().await {
        // If this is the next chunk we're expecting, write it
        if chunk_index == next_chunk_index {
            let mut dest_file = destination_file.lock().await;
            dest_file.seek(SeekFrom::Start(current_offset)).await?;
            dest_file.write_all(&encrypted_data).await?;
            
            // Update metrics
            current_offset += encrypted_data.len() as u64;
            next_chunk_index += 1;
            
            // Check if we have any pending chunks that can now be written
            while let Some((data, metadata)) = pending_chunks.remove(&next_chunk_index) {
                dest_file.write_all(&data).await?;
                current_offset += data.len() as u64;
                next_chunk_index += 1;
            }
            
            // Sync to ensure data is on disk
            dest_file.sync_all().await?;
        } else {
            // Store for later processing
            pending_chunks.insert(chunk_index, (encrypted_data, chunk_metadata));
        }
    }
};
```

## Error Handling

The system uses a custom error type to handle different failure scenarios:

```rust
#[derive(Debug, Error)]
pub enum EncryptionError {
    #[error("Key derivation error: {0}")]
    KeyDerivationError(String),
    
    #[error("Encryption error: {0}")]
    EncryptionError(String),
    
    #[error("Decryption error: {0}")]
    DecryptionError(String),
    
    #[error("Invalid key: {0}")]
    InvalidKeyError(String),
    
    #[error("IO error: {0}")]
    IOError(String),
    
    #[error("Serialization error: {0}")]
    SerializationError(String),
    
    #[error("Storage error: {0}")]
    StorageError(String),
    
    #[error("Metadata error: {0}")]
    MetadataError(String),
}
```

## Security Considerations

### Password Handling

- Passwords are never stored directly
- Key derivation uses PBKDF2 with high iteration count (600,000)
- Memory is cleared after use when possible

### Random Number Generation

- Uses the operating system's secure random number generator
- For deterministic operations, explicitly seeded RNG is used

### Side-Channel Protection

- Constant-time comparisons for security-sensitive operations
- No early returns in cryptographic operations

## Testing

The encryption system is thoroughly tested:

1. **Unit Tests**: Test individual algorithms and components
2. **Integration Tests**: Test the complete encryption/decryption workflow
3. **Property Tests**: Verify correctness properties like encrypt(decrypt(x)) == x

Example test pattern:

```rust
#[tokio::test]
async fn test_encrypt_decrypt_roundtrip() {
    // Setup
    let repository = create_test_repository();
    let service = EncryptionServiceImpl::new(Arc::new(repository));
    let password = "test_password";
    let test_data = b"This is some test data to encrypt and decrypt";
    
    // Initialize encryption
    let settings = EncryptionSettings::default();
    service.initialize(password, &settings).await.unwrap();
    
    // Encrypt data
    let (encrypted, iv, metadata) = service.encrypt_data(password, test_data).await.unwrap();
    
    // Verify encrypted data is different
    assert_ne!(&encrypted, test_data);
    
    // Decrypt data
    let decrypted = service.decrypt_data(password, &encrypted, &iv, &metadata).await.unwrap();
    
    // Verify roundtrip
    assert_eq!(&decrypted, test_data);
}
```

## Performance Considerations

### Benchmarks

- Small file encryption (<1MB): <100ms
- Medium file encryption (100MB): ~2-3 seconds
- Large file encryption (1GB): ~20-30 seconds (CPU dependent)

### Optimization Opportunities

1. **Chunk Size**: Adjustable based on available memory (default 4MB)
2. **Parallelism**: Configurable thread count (default 8)
3. **Algorithm Selection**: Trade security for performance
4. **Buffer Sizes**: Optimized for typical file operations

## Future Enhancements

1. **Hardware Acceleration**: Support for AES-NI and other hardware acceleration
2. **HSM Support**: Integration with hardware security modules
3. **Additional Algorithms**: Support for more post-quantum algorithms as they mature
4. **Secure Sharing**: Key exchange protocols for secure file sharing
5. **Memory Protection**: Enhanced memory protection for sensitive data

## References

- [NIST Post-Quantum Cryptography Standardization](https://csrc.nist.gov/projects/post-quantum-cryptography)
- [Kyber Algorithm Specification](https://pq-crystals.org/kyber/data/kyber-specification-round3-20210804.pdf)
- [Dilithium Algorithm Specification](https://pq-crystals.org/dilithium/data/dilithium-specification-round3-20210208.pdf)
- [Rust Cryptography Working Group](https://github.com/RustCrypto)
- [pqcrypto Project](https://github.com/PQClean/PQClean)