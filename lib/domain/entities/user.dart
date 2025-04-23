/// User entity representing a user account
class User {
  /// Unique identifier
  final String id;
  
  /// Username for login
  final String username;
  
  /// Display name (may be same as username)
  final String displayName;
  
  /// Email address (may be null)
  final String? email;
  
  /// Whether the user has admin privileges
  final bool isAdmin;
  
  /// Total quota in bytes (0 if unlimited)
  final int quotaBytes;
  
  /// Currently used storage in bytes
  final int usedBytes;
  
  /// Creates a user entity
  const User({
    required this.id,
    required this.username,
    required this.displayName,
    this.email,
    this.isAdmin = false,
    this.quotaBytes = 0,
    this.usedBytes = 0,
  });
  
  /// Creates a copy of this user with the given fields replaced
  User copyWith({
    String? id,
    String? username,
    String? displayName,
    String? email,
    bool? isAdmin,
    int? quotaBytes,
    int? usedBytes,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      isAdmin: isAdmin ?? this.isAdmin,
      quotaBytes: quotaBytes ?? this.quotaBytes,
      usedBytes: usedBytes ?? this.usedBytes,
    );
  }
  
  /// Remaining quota in bytes (or -1 if unlimited)
  int get remainingBytes {
    if (quotaBytes == 0) {
      return -1; // Unlimited
    }
    return quotaBytes - usedBytes;
  }
  
  /// Storage usage percentage (0-100, or -1 if unlimited)
  double get usagePercentage {
    if (quotaBytes == 0) {
      return -1; // Unlimited
    }
    return (usedBytes / quotaBytes) * 100;
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username;
  
  @override
  int get hashCode => id.hashCode ^ username.hashCode;
  
  @override
  String toString() => 'User(id: $id, username: $username, displayName: $displayName)';
}