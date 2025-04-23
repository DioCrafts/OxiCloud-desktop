import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// A fallback implementation for Linux secure storage
/// This will use file-based storage with basic encryption
class LinuxSecureStorage {
  final Logger _logger = LoggingManager.getLogger('LinuxSecureStorage');
  late final Directory _storageDir;
  static const String _salt = 'oxicloud_secure_storage';
  
  /// Initialize the storage
  Future<void> initialize() async {
    try {
      final appDir = await getApplicationSupportDirectory();
      _storageDir = Directory('${appDir.path}/secure_storage');
      if (!await _storageDir.exists()) {
        await _storageDir.create(recursive: true);
      }
      
      // Create a .nomedia file to prevent indexing
      final nomediaFile = File('${_storageDir.path}/.nomedia');
      if (!await nomediaFile.exists()) {
        await nomediaFile.create();
      }
      
      _logger.info('Linux secure storage initialized at: ${_storageDir.path}');
    } catch (e) {
      _logger.severe('Failed to initialize Linux secure storage: $e');
      rethrow;
    }
  }
  
  /// Get the file path for a key
  String _getFilePath(String key) {
    final hashedKey = sha256.convert(utf8.encode('$key$_salt')).toString();
    return '${_storageDir.path}/$hashedKey';
  }
  
  /// Read value for a key
  Future<String?> read({required String key}) async {
    try {
      final file = File(_getFilePath(key));
      if (!await file.exists()) {
        return null;
      }
      
      final encrypted = await file.readAsString();
      // Simple XOR "encryption" - not truly secure but better than plaintext
      final decrypted = _xorCrypt(encrypted, key);
      return decrypted;
    } catch (e) {
      _logger.warning('Failed to read value for key: $key - $e');
      return null;
    }
  }
  
  /// Write value for a key
  Future<void> write({required String key, required String? value}) async {
    try {
      if (value == null) {
        await delete(key: key);
        return;
      }
      
      final file = File(_getFilePath(key));
      // Simple XOR "encryption" - not truly secure but better than plaintext
      final encrypted = _xorCrypt(value, key);
      await file.writeAsString(encrypted);
    } catch (e) {
      _logger.severe('Failed to write value for key: $key - $e');
      rethrow;
    }
  }
  
  /// Delete value for a key
  Future<void> delete({required String key}) async {
    try {
      final file = File(_getFilePath(key));
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      _logger.warning('Failed to delete value for key: $key - $e');
      rethrow;
    }
  }
  
  /// Delete all values
  Future<void> deleteAll() async {
    try {
      final files = await _storageDir.list().toList();
      for (final file in files) {
        if (file is File && !file.path.endsWith('.nomedia')) {
          await file.delete();
        }
      }
    } catch (e) {
      _logger.severe('Failed to delete all values: $e');
      rethrow;
    }
  }
  
  /// Simple XOR encryption/decryption
  String _xorCrypt(String input, String key) {
    final inputBytes = utf8.encode(input);
    final keyBytes = utf8.encode(key);
    final result = List<int>.filled(inputBytes.length, 0);
    
    for (var i = 0; i < inputBytes.length; i++) {
      result[i] = inputBytes[i] ^ keyBytes[i % keyBytes.length];
    }
    
    return base64.encode(result);
  }
}