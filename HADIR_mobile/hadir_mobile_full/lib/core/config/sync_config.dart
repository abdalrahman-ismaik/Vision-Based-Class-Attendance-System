/// Sync configuration for mobile-to-backend synchronization
/// 
/// Contains all settings for backend communication, timeouts, retry logic,
/// and sync behavior. Configure these values based on your environment.
library;

class SyncConfig {
  // ========================================================================
  // Backend Server Configuration
  // ========================================================================
  
  /// Base URL for backend API
  /// 
  /// - Android Emulator: Use 10.0.2.2 (maps to host machine's localhost)
  /// - iOS Simulator: Use localhost or 127.0.0.1
  /// - Physical Device: Use your computer's IP address (e.g., 192.168.1.100)
  /// 
  /// Examples:
  /// - Development (Android Emulator): 'http://10.0.2.2:5000/api'
  /// - Development (iOS Simulator): 'http://localhost:5000/api'
  /// - Development (Physical Device): 'http://192.168.1.100:5000/api'
  /// - Production: 'https://api.hadir.edu/api'
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://172.18.103.83:5000/api', // Using physical IP (backend shows: Running on http://172.18.103.83:5000)
  );
  
  /// Backend API version
  static const String apiVersion = 'v1';
  
  // ========================================================================
  // Timeout Configuration
  // ========================================================================
  
  /// Connection timeout - Time to establish connection to server
  static const Duration connectionTimeout = Duration(minutes: 2); // Increased for emulator network delays
  
  /// Receive timeout - Time to wait for server response
  static const Duration receiveTimeout = Duration(minutes: 3); // Increased for face processing
  
  /// Send timeout - Time to wait for data upload completion
  static const Duration sendTimeout = Duration(minutes: 5);
  
  /// Status polling interval - How often to check processing status
  static const Duration statusPollInterval = Duration(seconds: 10);
  
  /// Maximum polling duration - Stop polling after this time
  static const Duration maxPollingDuration = Duration(minutes: 10);
  
  // ========================================================================
  // Retry Configuration
  // ========================================================================
  
  /// Maximum number of retry attempts for failed syncs
  static const int maxRetryAttempts = 3;
  
  /// Initial retry delay (exponential backoff starts from this)
  /// Retry delays: 5s, 10s, 20s, 40s...
  static const Duration initialRetryDelay = Duration(seconds: 5);
  
  /// Maximum retry delay (cap for exponential backoff)
  static const Duration maxRetryDelay = Duration(seconds: 60);
  
  /// Whether to use exponential backoff for retries
  static const bool useExponentialBackoff = true;
  
  // ========================================================================
  // Sync Behavior
  // ========================================================================
  
  /// Maximum number of students to sync in a single batch
  static const int maxBatchSize = 10;
  
  /// Auto-sync on app resume (when app comes to foreground)
  static const bool autoSyncOnResume = false; // Disabled for MVP
  
  /// Auto-sync on network reconnection
  static const bool autoSyncOnNetworkReconnect = false; // Disabled for MVP
  
  /// Sync immediately after student registration
  static const bool syncImmediatelyAfterRegistration = true;
  
  // ========================================================================
  // Image Configuration
  // ========================================================================
  
  /// Maximum image file size in MB
  static const int maxImageSizeMB = 10;
  
  /// Allowed image formats
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png'];
  
  /// Image quality for upload (1-100)
  static const int imageQuality = 90;
  
  // ========================================================================
  // Logging Configuration
  // ========================================================================
  
  /// Enable detailed logging for sync operations
  static const bool enableDetailedLogging = true;
  
  /// Log HTTP request/response bodies
  static const bool logRequestBodies = true;
  
  /// Log HTTP response bodies
  static const bool logResponseBodies = true;
  
  /// Maximum log file size in MB
  static const int maxLogFileSizeMB = 10;
  
  /// Number of log files to keep
  static const int maxLogFiles = 5;
  
  // ========================================================================
  // Development/Debug Settings
  // ========================================================================
  
  /// Enable mock mode (for testing without backend)
  static const bool enableMockMode = false;
  
  /// Mock sync delay (simulates network delay)
  static const Duration mockSyncDelay = Duration(seconds: 2);
  
  /// Throw errors in debug mode for easier debugging
  static const bool throwErrorsInDebugMode = true;
  
  // ========================================================================
  // HTTP Headers
  // ========================================================================
  
  /// Default HTTP headers for all requests
  static Map<String, String> get defaultHeaders => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'User-Agent': 'HADIR-Mobile/$appVersion',
  };
  
  /// App version (should match pubspec.yaml)
  static const String appVersion = '1.0.0';
  
  // ========================================================================
  // Validation
  // ========================================================================
  
  /// Validate configuration on app startup
  static bool validate() {
    // Check backend URL is not empty
    if (backendBaseUrl.isEmpty) {
      throw Exception('Backend URL is not configured');
    }
    
    // Check URL format
    if (!backendBaseUrl.startsWith('http://') && 
        !backendBaseUrl.startsWith('https://')) {
      throw Exception('Backend URL must start with http:// or https://');
    }
    
    // Check timeouts are reasonable
    if (connectionTimeout.inSeconds < 5) {
      throw Exception('Connection timeout too short (minimum 5 seconds)');
    }
    
    if (maxRetryAttempts < 1 || maxRetryAttempts > 10) {
      throw Exception('Max retry attempts must be between 1 and 10');
    }
    
    return true;
  }
  
  // ========================================================================
  // Helper Methods
  // ========================================================================
  
  /// Get full URL for an endpoint
  static String getEndpointUrl(String endpoint) {
    // Remove leading slash if present
    final cleanEndpoint = endpoint.startsWith('/') 
        ? endpoint.substring(1) 
        : endpoint;
    
    // Ensure base URL doesn't end with slash
    final cleanBaseUrl = backendBaseUrl.endsWith('/') 
        ? backendBaseUrl.substring(0, backendBaseUrl.length - 1)
        : backendBaseUrl;
    
    return '$cleanBaseUrl/$cleanEndpoint';
  }
  
  /// Calculate retry delay based on attempt number
  static Duration getRetryDelay(int attemptNumber) {
    if (!useExponentialBackoff) {
      return initialRetryDelay;
    }
    
    // Exponential backoff: delay * 2^(attempt-1)
    final delaySeconds = initialRetryDelay.inSeconds * 
        (1 << (attemptNumber - 1)); // Bit shift for 2^n
    
    // Cap at maximum delay
    final cappedDelay = delaySeconds > maxRetryDelay.inSeconds
        ? maxRetryDelay.inSeconds
        : delaySeconds;
    
    return Duration(seconds: cappedDelay);
  }
  
  /// Check if image file is valid for upload
  static bool isImageValid(String filePath, int fileSizeBytes) {
    // Check file extension
    final extension = filePath.split('.').last.toLowerCase();
    if (!allowedImageFormats.contains(extension)) {
      return false;
    }
    
    // Check file size
    final fileSizeMB = fileSizeBytes / (1024 * 1024);
    if (fileSizeMB > maxImageSizeMB) {
      return false;
    }
    
    return true;
  }
  
  /// Get configuration summary for debugging
  static String getSummary() {
    return '''
Sync Configuration:
------------------
Backend URL: $backendBaseUrl
Connection Timeout: ${connectionTimeout.inSeconds}s
Max Retries: $maxRetryAttempts
Initial Retry Delay: ${initialRetryDelay.inSeconds}s
Status Poll Interval: ${statusPollInterval.inSeconds}s
Max Image Size: ${maxImageSizeMB}MB
Detailed Logging: $enableDetailedLogging
Mock Mode: $enableMockMode
''';
  }
}
