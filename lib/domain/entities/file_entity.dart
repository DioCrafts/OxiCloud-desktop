import 'package:equatable/equatable.dart';

class FileEntity extends Equatable {
  final String id;
  final String name;
  final String path;
  final int size;
  final String mimeType;
  final String? folderId;
  final String? ownerId;
  final String? hash;
  final String? etag;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final bool isFavorite;
  final bool isAvailableOffline;
  final String? localCachePath;

  const FileEntity({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.mimeType,
    this.folderId,
    this.ownerId,
    this.hash,
    this.etag,
    required this.createdAt,
    required this.modifiedAt,
    this.isFavorite = false,
    this.isAvailableOffline = false,
    this.localCachePath,
  });

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get extension {
    final dot = name.lastIndexOf('.');
    return dot != -1 ? name.substring(dot + 1).toLowerCase() : '';
  }

  bool get isImage => mimeType.startsWith('image/');
  bool get isVideo => mimeType.startsWith('video/');
  bool get isAudio => mimeType.startsWith('audio/');
  bool get isPdf => mimeType == 'application/pdf';

  FileEntity copyWith({
    String? name,
    String? folderId,
    bool? isFavorite,
    bool? isAvailableOffline,
    String? localCachePath,
  }) {
    return FileEntity(
      id: id,
      name: name ?? this.name,
      path: path,
      size: size,
      mimeType: mimeType,
      folderId: folderId ?? this.folderId,
      ownerId: ownerId,
      hash: hash,
      etag: etag,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isAvailableOffline: isAvailableOffline ?? this.isAvailableOffline,
      localCachePath: localCachePath ?? this.localCachePath,
    );
  }

  @override
  List<Object?> get props => [id, name, path, size, mimeType, modifiedAt];
}
