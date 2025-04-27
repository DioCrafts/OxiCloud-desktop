import 'package:flutter/material.dart';

enum FileType {
  folder,
  image,
  video,
  audio,
  document,
  pdf,
  code,
  archive,
  other
}

enum SyncStatus {
  synced,      // Sincronizado y disponible localmente
  onlineOnly,  // Solo disponible en el servidor
  syncing,     // En proceso de sincronización
  error        // Error en la sincronización
}

class FileModel {
  final String id;
  final String name;
  final String path;
  final FileType type;
  final int size;
  final DateTime modifiedDate;
  final String? thumbnailUrl;
  final bool isFavorite;
  final bool isShared;
  final String? sharedBy;
  final String? owner;
  final List<String> tags;
  final SyncStatus syncStatus;
  final String? localPath;  // Ruta local del archivo si está sincronizado
  final int? downloadedSize; // Tamaño descargado si está en proceso de sincronización

  FileModel({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    required this.modifiedDate,
    this.thumbnailUrl,
    this.isFavorite = false,
    this.isShared = false,
    this.sharedBy,
    this.owner,
    this.tags = const [],
    this.syncStatus = SyncStatus.onlineOnly,
    this.localPath,
    this.downloadedSize,
  });

  String get fileExtension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get formattedDate {
    return '${modifiedDate.day}/${modifiedDate.month}/${modifiedDate.year}';
  }

  IconData get icon {
    switch (type) {
      case FileType.folder:
        return Icons.folder;
      case FileType.image:
        return Icons.image;
      case FileType.video:
        return Icons.video_file;
      case FileType.audio:
        return Icons.audio_file;
      case FileType.document:
        return Icons.description;
      case FileType.pdf:
        return Icons.picture_as_pdf;
      case FileType.code:
        return Icons.code;
      case FileType.archive:
        return Icons.archive;
      case FileType.other:
        return Icons.insert_drive_file;
    }
  }

  Color get color {
    switch (type) {
      case FileType.folder:
        return Colors.amber;
      case FileType.image:
        return Colors.green;
      case FileType.video:
        return Colors.purple;
      case FileType.audio:
        return Colors.blue;
      case FileType.document:
        return Colors.blueGrey;
      case FileType.pdf:
        return Colors.red;
      case FileType.code:
        return Colors.orange;
      case FileType.archive:
        return Colors.brown;
      case FileType.other:
        return Colors.grey;
    }
  }

  String get syncStatusText {
    switch (syncStatus) {
      case SyncStatus.synced:
        return 'Disponible sin conexión';
      case SyncStatus.onlineOnly:
        return 'Solo en línea';
      case SyncStatus.syncing:
        return 'Sincronizando...';
      case SyncStatus.error:
        return 'Error de sincronización';
    }
  }

  IconData get syncStatusIcon {
    switch (syncStatus) {
      case SyncStatus.synced:
        return Icons.check_circle;
      case SyncStatus.onlineOnly:
        return Icons.cloud;
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.error:
        return Icons.error;
    }
  }

  Color get syncStatusColor {
    switch (syncStatus) {
      case SyncStatus.synced:
        return Colors.green;
      case SyncStatus.onlineOnly:
        return Colors.blue;
      case SyncStatus.syncing:
        return Colors.orange;
      case SyncStatus.error:
        return Colors.red;
    }
  }

  double get downloadProgress {
    if (downloadedSize == null || size == 0) return 0.0;
    return downloadedSize! / size;
  }

  FileModel copyWith({
    String? id,
    String? name,
    String? path,
    FileType? type,
    int? size,
    DateTime? modifiedDate,
    String? thumbnailUrl,
    bool? isFavorite,
    bool? isShared,
    String? sharedBy,
    String? owner,
    List<String>? tags,
    SyncStatus? syncStatus,
    String? localPath,
    int? downloadedSize,
  }) {
    return FileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      type: type ?? this.type,
      size: size ?? this.size,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      isShared: isShared ?? this.isShared,
      sharedBy: sharedBy ?? this.sharedBy,
      owner: owner ?? this.owner,
      tags: tags ?? this.tags,
      syncStatus: syncStatus ?? this.syncStatus,
      localPath: localPath ?? this.localPath,
      downloadedSize: downloadedSize ?? this.downloadedSize,
    );
  }
} 