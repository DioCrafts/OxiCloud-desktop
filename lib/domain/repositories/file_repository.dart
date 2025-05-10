import 'dart:io';
import 'package:oxicloud_desktop/domain/entities/file_item.dart';

abstract class FileRepository {
  /// Obtiene el contenido de un directorio
  Future<List<FileItem>> listFiles(String path);
  
  /// Crea un nuevo directorio
  Future<void> createFolder(String path, String name);
  
  /// Sube un archivo
  Future<void> uploadFile(File file, String destinationPath);
  
  /// Descarga un archivo
  Future<void> downloadFile(String path, String destination);
  
  /// Elimina un archivo o directorio
  Future<void> deleteFile(String path);
  
  /// Mueve un archivo o directorio
  Future<void> moveFile(String sourcePath, String destinationPath);
  
  /// Copia un archivo o directorio
  Future<void> copyFile(String sourcePath, String destinationPath);
  
  /// Renombra un archivo o directorio
  Future<void> renameFile(String path, String newName);
  
  /// Comparte un archivo o directorio
  Future<FileItem> share(String path, List<String> userIds);
  
  /// Obtiene los detalles de un archivo o directorio
  Future<FileItem> getDetails(String path);
  
  /// Busca archivos y directorios
  Future<List<FileItem>> search(String query);
  
  /// Obtiene la URL de vista previa de un archivo
  Future<String> getPreviewUrl(String fileId);
  
  /// Obtiene la URL de descarga directa de un archivo
  Future<String> getDownloadUrl(String fileId);
} 