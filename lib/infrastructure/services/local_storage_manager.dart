import 'dart:io';
import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';
import 'package:oxicloud_desktop/infrastructure/services/resource_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Manages local file storage with optimization for size and performance
class LocalStorageManager {
  /// Box name for metadata
  static const String _metadataBoxName = 'file_metadata';
  
  /// Box name for sync state
  static const String _syncStateBoxName = 'sync_state';
  
  /// Directory for cached files
  late final Directory _cacheDir;
  
  /// Directory for offline files
  late final Directory _offlineDir;
  
  /// Hive box for file metadata
  late final Box<dynamic> _metadataBox;
  
  /// Hive box for sync state
  late final Box<dynamic> _syncStateBox;
  
  /// Resource manager for optimizing storage usage
  final ResourceManager _resourceManager;
  
  /// Logger instance
  final Logger _logger = LoggingManager.getLogger('LocalStorageManager');
  
  /// Last cleanup time
  DateTime? _lastCleanupTime;
  
  /// Create a LocalStorageManager
  LocalStorageManager(this._resourceManager);
  
  /// Initialize the local storage manager
  Future<void> initialize() async {
    try {
      // Get application support directory
      final appDir = await getApplicationSupportDirectory();
      
      // Create cache and offline directories
      _cacheDir = Directory(p.join(appDir.path, 'cache'));
      _offlineDir = Directory(p.join(appDir.path, 'offline'));
      
      // Ensure directories exist
      if (!await _cacheDir.exists()) {
        await _cacheDir.create(recursive: true);
      }
      if (!await _offlineDir.exists()) {
        await _offlineDir.create(recursive: true);
      }
      
      // Initialize Hive boxes
      await Hive.initFlutter(appDir.path);
      _metadataBox = await Hive.openBox(_metadataBoxName);
      _syncStateBox = await Hive.openBox(_syncStateBoxName);
      
      // Run initial cleanup
      await cleanupCache();
      
      _logger.info('Local storage manager initialized');
    } catch (e) {
      _logger.severe('Failed to initialize local storage manager: $e');
      rethrow;
    }
  }
  
  /// Get a cached file
  Future<File?> getCachedFile(String fileId) async {
    try {
      final metadata = _getFileMetadata(fileId);
      if (metadata == null) {
        return null;
      }
      
      final file = File(metadata['localPath'] as String);
      if (await file.exists()) {
        // Update last accessed time
        _updateFileMetadata(fileId, {
          'lastAccessed': DateTime.now().millisecondsSinceEpoch,
          'accessCount': (metadata['accessCount'] as int) + 1,
        });
        
        return file;
      }
      
      // File doesn't exist, remove metadata
      _removeFileMetadata(fileId);
      return null;
    } catch (e) {
      _logger.warning('Failed to get cached file: $fileId - $e');
      return null;
    }
  }
  
  /// Cache a file
  Future<File> cacheFile(String fileId, Uint8List data, {
    required String name,
    bool keepOffline = false,
  }) async {
    try {
      // Generate a hash of the file ID to use as filename
      final fileHash = _generateFileHash(fileId);
      
      // Determine directory (cache or offline)
      final dir = keepOffline ? _offlineDir : _cacheDir;
      
      // Ensure space is available
      if (!keepOffline) {
        await _ensureCacheSpace(data.length);
      }
      
      // Create file
      final filePath = p.join(dir.path, fileHash);
      final file = File(filePath);
      await file.writeAsBytes(data, flush: true);
      
      // Store metadata
      _storeFileMetadata(fileId, {
        'localPath': filePath,
        'size': data.length,
        'name': name,
        'lastAccessed': DateTime.now().millisecondsSinceEpoch,
        'lastModified': DateTime.now().millisecondsSinceEpoch,
        'accessCount': 1,
        'keepOffline': keepOffline,
      });
      
      return file;
    } catch (e) {
      _logger.warning('Failed to cache file: $fileId - $e');
      rethrow;
    }
  }
  
  /// Ensure a file is available offline
  Future<void> ensureOffline(String fileId, Uint8List data, {
    required String name,
  }) async {
    try {
      // Check if file is already offline
      final metadata = _getFileMetadata(fileId);
      if (metadata != null && metadata['keepOffline'] == true) {
        // File is already offline, update if needed
        final file = File(metadata['localPath'] as String);
        if (await file.exists()) {
          // Update last accessed time
          _updateFileMetadata(fileId, {
            'lastAccessed': DateTime.now().millisecondsSinceEpoch,
            'accessCount': (metadata['accessCount'] as int) + 1,
          });
          return;
        }
      }
      
      // Move from cache to offline or create new offline file
      await cacheFile(fileId, data, name: name, keepOffline: true);
    } catch (e) {
      _logger.warning('Failed to ensure file is offline: $fileId - $e');
      rethrow;
    }
  }
  
  /// Remove a file from the cache
  Future<void> removeFromCache(String fileId) async {
    try {
      final metadata = _getFileMetadata(fileId);
      if (metadata == null) {
        return;
      }
      
      final file = File(metadata['localPath'] as String);
      if (await file.exists()) {
        await file.delete();
      }
      
      _removeFileMetadata(fileId);
    } catch (e) {
      _logger.warning('Failed to remove file from cache: $fileId - $e');
    }
  }
  
  /// Get metadata for a file
  Map<String, dynamic>? _getFileMetadata(String fileId) {
    try {
      return _metadataBox.get(fileId) as Map<String, dynamic>?;
    } catch (e) {
      _logger.warning('Failed to get file metadata: $fileId - $e');
      return null;
    }
  }
  
  /// Store metadata for a file
  Future<void> _storeFileMetadata(String fileId, Map<String, dynamic> metadata) async {
    try {
      await _metadataBox.put(fileId, metadata);
    } catch (e) {
      _logger.warning('Failed to store file metadata: $fileId - $e');
    }
  }
  
  /// Update metadata for a file
  Future<void> _updateFileMetadata(String fileId, Map<String, dynamic> updates) async {
    try {
      final metadata = _getFileMetadata(fileId);
      if (metadata == null) {
        return;
      }
      
      metadata.addAll(updates);
      await _storeFileMetadata(fileId, metadata);
    } catch (e) {
      _logger.warning('Failed to update file metadata: $fileId - $e');
    }
  }
  
  /// Remove metadata for a file
  Future<void> _removeFileMetadata(String fileId) async {
    try {
      await _metadataBox.delete(fileId);
    } catch (e) {
      _logger.warning('Failed to remove file metadata: $fileId - $e');
    }
  }
  
  /// Generate a hash for a file ID
  String _generateFileHash(String fileId) {
    final bytes = utf8.encode(fileId);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Ensure there is enough space in the cache
  Future<void> _ensureCacheSpace(int requiredBytes) async {
    try {
      final maxCacheBytes = _resourceManager.getRecommendedCacheSize();
      
      // Get current cache size
      final cacheSize = await _calculateCacheSize();
      
      // Check if we need to free up space
      if (cacheSize + requiredBytes <= maxCacheBytes) {
        return;
      }
      
      // Calculate how much space to free
      // Target 20% free space after adding the new file
      final targetFreeSpace = (maxCacheBytes * 0.2).toInt() + requiredBytes;
      final spaceToFree = cacheSize + requiredBytes - maxCacheBytes + targetFreeSpace;
      
      _logger.info('Cache cleanup: need to free $spaceToFree bytes');
      
      // Get all cached files (not offline)
      final cachedFiles = <Map<String, dynamic>>[];
      for (final key in _metadataBox.keys) {
        final metadata = _getFileMetadata(key as String);
        if (metadata != null && metadata['keepOffline'] != true) {
          cachedFiles.add({
            'id': key,
            'metadata': metadata,
            'score': _calculateEvictionScore(metadata),
          });
        }
      }
      
      // Sort by eviction score (higher = more likely to be evicted)
      cachedFiles.sort((a, b) {
        return (b['score'] as double).compareTo(a['score'] as double);
      });
      
      // Remove files until we have freed enough space
      int freedBytes = 0;
      for (final item in cachedFiles) {
        if (freedBytes >= spaceToFree) {
          break;
        }
        
        final fileId = item['id'] as String;
        final metadata = item['metadata'] as Map<String, dynamic>;
        final localPath = metadata['localPath'] as String;
        final size = metadata['size'] as int;
        
        // Delete the file
        final file = File(localPath);
        if (await file.exists()) {
          await file.delete();
          _removeFileMetadata(fileId);
          freedBytes += size;
          
          _logger.fine('Removed $fileId from cache, freed $size bytes');
        }
      }
      
      _logger.info('Cache cleanup completed, freed $freedBytes bytes');
    } catch (e) {
      _logger.warning('Failed to ensure cache space: $e');
    }
  }
  
  /// Calculate the current cache size
  Future<int> _calculateCacheSize() async {
    try {
      int totalSize = 0;
      
      for (final key in _metadataBox.keys) {
        final metadata = _getFileMetadata(key as String);
        if (metadata != null && metadata['keepOffline'] != true) {
          totalSize += metadata['size'] as int;
        }
      }
      
      return totalSize;
    } catch (e) {
      _logger.warning('Failed to calculate cache size: $e');
      return 0;
    }
  }
  
  /// Calculate an eviction score for a file
  /// Higher score = more likely to be evicted
  double _calculateEvictionScore(Map<String, dynamic> metadata) {
    final lastAccessedMs = metadata['lastAccessed'] as int;
    final lastAccessed = DateTime.fromMillisecondsSinceEpoch(lastAccessedMs);
    final accessCount = metadata['accessCount'] as int;
    
    // Calculate age in hours
    final ageHours = DateTime.now().difference(lastAccessed).inHours;
    
    // Calculate score (higher = more likely to be evicted)
    // Age has higher weight than access count
    return (ageHours + 1) / (accessCount + 1);
  }
  
  /// Clean up the cache
  Future<void> cleanupCache() async {
    try {
      // Only run cleanup once per hour
      final now = DateTime.now();
      if (_lastCleanupTime != null && 
          now.difference(_lastCleanupTime!).inHours < 1) {
        return;
      }
      
      _lastCleanupTime = now;
      
      // Get recommended cache size
      final maxCacheBytes = _resourceManager.getRecommendedCacheSize();
      
      // Calculate current cache size
      final cacheSize = await _calculateCacheSize();
      
      // Check if we need to clean up
      if (cacheSize <= maxCacheBytes * 0.8) {
        // Cache is less than 80% full, no need to clean up
        return;
      }
      
      // Calculate how much space to free
      // Target 20% free space
      final targetFreeBytes = (maxCacheBytes * 0.2).toInt();
      final spaceToFree = cacheSize - maxCacheBytes + targetFreeBytes;
      
      // Ensure cache space by freeing up required bytes
      await _ensureCacheSpace(spaceToFree);
    } catch (e) {
      _logger.warning('Failed to clean up cache: $e');
    }
  }
  
  /// Get all offline files
  Future<List<String>> getOfflineFileIds() async {
    try {
      final offlineFiles = <String>[];
      
      for (final key in _metadataBox.keys) {
        final metadata = _getFileMetadata(key as String);
        if (metadata != null && metadata['keepOffline'] == true) {
          offlineFiles.add(key as String);
        }
      }
      
      return offlineFiles;
    } catch (e) {
      _logger.warning('Failed to get offline files: $e');
      return [];
    }
  }
  
  /// Store sync state
  Future<void> storeSyncState(String key, dynamic value) async {
    try {
      await _syncStateBox.put(key, value);
    } catch (e) {
      _logger.warning('Failed to store sync state: $key - $e');
    }
  }
  
  /// Get sync state
  dynamic getSyncState(String key) {
    try {
      return _syncStateBox.get(key);
    } catch (e) {
      _logger.warning('Failed to get sync state: $key - $e');
      return null;
    }
  }
  
  /// Clear the cache (excluding offline files)
  Future<void> clearCache() async {
    try {
      // Get all cached files (not offline)
      final cachedFiles = <String>[];
      for (final key in _metadataBox.keys) {
        final metadata = _getFileMetadata(key as String);
        if (metadata != null && metadata['keepOffline'] != true) {
          cachedFiles.add(key as String);
        }
      }
      
      // Remove all cached files
      for (final fileId in cachedFiles) {
        await removeFromCache(fileId);
      }
      
      _logger.info('Cache cleared');
    } catch (e) {
      _logger.warning('Failed to clear cache: $e');
    }
  }
  
  /// Clear offline files
  Future<void> clearOfflineFiles() async {
    try {
      // Get all offline files
      final offlineFiles = <String>[];
      for (final key in _metadataBox.keys) {
        final metadata = _getFileMetadata(key as String);
        if (metadata != null && metadata['keepOffline'] == true) {
          offlineFiles.add(key as String);
        }
      }
      
      // Remove all offline files
      for (final fileId in offlineFiles) {
        await removeFromCache(fileId);
      }
      
      _logger.info('Offline files cleared');
    } catch (e) {
      _logger.warning('Failed to clear offline files: $e');
    }
  }
  
  /// Clear everything
  Future<void> clearAll() async {
    try {
      // Clear cache
      await clearCache();
      
      // Clear offline files
      await clearOfflineFiles();
      
      // Clear sync state
      await _syncStateBox.clear();
      
      _logger.info('All local storage cleared');
    } catch (e) {
      _logger.warning('Failed to clear all local storage: $e');
    }
  }
  
  /// Get the total size of cached files
  Future<int> getCacheSize() async {
    return _calculateCacheSize();
  }
  
  /// Get the total size of offline files
  Future<int> getOfflineSize() async {
    try {
      int totalSize = 0;
      
      for (final key in _metadataBox.keys) {
        final metadata = _getFileMetadata(key as String);
        if (metadata != null && metadata['keepOffline'] == true) {
          totalSize += metadata['size'] as int;
        }
      }
      
      return totalSize;
    } catch (e) {
      _logger.warning('Failed to calculate offline size: $e');
      return 0;
    }
  }
  
  /// Close the storage manager
  Future<void> close() async {
    try {
      await _metadataBox.close();
      await _syncStateBox.close();
    } catch (e) {
      _logger.warning('Failed to close local storage manager: $e');
    }
  }
}