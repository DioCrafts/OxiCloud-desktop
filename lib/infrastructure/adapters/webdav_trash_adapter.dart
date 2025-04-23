import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/core/config/app_config.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';
import 'package:oxicloud_desktop/core/storage/secure_storage.dart';
import 'package:oxicloud_desktop/domain/entities/file.dart';
import 'package:oxicloud_desktop/domain/entities/folder.dart';
import 'package:oxicloud_desktop/domain/entities/trashed_item.dart';
import 'package:oxicloud_desktop/domain/repositories/trash_repository.dart';
import 'package:oxicloud_desktop/infrastructure/adapters/webdav_file_adapter.dart';
import 'package:oxicloud_desktop/infrastructure/adapters/webdav_folder_adapter.dart';
import 'package:http/http.dart' as http;

/// WebDAV adapter for trash operations
class WebDAVTrashAdapter implements TrashRepository {
  final AppConfig _appConfig;
  final SecureStorage _secureStorage;
  final WebDAVFileAdapter _fileAdapter;
  final WebDAVFolderAdapter _folderAdapter;
  final Logger _logger = LoggingManager.getLogger('WebDAVTrashAdapter');
  
  /// Default trash expiration in days
  static const int _defaultExpirationDays = 30;
  
  /// Create a WebDAVTrashAdapter
  WebDAVTrashAdapter(
    this._appConfig,
    this._secureStorage,
    this._fileAdapter,
    this._folderAdapter,
  );
  
  @override
  Future<List<TrashedItem>> listTrashedItems() async {
    try {
      // OxiCloud extension for trash
      final trashUrl = '${_appConfig.apiUrl}/trash';
      
      final token = await _secureStorage.getToken();
      
      final response = await http.get(
        Uri.parse(trashUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final trashData = jsonDecode(response.body) as Map<String, dynamic>;
        final items = trashData['items'] as List<dynamic>;
        
        return items.map((item) {
          final itemData = item as Map<String, dynamic>;
          
          return TrashedItem(
            id: itemData['id'] as String,
            originalPath: itemData['originalPath'] as String,
            name: itemData['name'] as String,
            isFolder: itemData['isFolder'] as bool,
            size: itemData['size'] as int,
            mimeType: itemData['isFolder'] ? null : itemData['mimeType'] as String?,
            trashedAt: DateTime.parse(itemData['trashedAt'] as String),
            expiresAt: DateTime.parse(itemData['expiresAt'] as String),
            originalId: itemData['originalId'] as String,
          );
        }).toList();
      }
      
      return [];
    } catch (e) {
      _logger.warning('Failed to list trashed items: $e');
      rethrow;
    }
  }
  
  @override
  Future<TrashedItem> getTrashedItem(String trashedItemId) async {
    try {
      // OxiCloud extension for trash
      final trashItemUrl = '${_appConfig.apiUrl}/trash/$trashedItemId';
      
      final token = await _secureStorage.getToken();
      
      final response = await http.get(
        Uri.parse(trashItemUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final itemData = jsonDecode(response.body) as Map<String, dynamic>;
        
        return TrashedItem(
          id: itemData['id'] as String,
          originalPath: itemData['originalPath'] as String,
          name: itemData['name'] as String,
          isFolder: itemData['isFolder'] as bool,
          size: itemData['size'] as int,
          mimeType: itemData['isFolder'] ? null : itemData['mimeType'] as String?,
          trashedAt: DateTime.parse(itemData['trashedAt'] as String),
          expiresAt: DateTime.parse(itemData['expiresAt'] as String),
          originalId: itemData['originalId'] as String,
        );
      }
      
      throw Exception('Trashed item not found: $trashedItemId');
    } catch (e) {
      _logger.warning('Failed to get trashed item: $trashedItemId - $e');
      rethrow;
    }
  }
  
  @override
  Future<TrashedItem> moveToTrash(String itemId, bool isFolder) async {
    try {
      // First, get the item details
      if (isFolder) {
        await _folderAdapter.getFolder(itemId);
      } else {
        await _fileAdapter.getFile(itemId);
      }
      
      // OxiCloud extension for trash
      final trashUrl = '${_appConfig.apiUrl}/trash';
      
      final token = await _secureStorage.getToken();
      
      final response = await http.post(
        Uri.parse(trashUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'itemId': itemId,
          'isFolder': isFolder,
        }),
      );
      
      if (response.statusCode == 200) {
        final itemData = jsonDecode(response.body) as Map<String, dynamic>;
        
        return TrashedItem(
          id: itemData['id'] as String,
          originalPath: itemData['originalPath'] as String,
          name: itemData['name'] as String,
          isFolder: itemData['isFolder'] as bool,
          size: itemData['size'] as int,
          mimeType: itemData['isFolder'] ? null : itemData['mimeType'] as String?,
          trashedAt: DateTime.parse(itemData['trashedAt'] as String),
          expiresAt: DateTime.parse(itemData['expiresAt'] as String),
          originalId: itemData['originalId'] as String,
        );
      }
      
      throw Exception('Failed to move item to trash: $itemId');
    } catch (e) {
      _logger.warning('Failed to move item to trash: $itemId - $e');
      rethrow;
    }
  }
  
  @override
  Future<bool> restoreFromTrash(String trashedItemId) async {
    try {
      // OxiCloud extension for trash
      final restoreUrl = '${_appConfig.apiUrl}/trash/$trashedItemId/restore';
      
      final token = await _secureStorage.getToken();
      
      final response = await http.post(
        Uri.parse(restoreUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      return response.statusCode == 200;
    } catch (e) {
      _logger.warning('Failed to restore item from trash: $trashedItemId - $e');
      rethrow;
    }
  }
  
  @override
  Future<bool> restoreFromTrashTo(String trashedItemId, String destinationFolderId) async {
    try {
      // OxiCloud extension for trash
      final restoreUrl = '${_appConfig.apiUrl}/trash/$trashedItemId/restore';
      
      final token = await _secureStorage.getToken();
      
      final response = await http.post(
        Uri.parse(restoreUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'destinationFolderId': destinationFolderId,
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      _logger.warning('Failed to restore item from trash to folder: $trashedItemId, $destinationFolderId - $e');
      rethrow;
    }
  }
  
  @override
  Future<bool> deletePermanently(String trashedItemId) async {
    try {
      // OxiCloud extension for trash
      final deleteUrl = '${_appConfig.apiUrl}/trash/$trashedItemId';
      
      final token = await _secureStorage.getToken();
      
      final response = await http.delete(
        Uri.parse(deleteUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      return response.statusCode == 200;
    } catch (e) {
      _logger.warning('Failed to delete item permanently: $trashedItemId - $e');
      rethrow;
    }
  }
  
  @override
  Future<int> emptyTrash() async {
    try {
      // OxiCloud extension for trash
      final emptyUrl = '${_appConfig.apiUrl}/trash/empty';
      
      final token = await _secureStorage.getToken();
      
      final response = await http.delete(
        Uri.parse(emptyUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        return result['deletedCount'] as int;
      }
      
      return 0;
    } catch (e) {
      _logger.warning('Failed to empty trash: $e');
      rethrow;
    }
  }
  
  @override
  Future<int> getTrashExpirationDays() async {
    try {
      // OxiCloud extension for trash
      final settingsUrl = '${_appConfig.apiUrl}/trash/settings';
      
      final token = await _secureStorage.getToken();
      
      final response = await http.get(
        Uri.parse(settingsUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final settings = jsonDecode(response.body) as Map<String, dynamic>;
        return settings['expirationDays'] as int;
      }
      
      return _defaultExpirationDays;
    } catch (e) {
      _logger.warning('Failed to get trash expiration days: $e');
      return _defaultExpirationDays;
    }
  }
  
  @override
  Future<bool> updateExpirationDate(String trashedItemId, DateTime newExpirationDate) async {
    try {
      // OxiCloud extension for trash
      final updateUrl = '${_appConfig.apiUrl}/trash/$trashedItemId/expiration';
      
      final token = await _secureStorage.getToken();
      
      final response = await http.put(
        Uri.parse(updateUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'expiresAt': newExpirationDate.toIso8601String(),
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      _logger.warning('Failed to update expiration date: $trashedItemId - $e');
      rethrow;
    }
  }
}