import 'dart:async';
import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';
import 'package:oxicloud_desktop/domain/entities/auth_token.dart';
import 'package:oxicloud_desktop/domain/entities/user.dart';
import 'package:oxicloud_desktop/domain/repositories/auth_repository.dart';

/// Application service for authentication operations
class AuthService {
  final AuthRepository _authRepository;
  final Logger _logger = LoggingManager.getLogger('AuthService');
  
  final StreamController<AuthState> _authStateController = 
      StreamController<AuthState>.broadcast();
  
  User? _currentUser;
  
  /// Stream of authentication state changes
  Stream<AuthState> get authStateStream => _authStateController.stream;
  
  /// The current authentication state
  AuthState get currentState => 
      _currentUser != null ? AuthState.authenticated : AuthState.unauthenticated;
  
  /// The current user (or null if not authenticated)
  User? get currentUser => _currentUser;
  
  /// Create an AuthService
  AuthService(this._authRepository) {
    _initialize();
  }
  
  /// Initialize the service
  Future<void> _initialize() async {
    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      
      if (isLoggedIn) {
        // Try to get current user
        try {
          _currentUser = await _authRepository.getCurrentUser();
          _authStateController.add(AuthState.authenticated);
          _logger.info('User authenticated: ${_currentUser?.username}');
        } catch (e) {
          // Failed to get user, consider not authenticated
          _currentUser = null;
          _authStateController.add(AuthState.unauthenticated);
          _logger.warning('Failed to get user info, considered unauthenticated: $e');
        }
      } else {
        _currentUser = null;
        _authStateController.add(AuthState.unauthenticated);
        _logger.info('No authentication found');
      }
    } catch (e) {
      _logger.severe('Failed to initialize auth service: $e');
      _currentUser = null;
      _authStateController.add(AuthState.error);
    }
  }
  
  /// Login with username and password
  Future<User> login(String username, String password) async {
    try {
      // Perform login
      await _authRepository.login(username, password);
      
      // Get user info
      _currentUser = await _authRepository.getCurrentUser();
      
      // Update auth state
      _authStateController.add(AuthState.authenticated);
      
      _logger.info('User logged in: $username');
      
      return _currentUser!;
    } catch (e) {
      _logger.warning('Login failed: $e');
      _authStateController.add(AuthState.error);
      rethrow;
    }
  }
  
  /// Logout the current user
  Future<void> logout() async {
    try {
      await _authRepository.logout();
      _currentUser = null;
      _authStateController.add(AuthState.unauthenticated);
      _logger.info('User logged out');
    } catch (e) {
      _logger.warning('Logout failed: $e');
      rethrow;
    }
  }
  
  /// Refresh the user information
  Future<User> refreshUserInfo() async {
    try {
      _currentUser = await _authRepository.getCurrentUser();
      return _currentUser!;
    } catch (e) {
      _logger.warning('Failed to refresh user info: $e');
      rethrow;
    }
  }
  
  /// Set the server URL
  Future<void> setServerUrl(String url) async {
    try {
      await _authRepository.setServerUrl(url);
      _logger.info('Server URL set: $url');
    } catch (e) {
      _logger.warning('Failed to set server URL: $e');
      rethrow;
    }
  }
  
  /// Get the server URL
  Future<String?> getServerUrl() async {
    try {
      return await _authRepository.getServerUrl();
    } catch (e) {
      _logger.warning('Failed to get server URL: $e');
      rethrow;
    }
  }
  
  /// Check if a server URL is set
  Future<bool> hasServerUrl() async {
    final url = await getServerUrl();
    return url != null && url.isNotEmpty;
  }
  
  /// Check if the user is logged in
  Future<bool> isLoggedIn() async {
    return _authRepository.isLoggedIn();
  }
  
  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}

/// Authentication state
enum AuthState {
  /// User is authenticated
  authenticated,
  
  /// User is not authenticated
  unauthenticated,
  
  /// Authentication error occurred
  error,
}