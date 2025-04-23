import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';

/// Service for working with MIME types
class MimeTypeService {
  /// Common file extensions and their MIME types
  static const Map<String, String> _extensionToMimeType = {
    // Images
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'bmp': 'image/bmp',
    'webp': 'image/webp',
    'svg': 'image/svg+xml',
    
    // Documents
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'odt': 'application/vnd.oasis.opendocument.text',
    'ods': 'application/vnd.oasis.opendocument.spreadsheet',
    'odp': 'application/vnd.oasis.opendocument.presentation',
    
    // Text
    'txt': 'text/plain',
    'html': 'text/html',
    'htm': 'text/html',
    'xml': 'text/xml',
    'css': 'text/css',
    'csv': 'text/csv',
    'md': 'text/markdown',
    
    // Audio
    'mp3': 'audio/mpeg',
    'wav': 'audio/wav',
    'ogg': 'audio/ogg',
    'm4a': 'audio/mp4',
    'flac': 'audio/flac',
    
    // Video
    'mp4': 'video/mp4',
    'avi': 'video/x-msvideo',
    'mov': 'video/quicktime',
    'wmv': 'video/x-ms-wmv',
    'mkv': 'video/x-matroska',
    'webm': 'video/webm',
    
    // Archives
    'zip': 'application/zip',
    'rar': 'application/x-rar-compressed',
    'tar': 'application/x-tar',
    'gz': 'application/gzip',
    '7z': 'application/x-7z-compressed',
    
    // Programming
    'js': 'application/javascript',
    'json': 'application/json',
    'py': 'text/x-python',
    'java': 'text/x-java',
    'c': 'text/x-c',
    'cpp': 'text/x-c++',
    'cs': 'text/x-csharp',
    'php': 'text/x-php',
    'rb': 'text/x-ruby',
    'swift': 'text/x-swift',
    'go': 'text/x-go',
    'rs': 'text/x-rust',
    'dart': 'text/x-dart',
    
    // Other
    'exe': 'application/x-msdownload',
    'apk': 'application/vnd.android.package-archive',
    'iso': 'application/x-iso9660-image',
    'bin': 'application/octet-stream',
  };

  /// Get MIME type from file extension
  static String getMimeTypeFromExtension(String filename) {
    final extension = p.extension(filename).toLowerCase();
    
    // Remove the leading dot
    final ext = extension.startsWith('.') ? extension.substring(1) : extension;
    
    return _extensionToMimeType[ext] ?? 'application/octet-stream';
  }
  
  /// Get file type category from MIME type
  static FileTypeCategory getFileCategory(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return FileTypeCategory.image;
    } else if (mimeType.startsWith('video/')) {
      return FileTypeCategory.video;
    } else if (mimeType.startsWith('audio/')) {
      return FileTypeCategory.audio;
    } else if (mimeType == 'application/pdf' ||
        mimeType.startsWith('application/vnd.openxmlformats-officedocument') ||
        mimeType.startsWith('application/vnd.oasis.opendocument') ||
        mimeType.startsWith('application/msword') ||
        mimeType.startsWith('application/vnd.ms-')) {
      return FileTypeCategory.document;
    } else if (mimeType.startsWith('text/') ||
        mimeType == 'application/json' ||
        mimeType == 'application/xml' ||
        mimeType == 'application/javascript') {
      return FileTypeCategory.text;
    } else if (mimeType == 'application/zip' ||
        mimeType == 'application/x-rar-compressed' ||
        mimeType == 'application/x-tar' ||
        mimeType == 'application/gzip' ||
        mimeType == 'application/x-7z-compressed') {
      return FileTypeCategory.archive;
    }
    
    return FileTypeCategory.other;
  }
  
  /// Get icon for file based on its MIME type
  static IconData getFileIcon(String mimeType) {
    final category = getFileCategory(mimeType);
    
    switch (category) {
      case FileTypeCategory.image:
        return Icons.photo;
      case FileTypeCategory.video:
        return Icons.video_file;
      case FileTypeCategory.audio:
        return Icons.audio_file;
      case FileTypeCategory.document:
        return Icons.description;
      case FileTypeCategory.text:
        return Icons.insert_drive_file;
      case FileTypeCategory.archive:
        return Icons.folder_zip;
      case FileTypeCategory.other:
        return Icons.insert_drive_file;
    }
  }
  
  /// Check if file type can be previewed
  static bool canPreview(String mimeType) {
    return mimeType.startsWith('image/') ||
        mimeType.startsWith('text/') ||
        mimeType == 'application/pdf' ||
        mimeType == 'application/json' ||
        mimeType == 'application/xml';
  }
}

/// Categories of file types
enum FileTypeCategory {
  /// Image files
  image,
  
  /// Video files
  video,
  
  /// Audio files
  audio,
  
  /// Document files
  document,
  
  /// Text files
  text,
  
  /// Archive files
  archive,
  
  /// Other files
  other,
}