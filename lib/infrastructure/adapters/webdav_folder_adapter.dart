import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/core/config/app_config.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';
import 'package:oxicloud_desktop/core/storage/secure_storage.dart';
import 'package:oxicloud_desktop/domain/entities/folder.dart';
import 'package:oxicloud_desktop/domain/entities/item.dart';
import 'package:oxicloud_desktop/domain/repositories/folder_repository.dart';
import 'package:webdav_client/webdav_client.dart' as webdav hide Client;
import 'package:oxicloud_desktop/infrastructure/services/webdav_client_plus.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

/// WebDAV adapter for folder operations
class WebDAVFolderAdapter implements FolderRepository {
  late final Client _client;
  final AppConfig _appConfig;
  final SecureStorage _secureStorage;
  final Logger _logger = LoggingManager.getLogger('WebDAVFolderAdapter');
  
  /// Create a WebDAVFolderAdapter
  WebDAVFolderAdapter(this._appConfig, this._secureStorage) {
    _initClient();
  }
  
  /// Initialize the WebDAV client
  Future<void> _initClient() async {
    final serverUrl = _appConfig.webdavUrl;
    
    // Get auth token
    final token = await _secureStorage.getToken();
    
    // Create client with token auth
    _client = newClient(
      baseUrl: serverUrl,
      httpClient: http.Client(),
    );
    
    _client.defaultHeaders = {
      'Authorization': 'Bearer $token',
    };
    
    _logger.info('WebDAV client initialized with server: $serverUrl');
  }
  
  /// Ensure client is authenticated
  Future<void> _ensureAuthenticated() async {
    // Check if token has changed
    final token = await _secureStorage.getToken();
    
    // If token is different, update client
    if (token != null && _client.defaultHeaders['Authorization'] != 'Bearer $token') {
      _client.defaultHeaders = {
        ..._client.defaultHeaders,
        'Authorization': 'Bearer $token',
      };
    }
  }
  
  /// Convert WebDAV file to domain Folder
  Folder _convertWebDavFolder(webdav.File webdavFile) {
    final name = p.basename(webdavFile.path);
    final parentPath = p.dirname(webdavFile.path);
    
    return Folder(
      id: webdavFile.path,
      name: name == '/' ? 'Root' : name,
      path: webdavFile.path,
      modifiedAt: webdavFile.mTime,
      isShared: false, // WebDAV doesn't provide this info directly
      parentId: parentPath == '/' ? null : parentPath,
      etag: webdavFile.eTag,
    );
  }
  
  /// Convert WebDAV file to StorageItem
  StorageItem _convertWebDavFileToItem(webdav.File webdavFile) {
    final name = p.basename(webdavFile.path);
    
    if (webdavFile.isDir) {
      return StorageItem(
        id: webdavFile.path,
        name: name == '/' ? 'Root' : name,
        path: webdavFile.path,
        modifiedAt: webdavFile.mTime,
        isShared: false, // WebDAV doesn't provide this info directly
        isFavorite: false, // Same here
        type: ItemType.folder,
      );
    } else {
      return StorageItem(
        id: webdavFile.path,
        name: name,
        path: webdavFile.path,
        modifiedAt: webdavFile.mTime,
        isShared: false, // WebDAV doesn't provide this info directly
        isFavorite: false, // Same here
        type: ItemType.file,
        size: webdavFile.size,
        mimeType: webdavFile.mimeType,
      );
    }
  }
  
  @override
  Future<Folder> getFolder(String folderId) async {
    try {
      await _ensureAuthenticated();
      
      final folder = await _client.getFileProps(folderId);
      if (!folder.isDir) {
        throw Exception('Not a folder: $folderId');
      }
      
      return _convertWebDavFolder(folder);
    } catch (e) {
      _logger.warning('Failed to get folder: $folderId - $e');
      rethrow;
    }
  }
  
  @override
  Future<Folder> getRootFolder() async {
    try {
      await _ensureAuthenticated();
      
      final folder = await _client.getFileProps('/');
      return _convertWebDavFolder(folder);
    } catch (e) {
      _logger.warning('Failed to get root folder - $e');
      rethrow;
    }
  }
  
  @override
  Future<List<StorageItem>> listFolderContents(String folderId) async {
    try {
      await _ensureAuthenticated();
      
      final items = await _client.readDir(folderId);
      
      return items.map(_convertWebDavFileToItem).toList();
    } catch (e) {
      _logger.warning('Failed to list folder contents: $folderId - $e');
      rethrow;
    }
  }
  
  @override
  Future<Folder> createFolder({
    required String parentFolderId,
    required String name,
  }) async {
    try {
      await _ensureAuthenticated();
      
      // Ensure parent folder path ends with a slash
      final normalizedParentPath = parentFolderId.endsWith('/')
          ? parentFolderId
          : '$parentFolderId/';
      
      // Construct folder path
      final folderPath = '$normalizedParentPath$name';
      
      // Create folder
      await _client.mkCol(folderPath);
      
      // Get the created folder properties
      final folder = await _client.getFileProps(folderPath);
      
      return _convertWebDavFolder(folder);
    } catch (e) {
      _logger.warning('Failed to create folder: $name - $e');
      rethrow;
    }
  }
  
  @override
  Future<Folder> renameFolder(String folderId, String newName) async {
    try {
      await _ensureAuthenticated();
      
      // Get parent folder path
      final parentPath = p.dirname(folderId);
      final normalizedParentPath = parentPath.endsWith('/')
          ? parentPath
          : '$parentPath/';
      
      // Construct new folder path
      final newPath = '$normalizedParentPath$newName';
      
      // Move folder to new path (rename)
      await _client.rename(folderId, newPath);
      
      // Get the renamed folder properties
      final folder = await _client.getFileProps(newPath);
      
      return _convertWebDavFolder(folder);
    } catch (e) {
      _logger.warning('Failed to rename folder: $folderId - $e');
      rethrow;
    }
  }
  
  @override
  Future<Folder> moveFolder(String folderId, String newParentFolderId) async {
    try {
      await _ensureAuthenticated();
      
      // Get folder name
      final name = p.basename(folderId);
      
      // Ensure new parent folder path ends with a slash
      final normalizedParentPath = newParentFolderId.endsWith('/')
          ? newParentFolderId
          : '$newParentFolderId/';
      
      // Construct new folder path
      final newPath = '$normalizedParentPath$name';
      
      // Move folder to new path
      await _client.rename(folderId, newPath);
      
      // Get the moved folder properties
      final folder = await _client.getFileProps(newPath);
      
      return _convertWebDavFolder(folder);
    } catch (e) {
      _logger.warning('Failed to move folder: $folderId - $e');
      rethrow;
    }
  }
  
  @override
  Future<void> deleteFolder(String folderId) async {
    try {
      await _ensureAuthenticated();
      
      // Delete folder
      await _client.remove(folderId);
    } catch (e) {
      _logger.warning('Failed to delete folder: $folderId - $e');
      rethrow;
    }
  }
  
  @override
  Future<Folder> markAsFavorite(String folderId, bool favorite) async {
    try {
      await _ensureAuthenticated();
      
      // OxiCloud WebDAV extension for favorites
      final String propertyValue = favorite ? 'true' : 'false';
      
      // Set favorite property
      await _setProp(folderId, 'oc:favorite', propertyValue);
      
      // Get the updated folder properties
      final folder = await _client.getFileProps(folderId);
      final domainFolder = _convertWebDavFolder(folder);
      
      // Return with updated favorite status since WebDAV doesn't reflect this immediately
      return domainFolder.copyWith(isFavorite: favorite);
    } catch (e) {
      _logger.warning('Failed to mark folder as favorite: $folderId - $e');
      rethrow;
    }
  }
  
  /// Set a WebDAV property
  Future<void> _setProp(String path, String propertyName, String value) async {
    // WebDAV PROPPATCH request
    final uri = Uri.parse('${_appConfig.webdavUrl}$path');
    
    final body = '''
      <?xml version="1.0" encoding="utf-8" ?>
      <d:propertyupdate xmlns:d="DAV:" xmlns:oc="http://owncloud.org/ns">
        <d:set>
          <d:prop>
            <$propertyName>$value</$propertyName>
          </d:prop>
        </d:set>
      </d:propertyupdate>
    ''';
    
    final token = await _secureStorage.getToken();
    
    final response = await http.send(http.Request('PROPPATCH', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Content-Type'] = 'application/xml'
      ..body = body);
    
    if (response.statusCode >= 400) {
      throw Exception('Failed to set property: ${response.statusCode}');
    }
  }
  
  @override
  Future<List<Folder>> getFolderPath(String folderId) async {
    try {
      await _ensureAuthenticated();
      
      // Parse folder path
      final parts = folderId.split('/')
        ..removeWhere((part) => part.isEmpty);
      
      // Add root folder
      final path = <Folder>[];
      
      // Get root folder
      final rootFolder = await getRootFolder();
      path.add(rootFolder);
      
      // Build path incrementally
      String currentPath = '';
      for (final part in parts) {
        currentPath += '/$part';
        
        // Skip root folder
        if (currentPath == '/') continue;
        
        final folder = await _client.getFileProps(currentPath);
        path.add(_convertWebDavFolder(folder));
      }
      
      return path;
    } catch (e) {
      _logger.warning('Failed to get folder path: $folderId - $e');
      rethrow;
    }
  }
  
  @override
  Future<List<Folder>> searchFolders(String query) async {
    try {
      await _ensureAuthenticated();
      
      // OxiCloud WebDAV extension for search
      final searchUrl = '${_appConfig.apiUrl}/search?query=$query&type=folder';
      
      final token = await _secureStorage.getToken();
      
      final response = await http.get(
        Uri.parse(searchUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final searchResults = jsonDecode(response.body) as Map<String, dynamic>;
        final results = searchResults['results'] as List<dynamic>;
        
        final folders = <Folder>[];
        
        for (final result in results) {
          final resultMap = result as Map<String, dynamic>;
          
          // Get folder properties
          final path = resultMap['path'] as String;
          final folder = await _client.getFileProps(path);
          
          if (folder.isDir) {
            folders.add(_convertWebDavFolder(folder));
          }
        }
        
        return folders;
      }
      
      return [];
    } catch (e) {
      _logger.warning('Failed to search folders: $query - $e');
      rethrow;
    }
  }
  
  @override
  Future<int> getFolderSize(String folderId) async {
    try {
      await _ensureAuthenticated();
      
      // OxiCloud WebDAV extension for folder size
      final sizeUrl = '${_appConfig.apiUrl}/size?path=$folderId';
      
      final token = await _secureStorage.getToken();
      
      final response = await http.get(
        Uri.parse(sizeUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final sizeData = jsonDecode(response.body) as Map<String, dynamic>;
        final size = sizeData['size'] as int;
        
        return size;
      }
      
      return _calculateFolderSizeFallback(folderId);
    } catch (e) {
      _logger.warning('Failed to get folder size: $folderId - $e');
      
      // Fallback to manual calculation
      return _calculateFolderSizeFallback(folderId);
    }
  }
  
  /// Calculate folder size by recursively listing contents
  Future<int> _calculateFolderSizeFallback(String folderId) async {
    try {
      // List folder contents
      final items = await _client.readDir(folderId);
      
      int totalSize = 0;
      
      for (final item in items) {
        if (item.isDir) {
          // Recursively calculate subfolder size
          totalSize += await _calculateFolderSizeFallback(item.path);
        } else {
          // Add file size
          totalSize += item.size;
        }
      }
      
      return totalSize;
    } catch (e) {
      _logger.warning('Failed to calculate folder size: $folderId - $e');
      return 0;
    }
  }
}