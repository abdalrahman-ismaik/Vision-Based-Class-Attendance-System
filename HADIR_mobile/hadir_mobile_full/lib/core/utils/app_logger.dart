/// Log levels
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Logging utility for the HADIR application
/// Provides centralized logging with different levels and formatting
class AppLogger {
  static const String _tag = 'HADIR';
  
  /// Enable/disable logging based on build mode
  static bool _loggingEnabled = true;
  
  /// Set logging enabled state
  static void setLoggingEnabled(bool enabled) {
    _loggingEnabled = enabled;
  }
  
  /// Log debug message
  static void debug(String message, {String? tag}) {
    _log(LogLevel.debug, message, tag: tag);
  }
  
  /// Log info message
  static void info(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }
  
  /// Log warning message
  static void warning(String message, {String? tag}) {
    _log(LogLevel.warning, message, tag: tag);
  }
  
  /// Log error message
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// Internal logging method
  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_loggingEnabled) return;
    
    final timestamp = DateTime.now().toIso8601String();
    final logTag = tag ?? _tag;
    final levelString = _getLevelString(level);
    
    // Format the log message
    final logMessage = '[$timestamp] [$levelString] [$logTag] $message';
    
    // Print to console (in a real app, this could be sent to a logging service)
    print(logMessage);
    
    // Print error details if provided
    if (error != null) {
      print('Error: $error');
    }
    
    if (stackTrace != null) {
      print('Stack trace:');
      print(stackTrace);
    }
  }
  
  /// Get string representation of log level
  static String _getLevelString(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
    }
  }
  
  /// Log network request
  static void logNetworkRequest(String method, String url, {Map<String, dynamic>? params}) {
    if (!_loggingEnabled) return;
    
    info('Network Request: $method $url', tag: 'Network');
    if (params != null && params.isNotEmpty) {
      debug('Request params: $params', tag: 'Network');
    }
  }
  
  /// Log network response
  static void logNetworkResponse(String url, int statusCode, {String? responseBody}) {
    if (!_loggingEnabled) return;
    
    info('Network Response: $url - Status: $statusCode', tag: 'Network');
    if (responseBody != null) {
      debug('Response body: $responseBody', tag: 'Network');
    }
  }
  
  /// Log camera event
  static void logCameraEvent(String event, {Map<String, dynamic>? details}) {
    if (!_loggingEnabled) return;
    
    info('Camera Event: $event', tag: 'Camera');
    if (details != null && details.isNotEmpty) {
      debug('Camera details: $details', tag: 'Camera');
    }
  }
  
  /// Log face detection event
  static void logFaceDetection(String event, {int? faceCount, Map<String, dynamic>? details}) {
    if (!_loggingEnabled) return;
    
    info('Face Detection: $event${faceCount != null ? ' (faces: $faceCount)' : ''}', tag: 'FaceDetection');
    if (details != null && details.isNotEmpty) {
      debug('Detection details: $details', tag: 'FaceDetection');
    }
  }
  
  /// Log frame processing event
  static void logFrameProcessing(String event, {Map<String, dynamic>? metrics}) {
    if (!_loggingEnabled) return;
    
    info('Frame Processing: $event', tag: 'FrameProcessing');
    if (metrics != null && metrics.isNotEmpty) {
      debug('Processing metrics: $metrics', tag: 'FrameProcessing');
    }
  }
  
  /// Log database operation
  static void logDatabaseOperation(String operation, {String? table, Map<String, dynamic>? data}) {
    if (!_loggingEnabled) return;
    
    info('Database: $operation${table != null ? ' on $table' : ''}', tag: 'Database');
    if (data != null && data.isNotEmpty) {
      debug('Database data: $data', tag: 'Database');
    }
  }
  
  /// Log user action
  static void logUserAction(String action, {Map<String, dynamic>? context}) {
    if (!_loggingEnabled) return;
    
    info('User Action: $action', tag: 'UserAction');
    if (context != null && context.isNotEmpty) {
      debug('Action context: $context', tag: 'UserAction');
    }
  }
  
  /// Log performance metrics
  static void logPerformance(String operation, Duration duration, {Map<String, dynamic>? metrics}) {
    if (!_loggingEnabled) return;
    
    info('Performance: $operation took ${duration.inMilliseconds}ms', tag: 'Performance');
    if (metrics != null && metrics.isNotEmpty) {
      debug('Performance metrics: $metrics', tag: 'Performance');
    }
  }
}