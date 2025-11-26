/// Error Logging Service
/// 
/// Centralized service for tracking and storing application errors.
/// Provides error logs with timestamps, severity levels, and context.
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Error severity levels
enum ErrorSeverity {
  info,
  warning,
  error,
  critical;
  
  String get displayName {
    switch (this) {
      case ErrorSeverity.info:
        return 'Info';
      case ErrorSeverity.warning:
        return 'Warning';
      case ErrorSeverity.error:
        return 'Error';
      case ErrorSeverity.critical:
        return 'Critical';
    }
  }
  
  String get emoji {
    switch (this) {
      case ErrorSeverity.info:
        return 'ℹ️';
      case ErrorSeverity.warning:
        return '⚠️';
      case ErrorSeverity.error:
        return '❌';
      case ErrorSeverity.critical:
        return '🚨';
    }
  }
}

/// Log entry representing a single error or event
class ErrorLogEntry {
  final String id;
  final DateTime timestamp;
  final ErrorSeverity severity;
  final String category;
  final String message;
  final String? stackTrace;
  final Map<String, dynamic>? context;
  
  ErrorLogEntry({
    required this.id,
    required this.timestamp,
    required this.severity,
    required this.category,
    required this.message,
    this.stackTrace,
    this.context,
  });
  
  /// Create from JSON
  factory ErrorLogEntry.fromJson(Map<String, dynamic> json) {
    return ErrorLogEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      severity: ErrorSeverity.values.byName(json['severity'] as String),
      category: json['category'] as String,
      message: json['message'] as String,
      stackTrace: json['stackTrace'] as String?,
      context: json['context'] as Map<String, dynamic>?,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'severity': severity.name,
      'category': category,
      'message': message,
      'stackTrace': stackTrace,
      'context': context,
    };
  }
  
  /// Format for display
  String get formattedTimestamp {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} '
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }
}

/// Service for managing error logs
class ErrorLogService {
  static const String _keyErrorLogs = 'error_logs';
  static const int _maxLogEntries = 500;
  
  final SharedPreferences _prefs;
  final List<ErrorLogEntry> _logs = [];
  
  ErrorLogService(this._prefs) {
    _loadLogs();
  }
  
  /// Load logs from preferences
  void _loadLogs() {
    try {
      final logsJson = _prefs.getString(_keyErrorLogs);
      if (logsJson != null) {
        final List<dynamic> decoded = jsonDecode(logsJson);
        _logs.clear();
        _logs.addAll(
          decoded.map((e) => ErrorLogEntry.fromJson(e as Map<String, dynamic>)),
        );
      }
    } catch (e) {
      print('Error loading logs: $e');
    }
  }
  
  /// Save logs to preferences
  Future<void> _saveLogs() async {
    try {
      final encoded = jsonEncode(_logs.map((e) => e.toJson()).toList());
      await _prefs.setString(_keyErrorLogs, encoded);
    } catch (e) {
      print('Error saving logs: $e');
    }
  }
  
  /// Log an error or event
  Future<void> log({
    required ErrorSeverity severity,
    required String category,
    required String message,
    String? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    final entry = ErrorLogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      severity: severity,
      category: category,
      message: message,
      stackTrace: stackTrace,
      context: context,
    );
    
    _logs.insert(0, entry); // Add to beginning (most recent first)
    
    // Trim if exceeds max
    if (_logs.length > _maxLogEntries) {
      _logs.removeRange(_maxLogEntries, _logs.length);
    }
    
    await _saveLogs();
    
    // Also print to console for debugging
    print('${entry.severity.emoji} [${entry.category}] ${entry.message}');
  }
  
  /// Convenience methods for different severity levels
  Future<void> logInfo(String category, String message, {Map<String, dynamic>? context}) async {
    await log(severity: ErrorSeverity.info, category: category, message: message, context: context);
  }
  
  Future<void> logWarning(String category, String message, {Map<String, dynamic>? context}) async {
    await log(severity: ErrorSeverity.warning, category: category, message: message, context: context);
  }
  
  Future<void> logError(String category, String message, {String? stackTrace, Map<String, dynamic>? context}) async {
    await log(severity: ErrorSeverity.error, category: category, message: message, stackTrace: stackTrace, context: context);
  }
  
  Future<void> logCritical(String category, String message, {String? stackTrace, Map<String, dynamic>? context}) async {
    await log(severity: ErrorSeverity.critical, category: category, message: message, stackTrace: stackTrace, context: context);
  }
  
  /// Get all logs
  List<ErrorLogEntry> get allLogs => List.unmodifiable(_logs);
  
  /// Get logs filtered by severity
  List<ErrorLogEntry> getLogsBySeverity(ErrorSeverity severity) {
    return _logs.where((log) => log.severity == severity).toList();
  }
  
  /// Get logs filtered by category
  List<ErrorLogEntry> getLogsByCategory(String category) {
    return _logs.where((log) => log.category == category).toList();
  }
  
  /// Get logs within date range
  List<ErrorLogEntry> getLogsByDateRange(DateTime start, DateTime end) {
    return _logs.where((log) {
      return log.timestamp.isAfter(start) && log.timestamp.isBefore(end);
    }).toList();
  }
  
  /// Get recent logs (last n entries)
  List<ErrorLogEntry> getRecentLogs(int count) {
    return _logs.take(count).toList();
  }
  
  /// Clear all logs
  Future<void> clearAll() async {
    _logs.clear();
    await _saveLogs();
  }
  
  /// Clear logs older than specified days
  Future<void> clearOlderThan(int days) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    _logs.removeWhere((log) => log.timestamp.isBefore(cutoffDate));
    await _saveLogs();
  }
  
  /// Get statistics
  Map<String, int> getStatistics() {
    final stats = <String, int>{
      'total': _logs.length,
      'info': 0,
      'warning': 0,
      'error': 0,
      'critical': 0,
    };
    
    for (final log in _logs) {
      stats[log.severity.name] = (stats[log.severity.name] ?? 0) + 1;
    }
    
    return stats;
  }
  
  /// Get unique categories
  Set<String> get categories {
    return _logs.map((log) => log.category).toSet();
  }
  
  /// Singleton instance
  static ErrorLogService? _instance;
  
  /// Initialize service
  static Future<ErrorLogService> initialize() async {
    if (_instance != null) return _instance!;
    
    final prefs = await SharedPreferences.getInstance();
    _instance = ErrorLogService(prefs);
    return _instance!;
  }
  
  /// Get instance (must be initialized first)
  static ErrorLogService get instance {
    if (_instance == null) {
      throw StateError(
        'ErrorLogService not initialized. Call initialize() first.',
      );
    }
    return _instance!;
  }
}
