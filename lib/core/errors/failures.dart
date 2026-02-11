import 'package:equatable/equatable.dart';

/// Base failure class for all domain failures.
///
/// Provides a unified error hierarchy that all feature-specific
/// failures extend from, enabling generic error handling.
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

// =============================================================================
// Auth failures
// =============================================================================

/// Base class for authentication-related failures.
abstract class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure()
      : super('Invalid username or password', code: 'INVALID_CREDENTIALS');
}

class ServerUnreachableFailure extends AuthFailure {
  const ServerUnreachableFailure(String detail)
      : super('Server unreachable: $detail', code: 'SERVER_UNREACHABLE');
}

class NetworkFailure extends AuthFailure {
  const NetworkFailure(String detail)
      : super('Network error: $detail', code: 'NETWORK_ERROR');
}

class UnknownAuthFailure extends AuthFailure {
  const UnknownAuthFailure(String detail)
      : super(detail, code: 'UNKNOWN_AUTH');
}

// =============================================================================
// Sync failures
// =============================================================================

/// Base class for synchronization-related failures.
abstract class SyncFailure extends Failure {
  const SyncFailure(super.message, {super.code});
}

class NotInitializedFailure extends SyncFailure {
  const NotInitializedFailure()
      : super('Sync engine not initialized', code: 'NOT_INITIALIZED');
}

class NotAuthenticatedFailure extends SyncFailure {
  const NotAuthenticatedFailure()
      : super('Not authenticated', code: 'NOT_AUTHENTICATED');
}

class NetworkSyncFailure extends SyncFailure {
  const NetworkSyncFailure(String detail)
      : super('Network error: $detail', code: 'NETWORK_SYNC');
}

class StorageSyncFailure extends SyncFailure {
  const StorageSyncFailure(String detail)
      : super('Storage error: $detail', code: 'STORAGE_SYNC');
}

class UnknownSyncFailure extends SyncFailure {
  const UnknownSyncFailure(String detail)
      : super(detail, code: 'UNKNOWN_SYNC');
}

// =============================================================================
// File browser failures
// =============================================================================

/// Base class for file-browser related failures.
abstract class FileBrowserFailure extends Failure {
  const FileBrowserFailure(super.message, {super.code});
}

class FolderNotFoundFailure extends FileBrowserFailure {
  const FolderNotFoundFailure(String id)
      : super('Folder not found: $id', code: 'FOLDER_NOT_FOUND');
}

class FileNotFoundFailure extends FileBrowserFailure {
  const FileNotFoundFailure(String id)
      : super('File not found: $id', code: 'FILE_NOT_FOUND');
}

class UploadFailure extends FileBrowserFailure {
  const UploadFailure(String detail)
      : super('Upload failed: $detail', code: 'UPLOAD_FAILED');
}

class DownloadFailure extends FileBrowserFailure {
  const DownloadFailure(String detail)
      : super('Download failed: $detail', code: 'DOWNLOAD_FAILED');
}

class FolderAlreadyExistsFailure extends FileBrowserFailure {
  const FolderAlreadyExistsFailure(String name)
      : super('Folder already exists: $name', code: 'FOLDER_EXISTS');
}

class PermissionDeniedFailure extends FileBrowserFailure {
  const PermissionDeniedFailure()
      : super('Permission denied', code: 'PERMISSION_DENIED');
}

class FileBrowserNetworkFailure extends FileBrowserFailure {
  const FileBrowserNetworkFailure(String detail)
      : super('Network error: $detail', code: 'NETWORK_FILE_BROWSER');
}

class UnknownFileBrowserFailure extends FileBrowserFailure {
  const UnknownFileBrowserFailure(String detail)
      : super(detail, code: 'UNKNOWN_FILE_BROWSER');
}

// =============================================================================
// Trash failures
// =============================================================================

/// Base class for trash-related failures.
abstract class TrashFailure extends Failure {
  const TrashFailure(super.message, {super.code});
}

class TrashDisabledFailure extends TrashFailure {
  const TrashDisabledFailure()
      : super('Trash feature is not enabled', code: 'TRASH_DISABLED');
}

class TrashItemNotFoundFailure extends TrashFailure {
  const TrashItemNotFoundFailure(String id)
      : super('Trash item not found: $id', code: 'TRASH_ITEM_NOT_FOUND');
}

class TrashNetworkFailure extends TrashFailure {
  const TrashNetworkFailure(String detail)
      : super('Network error: $detail', code: 'NETWORK_TRASH');
}

class UnknownTrashFailure extends TrashFailure {
  const UnknownTrashFailure(String detail)
      : super(detail, code: 'UNKNOWN_TRASH');
}

// =============================================================================
// Share failures
// =============================================================================

/// Base class for share-related failures.
abstract class ShareFailure extends Failure {
  const ShareFailure(super.message, {super.code});
}

class ShareNotFoundFailure extends ShareFailure {
  const ShareNotFoundFailure(String id)
      : super('Share not found: $id', code: 'SHARE_NOT_FOUND');
}

class ShareExpiredFailure extends ShareFailure {
  const ShareExpiredFailure()
      : super('Share link has expired', code: 'SHARE_EXPIRED');
}

class SharePasswordRequiredFailure extends ShareFailure {
  const SharePasswordRequiredFailure()
      : super('Password required', code: 'SHARE_PASSWORD_REQUIRED');
}

class ShareAccessDeniedFailure extends ShareFailure {
  const ShareAccessDeniedFailure()
      : super('Access denied', code: 'SHARE_ACCESS_DENIED');
}

class ShareNetworkFailure extends ShareFailure {
  const ShareNetworkFailure(String detail)
      : super('Network error: $detail', code: 'NETWORK_SHARE');
}

class UnknownShareFailure extends ShareFailure {
  const UnknownShareFailure(String detail)
      : super(detail, code: 'UNKNOWN_SHARE');
}

// =============================================================================
// Search failures
// =============================================================================

/// Base class for search-related failures.
abstract class SearchFailure extends Failure {
  const SearchFailure(super.message, {super.code});
}

class SearchUnavailableFailure extends SearchFailure {
  const SearchUnavailableFailure()
      : super('Search service is not available', code: 'SEARCH_UNAVAILABLE');
}

class SearchNetworkFailure extends SearchFailure {
  const SearchNetworkFailure(String detail)
      : super('Network error: $detail', code: 'NETWORK_SEARCH');
}

class UnknownSearchFailure extends SearchFailure {
  const UnknownSearchFailure(String detail)
      : super(detail, code: 'UNKNOWN_SEARCH');
}
