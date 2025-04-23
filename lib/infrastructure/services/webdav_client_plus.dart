import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:webdav_client/webdav_client.dart' as base;
import 'package:xml/xml.dart';

/// Extended WebDAV client implementation with additional features
class Client extends base.Client {
  /// Default headers for requests
  Map<String, String> defaultHeaders = {};
  
  /// Creates a client from a base client
  Client.fromClient(base.Client baseClient) : super(baseClient.baseUrl) {
    this.httpClient = baseClient.httpClient;
    this.webdavServerUrl = baseClient.webdavServerUrl;
    this.credentials = baseClient.credentials;
    this.protocol = baseClient.protocol;
  }
  
  /// Gets file properties
  Future<base.File> getFileProps(String path) async {
    final response = await propfind(path, depth: '0');
    final files = baseResponseParser(response, path);
    if (files.isEmpty) {
      throw Exception('File not found: $path');
    }
    return files.first;
  }
  
  /// Reads a file as binary
  Future<Uint8List> readBinary(String path) async {
    final url = '$webdavServerUrl$path';
    final request = http.Request('GET', Uri.parse(url));
    
    if (credentials != null) {
      request.headers['Authorization'] = 'Basic ${base64Encode(utf8.encode('${credentials?.username}:${credentials?.password}'))}';
    }
    
    // Add custom headers
    if (defaultHeaders.isNotEmpty) {
      request.headers.addAll(defaultHeaders);
    }
    
    final streamResponse = await httpClient.send(request);
    final response = await http.Response.fromStream(streamResponse);
    
    if (response.statusCode != 200) {
      throw Exception('Failed to read file: ${response.statusCode} ${response.reasonPhrase}');
    }
    
    return response.bodyBytes;
  }
  
  /// Writes a file 
  Future<void> writeFile(String path, Uint8List data, {String? contentType}) async {
    final url = '$webdavServerUrl$path';
    final request = http.Request('PUT', Uri.parse(url));
    
    if (credentials != null) {
      request.headers['Authorization'] = 'Basic ${base64Encode(utf8.encode('${credentials?.username}:${credentials?.password}'))}';
    }
    
    // Add content type
    if (contentType != null) {
      request.headers['Content-Type'] = contentType;
    }
    
    // Add custom headers
    if (defaultHeaders.isNotEmpty) {
      request.headers.addAll(defaultHeaders);
    }
    
    request.bodyBytes = data;
    
    final streamResponse = await httpClient.send(request);
    final response = await http.Response.fromStream(streamResponse);
    
    if (response.statusCode != 201 && response.statusCode != 204) {
      throw Exception('Failed to write file: ${response.statusCode} ${response.reasonPhrase}');
    }
  }
  
  /// Downloads a file to local path
  Future<void> download(String remotePath, String localPath) async {
    final data = await readBinary(remotePath);
    await base.File(localPath).writeAsBytes(data);
  }
  
  /// Creates a collection (directory)
  Future<void> mkCol(String path) async {
    final url = '$webdavServerUrl$path';
    final request = http.Request('MKCOL', Uri.parse(url));
    
    if (credentials != null) {
      request.headers['Authorization'] = 'Basic ${base64Encode(utf8.encode('${credentials?.username}:${credentials?.password}'))}';
    }
    
    // Add custom headers
    if (defaultHeaders.isNotEmpty) {
      request.headers.addAll(defaultHeaders);
    }
    
    final streamResponse = await httpClient.send(request);
    final response = await http.Response.fromStream(streamResponse);
    
    if (response.statusCode != 201 && response.statusCode != 204) {
      throw Exception('Failed to create collection: ${response.statusCode} ${response.reasonPhrase}');
    }
  }

  /// Renames a file or folder
  Future<void> rename(String oldPath, String newPath, {bool overwrite = false}) async {
    final url = '$webdavServerUrl$oldPath';
    final request = http.Request('MOVE', Uri.parse(url));
    
    if (credentials != null) {
      request.headers['Authorization'] = 'Basic ${base64Encode(utf8.encode('${credentials?.username}:${credentials?.password}'))}';
    }
    
    // Add destination header
    request.headers['Destination'] = '$webdavServerUrl$newPath';
    
    // Add overwrite header
    request.headers['Overwrite'] = overwrite ? 'T' : 'F';
    
    // Add custom headers
    if (defaultHeaders.isNotEmpty) {
      request.headers.addAll(defaultHeaders);
    }
    
    final streamResponse = await httpClient.send(request);
    final response = await http.Response.fromStream(streamResponse);
    
    if (response.statusCode != 201 && response.statusCode != 204) {
      throw Exception('Failed to rename file: ${response.statusCode} ${response.reasonPhrase}');
    }
  }
}

/// Creates a new client
Client newClient({
  required String baseUrl,
  http.Client? httpClient,
  base.Credentials? credentials,
}) {
  final baseClient = base.newClient(baseUrl, httpClient: httpClient, credentials: credentials);
  return Client.fromClient(baseClient);
}