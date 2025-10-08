/// Domain models for frame selection and image analysis
/// 
/// These models represent the core data structures used throughout
/// the application for frame selection operations.

/// Service health check result
class ServiceHealthResult {
  final bool isHealthy;
  final String? version;
  final List<String>? capabilities;
  final int? uptime;
  final String? error;
  final DateTime lastUpdate;

  ServiceHealthResult({
    required this.isHealthy,
    this.version,
    this.capabilities,
    this.uptime,
    this.error,
    required this.lastUpdate,
  });

  bool get hasError => error != null;
  bool get isOnline => isHealthy && error == null;
}

/// Frame selection result containing selected frames and metadata
class FrameSelectionResult {
  final List<SelectedFrame> selectedFrames;
  final int totalFramesProcessed;
  final int processingTimeMs;
  final String algorithm;
  final Map<String, dynamic> metadata;

  FrameSelectionResult({
    required this.selectedFrames,
    required this.totalFramesProcessed,
    required this.processingTimeMs,
    required this.algorithm,
    required this.metadata,
  });

  /// Get the best frame (highest quality score)
  SelectedFrame? get bestFrame {
    if (selectedFrames.isEmpty) return null;
    return selectedFrames.reduce((a, b) => 
        a.qualityScore > b.qualityScore ? a : b);
  }

  /// Get average quality score of selected frames
  double get averageQualityScore {
    if (selectedFrames.isEmpty) return 0.0;
    final sum = selectedFrames.fold<double>(
        0.0, (sum, frame) => sum + frame.qualityScore);
    return sum / selectedFrames.length;
  }

  /// Get processing time in seconds
  double get processingTimeSeconds => processingTimeMs / 1000.0;
}

/// Selected frame with quality metrics and analysis
class SelectedFrame {
  final int originalIndex;
  final String frameId;
  final double qualityScore;
  final double sharpnessScore;
  final double brightnessScore;
  final int faceCount;
  final List<FaceDetection> faces;
  final String imagePath;
  final String? base64Image;

  SelectedFrame({
    required this.originalIndex,
    required this.frameId,
    required this.qualityScore,
    required this.sharpnessScore,
    required this.brightnessScore,
    required this.faceCount,
    required this.faces,
    required this.imagePath,
    this.base64Image,
  });

  /// Check if frame has good quality (above threshold)
  bool get hasGoodQuality => qualityScore >= 0.7;

  /// Check if frame has acceptable sharpness
  bool get isSharp => sharpnessScore >= 0.6;

  /// Check if frame has good lighting
  bool get hasGoodLighting => brightnessScore >= 0.5;

  /// Get the primary face (highest confidence)
  FaceDetection? get primaryFace {
    if (faces.isEmpty) return null;
    return faces.reduce((a, b) => 
        a.confidence > b.confidence ? a : b);
  }

  /// Overall frame quality assessment
  FrameQuality get qualityAssessment {
    if (qualityScore >= 0.9) return FrameQuality.excellent;
    if (qualityScore >= 0.8) return FrameQuality.good;
    if (qualityScore >= 0.6) return FrameQuality.acceptable;
    if (qualityScore >= 0.4) return FrameQuality.poor;
    return FrameQuality.veryPoor;
  }
}

/// Face detection result with keypoints and pose information
class FaceDetection {
  final double confidence;
  final BoundingBox boundingBox;
  final List<KeyPoint> keypoints;
  final Map<String, double> angles;

  FaceDetection({
    required this.confidence,
    required this.boundingBox,
    required this.keypoints,
    required this.angles,
  });

  /// Check if face detection is reliable
  bool get isReliable => confidence >= 0.8;

  /// Get head pose angles
  double get headPitch => angles['head_pitch'] ?? 0.0;
  double get headYaw => angles['head_yaw'] ?? 0.0;
  double get headRoll => angles['head_roll'] ?? 0.0;

  /// Check if face is looking forward (good for ID photos)
  bool get isLookingForward {
    return headYaw.abs() <= 15.0 && 
           headPitch.abs() <= 15.0 && 
           headRoll.abs() <= 15.0;
  }

  /// Get face center point
  Point get center {
    return Point(
      boundingBox.x + boundingBox.width / 2,
      boundingBox.y + boundingBox.height / 2,
    );
  }

  /// Get specific keypoints by name
  KeyPoint? getKeypoint(String name) {
    try {
      return keypoints.firstWhere((kp) => kp.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Get eye keypoints
  List<KeyPoint> get eyeKeypoints {
    return keypoints.where((kp) => 
        kp.name.contains('eye')).toList();
  }
}

/// Bounding box for face detection
class BoundingBox {
  final double x;
  final double y;
  final double width;
  final double height;

  BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Get bounding box area
  double get area => width * height;

  /// Get bounding box center
  Point get center => Point(x + width / 2, y + height / 2);

  /// Get top-left corner
  Point get topLeft => Point(x, y);

  /// Get bottom-right corner
  Point get bottomRight => Point(x + width, y + height);

  /// Check if point is inside bounding box
  bool contains(Point point) {
    return point.x >= x && 
           point.x <= x + width &&
           point.y >= y && 
           point.y <= y + height;
  }
}

/// Keypoint for pose estimation
class KeyPoint {
  final double x;
  final double y;
  final double confidence;
  final String name;

  KeyPoint({
    required this.x,
    required this.y,
    required this.confidence,
    required this.name,
  });

  /// Check if keypoint is visible/reliable
  bool get isVisible => confidence >= 0.5;

  /// Get keypoint as a Point
  Point get point => Point(x, y);

  /// Calculate distance to another keypoint
  double distanceTo(KeyPoint other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return sqrt(dx * dx + dy * dy);
  }
}

/// Simple Point class
class Point {
  final double x;
  final double y;

  Point(this.x, this.y);

  /// Calculate distance to another point
  double distanceTo(Point other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return sqrt(dx * dx + dy * dy);
  }

  @override
  String toString() => 'Point($x, $y)';
}

/// Service information result
class ServiceInfoResult {
  final String serviceName;
  final String version;
  final String description;
  final Map<String, dynamic> capabilities;
  final Map<String, dynamic> configuration;
  final List<String> endpoints;

  ServiceInfoResult({
    required this.serviceName,
    required this.version,
    required this.description,
    required this.capabilities,
    required this.configuration,
    required this.endpoints,
  });

  /// Check if service supports a specific capability
  bool hasCapability(String capability) {
    return capabilities.containsKey(capability);
  }

  /// Get configuration value
  T? getConfigValue<T>(String key) {
    return configuration[key] as T?;
  }
}

/// Image analysis result for individual images
class ImageAnalysisResult {
  final List<ImageAnalysis> analyses;
  final int totalImages;
  final int processingTimeMs;
  final DateTime timestamp;

  ImageAnalysisResult({
    required this.analyses,
    required this.totalImages,
    required this.processingTimeMs,
    required this.timestamp,
  });

  /// Get analyses with good quality
  List<ImageAnalysis> get goodQualityAnalyses {
    return analyses.where((analysis) => 
        analysis.qualityScore >= 0.7).toList();
  }

  /// Get average quality score across all images
  double get averageQualityScore {
    if (analyses.isEmpty) return 0.0;
    final sum = analyses.fold<double>(
        0.0, (sum, analysis) => sum + analysis.qualityScore);
    return sum / analyses.length;
  }
}

/// Analysis result for a single image
class ImageAnalysis {
  final int imageIndex;
  final String imagePath;
  final double qualityScore;
  final double sharpnessScore;
  final double brightnessScore;
  final int faceCount;
  final List<FaceDetection> faces;

  ImageAnalysis({
    required this.imageIndex,
    required this.imagePath,
    required this.qualityScore,
    required this.sharpnessScore,
    required this.brightnessScore,
    required this.faceCount,
    required this.faces,
  });

  /// Check if image has acceptable quality
  bool get hasAcceptableQuality => qualityScore >= 0.6;

  /// Get primary face detection
  FaceDetection? get primaryFace {
    if (faces.isEmpty) return null;
    return faces.reduce((a, b) => 
        a.confidence > b.confidence ? a : b);
  }
}

/// Frame selection options
class FrameSelectionOptions {
  final double minQualityScore;
  final double minSharpnessScore;
  final double minBrightnessScore;
  final double minFaceConfidence;
  final bool requireFrontalFace;
  final bool enableDiversityScoring;
  final Map<String, dynamic>? customOptions;

  FrameSelectionOptions({
    this.minQualityScore = 0.6,
    this.minSharpnessScore = 0.5,
    this.minBrightnessScore = 0.4,
    this.minFaceConfidence = 0.8,
    this.requireFrontalFace = true,
    this.enableDiversityScoring = true,
    this.customOptions,
  });

  Map<String, dynamic> toJson() {
    return {
      'min_quality_score': minQualityScore,
      'min_sharpness_score': minSharpnessScore,
      'min_brightness_score': minBrightnessScore,
      'min_face_confidence': minFaceConfidence,
      'require_frontal_face': requireFrontalFace,
      'enable_diversity_scoring': enableDiversityScoring,
      if (customOptions != null) ...customOptions!,
    };
  }
}

/// Frame quality enumeration
enum FrameQuality {
  excellent,
  good,
  acceptable,
  poor,
  veryPoor,
}

/// Extension to get quality description
extension FrameQualityExtension on FrameQuality {
  String get description {
    switch (this) {
      case FrameQuality.excellent:
        return 'Excellent';
      case FrameQuality.good:
        return 'Good';
      case FrameQuality.acceptable:
        return 'Acceptable';
      case FrameQuality.poor:
        return 'Poor';
      case FrameQuality.veryPoor:
        return 'Very Poor';
    }
  }

  String get detailedDescription {
    switch (this) {
      case FrameQuality.excellent:
        return 'Perfect for professional use';
      case FrameQuality.good:
        return 'Suitable for most purposes';
      case FrameQuality.acceptable:
        return 'Usable but could be better';
      case FrameQuality.poor:
        return 'Low quality, consider retaking';
      case FrameQuality.veryPoor:
        return 'Very poor quality, retake recommended';
    }
  }
}

/// Simple square root implementation
double sqrt(double x) {
  if (x < 0) return double.nan;
  if (x == 0) return 0;
  
  double guess = x / 2;
  double previousGuess;
  
  do {
    previousGuess = guess;
    guess = (guess + x / guess) / 2;
  } while ((guess - previousGuess).abs() > 0.000001);
  
  return guess;
}