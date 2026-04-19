import 'package:equatable/equatable.dart';

class ShareEntity extends Equatable {
  final String id;
  final String itemId;
  final String? itemName;
  final String itemType;
  final String token;
  final String url;
  final bool hasPassword;
  final DateTime? expiresAt;
  final SharePermissions permissions;
  final DateTime createdAt;
  final String createdBy;
  final int accessCount;

  const ShareEntity({
    required this.id,
    required this.itemId,
    this.itemName,
    required this.itemType,
    required this.token,
    required this.url,
    this.hasPassword = false,
    this.expiresAt,
    required this.permissions,
    required this.createdAt,
    required this.createdBy,
    this.accessCount = 0,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  @override
  List<Object?> get props => [id, itemId, token];
}

class SharePermissions extends Equatable {
  final bool read;
  final bool write;
  final bool reshare;

  const SharePermissions({
    this.read = true,
    this.write = false,
    this.reshare = false,
  });

  @override
  List<Object?> get props => [read, write, reshare];
}
