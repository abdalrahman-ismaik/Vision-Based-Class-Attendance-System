/// Backend Configuration Service
/// 
/// Manages backend server URL configuration with persistence using SharedPreferences.
/// Allows users to configure backend URL and test connection.
library;

import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Service for managing backend configuration
class BackendConfigService {
  static const String _keyBackendUrl = 'backend_url';
  static const String _keyLastSuccessfulConnection = 'last_successful_connection';
  
  /// Default backend URLs for different environments
  static const String defaultAndroidEmulator = 'http://10.0.2.2:5000/api';
  static const String defaultIOSSimulator = 'http://localhost:5000/api';
  static const String defaultPhysicalDevice = 'http://10.215.149.56:5000/api'; // Updated to your current IP
  
  final SharedPreferences _prefs;
  String _currentUrl = defaultAndroidEmulator;
  
  BackendConfigService(this._prefs) {
    _loadUrl();
  }
  
  /// Load saved URL from preferences
  void _loadUrl() {
    // Prefer physical device URL if not set, as we are testing on mobile
    _currentUrl = _prefs.getString(_keyBackendUrl) ?? defaultPhysicalDevice;
  }
  
  /// Get current backend URL
  String get backendUrl => _currentUrl;
  
  /// Get base URL (without /api suffix)
  String get baseUrl {
    if (_currentUrl.endsWith('/api')) {
      return _currentUrl.substring(0, _currentUrl.length - 4);
    }
    return _currentUrl;
  }
  
  /// Save backend URL
  Future<void> setBackendUrl(String url) async {
    // Clean up URL
    String cleanUrl = url.trim();
    
    // Ensure it ends with /api
    if (!cleanUrl.endsWith('/api')) {
      if (cleanUrl.endsWith('/')) {
        cleanUrl = '${cleanUrl}api';
      } else {
        cleanUrl = '$cleanUrl/api';
      }
    }
    
    _currentUrl = cleanUrl;
    await _prefs.setString(_keyBackendUrl, cleanUrl);
  }
  
  /// Reset to default URL
  Future<void> resetToDefault() async {
    await setBackendUrl(defaultPhysicalDevice);
  }
  
  /// Get last successful connection timestamp
  DateTime? get lastSuccessfulConnection {
    final timestamp = _prefs.getInt(_keyLastSuccessfulConnection);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }
  
  /// Record successful connection
  Future<void> recordSuccessfulConnection() async {
    await _prefs.setInt(
      _keyLastSuccessfulConnection,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
  
  /// Test connection to backend
  Future<BackendConnectionResult> testConnection({String? customUrl}) async {
    final testUrl = customUrl ?? _currentUrl;
    final dio = Dio(BaseOptions(
      baseUrl: testUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'bypass-tunnel-reminder': 'true',
      },
    ));
    
    try {
      // Test health endpoint
      // Backend endpoint is /api/health/status
      final response = await dio.get('/health/status');
      
      if (response.statusCode == 200) {
        await recordSuccessfulConnection();
        return BackendConnectionResult.success(
          message: 'Connected successfully',
          responseTime: response.headers['x-response-time']?.first,
        );
      } else {
        return BackendConnectionResult.failure(
          error: 'Server returned status ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      String errorMessage;
      
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Connection timeout. Check if server is running.';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'Cannot reach server. Check URL and network.';
          break;
        case DioExceptionType.badResponse:
          errorMessage = 'Server error: ${e.response?.statusCode}';
          break;
        case DioExceptionType.unknown:
          errorMessage = 'Unknown error: ${e.message ?? "Check URL format"}';
          break;
        default:
          errorMessage = 'Connection failed: ${e.message ?? "Unknown error"}';
      }
      
      return BackendConnectionResult.failure(error: errorMessage);
    } catch (e) {
      return BackendConnectionResult.failure(
        error: 'Unexpected error: ${e.toString()}',
      );
    }
  }
  
  /// Singleton instance
  static BackendConfigService? _instance;
  
  /// Initialize service
  static Future<BackendConfigService> initialize() async {
    if (_instance != null) return _instance!;
    
    final prefs = await SharedPreferences.getInstance();
    _instance = BackendConfigService(prefs);
    
    // Auto-detect environment if not configured
    await _instance!._detectAndSetDefaultUrl();
    
    return _instance!;
  }
  
  /// Detect environment and set appropriate default URL
  Future<void> _detectAndSetDefaultUrl() async {
    // If already configured, don't overwrite
    if (_prefs.containsKey(_keyBackendUrl)) return;

    try {
      final deviceInfo = DeviceInfoPlugin();
      String? detectedUrl;
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        if (androidInfo.isPhysicalDevice) {
          // Physical Android device - cannot use 10.0.2.2
          // Default to a common local IP placeholder
          detectedUrl = defaultPhysicalDevice;
        } else {
          // Android Emulator
          detectedUrl = defaultAndroidEmulator;
        }
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        if (iosInfo.isPhysicalDevice) {
          // Physical iOS device
          detectedUrl = defaultPhysicalDevice;
        } else {
          // iOS Simulator
          detectedUrl = defaultIOSSimulator;
        }
      }
      
      if (detectedUrl != null) {
        _currentUrl = detectedUrl;
        await _prefs.setString(_keyBackendUrl, detectedUrl);
      }
    } catch (e) {
      // Fallback to default if detection fails
      print('Error detecting device: $e');
    }
  }
  
  /// Get instance (must be initialized first)
  static BackendConfigService get instance {
    if (_instance == null) {
      throw StateError(
        'BackendConfigService not initialized. Call initialize() first.',
      );
    }
    return _instance!;
  }
}

/// Result of backend connection test
class BackendConnectionResult {
  final bool success;
  final String? message;
  final String? error;
  final String? responseTime;
  
  const BackendConnectionResult({
    required this.success,
    this.message,
    this.error,
    this.responseTime,
  });
  
  factory BackendConnectionResult.success({
    String? message,
    String? responseTime,
  }) {
    return BackendConnectionResult(
      success: true,
      message: message ?? 'Connection successful',
      responseTime: responseTime,
    );
  }
  
  factory BackendConnectionResult.failure({
    required String error,
  }) {
    return BackendConnectionResult(
      success: false,
      error: error,
    );
  }
}
