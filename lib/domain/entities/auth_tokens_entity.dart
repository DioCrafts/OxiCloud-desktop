import 'package:equatable/equatable.dart';

class AuthTokens extends Equatable {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final DateTime issuedAt;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.issuedAt,
  });

  DateTime get expiresAt => issuedAt.add(Duration(seconds: expiresIn));

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isAboutToExpire =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 5)));

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresIn];
}
