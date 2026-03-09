part of 'auth_bloc.dart';

// ============================================================================
// AUTH STATES
// ============================================================================

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final User user;

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.lastServerUrl, this.lastUsername});

  final String? lastServerUrl;
  final String? lastUsername;

  @override
  List<Object?> get props => [lastServerUrl, lastUsername];
}

class AuthError extends AuthState {
  const AuthError({required this.message, required this.type});

  final String message;
  final AuthErrorType type;

  @override
  List<Object?> get props => [message, type];
}

enum AuthErrorType {
  invalidCredentials,
  serverUnreachable,
  networkError,
  unknown,
}
