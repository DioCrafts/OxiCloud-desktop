import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxicloud_desktop/application/services/auth_service.dart';
import 'package:oxicloud_desktop/core/di/dependency_injection.dart';
import 'package:oxicloud_desktop/domain/entities/user.dart';

/// Provider for authentication state
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = getIt<AuthService>();
  return authService.authStateStream;
});

/// Provider for current user
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenData((state) {
    if (state == AuthState.authenticated) {
      return getIt<AuthService>().currentUser;
    }
    return null;
  }).value;
});

/// Provider for server URL
final serverUrlProvider = FutureProvider<String?>((ref) async {
  final authService = getIt<AuthService>();
  return authService.getServerUrl();
});

/// Notifier for authentication actions
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;
  
  /// Create an AuthNotifier
  AuthNotifier(this._authService) : super(const AsyncValue.data(null));
  
  /// Set the server URL
  Future<void> setServerUrl(String url) async {
    state = const AsyncValue.loading();
    
    try {
      await _authService.setServerUrl(url);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  /// Login with username and password
  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    
    try {
      await _authService.login(username, password);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  /// Logout the current user
  Future<void> logout() async {
    state = const AsyncValue.loading();
    
    try {
      await _authService.logout();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Provider for authentication actions
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(getIt<AuthService>());
});