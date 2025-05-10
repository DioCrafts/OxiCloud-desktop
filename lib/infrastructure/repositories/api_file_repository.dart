import 'dart:io';
import 'package:dio/dio.dart';
import 'package:oxicloud_desktop/domain/entities/file_item.dart';
import 'package:oxicloud_desktop/domain/repositories/file_repository.dart';

class ApiFileRepository implements FileRepository {
  final Dio _dio;
  final String _baseUrl;

  ApiFileRepository(this._dio, this._baseUrl);

  @override
  Future<List<FileItem>> listFiles(String path) async {
    try {
      final response = await _dio.get('$_baseUrl/files', queryParameters: {'path': path});
      return (response.data as List)
          .map((item) => FileItem.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Error al listar archivos: $e');
    }
  }

  @override
  Future<void> createFolder(String path, String name) async {
    try {
      await _dio.post('$_baseUrl/folders', data: {
        'path': path,
        'name': name,
      });
    } catch (e) {
      throw Exception('Error al crear carpeta: $e');
    }
  }

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) async {
    try {
      await _dio.post('$_baseUrl/files/move', data: {
        'sourcePath': sourcePath,
        'destinationPath': destinationPath,
      });
    } catch (e) {
      throw Exception('Error al mover archivo: $e');
    }
  }

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) async {
    try {
      await _dio.post('$_baseUrl/files/copy', data: {
        'sourcePath': sourcePath,
        'destinationPath': destinationPath,
      });
    } catch (e) {
      throw Exception('Error al copiar archivo: $e');
    }
  }

  @override
  Future<void> renameFile(String path, String newName) async {
    try {
      await _dio.post('$_baseUrl/files/rename', data: {
        'path': path,
        'newName': newName,
      });
    } catch (e) {
      throw Exception('Error al renombrar archivo: $e');
    }
  }

  @override
  Future<void> deleteFile(String path) async {
    try {
      await _dio.delete('$_baseUrl/files', data: {'path': path});
    } catch (e) {
      throw Exception('Error al eliminar archivo: $e');
    }
  }

  @override
  Future<void> uploadFile(File file, String destinationPath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        'path': destinationPath,
      });
      await _dio.post('$_baseUrl/files/upload', data: formData);
    } catch (e) {
      throw Exception('Error al subir archivo: $e');
    }
  }

  @override
  Future<void> downloadFile(String path, String destination) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/files/download',
        queryParameters: {'path': path},
        options: Options(responseType: ResponseType.bytes),
      );
      final file = File(destination);
      await file.writeAsBytes(response.data);
    } catch (e) {
      throw Exception('Error al descargar archivo: $e');
    }
  }

  @override
  Future<FileItem> getDetails(String path) async {
    try {
      final response = await _dio.get('$_baseUrl/files/details', queryParameters: {'path': path});
      return FileItem.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener detalles del archivo: $e');
    }
  }

  @override
  Future<List<FileItem>> search(String query) async {
    try {
      final response = await _dio.get('$_baseUrl/files/search', queryParameters: {'query': query});
      return (response.data as List)
          .map((item) => FileItem.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar archivos: $e');
    }
  }

  @override
  Future<FileItem> share(String path, List<String> userIds) async {
    try {
      final response = await _dio.post('$_baseUrl/files/share', data: {
        'path': path,
        'userIds': userIds,
      });
      return FileItem.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al compartir archivo: $e');
    }
  }

  @override
  Future<String> getPreviewUrl(String fileId) async {
    try {
      final response = await _dio.get('$_baseUrl/files/preview/$fileId');
      return response.data['url'] as String;
    } catch (e) {
      throw Exception('Error al obtener URL de vista previa: $e');
    }
  }

  @override
  Future<String> getDownloadUrl(String fileId) async {
    try {
      final response = await _dio.get('$_baseUrl/files/download-url/$fileId');
      return response.data['url'] as String;
    } catch (e) {
      throw Exception('Error al obtener URL de descarga: $e');
    }
  }
} 