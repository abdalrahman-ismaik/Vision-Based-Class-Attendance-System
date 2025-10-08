/// Registration-specific exceptions for the HADIR mobile application
/// Provides detailed error handling for registration workflow operations
library;

import 'package:hadir_mobile_full/shared/domain/exceptions/hadir_exceptions.dart';

/// Exception thrown when attempting to create a registration session for a student
/// who already has an active session
class DuplicateSessionException extends HadirException {
  const DuplicateSessionException(String message) : super(message);
}

/// Exception thrown when registration session state is invalid for the requested operation
class InvalidSessionStateException extends HadirException {
  const InvalidSessionStateException(String message) : super(message);
}

/// Exception thrown when registration session is incomplete and cannot be processed
class IncompleteSessionException extends HadirException {
  const IncompleteSessionException(String message) : super(message);
}

/// Exception thrown when captured frame quality is below acceptable threshold
class LowQualityFrameException extends HadirException {
  const LowQualityFrameException(String message) : super(message);
}

/// Exception thrown when pose angle detection fails or is incorrect
class IncorrectPoseAngleException extends HadirException {
  const IncorrectPoseAngleException(String message) : super(message);
}

/// Exception thrown when quality threshold validation fails
class QualityThresholdException extends HadirException {
  const QualityThresholdException(String message) : super(message);
}

/// Exception thrown when concurrent operations conflict during registration
class ConcurrencyException extends HadirException {
  const ConcurrencyException(String message) : super(message);
}

/// Exception thrown when memory is insufficient for registration processing
class MemoryException extends HadirException {
  const MemoryException(String message) : super(message);
}

/// Exception thrown when YOLOv7-Pose detection processing times out
class ProcessingTimeoutException extends HadirException {
  const ProcessingTimeoutException(String message) : super(message);
}

/// Pose target enumeration for registration workflow
enum PoseTarget {
  frontalFace,
  leftProfile,
  rightProfile,
  upwardAngle,
  downwardAngle;

  String get displayName {
    switch (this) {
      case PoseTarget.frontalFace:
        return 'Frontal Face';
      case PoseTarget.leftProfile:
        return 'Left Profile';
      case PoseTarget.rightProfile:
        return 'Right Profile';
      case PoseTarget.upwardAngle:
        return 'Looking Up';
      case PoseTarget.downwardAngle:
        return 'Looking Down';
    }
  }
}

/// Session status enumeration for tracking registration progress
enum SessionStatus {
  pending,
  inProgress,
  completed,
  failed,
  cancelled;

  String get displayName {
    switch (this) {
      case SessionStatus.pending:
        return 'Pending';
      case SessionStatus.inProgress:
        return 'In Progress';
      case SessionStatus.completed:
        return 'Completed';
      case SessionStatus.failed:
        return 'Failed';
      case SessionStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Quality metrics for registration session tracking
class QualityMetrics {
  final double averageConfidence;
  final double minimumConfidence;
  final int totalFrames;
  final int acceptedFrames;
  final Map<String, double> poseSpecificScores;

  const QualityMetrics({
    required this.averageConfidence,
    required this.minimumConfidence,
    required this.totalFrames,
    required this.acceptedFrames,
    required this.poseSpecificScores,
  });

  factory QualityMetrics.initial() => const QualityMetrics(
    averageConfidence: 0.0,
    minimumConfidence: 0.0,
    totalFrames: 0,
    acceptedFrames: 0,
    poseSpecificScores: {},
  );

  QualityMetrics copyWith({
    double? averageConfidence,
    double? minimumConfidence,
    int? totalFrames,
    int? acceptedFrames,
    Map<String, double>? poseSpecificScores,
  }) => QualityMetrics(
    averageConfidence: averageConfidence ?? this.averageConfidence,
    minimumConfidence: minimumConfidence ?? this.minimumConfidence,
    totalFrames: totalFrames ?? this.totalFrames,
    acceptedFrames: acceptedFrames ?? this.acceptedFrames,
    poseSpecificScores: poseSpecificScores ?? this.poseSpecificScores,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QualityMetrics &&
        other.averageConfidence == averageConfidence &&
        other.minimumConfidence == minimumConfidence &&
        other.totalFrames == totalFrames &&
        other.acceptedFrames == acceptedFrames &&
        other.poseSpecificScores.toString() == poseSpecificScores.toString();
  }

  @override
  int get hashCode => Object.hash(
    averageConfidence,
    minimumConfidence,
    totalFrames,
    acceptedFrames,
    poseSpecificScores,
  );
}