import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/entities/user.dart';
import '../../../core/repositories/auth_repository.dart';

// ============================================================================
// EVENTS
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

// ============================================================================
// STATES
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

// ============================================================================
// BLOC
// ============================================================================

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(const AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final isLoggedInResult = await _authRepository.isLoggedIn();

    await isLoggedInResult.fold(
      (failure) async {
        final serverUrl = await _authRepository.getStoredServerUrl();
        final username = await _authRepository.getStoredUsername();
        emit(AuthUnauthenticated(
          lastServerUrl: serverUrl,
          lastUsername: username,
        ));
      },
      (isLoggedIn) async {
        if (isLoggedIn) {
          final userResult = await _authRepository.getCurrentUser();
          userResult.fold(
            (failure) async {
              final serverUrl = await _authRepository.getStoredServerUrl();
              final username = await _authRepository.getStoredUsername();
              emit(AuthUnauthenticated(
                lastServerUrl: serverUrl,
                lastUsername: username,
              ));
            },
            (user) {
              if (user != null) {
                emit(AuthAuthenticated(user));
              } else {
                emit(const AuthUnauthenticated());
              }
            },
          );
        } else {
          final serverUrl = await _authRepository.getStoredServerUrl();
          final username = await _authRepository.getStoredUsername();
          emit(AuthUnauthenticated(
            lastServerUrl: serverUrl,
            lastUsername: username,
          ));
        }
      },
    );
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _authRepository.login(AuthCredentials(
      serverUrl: event.serverUrl,
      username: event.username,
      password: event.password,
    ));

    result.fold(
      (failure) {
        final (message, type) = _mapFailureToError(failure);
        emit(AuthError(message: message, type: type));
      },
      (user) {
        emit(AuthAuthenticated(user));
      },
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    await _authRepository.logout();

    final serverUrl = await _authRepository.getStoredServerUrl();
    final username = await _authRepository.getStoredUsername();
    
    emit(AuthUnauthenticated(
      lastServerUrl: serverUrl,
      lastUsername: username,
    ));
  }

  (String, AuthErrorType) _mapFailureToError(AuthFailure failure) {
    if (failure is InvalidCredentialsFailure) {
      return ('Invalid username or password', AuthErrorType.invalidCredentials);
    } else if (failure is ServerUnreachableFailure) {
      return ('Could not connect to server: ${failure.message}', AuthErrorType.serverUnreachable);
    } else if (failure is UnknownAuthFailure) {
      return ('An error occurred: ${failure.message}', AuthErrorType.unknown);
    }
    return ('Unknown error', AuthErrorType.unknown);
  }
}
