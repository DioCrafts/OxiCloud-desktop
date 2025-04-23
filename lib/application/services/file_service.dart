import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';
import 'package:oxicloud_desktop/domain/entities/file.dart';
import 'package:oxicloud_desktop/domain/repositories/file_repository.dart';
import 'package:oxicloud_desktop/domain/services/mime_type_service.dart';
import 'package:oxicloud_desktop/infrastructure/services/resource_manager.dart';

/// Application service for file operations
class FileService {
  final FileRepository _fileRepository;
  final ResourceManager _resourceManager;
  final Logger _logger = LoggingManager.getLogger('FileService');
  
  /// Create a FileService
  FileService(this._fileRepository, this._resourceManager);
  
  /// Get a file by ID
  Future<File> getFile(String fileId) async {
    try {
      return await _fileRepository.getFile(fileId);
    } catch (e) {
      _logger.warning('Failed to get file: $fileId - $e');
      rethrow;
    }
  }
  
  /// List files in a folder
  Future<List<File>> listFiles(String folderId) async {
    try {
      return await _fileRepository.listFiles(folderId);
    } catch (e) {
      _logger.warning('Failed to list files in folder: $folderId - $e');
      rethrow;
    }
  }
  
  /// Upload a file to a folder
  Future<File> uploadFile({
    required String parentFolderId,
    required String name,
    required Uint8List data,
  }) async {
    try {
      // Check resource constraints
      final shouldExecute = _resourceManager.shouldExecuteOperation(OperationType.highPriority);
      if (!shouldExecute) {
        throw const OperationNotAllowedException(
          'File upload not allowed under current resource constraints',
        );
      }
      
      // Determine MIME type
      final mimeType = MimeTypeService.getMimeTypeFromExtension(name);
      
      _logger.info('Uploading file $name to folder $parentFolderId');
      return await _fileRepository.uploadFile(
        parentFolderId: parentFolderId,
        name: name,
        data: data,
        mimeType: mimeType,
      );
    } catch (e) {
      _logger.warning('Failed to upload file: $name - $e');
      rethrow;
    }
  }
  
  /// Update an existing file
  Future<File> updateFile({
    required String fileId,
    required Uint8List data,
  }) async {
    try {
      // Check resource constraints
      final shouldExecute = _resourceManager.shouldExecuteOperation(OperationType.highPriority);
      if (!shouldExecute) {
        throw const OperationNotAllowedException(
          'File update not allowed under current resource constraints',
        );
      }
      
      _logger.info('Updating file $fileId');
      return await _fileRepository.updateFile(
        fileId: fileId,
        data: data,
      );
    } catch (e) {
      _logger.warning('Failed to update file: $fileId - $e');
      rethrow;
    }
  }
  
  /// Download a file
  Future<Uint8List> downloadFile(String fileId) async {
    try {
      // Check resource constraints
      final shouldExecute = _resourceManager.shouldExecuteOperation(OperationType.normal);
      if (!shouldExecute) {
        throw const OperationNotAllowedException(
          'File download not allowed under current resource constraints',
        );
      }
      
      _logger.info('Downloading file $fileId');
      return await _fileRepository.downloadFile(fileId);
    } catch (e) {
      _logger.warning('Failed to download file: $fileId - $e');
      rethrow;
    }
  }
  
  /// Download a file to a local path
  Future<void> downloadFileToPath(String fileId, String localPath) async {
    try {
      // Check resource constraints
      final shouldExecute = _resourceManager.shouldExecuteOperation(OperationType.normal);
      if (!shouldExecute) {
        throw const OperationNotAllowedException(
          'File download not allowed under current resource constraints',
        );
      }
      
      _logger.info('Downloading file $fileId to $localPath');
      await _fileRepository.downloadFileToPath(fileId, localPath);
    } catch (e) {
      _logger.warning('Failed to download file to path: $fileId - $e');
      rethrow;
    }
  }
  
  /// Rename a file
  Future<File> renameFile(String fileId, String newName) async {
    try {
      _logger.info('Renaming file $fileId to $newName');
      return await _fileRepository.renameFile(fileId, newName);
    } catch (e) {
      _logger.warning('Failed to rename file: $fileId - $e');
      rethrow;
    }
  }
  
  /// Move a file to another folder
  Future<File> moveFile(String fileId, String newParentFolderId) async {
    try {
      _logger.info('Moving file $fileId to folder $newParentFolderId');
      return await _fileRepository.moveFile(fileId, newParentFolderId);
    } catch (e) {
      _logger.warning('Failed to move file: $fileId - $e');
      rethrow;
    }
  }
  
  /// Delete a file
  Future<void> deleteFile(String fileId) async {
    try {
      _logger.info('Deleting file $fileId');
      await _fileRepository.deleteFile(fileId);
    } catch (e) {
      _logger.warning('Failed to delete file: $fileId - $e');
      rethrow;
    }
  }
  
  /// Mark a file as favorite
  Future<File> markAsFavorite(String fileId, bool favorite) async {
    try {
      _logger.info('Marking file $fileId as favorite: $favorite');
      return await _fileRepository.markAsFavorite(fileId, favorite);
    } catch (e) {
      _logger.warning('Failed to mark file as favorite: $fileId - $e');
      rethrow;
    }
  }
  
  /// Get a file's thumbnail
  Future<Uint8List?> getThumbnail(String fileId, {int? size}) async {
    try {
      // Skip thumbnails if disabled in current resource profile
      final resourceProfile = _resourceManager.currentProfile;
      if (resourceProfile != null && !resourceProfile.useThumbnails) {
        return null;
      }
      
      return await _fileRepository.getThumbnail(fileId, size: size);
    } catch (e) {
      _logger.warning('Failed to get thumbnail: $fileId - $e');
      return null; // Fail gracefully for thumbnails
    }
  }
  
  /// Search for files
  Future<List<File>> searchFiles(String query) async {
    try {
      _logger.info('Searching for files: $query');
      return await _fileRepository.searchFiles(query);
    } catch (e) {
      _logger.warning('Failed to search files: $query - $e');
      rethrow;
    }
  }
  
  /// Get recently modified files
  Future<List<File>> getRecentFiles({int limit = 10}) async {
    try {
      return await _fileRepository.getRecentFiles(limit: limit);
    } catch (e) {
      _logger.warning('Failed to get recent files - $e');
      rethrow;
    }
  }
}

/// Exception thrown when an operation is not allowed due to resource constraints
class OperationNotAllowedException implements Exception {
  /// Exception message
  final String message;
  
  /// Creates an OperationNotAllowedException
  const OperationNotAllowedException(this.message);
  
  @override
  String toString() => 'OperationNotAllowedException: $message';
}