import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

/// Represents a file in the system
class File {
  /// Unique file identifier
  final String id;
  
  /// File name (without path)
  final String name;
  
  /// Full path in the storage
  final String path;
  
  /// Size in bytes
  final int size;
  
  /// Last modification timestamp
  final DateTime modifiedAt;
  
  /// MIME type of the file
  final String mimeType;
  
  /// Whether the file is shared
  final bool isShared;
  
  /// Whether the file is marked as favorite
  final bool isFavorite;
  
  /// ETag for synchronization
  final String? etag;
  
  /// Whether the file has been locally modified
  final bool isLocallyModified;
  
  /// Path to the local cached copy (if any)
  final String? localPath;
  
  /// Whether the file is available offline
  final bool isAvailableOffline;
  
  /// Creates a file entity
  const File({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.modifiedAt,
    required this.mimeType,
    this.isShared = false,
    this.isFavorite = false,
    this.etag,
    this.isLocallyModified = false,
    this.localPath,
    this.isAvailableOffline = false,
  });
  
  /// Creates a copy of this file with the given fields replaced
  File copyWith({
    String? id,
    String? name,
    String? path,
    int? size,
    DateTime? modifiedAt,
    String? mimeType,
    bool? isShared,
    bool? isFavorite,
    String? etag,
    bool? isLocallyModified,
    String? localPath,
    bool? isAvailableOffline,
  }) {
    return File(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      size: size ?? this.size,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      mimeType: mimeType ?? this.mimeType,
      isShared: isShared ?? this.isShared,
      isFavorite: isFavorite ?? this.isFavorite,
      etag: etag ?? this.etag,
      isLocallyModified: isLocallyModified ?? this.isLocallyModified,
      localPath: localPath ?? this.localPath,
      isAvailableOffline: isAvailableOffline ?? this.isAvailableOffline,
    );
  }
  
  /// Get file extension
  String get extension => p.extension(name).toLowerCase();
  
  /// Get parent folder path
  String get parentPath => p.dirname(path);
  
  /// Format file size for display
  String get formattedSize {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    num size = this.size;
    
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return i == 0
        ? '$size ${suffixes[i]}'
        : '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }
  
  /// Format last modified date
  String get formattedModifiedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final fileDate = DateTime(
      modifiedAt.year,
      modifiedAt.month,
      modifiedAt.day,
    );
    
    if (fileDate == today) {
      return 'Today ${DateFormat.Hm().format(modifiedAt)}';
    } else if (fileDate == yesterday) {
      return 'Yesterday ${DateFormat.Hm().format(modifiedAt)}';
    } else if (now.difference(modifiedAt).inDays < 7) {
      return DateFormat.E().format(modifiedAt) + ' ' + DateFormat.Hm().format(modifiedAt);
    } else {
      return DateFormat.yMMMd().format(modifiedAt);
    }
  }
  
  /// Check if file is an image
  bool get isImage => mimeType.startsWith('image/');
  
  /// Check if file is a video
  bool get isVideo => mimeType.startsWith('video/');
  
  /// Check if file is an audio
  bool get isAudio => mimeType.startsWith('audio/');
  
  /// Check if file is a document
  bool get isDocument => 
      mimeType.startsWith('application/pdf') ||
      mimeType.startsWith('application/msword') ||
      mimeType.startsWith('application/vnd.openxmlformats-officedocument') ||
      mimeType.startsWith('application/vnd.oasis.opendocument');
  
  /// Check if file is a text file
  bool get isText => 
      mimeType.startsWith('text/') ||
      mimeType == 'application/json' ||
      mimeType == 'application/xml';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is File &&
          runtimeType == other.runtimeType &&
          id == other.id;
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() => 'File(id: $id, name: $name, path: $path, size: $size)';
}