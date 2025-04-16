# OxiCloud Encryption System Documentation

## Overview

OxiCloud Desktop offers a robust end-to-end encryption (E2EE) system that protects your data both at rest and in transit. The encryption implementation includes post-quantum cryptographic algorithms to provide protection against future quantum computing threats.

## Features

- **End-to-End Encryption**: All data is encrypted on your device before being transmitted to the server
- **Post-Quantum Resistance**: Uses algorithms designed to resist attacks from quantum computers
- **Hybrid Encryption**: Combines classical algorithms with post-quantum ones for defense in depth
- **Fast Performance**: Optimized for large files with chunked processing and parallel operations
- **Secure Key Management**: Password-based key derivation with secure storage options
- **Transparent Operation**: Works automatically with minimal user configuration

## Supported Algorithms

OxiCloud Desktop supports several encryption algorithms, allowing you to choose the best balance of security and compatibility:

| Algorithm | Type | Security Level | Quantum Resistance |
|-----------|------|---------------|-------------------|
| AES-256-GCM | Symmetric | High | None |
| ChaCha20-Poly1305 | Symmetric | High | None |
| Kyber768 | KEM | Medium | Strong |
| Dilithium5 | Signature | High | Strong |
| HybridAesKyber | Hybrid | Very High | Strong |

### Default Algorithm

By default, OxiCloud Desktop uses the **HybridAesKyber** algorithm, which combines AES-256-GCM with the post-quantum Kyber KEM for the strongest protection against both classical and quantum adversaries.

## How It Works

### Encryption Process

1. When you set up encryption for the first time:
   - A secure master key is generated
   - This key is encrypted with your password using key derivation (PBKDF2)
   - The encrypted master key is stored locally

2. When you encrypt a file:
   - For small files (< 8MB): The entire file is encrypted in memory
   - For large files (≥ 8MB): The file is split into chunks, encrypted in parallel, and reassembled
   - Encryption metadata is stored with each file to enable decryption

3. During synchronization:
   - Files are automatically encrypted before upload
   - Downloaded files are automatically decrypted for use

### Technical Implementation

#### Key Management

- **Master Key**: A 256-bit key used for encrypting your actual data
- **Key Derivation**: Your password is strengthened using PBKDF2 with 600,000 iterations
- **Key Storage**: The encrypted master key is stored in a SQLite database on your device

#### Post-Quantum Algorithms

- **Kyber768**: A key encapsulation mechanism (KEM) with 181 bytes of ciphertext
- **Dilithium5**: A digital signature algorithm with signatures around 4KB
- **Hybrid Mode**: Uses both classical and post-quantum algorithms in layers

#### Large File Processing

- Files are split into 4MB chunks
- Up to 8 chunks are processed concurrently on separate threads
- Chunks are reassembled in the correct order, even when processed out of order
- Progress tracking allows for resumable operations

## Security Considerations

### Password Strength

Your encryption is only as strong as your password. We recommend:
- Use a password manager to generate a strong, unique password
- Minimum length of 12 characters
- Include uppercase, lowercase, numbers, and symbols
- Avoid personal information or dictionary words

### Recovery Options

Losing your encryption password means losing access to your encrypted files. Consider:
- Storing your password in a secure password manager
- Exporting your encryption key to a secure location (Settings → Security → Export Key)
- Creating a recovery key during initial setup

### Security Levels

OxiCloud Desktop offers three security profiles:

1. **Standard**: Uses AES-256-GCM for good performance and compatibility
2. **Enhanced**: Uses ChaCha20-Poly1305 with larger key derivation iterations
3. **Maximum**: Uses HybridAesKyber for the strongest possible protection

## User Guide

### Setting Up Encryption

1. Open OxiCloud Desktop and go to **Settings → Security**
2. Click **Enable End-to-End Encryption**
3. Create a strong password
4. Optionally create a recovery key
5. Choose your preferred security level
6. Click **Enable Encryption**

### Changing Encryption Settings

1. Go to **Settings → Security**
2. Enter your current encryption password
3. Modify settings as needed
4. Click **Apply Changes**

### Exporting Your Encryption Key

1. Go to **Settings → Security**
2. Click **Export Encryption Key**
3. Enter your password
4. Choose a secure location to save the key file
5. Keep this file safe and secure

### Importing an Encryption Key

1. Go to **Settings → Security**
2. Click **Import Encryption Key**
3. Browse to your key file
4. Enter the password for the key
5. Click **Import**

## Troubleshooting

### Common Issues

1. **"Unable to decrypt file"**
   - Verify you're using the correct password
   - Check if the file was encrypted with a different key
   - Try restarting the application

2. **"Error during encryption process"**
   - Check available disk space
   - Verify file permissions
   - Try with a smaller file first

3. **"Slow encryption performance"**
   - Try reducing the security level for better performance
   - Check if other applications are using system resources
   - Consider increasing the chunk size in advanced settings

### Getting Help

If you encounter issues with the encryption system:
1. Check the application logs (Settings → Advanced → View Logs)
2. Consult our [online documentation](https://github.com/yourusername/oxicloud-desktop)
3. Contact support with error details

## Technical FAQ

### Is my data encrypted on the server?

Yes, all data is encrypted before it leaves your device, so the server only stores encrypted data that only you can decrypt.

### Does OxiCloud Desktop encrypt file names?

Yes, by default both file contents and file names are encrypted. This can be configured in the encryption settings.

### How secure is the post-quantum implementation?

Our implementation uses the latest NIST-approved algorithms (Kyber and Dilithium) that have undergone extensive cryptanalysis. The hybrid approach ensures that even if one algorithm is compromised, your data remains protected by the other.

### Can I use hardware security keys?

Not yet, but support for hardware security modules (HSMs) and security keys is on our roadmap.

### Can I share encrypted files?

Yes, you can share encrypted files with other OxiCloud users. The system will handle the key exchange securely.

### What happens if I forget my password?

If you've created a recovery key, you can use it to regain access. Otherwise, your data will remain encrypted and inaccessible. There is no "backdoor" or way for us to recover your data.

### Does encryption affect sync performance?

Modern encryption is very fast, especially with our optimized implementation. For most users, there is minimal impact on sync performance. Large files may take slightly longer due to the encryption overhead.