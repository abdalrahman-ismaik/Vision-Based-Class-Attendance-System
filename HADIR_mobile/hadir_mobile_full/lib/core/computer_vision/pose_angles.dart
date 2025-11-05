import 'package:equatable/equatable.dart';

/// Class representing pose angles for head orientation
class PoseAngles extends Equatable {
  const PoseAngles({
    required this.yaw,
    required this.pitch,
    required this.roll,
    required this.confidence,
  });

  /// Yaw angle (rotation around Y-axis, side-to-side)
  final double yaw;

  /// Pitch angle (rotation around X-axis, up-and-down)
  final double pitch;

  /// Roll angle (rotation around Z-axis, tilting)
  final double roll;

  /// Confidence score of the pose estimation (0.0 to 1.0)
  final double confidence;

  @override
  List<Object?> get props => [yaw, pitch, roll, confidence];

  /// Create a copy with updated values
  PoseAngles copyWith({
    double? yaw,
    double? pitch,
    double? roll,
    double? confidence,
  }) {
    return PoseAngles(
      yaw: yaw ?? this.yaw,
      pitch: pitch ?? this.pitch,
      roll: roll ?? this.roll,
      confidence: confidence ?? this.confidence,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'yaw': yaw,
      'pitch': pitch,
      'roll': roll,
      'confidence': confidence,
    };
  }

  /// Create from JSON
  factory PoseAngles.fromJson(Map<String, dynamic> json) {
    return PoseAngles(
      yaw: (json['yaw'] as num).toDouble(),
      pitch: (json['pitch'] as num).toDouble(),
      roll: (json['roll'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  @override
  String toString() {
    return 'PoseAngles(yaw: $yaw, pitch: $pitch, roll: $roll, confidence: $confidence)';
  }
}