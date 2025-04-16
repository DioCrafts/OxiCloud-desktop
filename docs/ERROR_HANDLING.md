# Error Handling and Recovery in OxiCloud Desktop

This document describes the error handling and recovery mechanisms for the encryption system in OxiCloud Desktop, focusing on scenarios like forgotten passwords, corrupted encrypted files, and key recovery.

## Overview

Encryption errors can be particularly challenging because they often result in data loss if not handled properly. OxiCloud Desktop implements a robust error handling and recovery system to address these scenarios:

1. **Forgotten Passwords**: Multiple recovery mechanisms to restore access
2. **Corrupted Files**: Detection and repair of damaged encrypted files
3. **Key Management**: Secure backup and restoration of encryption keys

## Forgotten Password Recovery

OxiCloud Desktop implements a multi-layered approach to password recovery:

### 1. Security Questions

- Users can set up to 5 personal security questions
- Answer verification uses secure hashing
- Requires at least 2 correct answers to reset the password
- Questions and hashed answers are stored locally

### 2. Recovery Keys

- One-time use recovery codes that can reset the password
- Each key has an expiration date and verification code
- Can be printed, stored on another device, or saved to a USB drive
- Recovery keys are invalidated after use for security

### 3. Backup Key Files

- Encrypted backup of the master key stored separately
- Can be used to restore encryption without original password
- Encrypted using a different password than the main one
- Essential for all recovery methods

## Corrupted File Handling

When encrypted files become corrupted, the system implements:

### 1. Corruption Detection

- Header integrity checks
- Metadata validation
- Content block verification
- Authentication tag validation

### 2. Corruption Types

The system can identify specific types of corruption:
- Header corruption
- Content block corruption
- Metadata corruption
- IV (Initialization Vector) corruption
- Authentication tag corruption

### 3. Repair Strategies

Based on the type of corruption, different repair strategies are attempted:
- Header reconstruction
- Metadata recovery from file properties
- Partial data recovery
- Error correction for specific corruption patterns

## Key Recovery Process

The key recovery workflow is designed to be secure while providing multiple recovery options:

1. **Setup Phase**
   - User enables encryption and sets a password
   - System generates a master encryption key
   - User sets up recovery methods (questions, recovery keys)
   - System creates emergency backup key files

2. **Recovery Phase**
   - User indicates they've forgotten their password
   - System offers available recovery methods
   - User completes verification (answers questions or provides recovery key)
   - System regenerates access from backup
   - User sets a new password

## Technical Implementation

### Recovery Service

The `RecoveryService` provides these main functions:
- `setup_recovery()` - Initial setup of recovery options
- `add_security_questions()` - Add security questions for recovery
- `generate_recovery_key()` - Generate a one-time recovery key
- `reset_password_with_key()` - Reset password using recovery key
- `reset_password_with_questions()` - Reset using security questions
- `create_backup_key_file()` - Create backup key file for recovery

### Error Recovery Service

The `ErrorRecoveryService` provides:
- `verify_backup_key()` - Verify backup key file integrity
- `restore_from_backup()` - Restore encryption from backup key
- `repair_encrypted_file()` - Attempt to repair corrupted files
- `recover_file_metadata()` - Extract metadata from corrupted files

### Corruption Detector

The `CorruptionDetector` handles:
- `scan_for_corruption()` - Detect and diagnose file corruption
- `is_likely_corruption_error()` - Analyze errors for corruption patterns
- `can_repair()` - Determine if a corrupted file can be repaired

## Security Considerations

- Recovery methods are stored separately from the main encryption keys
- All recovery data is itself encrypted
- Recovery keys are one-time use only
- Security questions use secure hashing to store answers
- Backup key files are encrypted with a different password

## User Experience

From a user perspective, the process is designed to be straightforward:

1. During setup, users are prompted to set up recovery options
2. Regular reminders to verify recovery methods are still valid
3. When password is forgotten, a simple wizard guides recovery
4. For corrupted files, automatic detection and repair attempts

## Best Practices

To maximize resilience against data loss, users should:

1. Set up multiple recovery methods
2. Store recovery keys in physically separate locations
3. Periodically verify that recovery methods work
4. Create a backup key file on external media (e.g., USB drive)
5. Consider printing recovery codes and storing them securely