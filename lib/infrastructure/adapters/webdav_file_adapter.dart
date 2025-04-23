import 'dart:convert';
import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/core/config/app_config.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';
import 'package:oxicloud_desktop/core/storage/secure_storage.dart';
import 'package:oxicloud_desktop/domain/entities/file.dart';
import 'package:oxicloud_desktop/domain/repositories/file_repository.dart';
import 'package:webdav_client/webdav_client.dart' as webdav hide Client;
import 'package:oxicloud_desktop/infrastructure/services/webdav_client_plus.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

/// WebDAV adapter for file operations
class WebDAVFileAdapter implements FileRepository {
  late final Client _client;
  final AppConfig _appConfig;
  final SecureStorage _secureStorage;
  final Logger _logger = LoggingManager.getLogger('WebDAVFileAdapter');
  
  /// Create a WebDAVFileAdapter
  WebDAVFileAdapter(this._appConfig, this._secureStorage) {
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
  
  /// Convert WebDAV file to domain File
  File _convertWebDavFile(webdav.File webdavFile) {
    final name = p.basename(webdavFile.path);
    
    return File(
      id: webdavFile.path,
      name: name,
      path: webdavFile.path,
      size: webdavFile.size,
      modifiedAt: webdavFile.mTime,
      mimeType: webdavFile.mimeType ?? 'application/octet-stream',
      isShared: false, // WebDAV doesn't provide this info directly
      etag: webdavFile.eTag,
    );
  }
  
  @override
  Future<File> getFile(String fileId) async {
    try {
      await _ensureAuthenticated();
      
      final file = await _client.getFileProps(fileId);
      return _convertWebDavFile(file);
    } catch (e) {
      _logger.warning('Failed to get file: $fileId - $e');
      rethrow;
    }
  }
  
  @override
  Future<List<File>> listFiles(String folderId) async {
    try {
      await _ensureAuthenticated();
      
      final items = await _client.readDir(folderId);
      
      // Filter out directories
      final files = items.where((item) => !item.isDir);
      
      return files.map(_convertWebDavFile).toList();
    } catch (e) {
      _logger.warning('Failed to list files in folder: $folderId - $e');
      rethrow;
    }
  }
  
  @override
  Future<File> uploadFile({
    required String parentFolderId,
    required String name,
    required Uint8List data,
    String? mimeType,
  }) async {
    try {
      await _ensureAuthenticated();
      
      // Ensure parent folder path ends with a slash
      final normalizedParentPath = parentFolderId.endsWith('/')
          ? parentFolderId
          : '$parentFolderId/';
      
      // Construct file path
      final filePath = '$normalizedParentPath$name';
      
      // Upload file
      await _client.writeFile(
        filePath,
        data,
        onProgress: (count, total) {
          _logger.fine('Uploading $name: $count / $total bytes');
        },
      );
      
      // Get the uploaded file properties
      final file = await _client.getFileProps(filePath);
      
      return _convertWebDavFile(file);
    } catch (e) {
      _logger.warning('Failed to upload file: $name - $e');
      rethrow;
    }
  }
  
  @override
  Future<File> updateFile({
    required String fileId,
    required Uint8List data,
  }) async {
    try {
      await _ensureAuthenticated();
      
      // Upload file with the same ID (path)
      await _client.writeFile(
        fileId,
        data,
        onProgress: (count, total) {
          _logger.fine('Updating $fileId: $count / $total bytes');
        },
      );
      
      // Get the updated file properties
      final file = await _client.getFileProps(fileId);
      
      return _convertWebDavFile(file);
    } catch (e) {
      _logger.warning('Failed to update file: $fileId - $e');
      rethrow;
    }
  }
  
  @override
  Future<Uint8List> downloadFile(String fileId) async {
    try {
      await _ensureAuthenticated();
      
      // Download file
      final bytes = await _client.readBinary(fileId);
      
      return bytes;
    } catch (e) {
      _logger.warning('Failed to download file: $fileId - $e');
      rethrow;
    }
  }
  
  @override
  Future<void> downloadFileToPath(String fileId, String localPath) async {
    try {
      await _ensureAuthenticated();
      
      // Download file directly to path
      await _client.download(fileId, localPath);
    } catch (e) {
      _logger.warning('Failed to download file to path: $fileId - $e');
      rethrow;
    }
  }
  
  @override
  Future<File> renameFile(String fileId, String newName) async {
    try {
      await _ensureAuthenticated();
      
      // Get parent folder path
      final parentPath = p.dirname(fileId);
      final normalizedParentPath = parentPath.endsWith('/')
          ? parentPath
          : '$parentPath/';
      
      // Construct new file path
      final newPath = '$normalizedParentPath$newName';
      
      // Move file to new path (rename)
      await _client.rename(fileId, newPath);
      
      // Get the renamed file properties
      final file = await _client.getFileProps(newPath);
      
      return _convertWebDavFile(file);
    } catch (e) {
      _logger.warning('Failed to rename file: $fileId - $e');
      rethrow;
    }
  }
  
  @override
  Future<File> moveFile(String fileId, String newParentFolderId) async {
    try {
      await _ensureAuthenticated();
      
      // Get file name
      final name = p.basename(fileId);
      
      // Ensure new parent folder path ends with a slash
      final normalizedParentPath = newParentFolderId.endsWith('/')
          ? newParentFolderId
          : '$newParentFolderId/';
      
      // Construct new file path
      final newPath = '$normalizedParentPath$name';
      
      // Move file to new path
      await _client.rename(fileId, newPath);
      
      // Get the moved file properties
      final file = await _client.getFileProps(newPath);
      
      return _convertWebDavFile(file);
    } catch (e) {
      _logger.warning('Failed to move file: $fileId - $e');
      rethrow;
    }
  }
  
  @override
  Future<void> deleteFile(String fileId) async {
    try {
      await _ensureAuthenticated();
      
      // Delete file
      await _client.remove(fileId);
    } catch (e) {
      _logger.warning('Failed to delete file: $fileId - $e');
      rethrow;
    }
  }
  
  @override
  Future<File> markAsFavorite(String fileId, bool favorite) async {
    try {
      await _ensureAuthenticated();
      
      // OxiCloud WebDAV extension for favorites
      final String propertyValue = favorite ? 'true' : 'false';
      
      // Set favorite property
      await _setProp(fileId, 'oc:favorite', propertyValue);
      
      // Get the updated file properties
      final file = await _client.getFileProps(fileId);
      final domainFile = _convertWebDavFile(file);
      
      // Return with updated favorite status since WebDAV doesn't reflect this immediately
      return domainFile.copyWith(isFavorite: favorite);
    } catch (e) {
      _logger.warning('Failed to mark file as favorite: $fileId - $e');
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
  Future<Uint8List?> getThumbnail(String fileId, {int? size}) async {
    try {
      await _ensureAuthenticated();
      
      // OxiCloud WebDAV extension for thumbnails
      final thumbnailSize = size ?? 128;
      
      // Construct thumbnail URL
      final thumbnailUrl = '${_appConfig.apiUrl}/thumbnails?file=$fileId&size=$thumbnailSize';
      
      final token = await _secureStorage.getToken();
      
      final response = await http.get(
        Uri.parse(thumbnailUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      
      return null;
    } catch (e) {
      _logger.warning('Failed to get thumbnail: $fileId - $e');
      return null;
    }
  }
  
  @override
  Future<List<File>> searchFiles(String query) async {
    try {
      await _ensureAuthenticated();
      
      // OxiCloud WebDAV extension for search
      final searchUrl = '${_appConfig.apiUrl}/search?query=$query&type=file';
      
      final token = await _secureStorage.getToken();
      
      final response = await http.get(
        Uri.parse(searchUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final searchResults = jsonDecode(response.body) as Map<String, dynamic>;
        final results = searchResults['results'] as List<dynamic>;
        
        final files = <File>[];
        
        for (final result in results) {
          final resultMap = result as Map<String, dynamic>;
          
          // Get file properties
          final path = resultMap['path'] as String;
          final file = await _client.getFileProps(path);
          
          files.add(_convertWebDavFile(file));
        }
        
        return files;
      }
      
      return [];
    } catch (e) {
      _logger.warning('Failed to search files: $query - $e');
      rethrow;
    }
  }
  
  @override
  Future<List<File>> getSharedFiles() async {
    try {
      await _ensureAuthenticated();
      
      // OxiCloud WebDAV extension for shared files
      final sharedUrl = '${_appConfig.apiUrl}/shares';
      
      final token = await _secureStorage.getToken();
      
      final response = await http.get(
        Uri.parse(sharedUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final sharesData = jsonDecode(response.body) as Map<String, dynamic>;
        final shares = sharesData['shares'] as List<dynamic>;
        
        final files = <File>[];
        
        for (final share in shares) {
          final shareMap = share as Map<String, dynamic>;
          
          // Get file path
          final path = shareMap['path'] as String;
          
          // Check if it's a file (not a folder)
          final isFolder = shareMap['type'] == 'folder';
          if (!isFolder) {
            // Get file properties
            final file = await _client.getFileProps(path);
            files.add(_convertWebDavFile(file).copyWith(isShared: true));
          }
        }
        
        return files;
      }
      
      return [];
    } catch (e) {
      _logger.warning('Failed to get shared files - $e');
      rethrow;
    }
  }
  
  @override
  Future<List<File>> getRecentFiles({int limit = 10}) async {
    try {
      await _ensureAuthenticated();
      
      // OxiCloud WebDAV extension for recent files
      final recentUrl = '${_appConfig.apiUrl}/recent?limit=$limit';
      
      final token = await _secureStorage.getToken();
      
      final response = await http.get(
        Uri.parse(recentUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final recentData = jsonDecode(response.body) as Map<String, dynamic>;
        final items = recentData['items'] as List<dynamic>;
        
        final files = <File>[];
        
        for (final item in items) {
          final itemMap = item as Map<String, dynamic>;
          
          // Get file path
          final path = itemMap['path'] as String;
          
          // Check if it's a file (not a folder)
          if (itemMap['type'] == 'file') {
            // Get file properties
            final file = await _client.getFileProps(path);
            files.add(_convertWebDavFile(file));
          }
        }
        
        return files;
      }
      
      return [];
    } catch (e) {
      _logger.warning('Failed to get recent files - $e');
      rethrow;
    }
  }
}