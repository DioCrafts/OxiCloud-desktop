import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/entities/user.dart';
import '../../../core/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

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
