import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Application configuration that can be loaded from storage
/// and provides access to configuration values
class AppConfig {
  static const String _configKey = 'app_config';
  
  // Default values
  String _apiUrl = 'https://api.example.com';
  String _webdavUrl = 'https://api.example.com/webdav';
  int _syncIntervalMinutes = 30;
  int _maxCacheSizeMB = 100;
  bool _syncOnWifiOnly = false;
  bool _uploadOnWifiOnly = false;
  bool _enableBackgroundSync = true;
  bool _enableCompression = true;
  
  // Getters
  String get apiUrl => _apiUrl;
  String get webdavUrl => _webdavUrl;
  int get syncIntervalMinutes => _syncIntervalMinutes;
  int get maxCacheSizeMB => _maxCacheSizeMB;
  bool get syncOnWifiOnly => _syncOnWifiOnly;
  bool get uploadOnWifiOnly => _uploadOnWifiOnly;
  bool get enableBackgroundSync => _enableBackgroundSync;
  bool get enableCompression => _enableCompression;
  
  // Setters
  set apiUrl(String value) {
    _apiUrl = value;
    _save();
  }
  
  set webdavUrl(String value) {
    _webdavUrl = value;
    _save();
  }
  
  set syncIntervalMinutes(int value) {
    _syncIntervalMinutes = value;
    _save();
  }
  
  set maxCacheSizeMB(int value) {
    _maxCacheSizeMB = value;
    _save();
  }
  
  set syncOnWifiOnly(bool value) {
    _syncOnWifiOnly = value;
    _save();
  }
  
  set uploadOnWifiOnly(bool value) {
    _uploadOnWifiOnly = value;
    _save();
  }
  
  set enableBackgroundSync(bool value) {
    _enableBackgroundSync = value;
    _save();
  }
  
  set enableCompression(bool value) {
    _enableCompression = value;
    _save();
  }
  
  /// Load configuration from storage
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_configKey);
      
      if (jsonStr != null) {
        final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        
        _apiUrl = jsonMap['apiUrl'] as String? ?? _apiUrl;
        _webdavUrl = jsonMap['webdavUrl'] as String? ?? _webdavUrl;
        _syncIntervalMinutes = jsonMap['syncIntervalMinutes'] as int? ?? _syncIntervalMinutes;
        _maxCacheSizeMB = jsonMap['maxCacheSizeMB'] as int? ?? _maxCacheSizeMB;
        _syncOnWifiOnly = jsonMap['syncOnWifiOnly'] as bool? ?? _syncOnWifiOnly;
        _uploadOnWifiOnly = jsonMap['uploadOnWifiOnly'] as bool? ?? _uploadOnWifiOnly;
        _enableBackgroundSync = jsonMap['enableBackgroundSync'] as bool? ?? _enableBackgroundSync;
        _enableCompression = jsonMap['enableCompression'] as bool? ?? _enableCompression;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load app config: $e');
      }
      // Use default values if loading fails
    }
  }
  
  /// Save configuration to storage
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final jsonMap = {
        'apiUrl': _apiUrl,
        'webdavUrl': _webdavUrl,
        'syncIntervalMinutes': _syncIntervalMinutes,
        'maxCacheSizeMB': _maxCacheSizeMB,
        'syncOnWifiOnly': _syncOnWifiOnly,
        'uploadOnWifiOnly': _uploadOnWifiOnly,
        'enableBackgroundSync': _enableBackgroundSync,
        'enableCompression': _enableCompression,
      };
      
      await prefs.setString(_configKey, jsonEncode(jsonMap));
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save app config: $e');
      }
    }
  }
  
  /// Reset configuration to default values
  Future<void> reset() async {
    _apiUrl = 'https://api.example.com';
    _webdavUrl = 'https://api.example.com/webdav';
    _syncIntervalMinutes = 30;
    _maxCacheSizeMB = 100;
    _syncOnWifiOnly = false;
    _uploadOnWifiOnly = false;
    _enableBackgroundSync = true;
    _enableCompression = true;
    
    await _save();
  }
  
  /// Update server URLs
  Future<void> updateServerUrls(String serverUrl) async {
    // Ensure the URL doesn't end with a slash
    final normalizedUrl = serverUrl.endsWith('/') 
        ? serverUrl.substring(0, serverUrl.length - 1) 
        : serverUrl;
    
    _apiUrl = normalizedUrl;
    _webdavUrl = '$normalizedUrl/webdav';
    
    await _save();
  }
}