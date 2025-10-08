import 'package:equatable/equatable.dart';

/// Enumeration for frame quality levels
enum FrameQuality {
  poor,
  fair,
  good,
  excellent;

  @override
  String toString() {
    switch (this) {
      case FrameQuality.poor:
        return 'Poor';
      case FrameQuality.fair:
        return 'Fair';
      case FrameQuality.good:
        return 'Good';
      case FrameQuality.excellent:
        return 'Excellent';
    }
  }
}

/// Enumeration for pose types required in registration
enum PoseType {
  frontal,
  leftProfile,
  rightProfile,
  lookingUp,
  lookingDown;

  @override
  String toString() {
    switch (this) {
      case PoseType.frontal:
        return 'Frontal';
      case PoseType.leftProfile:
        return 'Left Profile';
      case PoseType.rightProfile:
        return 'Right Profile';
      case PoseType.lookingUp:
        return 'Looking Up';
      case PoseType.lookingDown:
        return 'Looking Down';
    }
  }

  /// Get user-friendly instruction for this pose
  String get instruction {
    switch (this) {
      case PoseType.frontal:
        return 'Look straight at the camera';
      case PoseType.leftProfile:
        return 'Turn your head to the left';
      case PoseType.rightProfile:
        return 'Turn your head to the right';
      case PoseType.lookingUp:
        return 'Look up slightly';
      case PoseType.lookingDown:
        return 'Look down slightly';
    }
  }
}

/// Domain entity representing a selected frame captured during registration
class SelectedFrame extends Equatable {
  const SelectedFrame({
    required this.id,
    required this.registrationSessionId,
    required this.imagePath,
    required this.poseType,
    required this.confidenceScore,
    required this.quality,
    required this.faceEmbedding,
    required this.faceBoundingBox,
    required this.keyPoints,
    required this.capturedAt,
    this.processingTime,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique identifier for the selected frame
  final String id;

  /// ID of the registration session this frame belongs to
  final String registrationSessionId;

  /// Local file path where the image is stored
  final String imagePath;

  /// Type of pose captured in this frame
  final PoseType poseType;

  /// Confidence score from YOLOv7-Pose detection (0.0 to 1.0)
  final double confidenceScore;

  /// Quality assessment of the frame
  final FrameQuality quality;

  /// Face embedding vector generated from the frame
  final List<double> faceEmbedding;

  /// Bounding box coordinates [x, y, width, height] for the detected face
  final List<double> faceBoundingBox;

  /// Facial key points detected by YOLOv7-Pose
  final List<List<double>> keyPoints;

  /// When the frame was captured
  final DateTime capturedAt;

  /// Time taken to process this frame (in milliseconds)
  final int? processingTime;

  /// Additional metadata for the frame
  final Map<String, dynamic> metadata;

  /// When the frame record was created
  final DateTime createdAt;

  /// When the frame record was last updated
  final DateTime updatedAt;

  /// Check if the frame meets minimum quality requirements
  bool get meetsQualityThreshold {
    return confidenceScore >= 0.9 && 
           quality != FrameQuality.poor &&
           faceEmbedding.isNotEmpty &&
           faceBoundingBox.length == 4;
  }

  /// Check if face is well-centered in the frame
  bool get isFaceCentered {
    if (faceBoundingBox.length != 4) return false;
    
    final centerX = faceBoundingBox[0] + (faceBoundingBox[2] / 2);
    final centerY = faceBoundingBox[1] + (faceBoundingBox[3] / 2);
    
    // Assuming frame is normalized to [0, 1], check if face center is reasonably centered
    return centerX >= 0.3 && centerX <= 0.7 && centerY >= 0.25 && centerY <= 0.75;
  }

  /// Get face area as percentage of frame
  double get faceAreaPercentage {
    if (faceBoundingBox.length != 4) return 0.0;
    return faceBoundingBox[2] * faceBoundingBox[3]; // width * height
  }

  /// Check if face size is appropriate (not too small or too large)
  bool get hasAppropriateSize {
    final area = faceAreaPercentage;
    return area >= 0.05 && area <= 0.4; // Between 5% and 40% of frame
  }

  /// Get overall frame score (0.0 to 1.0)
  double get overallScore {
    double score = confidenceScore * 0.4; // 40% weight on confidence
    
    // Quality score (30% weight)
    double qualityScore = switch (quality) {
      FrameQuality.poor => 0.0,
      FrameQuality.fair => 0.3,
      FrameQuality.good => 0.7,
      FrameQuality.excellent => 1.0,
    };
    score += qualityScore * 0.3;
    
    // Centering score (15% weight)
    score += (isFaceCentered ? 1.0 : 0.0) * 0.15;
    
    // Size score (15% weight)
    score += (hasAppropriateSize ? 1.0 : 0.0) * 0.15;
    
    return score.clamp(0.0, 1.0);
  }

  /// Create a copy of this frame with updated fields
  SelectedFrame copyWith({
    String? id,
    String? registrationSessionId,
    String? imagePath,
    PoseType? poseType,
    double? confidenceScore,
    FrameQuality? quality,
    List<double>? faceEmbedding,
    List<double>? faceBoundingBox,
    List<List<double>>? keyPoints,
    DateTime? capturedAt,
    int? processingTime,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SelectedFrame(
      id: id ?? this.id,
      registrationSessionId: registrationSessionId ?? this.registrationSessionId,
      imagePath: imagePath ?? this.imagePath,
      poseType: poseType ?? this.poseType,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      quality: quality ?? this.quality,
      faceEmbedding: faceEmbedding ?? this.faceEmbedding,
      faceBoundingBox: faceBoundingBox ?? this.faceBoundingBox,
      keyPoints: keyPoints ?? this.keyPoints,
      capturedAt: capturedAt ?? this.capturedAt,
      processingTime: processingTime ?? this.processingTime,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Convert frame to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'registrationSessionId': registrationSessionId,
      'imagePath': imagePath,
      'poseType': poseType.name,
      'confidenceScore': confidenceScore,
      'quality': quality.name,
      'faceEmbedding': faceEmbedding,
      'faceBoundingBox': faceBoundingBox,
      'keyPoints': keyPoints,
      'capturedAt': capturedAt.toIso8601String(),
      'processingTime': processingTime,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create frame from JSON
  factory SelectedFrame.fromJson(Map<String, dynamic> json) {
    return SelectedFrame(
      id: json['id'] as String,
      registrationSessionId: json['registrationSessionId'] as String,
      imagePath: json['imagePath'] as String,
      poseType: PoseType.values.firstWhere((e) => e.name == json['poseType']),
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      quality: FrameQuality.values.firstWhere((e) => e.name == json['quality']),
      faceEmbedding: (json['faceEmbedding'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      faceBoundingBox: (json['faceBoundingBox'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      keyPoints: (json['keyPoints'] as List<dynamic>)
          .map((e) => (e as List<dynamic>).map((v) => (v as num).toDouble()).toList())
          .toList(),
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      processingTime: json['processingTime'] as int?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Validate frame data
  static void validate({
    required String id,
    required String registrationSessionId,
    required String imagePath,
    required double confidenceScore,
    required List<double> faceEmbedding,
    required List<double> faceBoundingBox,
    required List<List<double>> keyPoints,
  }) {
    // Validate ID format (FRM followed by 8 digits)
    if (!RegExp(r'^FRM\d{8}$').hasMatch(id)) {
      throw ArgumentError('Frame ID must follow format: FRM########');
    }

    // Validate registration session ID format
    if (!RegExp(r'^REG\d{8}$').hasMatch(registrationSessionId)) {
      throw ArgumentError('Registration session ID must follow format: REG########');
    }

    // Validate image path
    if (imagePath.trim().isEmpty) {
      throw ArgumentError('Image path cannot be empty');
    }

    // Validate confidence score
    if (confidenceScore < 0.0 || confidenceScore > 1.0) {
      throw ArgumentError('Confidence score must be between 0.0 and 1.0');
    }

    // Validate face embedding
    if (faceEmbedding.isEmpty) {
      throw ArgumentError('Face embedding cannot be empty');
    }

    // Validate bounding box
    if (faceBoundingBox.length != 4) {
      throw ArgumentError('Face bounding box must have exactly 4 values [x, y, width, height]');
    }

    if (faceBoundingBox.any((value) => value < 0 || value > 1)) {
      throw ArgumentError('Face bounding box values must be normalized between 0 and 1');
    }

    // Validate key points
    if (keyPoints.isEmpty) {
      throw ArgumentError('Key points cannot be empty');
    }

    for (final point in keyPoints) {
      if (point.length != 2) {
        throw ArgumentError('Each key point must have exactly 2 coordinates [x, y]');
      }
    }
  }

  @override
  List<Object?> get props => [
    id,
    registrationSessionId,
    imagePath,
    poseType,
    confidenceScore,
    quality,
    faceEmbedding,
    faceBoundingBox,
    keyPoints,
    capturedAt,
    processingTime,
    metadata,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'SelectedFrame(id: $id, poseType: $poseType, confidence: ${confidenceScore.toStringAsFixed(3)}, quality: $quality)';
  }
}