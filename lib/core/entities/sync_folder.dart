import 'package:equatable/equatable.dart';

/// Sync folder entity for selective sync
class SyncFolder extends Equatable {
  final String id;
  final String name;
  final String path;
  final int sizeBytes;
  final int itemCount;
  final bool isSelected;

  const SyncFolder({
    required this.id,
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.itemCount,
    required this.isSelected,
  });

  /// Create a copy with different selection state
  SyncFolder copyWith({bool? isSelected}) {
    return SyncFolder(
      id: id,
      name: name,
      path: path,
      sizeBytes: sizeBytes,
      itemCount: itemCount,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  /// Format size for display
  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  List<Object?> get props => [id, name, path, sizeBytes, itemCount, isSelected];
}

/// Sync item entity
class SyncItem extends Equatable {
  final String id;
  final String path;
  final String name;
  final bool isDirectory;
  final int size;
  final SyncItemStatus status;
  final SyncDirection direction;
  final DateTime? localModified;
  final DateTime? remoteModified;

  const SyncItem({
    required this.id,
    required this.path,
    required this.name,
    required this.isDirectory,
    required this.size,
    required this.status,
    required this.direction,
    this.localModified,
    this.remoteModified,
  });

  @override
  List<Object?> get props => [
        id,
        path,
        name,
        isDirectory,
        size,
        status,
        direction,
        localModified,
        remoteModified,
      ];
}

/// Sync item status
enum SyncItemStatus {
  synced,
  pending,
  syncing,
  conflict,
  error,
  ignored,
}

/// Sync direction
enum SyncDirection {
  upload,
  download,
  none,
}
