// App constants for HADIR Mobile MVP
class AppConstants {
  // Authentication
  static const String adminUsername = 'admin';
  static const String adminPassword = 'hadir2025';
  
  // Quality thresholds (relaxed for MVP)
  static const double minFaceConfidence = 0.5; // vs 0.8 in full version
  static const int targetFrameCount = 3; // vs 5-10 in full version
  
  // Performance targets (relaxed for MVP)
  static const int minFPS = 10; // vs 20+ in full version
  static const int maxProcessingTime = 300; // ms, vs 150ms in full version
  
  // Database
  static const String databaseName = 'hadir_mvp.db';
  static const int databaseVersion = 1;
  
  // Export
  static const String exportFileName = 'hadir_export.json';
  
  // UI Constants
  static const String appTitle = 'HADIR Mobile MVP';
  static const double defaultPadding = 16.0;
  static const double borderRadius = 8.0;
  
  // Video recording
  static const int maxRecordingDuration = 25; // seconds - Extended for better face poses
  static const int minRecordingDuration = 20;  // seconds - Minimum for all poses
  
  // Recording instructions phases (25 seconds total)
  static const Map<int, String> recordingInstructions = {
    0: "Look straight into the camera",
    5: "Slowly turn your face to the RIGHT",
    10: "Now turn your face to the LEFT",
    15: "Look straight, then tilt your head UP",
    20: "Now tilt your head DOWN, then back to center",
  };
  
  // Instruction duration for each phase
  static const int instructionPhaseSeconds = 5;
}