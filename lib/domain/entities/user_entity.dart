import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String username;
  final String? email;
  final String role;
  final int? storageQuotaBytes;
  final int? storageUsedBytes;

  const UserEntity({
    required this.id,
    required this.username,
    this.email,
    this.role = 'user',
    this.storageQuotaBytes,
    this.storageUsedBytes,
  });

  bool get isAdmin => role == 'admin';

  double? get storageUsagePercent {
    if (storageQuotaBytes == null ||
        storageUsedBytes == null ||
        storageQuotaBytes == 0) {
      return null;
    }
    return storageUsedBytes! / storageQuotaBytes!;
  }

  @override
  List<Object?> get props => [id, username, email, role];
}
