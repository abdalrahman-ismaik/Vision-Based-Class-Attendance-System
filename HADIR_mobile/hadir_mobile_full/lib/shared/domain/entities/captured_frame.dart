import 'package:equatable/equatable.dart';
import '../../../core/computer_vision/pose_angles.dart';
import '../../../core/computer_vision/bounding_box.dart';
import '../../../core/computer_vision/face_metrics.dart';
import '../../../core/computer_vision/pose_type.dart';
import 'selected_frame.dart';

/// Domain entity representing a raw captured frame during registration
/// This represents a frame that has been captured but not yet selected as final
class CapturedFrame extends Equatable {
  const CapturedFrame({
    required this.id,
    required this.sessionId,
    required this.imageFilePath,
    required this.timestampMs,
    required this.qualityScore,
    required this.poseAngles,
    required this.faceMetrics,
    required this.capturedAt,
    this.boundingBox,
    this.metadata = const {},
    PoseType? poseType,
    this.confidenceScore = 1.0,
    this.qualityMetrics,
  }) : poseType = poseType ?? PoseType.frontal;

  /// Unique identifier for the captured frame
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

  /// Optional quality metrics object
  final dynamic qualityMetrics;

  /// When the frame was captured
  final DateTime capturedAt;

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
    capturedAt,
    boundingBox,
    poseType,
    confidenceScore,
    qualityMetrics,
    metadata,
  ];

  /// Create a copy with updated fields
  CapturedFrame copyWith({
    String? id,
    String? sessionId,
    String? imageFilePath,
    int? timestampMs,
    double? qualityScore,
    PoseAngles? poseAngles,
    FaceMetrics? faceMetrics,
    DateTime? capturedAt,
    BoundingBox? boundingBox,
    Map<String, dynamic>? metadata,
    PoseType? poseType,
    double? confidenceScore,
    dynamic qualityMetrics,
  }) {
    return CapturedFrame(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      imageFilePath: imageFilePath ?? this.imageFilePath,
      timestampMs: timestampMs ?? this.timestampMs,
      qualityScore: qualityScore ?? this.qualityScore,
      poseAngles: poseAngles ?? this.poseAngles,
      faceMetrics: faceMetrics ?? this.faceMetrics,
      capturedAt: capturedAt ?? this.capturedAt,
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
      'capturedAt': capturedAt.toIso8601String(),
      'boundingBox': boundingBox?.toJson(),
      'poseType': poseType.index,
      'confidenceScore': confidenceScore,
      'qualityMetrics': qualityMetrics,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory CapturedFrame.fromJson(Map<String, dynamic> json) {
    return CapturedFrame(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      imageFilePath: json['imageFilePath'] as String,
      timestampMs: json['timestampMs'] as int,
      qualityScore: (json['qualityScore'] as num).toDouble(),
      poseAngles: PoseAngles.fromJson(json['poseAngles'] as Map<String, dynamic>),
      faceMetrics: FaceMetrics.fromJson(json['faceMetrics'] as Map<String, dynamic>),
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      boundingBox: json['boundingBox'] != null 
          ? BoundingBox.fromJson(json['boundingBox'] as Map<String, dynamic>)
          : null,
      poseType: json['poseType'] != null ? PoseType.values[json['poseType'] as int] : PoseType.frontal,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 1.0,
      qualityMetrics: json['qualityMetrics'],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert to SelectedFrame after selection
  SelectedFrame toSelectedFrame({
    required String selectionId,
    required DateTime extractedAt,
  }) {
    return SelectedFrame(
      id: selectionId,
      sessionId: sessionId,
      imageFilePath: imageFilePath,
      timestampMs: timestampMs,
      qualityScore: qualityScore,
      poseAngles: poseAngles,
      faceMetrics: faceMetrics,
      extractedAt: extractedAt,
      boundingBox: boundingBox,
      metadata: metadata,
      poseType: poseType,
      confidenceScore: confidenceScore,
      qualityMetrics: qualityMetrics,
    );
  }

  @override
  String toString() {
    return 'CapturedFrame(id: $id, sessionId: $sessionId, imageFilePath: $imageFilePath, '
           'timestampMs: $timestampMs, qualityScore: $qualityScore, '
           'poseType: ${poseType.nameLabel}, confidenceScore: $confidenceScore)';
  }
}
