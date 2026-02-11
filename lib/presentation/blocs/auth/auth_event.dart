part of 'auth_bloc.dart';

// ============================================================================
// AUTH EVENTS
// ============================================================================

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}

class LoginSubmitted extends AuthEvent {
  final String serverUrl;
  final String username;
  final String password;

  const LoginSubmitted({
    required this.serverUrl,
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [serverUrl, username, password];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
