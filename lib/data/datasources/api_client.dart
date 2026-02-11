import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton HTTP client for the OxiCloud REST API.
///
/// Wraps [Dio] with automatic JWT authentication, base-URL
/// configuration, and transparent 401 → re-login recovery.
class ApiClient {
  static const _serverUrlKey = 'server_url';
  static const _usernameKey = 'username';
  static const _passwordKey = 'password'; // stored for silent re-login
  static const _accessTokenKey = 'access_token';

  final Dio _dio;
  final Logger _logger = Logger();

  String? _baseUrl;
  String? _token;
  bool _configured = false;
  bool _isRefreshing = false;

  ApiClient() : _dio = Dio() {
    _dio.options
      ..connectTimeout = const Duration(seconds: 15)
      ..receiveTimeout = const Duration(seconds: 30)
      ..sendTimeout = const Duration(seconds: 60);

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        await _ensureConfigured();
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Transparent 401 recovery: re-login with stored credentials
        if (error.response?.statusCode == 401 && !_isRefreshing) {
          final refreshed = await _silentReLogin();
          if (refreshed) {
            // Retry the original request with the fresh token
            final opts = error.requestOptions;
            opts.headers['Authorization'] = 'Bearer $_token';
            try {
              final response = await _dio.fetch<dynamic>(opts);
              return handler.resolve(response);
            } on DioException catch (retryError) {
              return handler.next(retryError);
            }
          }
        }
        _logger.e('API error: ${error.requestOptions.uri} → '
            '${error.response?.statusCode}: ${error.message}');
        handler.next(error);
      },
    ));
  }

  // ── Public API ──────────────────────────────────────────────────────────

  /// The underlying [Dio] instance (pre-configured with base URL & auth).
  Dio get dio => _dio;

  /// Whether the client has a valid (non-null) access token.
  bool get isAuthenticated => _token != null;

  /// Call after a successful login to cache credentials in-memory
  /// so subsequent requests don't need to read SharedPreferences.
  void updateCredentials(String serverUrl, String token) {
    _baseUrl = _normaliseUrl(serverUrl);
    _token = token;
    _dio.options.baseUrl = _baseUrl!;
    _configured = true;
    _logger.i('ApiClient configured: $_baseUrl');
  }

  /// Force re-read from SharedPreferences on next request.
  void invalidate() {
    _configured = false;
    _baseUrl = null;
    _token = null;
  }

  // ── Internal ────────────────────────────────────────────────────────────

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = _normaliseUrl(prefs.getString(_serverUrlKey) ?? '');
    _token = prefs.getString(_accessTokenKey);
    if (_baseUrl != null && _baseUrl!.isNotEmpty) {
      _dio.options.baseUrl = _baseUrl!;
    }
    _configured = _token != null;
  }

  /// Try to obtain a fresh access token by calling the server login
  /// endpoint directly with stored credentials.
  Future<bool> _silentReLogin() async {
    _isRefreshing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final serverUrl = prefs.getString(_serverUrlKey);
      final username = prefs.getString(_usernameKey);
      final password = prefs.getString(_passwordKey);

      if (serverUrl == null || username == null || password == null) {
        _logger.w('Cannot re-login: missing stored credentials');
        return false;
      }

      final baseUrl = _normaliseUrl(serverUrl);
      final response = await Dio().post<Map<String, dynamic>>(
        '${baseUrl}auth/login',
        data: {'username': username, 'password': password},
      );

      final data = response.data;
      if (data == null) return false;

      final newToken = data['access_token'] as String?;
      if (newToken == null || newToken.isEmpty) return false;

      // Persist and apply the fresh token
      await prefs.setString(_accessTokenKey, newToken);
      _token = newToken;
      _dio.options.baseUrl = baseUrl;
      _configured = true;
      _logger.i('Silent re-login succeeded');
      return true;
    } catch (e) {
      _logger.e('Silent re-login failed: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  String _normaliseUrl(String url) {
    final trimmed = url.trimRight();
    return trimmed.endsWith('/') ? trimmed : '$trimmed/';
  }
}
