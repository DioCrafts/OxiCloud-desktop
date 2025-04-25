import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' as io;
import 'package:http/http.dart' as http;
import 'package:webdav_client/webdav_client.dart' as webdav;

/// Wrapper for WebDAV Client
class EnhancedWebDavClient {
  late final webdav.Client _client;
  final Map<String, String> _headers = {};
  
  EnhancedWebDavClient(String serverUrl, {String? token, http.Client? httpClient}) {
    _client = webdav.newClient(serverUrl);
    
    if (token != null) {
      updateAuthorization(token);
    }
  }
  
  /// Update authorization token
  void updateAuthorization(String token) {
    _headers['Authorization'] = 'Bearer $token';
    _client.setHeaders(_headers);
  }
  
  /// Gets file properties
  Future<webdav.File> getFileProps(String path) async {
    try {
      // Using the list API and filtering by path as the WebDAV client doesn't have a direct getProps method
      final props = await _client.readDir(path);
      if (props.isEmpty) {
        throw Exception('File not found: $path');
      }
      return props.first;
    } catch (e) {
      throw Exception('Failed to get file properties: $path - $e');
    }
  }
  
  /// Reads a file as binary
  Future<Uint8List> readBinary(String path) async {
    try {
      List<int> bytes = await _client.read(path);
      return Uint8List.fromList(bytes);
    } catch (e) {
      throw Exception('Failed to read file: $e');
    }
  }
  
  /// Writes a file 
  Future<void> writeFile(String path, Uint8List data, {String? contentType, Function(int, int)? onProgress}) async {
    try {
      await _client.write(path, data);
    } catch (e) {
      throw Exception('Failed to write file: $e');
    }
  }
  
  /// Downloads a file to local path
  Future<void> download(String remotePath, String localPath) async {
    try {
      final data = await readBinary(remotePath);
      await io.File(localPath).writeAsBytes(data);
    } catch (e) {
      throw Exception('Failed to download file: $e');
    }
  }
  
  /// Creates a collection (directory)
  Future<void> mkCol(String path) async {
    try {
      await _client.mkdir(path);
    } catch (e) {
      throw Exception('Failed to create directory: $e');
    }
  }

  /// Renames a file or folder
  Future<void> rename(String oldPath, String newPath, {bool overwrite = false}) async {
    try {
      // WebDAV client rename has different parameters in this version
      await _client.rename(oldPath, newPath, false);
    } catch (e) {
      throw Exception('Failed to rename: $e');
    }
  }
  
  /// Remove a file or directory
  Future<void> remove(String path) async {
    try {
      await _client.remove(path);
    } catch (e) {
      throw Exception('Failed to remove: $e');
    }
  }
  
  /// Read directory contents
  Future<List<webdav.File>> readDir(String path) async {
    try {
      return await _client.readDir(path);
    } catch (e) {
      throw Exception('Failed to read directory: $e');
    }
  }
  
  /// PROPPATCH request for setting properties
  Future<void> proppatch(String path, String propertyName, String value) async {
    try {
      // Using raw HTTP request because webdav_client doesn't support PROPPATCH directly
      String body = '''
      <?xml version="1.0" encoding="utf-8" ?>
      <d:propertyupdate xmlns:d="DAV:" xmlns:oc="http://owncloud.org/ns">
        <d:set>
          <d:prop>
            <$propertyName>$value</$propertyName>
          </d:prop>
        </d:set>
      </d:propertyupdate>
      ''';
      
      // Create URL manually as webdav_client doesn't expose baseUrl
      final url = "${_client.toString().split(' ').last.replaceAll(']', '')}$path";
      final request = http.Request('PROPPATCH', Uri.parse(url));
      
      request.headers.addAll(_headers);
      request.headers['Content-Type'] = 'application/xml';
      request.body = body;
      
      final response = await http.Client().send(request);
      
      if (response.statusCode >= 400) {
        throw Exception('Failed to set property: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to set property: $e');
    }
  }
}