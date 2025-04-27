import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/file_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:injectable/injectable.dart';

@injectable
class ApiService {
  static const String baseUrl = 'http://localhost:3000/api'; // TODO: Cambiar por la URL real del servidor
  String? _token;
  Directory? _localStorageDir;

  void setToken(String token) {
    _token = token;
  }

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  Future<void> _ensureLocalStorageDir() async {
    if (_localStorageDir == null) {
      final appDir = await getApplicationDocumentsDirectory();
      _localStorageDir = Directory(path.join(appDir.path, 'oxicloud_files'));
      if (!await _localStorageDir!.exists()) {
        await _localStorageDir!.create(recursive: true);
      }
    }
  }

  Future<String> getLocalPath(String fileId) async {
    await _ensureLocalStorageDir();
    return path.join(_localStorageDir!.path, fileId);
  }

  Future<void> downloadFile(FileModel file) async {
    try {
      final localPath = await getLocalPath(file.id);
      final response = await http.get(
        Uri.parse('$baseUrl/files/${file.id}/download'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final file = File(localPath);
        await file.writeAsBytes(response.bodyBytes);
      } else {
        throw Exception('Error al descargar archivo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> removeLocalFile(String fileId) async {
    try {
      final localPath = await getLocalPath(fileId);
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Error al eliminar archivo local: $e');
    }
  }

  Future<void> setSyncStatus(String fileId, SyncStatus status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/files/$fileId/sync'),
        headers: _headers,
        body: json.encode({
          'syncStatus': status.toString().split('.').last,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al actualizar estado de sincronización: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> syncFolder(String folderId, bool sync) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/files/$folderId/sync-folder'),
        headers: _headers,
        body: json.encode({
          'sync': sync,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al sincronizar carpeta: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<FileModel>> getFiles(String path) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/files?path=$path'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => _parseFileModel(item)).toList();
      } else {
        throw Exception('Error al cargar archivos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<FileModel> createFolder(String path, String name) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/files/folder'),
        headers: _headers,
        body: json.encode({
          'path': path,
          'name': name,
        }),
      );

      if (response.statusCode == 201) {
        return _parseFileModel(json.decode(response.body));
      } else {
        throw Exception('Error al crear carpeta: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> uploadFile(String path, String filePath) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/files/upload'));
      request.headers.addAll(_headers);
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      request.fields['path'] = path;

      var response = await request.send();
      if (response.statusCode != 201) {
        throw Exception('Error al subir archivo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> deleteFile(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/files/$id'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar archivo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> renameFile(String id, String newName) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/files/$id'),
        headers: _headers,
        body: json.encode({
          'name': newName,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al renombrar archivo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> moveFile(String id, String newPath) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/files/$id/move'),
        headers: _headers,
        body: json.encode({
          'path': newPath,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al mover archivo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/files/$id/favorite'),
        headers: _headers,
        body: json.encode({
          'isFavorite': isFavorite,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al actualizar favorito: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  FileModel _parseFileModel(Map<String, dynamic> data) {
    return FileModel(
      id: data['id'],
      name: data['name'],
      path: data['path'],
      type: _parseFileType(data['type']),
      size: data['size'],
      modifiedDate: DateTime.parse(data['modifiedDate']),
      thumbnailUrl: data['thumbnailUrl'],
      isFavorite: data['isFavorite'] ?? false,
      isShared: data['isShared'] ?? false,
      sharedBy: data['sharedBy'],
      owner: data['owner'],
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  FileType _parseFileType(String type) {
    switch (type.toLowerCase()) {
      case 'folder':
        return FileType.folder;
      case 'image':
        return FileType.image;
      case 'video':
        return FileType.video;
      case 'audio':
        return FileType.audio;
      case 'document':
        return FileType.document;
      case 'pdf':
        return FileType.pdf;
      case 'code':
        return FileType.code;
      case 'archive':
        return FileType.archive;
      default:
        return FileType.other;
    }
  }
} 