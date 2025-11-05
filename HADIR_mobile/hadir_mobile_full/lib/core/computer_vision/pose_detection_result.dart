import 'package:equatable/equatable.dart';
import 'pose_angles.dart';
import 'face_metrics.dart';
import 'bounding_box.dart';
import 'keypoint.dart';
import 'pose_type.dart';

class PoseDetectionResult extends Equatable {
  final PoseType poseType;
  final List<Keypoint> keypoints;
  final PoseAngles? angles;
  final FaceMetrics? faceMetrics;
  final BoundingBox? boundingBox;
  final DateTime timestamp;
  final double confidence;

  const PoseDetectionResult({
    required this.poseType,
    this.keypoints = const [],
    this.angles,
    this.faceMetrics,
    this.boundingBox,
    required this.timestamp,
    this.confidence = 1.0,
  });

  @override
  List<Object?> get props => [poseType, keypoints, angles, faceMetrics, boundingBox, timestamp, confidence];

  Map<String, dynamic> toJson() => {
        'poseType': poseType.index,
        'keypoints': keypoints.map((k) => k.toJson()).toList(),
        'angles': angles?.toJson(),
        'faceMetrics': faceMetrics?.toJson(),
        'boundingBox': boundingBox?.toJson(),
        'timestamp': timestamp.toIso8601String(),
        'confidence': confidence,
      };

  factory PoseDetectionResult.fromJson(Map<String, dynamic> json) => PoseDetectionResult(
        poseType: PoseType.values[json['poseType'] as int],
        keypoints: (json['keypoints'] as List<dynamic>?)
                ?.map((e) => Keypoint.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        angles: json['angles'] != null ? PoseAngles.fromJson(json['angles'] as Map<String, dynamic>) : null,
        faceMetrics: json['faceMetrics'] != null ? FaceMetrics.fromJson(json['faceMetrics'] as Map<String, dynamic>) : null,
        boundingBox: json['boundingBox'] != null ? BoundingBox.fromJson(json['boundingBox'] as Map<String, dynamic>) : null,
        timestamp: DateTime.parse(json['timestamp'] as String),
        confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      );
}
