/// Authentication token data
class AuthToken {
  /// The access token for API authentication
  final String token;
  
  /// The refresh token for obtaining a new access token
  final String refreshToken;
  
  /// Creates an authentication token
  const AuthToken({
    required this.token,
    required this.refreshToken,
  });
  
  /// Creates a copy of this token with the given fields replaced
  AuthToken copyWith({
    String? token,
    String? refreshToken,
  }) {
    return AuthToken(
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthToken &&
          runtimeType == other.runtimeType &&
          token == other.token &&
          refreshToken == other.refreshToken;
  
  @override
  int get hashCode => token.hashCode ^ refreshToken.hashCode;
  
  @override
  String toString() => 'AuthToken(token: ${token.substring(0, 8)}..., refreshToken: ${refreshToken.substring(0, 8)}...)';
}