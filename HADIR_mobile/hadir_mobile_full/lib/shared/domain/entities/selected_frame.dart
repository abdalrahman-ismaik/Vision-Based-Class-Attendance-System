import 'dart:convert';
import 'package:equatable/equatable.dart';
import '../../../core/computer_vision/pose_angles.dart';
import '../../../core/computer_vision/bounding_box.dart';
import '../../../core/computer_vision/face_metrics.dart';
import '../../../core/computer_vision/pose_type.dart';

/// Domain entity representing a selected frame captured during registration
class SelectedFrame extends Equatable {
  const SelectedFrame({
    required this.id,
    required this.sessionId,
    required this.imageFilePath,
    required this.timestampMs,
    required this.qualityScore,
    required this.poseAngles,
    required this.faceMetrics,
    required this.extractedAt,
    this.boundingBox,
    this.metadata = const {},
    PoseType? poseType,
    PoseTarget? poseTarget,
    this.confidenceScore = 1.0,
    this.qualityMetrics,
  }) : poseType = poseType ?? PoseType.frontal;

  /// Unique identifier for the selected frame
  final String id;

  /// ID of the registration session this frame belongs to
  final String sessionId;

  /// Path to the image file
  final String imageFilePath;

  /// Timestamp in milliseconds when the frame was captured
  final int timestampMs;

  /// Overall quality score (0.0 to 1.0)
  final double qualityScore;

  /// Pose angles for head orientation
  final PoseAngles poseAngles;

  /// Face quality metrics
  final FaceMetrics faceMetrics;

  /// The detected pose type for this frame (frontal, leftProfile, ...)
  final PoseType poseType;

  /// Confidence score for the detected pose/frame (0.0 - 1.0)
  final double confidenceScore;

  /// Optional quality metrics object (tests use FrameQualityMetrics)
  final dynamic qualityMetrics;

  /// When the frame was extracted/selected
  final DateTime extractedAt;

  /// Optional bounding box for face location
  final BoundingBox? boundingBox;

  /// Additional metadata
  final Map<String, dynamic> metadata;

  @override
  List<Object?> get props => [
    id,
    sessionId,
    imageFilePath,
    timestampMs,
    qualityScore,
    poseAngles,
    faceMetrics,
    extractedAt,
    boundingBox,
    poseType,
    confidenceScore,
    qualityMetrics,
    metadata,
  ];

  /// Create a copy with updated fields
  SelectedFrame copyWith({
    String? id,
    String? sessionId,
    String? imageFilePath,
    int? timestampMs,
    double? qualityScore,
    PoseAngles? poseAngles,
    FaceMetrics? faceMetrics,
    DateTime? extractedAt,
    BoundingBox? boundingBox,
    Map<String, dynamic>? metadata,
    PoseType? poseType,
    double? confidenceScore,
    dynamic qualityMetrics,
  }) {
    return SelectedFrame(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      imageFilePath: imageFilePath ?? this.imageFilePath,
      timestampMs: timestampMs ?? this.timestampMs,
      qualityScore: qualityScore ?? this.qualityScore,
      poseAngles: poseAngles ?? this.poseAngles,
      faceMetrics: faceMetrics ?? this.faceMetrics,
      extractedAt: extractedAt ?? this.extractedAt,
      boundingBox: boundingBox ?? this.boundingBox,
      metadata: metadata ?? this.metadata,
      poseType: poseType ?? this.poseType,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      qualityMetrics: qualityMetrics ?? this.qualityMetrics,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'imageFilePath': imageFilePath,
      'timestampMs': timestampMs,
      'qualityScore': qualityScore,
      'poseAngles': poseAngles.toJson(),
      'faceMetrics': faceMetrics.toJson(),
      'extractedAt': extractedAt.toIso8601String(),
      'boundingBox': boundingBox?.toJson(),
      'poseType': poseType.index,
      'confidenceScore': confidenceScore,
      'qualityMetrics': qualityMetrics,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory SelectedFrame.fromJson(Map<String, dynamic> json) {
    // Support both camelCase (for API) and snake_case (for database)
    return SelectedFrame(
      id: json['id'] as String,
      sessionId: (json['session_id'] ?? json['sessionId']) as String,
      imageFilePath: (json['image_file_path'] ?? json['imageFilePath']) as String,
      timestampMs: (json['timestamp_ms'] ?? json['timestampMs']) as int,
      qualityScore: ((json['quality_score'] ?? json['qualityScore']) as num).toDouble(),
      poseAngles: _parsePoseAngles(json['pose_angles'] ?? json['poseAngles']),
      faceMetrics: _parseFaceMetrics(json['face_metrics'] ?? json['faceMetrics'], json['bounding_box'] ?? json['boundingBox']),
      extractedAt: DateTime.parse((json['extracted_at'] ?? json['extractedAt']) as String),
      boundingBox: _parseBoundingBox(json['bounding_box'] ?? json['boundingBox']),
      poseType: _parsePoseType(json['pose_type'] ?? json['poseType']),
      confidenceScore: ((json['confidence_score'] ?? json['confidenceScore']) as num?)?.toDouble() ?? 1.0,
      qualityMetrics: _parseJsonField(json['quality_metrics'] ?? json['qualityMetrics']),
      metadata: _parseMetadata(json['metadata']),
    );
  }

  /// Helper to parse JSON fields that might be stored as strings
  static dynamic _parseJsonField(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return jsonDecode(value);
      } catch (e) {
        return null;
      }
    }
    return value;
  }

  /// Helper to parse metadata field
  static Map<String, dynamic> _parseMetadata(dynamic value) {
    if (value == null) return {};
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) return decoded;
        return {};
      } catch (e) {
        return {};
      }
    }
    if (value is Map<String, dynamic>) return value;
    return {};
  }

  /// Helper to parse BoundingBox from JSON or string
  static BoundingBox? _parseBoundingBox(dynamic value) {
    if (value == null) return null;
    
    try {
      if (value is String) {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) {
          return BoundingBox.fromJson(decoded);
        }
        return null;
      }
      if (value is Map<String, dynamic>) {
        return BoundingBox.fromJson(value);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Helper to parse PoseAngles from JSON or create default
  static PoseAngles _parsePoseAngles(dynamic value) {
    if (value == null) {
      return const PoseAngles(yaw: 0, pitch: 0, roll: 0, confidence: 0.5);
    }
    
    try {
      if (value is String) {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) {
          return PoseAngles.fromJson(decoded);
        }
        return const PoseAngles(yaw: 0, pitch: 0, roll: 0, confidence: 0.5);
      }
      if (value is Map<String, dynamic>) {
        return PoseAngles.fromJson(value);
      }
    } catch (e) {
      return const PoseAngles(yaw: 0, pitch: 0, roll: 0, confidence: 0.5);
    }
    
    return const PoseAngles(yaw: 0, pitch: 0, roll: 0, confidence: 0.5);
  }

  /// Helper to parse FaceMetrics from JSON or create default
  static FaceMetrics _parseFaceMetrics(dynamic value, dynamic boundingBoxValue) {
    // Create a default bounding box
    final defaultBoundingBox = _parseBoundingBox(boundingBoxValue) 
        ?? const BoundingBox(x: 0, y: 0, width: 100, height: 100);
    
    if (value == null) {
      return FaceMetrics(
        boundingBox: defaultBoundingBox,
        faceSize: 0.5,
        sharpnessScore: 0.5,
        lightingScore: 0.5,
        symmetryScore: 0.5,
        hasGlasses: false,
        hasHat: false,
        isSmiling: false,
      );
    }
    
    try {
      if (value is String) {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) {
          return FaceMetrics.fromJson(decoded);
        }
      }
      if (value is Map<String, dynamic>) {
        return FaceMetrics.fromJson(value);
      }
    } catch (e) {
      // Return default on parse error
    }
    
    return FaceMetrics(
      boundingBox: defaultBoundingBox,
      faceSize: 0.5,
      sharpnessScore: 0.5,
      lightingScore: 0.5,
      symmetryScore: 0.5,
      hasGlasses: false,
      hasHat: false,
      isSmiling: false,
    );
  }

  /// Helper to parse PoseType from string or int
  static PoseType _parsePoseType(dynamic value) {
    if (value == null) return PoseType.frontal;
    
    if (value is int) {
      // If it's an index, use values list
      if (value >= 0 && value < PoseType.values.length) {
        return PoseType.values[value];
      }
      return PoseType.frontal;
    }
    
    if (value is String) {
      // Try to match by name
      switch (value.toLowerCase()) {
        case 'frontal':
          return PoseType.frontal;
        case 'left_profile':
        case 'leftprofile':
          return PoseType.leftProfile;
        case 'right_profile':
        case 'rightprofile':
          return PoseType.rightProfile;
        case 'looking_up':
        case 'lookingup':
          return PoseType.lookingUp;
        case 'looking_down':
        case 'lookingdown':
          return PoseType.lookingDown;
        default:
          return PoseType.frontal;
      }
    }
    
    return PoseType.frontal;
  }

  @override
  String toString() {
    return 'SelectedFrame(id: $id, sessionId: $sessionId, imageFilePath: $imageFilePath, '
           'timestampMs: $timestampMs, qualityScore: $qualityScore, '
           'poseAngles: $poseAngles, faceMetrics: $faceMetrics, '
           'extractedAt: $extractedAt, boundingBox: $boundingBox, metadata: $metadata)';
  }
}