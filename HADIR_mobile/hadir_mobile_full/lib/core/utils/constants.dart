/// Global constants for the HADIR Mobile application
library;

/// API Configuration
class ApiConstants {
  // Frame Selection Service endpoints
  static const String baseUrl = 'http://localhost:8000';
  static const String frameSelectionEndpoint = '$baseUrl/select-frames';
  static const String healthCheckEndpoint = '$baseUrl/health';
  
  // Request timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 30);
}

/// Camera Configuration
class CameraConstants {
  // Face detection settings
  static const double minFaceSize = 0.15; // 15% of image
  static const double maxFaceSize = 0.7;  // 70% of image
  
  // Frame selection criteria
  static const int maxFramesPerSession = 10;
  static const int minFramesForSelection = 3;
  static const Duration captureInterval = Duration(milliseconds: 500);
  
  // Quality thresholds
  static const double minSharpnessScore = 0.7;
  static const double minBrightnessScore = 0.6;
  static const double minFaceConfidence = 0.8;
}

/// UI Constants
class UIConstants {
  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingExtraLarge = 32.0;
  
  // Dimensions
  static const double borderRadius = 12.0;
  static const double buttonHeight = 48.0;
  static const double iconSize = 24.0;
  static const double avatarSize = 80.0;
  
  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
}

/// Storage Keys
class StorageKeys {
  // Shared Preferences keys
  static const String isOnboardingComplete = 'is_onboarding_complete';
  static const String userPreferences = 'user_preferences';
  static const String cacheVersion = 'cache_version';
  
  // Database table names
  static const String studentsTable = 'students';
  static const String sessionsTable = 'sessions';
  static const String framesTable = 'frames';
}

/// Error Messages
class ErrorMessages {
  static const String networkError = 'Network connection failed. Please check your internet connection.';
  static const String serverError = 'Server error occurred. Please try again later.';
  static const String cameraPermissionDenied = 'Camera permission is required to capture photos.';
  static const String cameraNotAvailable = 'Camera is not available on this device.';
  static const String faceNotDetected = 'No face detected. Please position your face in the camera view.';
  static const String qualityTooLow = 'Image quality is too low. Please ensure good lighting and stability.';
  static const String processingFailed = 'Frame processing failed. Please try again.';
  static const String invalidInput = 'Invalid input provided. Please check your data.';
  static const String storageError = 'Failed to save data. Please check device storage.';
}

/// Success Messages
class SuccessMessages {
  static const String registrationComplete = 'Student registration completed successfully!';
  static const String framesProcessed = 'Frames processed and analyzed successfully.';
  static const String dataSaved = 'Data saved successfully.';
  static const String cameraInitialized = 'Camera initialized successfully.';
}

/// Feature Flags
class FeatureFlags {
  static const bool enableAdvancedPoseEstimation = true;
  static const bool enableOfflineMode = false;
  static const bool enableAnalytics = false;
  static const bool enableDebugLogging = true;
}