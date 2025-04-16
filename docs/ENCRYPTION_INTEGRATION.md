# End-to-End Encryption Integration with Sync Service

This document describes how end-to-end encryption (E2EE) is integrated with the synchronization system in OxiCloud Desktop.

## Overview

OxiCloud Desktop provides robust end-to-end encryption (E2EE) with post-quantum resistance. This encryption ensures that:

1. Files are encrypted locally before being uploaded to the server
2. Files remain encrypted during transit and on the server
3. Files are only decrypted locally after download, using the user's encryption password
4. No unencrypted data is ever stored on the server

The encryption system integrates with the synchronization system to provide a seamless user experience with security built-in.

## Components

The integration consists of these main components:

1. **EncryptionService** - Core service for encryption/decryption operations
2. **SyncService** - Enhanced with encryption capabilities
3. **Application Layer** - Exposes encryption configuration to the UI

## Workflow

The synchronization process handles encryption/decryption as follows:

### Upload Flow

1. User initiates an upload or sync operation
2. SyncService checks if encryption is enabled
3. If enabled, it checks if the encryption password is set
4. Before upload, the file is encrypted locally with the encrypt_file_for_upload method
5. The encryption metadata (IV, algorithm parameters) is stored with the file
6. The encrypted file is uploaded to the server instead of the original
7. The local file remains unencrypted for user access

### Download Flow

1. User downloads a file or initiates a sync
2. SyncService checks if the file has encryption metadata
3. If encrypted and password is set, it downloads the encrypted file
4. After download, the file is decrypted with decrypt_file_after_download method
5. The decrypted file is saved locally for user access
6. Encryption metadata is preserved for future operations

## Security Features

- **Post-Quantum Resistance**: Support for post-quantum algorithms like Kyber768 and Dilithium5
- **Hybrid Encryption**: Combines classical and post-quantum algorithms for maximum security
- **Password Management**: Securely stores the encryption password in memory only
- **Check Before Sync**: Prevents synchronization if encryption is enabled but no password is set
- **Event Notifications**: Provides real-time encryption/decryption status to the UI

## Implementation Details

### Encryption Integration Points

The SyncService has been modified with these key additions:

1. **set_encryption_password**: Sets the password used for encryption/decryption operations
2. **encrypt_file_for_upload**: Encrypts a file before uploading
3. **decrypt_file_after_download**: Decrypts a file after downloading
4. **is_encryption_enabled**: Checks if encryption is enabled in settings

### Events

New sync events have been added for encryption operations:

- **EncryptionStarted**: When encryption of a file begins
- **EncryptionCompleted**: When encryption is completed
- **DecryptionStarted**: When decryption of a file begins
- **DecryptionCompleted**: When decryption is completed
- **EncryptionError**: When an encryption/decryption error occurs

### Error Handling

Encryption-specific errors are captured and reported to the user, including:

- Missing encryption password
- Failed encryption/decryption operations
- Missing encryption metadata on encrypted files

## Testing

Comprehensive tests have been implemented to verify the encryption integration:

1. **Unit Tests**: For core encryption/decryption functionality
2. **Integration Tests**: For the interaction between encryption and sync services
3. **End-to-End Tests**: Simulating real-world scenarios with file uploads/downloads

## User Experience

From a user perspective:

1. User enables encryption in the settings and sets a password
2. User uploads/downloads files normally
3. Encryption/decryption happens automatically in the background
4. Progress indicators show encryption/decryption status
5. No plaintext data is ever sent to the server

## Security Considerations

- **Password Storage**: The encryption password is never stored persistently
- **Memory Protection**: The password is kept in memory only as long as needed
- **Forward Secrecy**: Each file uses a unique IV (Initialization Vector)
- **No Backdoors**: The encryption implementation has no backdoors or key escrow
- **Open Standards**: Uses widely-reviewed encryption algorithms and standards