/// Application configuration class
/// Contains environment-specific settings and configuration values
class AppConfig {
  // Environment settings
  static const String environment = String.fromEnvironment('ENV', defaultValue: 'development');
  static const bool isDevelopment = environment == 'development';
  static const bool isProduction = environment == 'production';
  
  // API Configuration
  static const String defaultApiBaseUrl = 'http://localhost:8000';
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: defaultApiBaseUrl);
  
  // Frame Selection Service
  static const String frameSelectionEndpoint = '/select-frames';
  static const String healthCheckEndpoint = '/health';
  
  // Request Configuration
  static const int connectTimeoutSeconds = 30;
  static const int receiveTimeoutSeconds = 60;
  static const int sendTimeoutSeconds = 30;
  
  // Camera Settings
  static const double minFaceSize = 0.15; // 15% of image
  static const double maxFaceSize = 0.7;  // 70% of image
  static const int maxFramesPerSession = 10;
  static const int minFramesForSelection = 3;
  static const int captureIntervalMs = 500;
  
  // Quality Thresholds
  static const double minSharpnessScore = 0.7;
  static const double minBrightnessScore = 0.6;
  static const double minFaceConfidence = 0.8;
  
  // Storage Configuration
  static const String databaseName = 'hadir.db';
  static const int databaseVersion = 1;
  
  // Logging Configuration
  static const bool enableLogging = isDevelopment;
  static const bool enableVerboseLogging = isDevelopment;
  
  // Feature Flags
  static const bool enableAdvancedPoseEstimation = true;
  static const bool enableOfflineMode = false;
  static const bool enableAnalytics = false;
  
  // UI Configuration
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double defaultButtonHeight = 48.0;
  static const int shortAnimationMs = 200;
  static const int mediumAnimationMs = 400;
  static const int longAnimationMs = 600;
  
  // Validation Rules
  static const int minStudentIdLength = 6;
  static const int maxStudentIdLength = 20;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  
  // File Configuration
  static const String imageFileExtension = 'jpg';
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const String appDirectoryName = 'hadir';
  
  // Network Configuration
  static const String networkTestHost = 'google.com';
  static const int networkTimeoutSeconds = 10;
  
  // Cache Configuration
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100; // number of items
  
  /// Get full API URL for an endpoint
  static String getApiUrl(String endpoint) {
    return '$apiBaseUrl$endpoint';
  }
  
  /// Get frame selection service URL
  static String get frameSelectionUrl => getApiUrl(frameSelectionEndpoint);
  
  /// Get health check URL
  static String get healthCheckUrl => getApiUrl(healthCheckEndpoint);
  
  /// Get connect timeout duration
  static Duration get connectTimeout => Duration(seconds: connectTimeoutSeconds);
  
  /// Get receive timeout duration
  static Duration get receiveTimeout => Duration(seconds: receiveTimeoutSeconds);
  
  /// Get send timeout duration
  static Duration get sendTimeout => Duration(seconds: sendTimeoutSeconds);
  
  /// Get capture interval duration
  static Duration get captureInterval => Duration(milliseconds: captureIntervalMs);
  
  /// Get short animation duration
  static Duration get shortAnimation => Duration(milliseconds: shortAnimationMs);
  
  /// Get medium animation duration
  static Duration get mediumAnimation => Duration(milliseconds: mediumAnimationMs);
  
  /// Get long animation duration
  static Duration get longAnimation => Duration(milliseconds: longAnimationMs);
  
  /// Check if current environment is development
  static bool get isDebugMode => isDevelopment;
  
  /// Get environment-specific app title
  static String get appTitle {
    if (isDevelopment) {
      return 'HADIR Mobile - Dev';
    } else if (environment == 'staging') {
      return 'HADIR Mobile - Staging';
    }
    return 'HADIR Mobile';
  }
  
  /// Get build configuration info
  static Map<String, dynamic> get buildInfo => {
    'environment': environment,
    'isDevelopment': isDevelopment,
    'isProduction': isProduction,
    'apiBaseUrl': apiBaseUrl,
    'enableLogging': enableLogging,
    'buildTime': DateTime.now().toIso8601String(),
  };
}