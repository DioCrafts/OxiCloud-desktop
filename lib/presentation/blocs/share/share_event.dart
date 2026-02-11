part of 'share_bloc.dart';

abstract class ShareEvent extends Equatable {
  const ShareEvent();

  @override
  List<Object?> get props => [];
}

class LoadShares extends ShareEvent {
  const LoadShares();
}

class LoadMoreShares extends ShareEvent {
  const LoadMoreShares();
}

class CreateShareRequested extends ShareEvent {
  final String itemId;
  final String itemType;
  final String? password;
  final DateTime? expiresAt;
  final SharePermissions? permissions;

  const CreateShareRequested({
    required this.itemId,
    required this.itemType,
    this.password,
    this.expiresAt,
    this.permissions,
  });

  @override
  List<Object?> get props =>
      [itemId, itemType, password, expiresAt, permissions];
}

class UpdateShareRequested extends ShareEvent {
  final String shareId;
  final String? password;
  final DateTime? expiresAt;
  final SharePermissions? permissions;

  const UpdateShareRequested({
    required this.shareId,
    this.password,
    this.expiresAt,
    this.permissions,
  });

  @override
  List<Object?> get props => [shareId, password, expiresAt, permissions];
}

class DeleteShareRequested extends ShareEvent {
  final String shareId;
  const DeleteShareRequested(this.shareId);

  @override
  List<Object?> get props => [shareId];
}
