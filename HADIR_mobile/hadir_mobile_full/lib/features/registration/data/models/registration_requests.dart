/// Registration request models for API communication
/// Contains request DTOs for registration workflow operations
library;

/// Request model for starting a new registration session
class StartRegistrationRequest {
  final String studentId;
  final String administratorId;
  final List<String> poseTargets;
  final Map<String, dynamic> qualityThresholds;
  final bool autoValidate;

  const StartRegistrationRequest({
    required this.studentId,
    required this.administratorId,
    required this.poseTargets,
    required this.qualityThresholds,
    this.autoValidate = true,
  });

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'administratorId': administratorId,
    'poseTargets': poseTargets,
    'qualityThresholds': qualityThresholds,
    'autoValidate': autoValidate,
  };

  factory StartRegistrationRequest.fromJson(Map<String, dynamic> json) =>
      StartRegistrationRequest(
        studentId: json['studentId'] as String,
        administratorId: json['administratorId'] as String,
        poseTargets: List<String>.from(json['poseTargets'] as List),
        qualityThresholds: json['qualityThresholds'] as Map<String, dynamic>,
        autoValidate: json['autoValidate'] as bool? ?? true,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StartRegistrationRequest &&
        other.studentId == studentId &&
        other.administratorId == administratorId &&
        other.poseTargets.toString() == poseTargets.toString() &&
        other.qualityThresholds.toString() == qualityThresholds.toString() &&
        other.autoValidate == autoValidate;
  }

  @override
  int get hashCode => Object.hash(
    studentId,
    administratorId,
    poseTargets,
    qualityThresholds,
    autoValidate,
  );
}

/// Request model for capturing a frame during registration
class CaptureFrameRequest {
  final String sessionId;
  final String poseType;
  final List<int> imageData;
  final Map<String, dynamic> metadata;
  final double? qualityThreshold;

  const CaptureFrameRequest({
    required this.sessionId,
    required this.poseType,
    required this.imageData,
    required this.metadata,
    this.qualityThreshold,
  });

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'poseType': poseType,
    'imageData': imageData,
    'metadata': metadata,
    if (qualityThreshold != null) 'qualityThreshold': qualityThreshold,
  };

  factory CaptureFrameRequest.fromJson(Map<String, dynamic> json) =>
      CaptureFrameRequest(
        sessionId: json['sessionId'] as String,
        poseType: json['poseType'] as String,
        imageData: List<int>.from(json['imageData'] as List),
        metadata: json['metadata'] as Map<String, dynamic>,
        qualityThreshold: json['qualityThreshold'] as double?,
      );
}

/// Request model for completing a registration session
class CompleteRegistrationRequest {
  final String sessionId;
  final List<String> selectedFrameIds;
  final Map<String, dynamic> finalValidation;
  final bool generateEmbedding;

  const CompleteRegistrationRequest({
    required this.sessionId,
    required this.selectedFrameIds,
    required this.finalValidation,
    this.generateEmbedding = true,
  });

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'selectedFrameIds': selectedFrameIds,
    'finalValidation': finalValidation,
    'generateEmbedding': generateEmbedding,
  };

  factory CompleteRegistrationRequest.fromJson(Map<String, dynamic> json) =>
      CompleteRegistrationRequest(
        sessionId: json['sessionId'] as String,
        selectedFrameIds: List<String>.from(json['selectedFrameIds'] as List),
        finalValidation: json['finalValidation'] as Map<String, dynamic>,
        generateEmbedding: json['generateEmbedding'] as bool? ?? true,
      );
}