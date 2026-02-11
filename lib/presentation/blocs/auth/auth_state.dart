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
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  final String? lastServerUrl;
  final String? lastUsername;

  const AuthUnauthenticated({this.lastServerUrl, this.lastUsername});

  @override
  List<Object?> get props => [lastServerUrl, lastUsername];
}

class AuthError extends AuthState {
  final String message;
  final AuthErrorType type;

  const AuthError({required this.message, required this.type});

  @override
  List<Object?> get props => [message, type];
}

enum AuthErrorType {
  invalidCredentials,
  serverUnreachable,
  networkError,
  unknown,
}
