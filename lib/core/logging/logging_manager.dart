import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// A centralized logging system that forwards logs to appropriate outputs
/// based on environment and platform.
class LoggingManager {
  static final Logger _rootLogger = Logger.root;
  static File? _logFile;
  static IOSink? _logSink;
  static bool _initialized = false;
  
  /// Maximum size of log file in bytes (5MB)
  static const int _maxLogSize = 5 * 1024 * 1024;
  
  /// Initialize the logging system
  static Future<void> initialize() async {
    if (_initialized) return;
    
    // Set the log level
    _rootLogger.level = kDebugMode ? Level.ALL : Level.INFO;
    
    // Setup the file logger for non-web platforms
    if (!kIsWeb) {
      await _setupFileLogging();
    }
    
    // Setup log listeners
    Logger.root.onRecord.listen((record) {
      // Log to console in debug mode
      if (kDebugMode) {
        print('${record.level.name}: ${record.time}: ${record.message}');
        if (record.error != null) {
          print('Error: ${record.error}');
        }
        if (record.stackTrace != null) {
          print('Stack trace: ${record.stackTrace}');
        }
      }
      
      // Log to file
      _logToFile(record);
    });
    
    _initialized = true;
    
    // Log initialization
    final logger = Logger('LoggingManager');
    logger.info('Logging system initialized');
  }
  
  /// Setup file logging
  static Future<void> _setupFileLogging() async {
    try {
      // Get the documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final logDir = Directory(path.join(appDocDir.path, 'logs'));
      
      // Create logs directory if it doesn't exist
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      
      // Create or rotate log file
      final logFilePath = path.join(logDir.path, 'oxicloud.log');
      final logFile = File(logFilePath);
      
      // Check if log file exists and needs rotation
      if (await logFile.exists()) {
        final fileSize = await logFile.length();
        if (fileSize > _maxLogSize) {
          // Rotate log file
          final backupPath = path.join(logDir.path, 'oxicloud.log.bak');
          final backupFile = File(backupPath);
          if (await backupFile.exists()) {
            await backupFile.delete();
          }
          await logFile.rename(backupPath);
        }
      }
      
      // Create new log file if it doesn't exist
      _logFile = logFile;
      _logSink = _logFile!.openWrite(mode: FileMode.append);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to setup file logging: $e');
      }
    }
  }
  
  /// Log a record to file
  static void _logToFile(LogRecord record) {
    if (_logSink != null) {
      try {
        _logSink!.writeln(
          '${record.time} [${record.level.name}] ${record.loggerName}: ${record.message}'
        );
        if (record.error != null) {
          _logSink!.writeln('Error: ${record.error}');
        }
        if (record.stackTrace != null) {
          _logSink!.writeln('Stack trace: ${record.stackTrace}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to write to log file: $e');
        }
      }
    }
  }
  
  /// Clean up resources
  static Future<void> dispose() async {
    await _logSink?.flush();
    await _logSink?.close();
    _logSink = null;
    _logFile = null;
  }
  
  /// Get a logger with the specified name
  static Logger getLogger(String name) {
    return Logger(name);
  }
}