import 'package:equatable/equatable.dart';

class FileItem extends Equatable {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final DateTime lastModified;
  final String? mimeType;
  final String? thumbnailUrl;

  const FileItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
    required this.lastModified,
    this.mimeType,
    this.thumbnailUrl,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      name: json['name'] as String,
      path: json['path'] as String,
      isDirectory: json['isDirectory'] as bool,
      size: json['size'] as int,
      lastModified: DateTime.parse(json['lastModified'] as String),
      mimeType: json['mimeType'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'isDirectory': isDirectory,
      'size': size,
      'lastModified': lastModified.toIso8601String(),
      'mimeType': mimeType,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  @override
  List<Object?> get props => [
        name,
        path,
        isDirectory,
        size,
        lastModified,
        mimeType,
        thumbnailUrl,
      ];
} 