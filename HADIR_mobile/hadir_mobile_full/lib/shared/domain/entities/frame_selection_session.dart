import 'package:equatable/equatable.dart';
import 'captured_frame.dart';
import 'selected_frame.dart';
import '../../../core/computer_vision/pose_type.dart';

/// Enumeration for frame selection session status
enum SelectionStatus {
  /// Selection process is in progress
  inProgress,
  /// Selection completed successfully
  completed,
  /// Selection failed
  failed,
  /// Selection cancelled
  cancelled;

  @override
  String toString() {
    switch (this) {
      case SelectionStatus.inProgress:
        return 'In Progress';
      case SelectionStatus.completed:
        return 'Completed';
      case SelectionStatus.failed:
        return 'Failed';
      case SelectionStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Domain entity representing a frame selection session
/// This represents the process of selecting optimal frames from captured images
class FrameSelectionSession extends Equatable {
  FrameSelectionSession({
    required this.id,
    required this.registrationSessionId,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.candidateFrames = const [],
    this.selectedFrames = const [],
    this.requiredPoses = const [],
    this.qualityThreshold = 0.7,
    this.framesPerPose = 3,
    this.selectionMetrics,
    this.metadata = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Unique identifier for the selection session
  final String id;

  /// ID of the registration session this selection belongs to
  final String registrationSessionId;

  /// Current status of the selection session
  final SelectionStatus status;

  /// When the selection session was started
  final DateTime startedAt;

  /// When the selection session was completed (if completed)
  final DateTime? completedAt;

  /// List of candidate captured frames to select from
  final List<CapturedFrame> candidateFrames;

  /// List of selected frames after selection process
  final List<SelectedFrame> selectedFrames;

  /// Required pose types that must be covered
  final List<PoseType> requiredPoses;

  /// Quality threshold for frame selection (0.0 to 1.0)
  final double qualityThreshold;

  /// Number of frames to select per pose type
  final int framesPerPose;

  /// Metrics about the selection process
  final Map<String, dynamic>? selectionMetrics;

  /// Additional metadata
  final Map<String, dynamic> metadata;

  /// When the selection session record was created
  final DateTime createdAt;

  /// When the selection session record was last updated
  final DateTime updatedAt;

  /// Check if selection is complete
  bool get isComplete => status == SelectionStatus.completed;

  /// Check if selection has failed
  bool get isFailed => status == SelectionStatus.failed;

  /// Check if selection is in progress
  bool get isInProgress => status == SelectionStatus.inProgress;

  /// Get selection duration
  Duration get duration {
    final endTime = completedAt ?? DateTime.now();
    return endTime.difference(startedAt);
  }

  /// Get selection progress (0.0 to 1.0)
  double get progress {
    if (requiredPoses.isEmpty) return 0.0;
    return selectedFrames.length / (requiredPoses.length * framesPerPose);
  }

  /// Get coverage percentage of required poses
  double get poseCoverage {
    if (requiredPoses.isEmpty) return 0.0;
    final coveredPoses = requiredPoses.where((pose) =>
        selectedFrames.any((frame) => frame.poseType == pose)).length;
    return coveredPoses / requiredPoses.length;
  }

  /// Get average quality of selected frames
  double get averageQuality {
    if (selectedFrames.isEmpty) return 0.0;
    final totalQuality = selectedFrames
        .map((frame) => frame.qualityScore)
        .reduce((a, b) => a + b);
    return totalQuality / selectedFrames.length;
  }

  @override
  List<Object?> get props => [
    id,
    registrationSessionId,
    status,
    startedAt,
    completedAt,
    candidateFrames,
    selectedFrames,
    requiredPoses,
    qualityThreshold,
    framesPerPose,
    selectionMetrics,
    metadata,
    createdAt,
    updatedAt,
  ];

  /// Create a copy with updated fields
  FrameSelectionSession copyWith({
    String? id,
    String? registrationSessionId,
    SelectionStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    List<CapturedFrame>? candidateFrames,
    List<SelectedFrame>? selectedFrames,
    List<PoseType>? requiredPoses,
    double? qualityThreshold,
    int? framesPerPose,
    Map<String, dynamic>? selectionMetrics,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FrameSelectionSession(
      id: id ?? this.id,
      registrationSessionId: registrationSessionId ?? this.registrationSessionId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      candidateFrames: candidateFrames ?? this.candidateFrames,
      selectedFrames: selectedFrames ?? this.selectedFrames,
      requiredPoses: requiredPoses ?? this.requiredPoses,
      qualityThreshold: qualityThreshold ?? this.qualityThreshold,
      framesPerPose: framesPerPose ?? this.framesPerPose,
      selectionMetrics: selectionMetrics ?? this.selectionMetrics,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Mark selection as complete with selected frames
  FrameSelectionSession markComplete(
    List<SelectedFrame> selectedFrames,
    Map<String, dynamic> metrics,
  ) {
    return copyWith(
      selectedFrames: selectedFrames,
      selectionMetrics: metrics,
      status: SelectionStatus.completed,
      completedAt: DateTime.now(),
    );
  }

  /// Mark selection as failed
  FrameSelectionSession markFailed(String reason) {
    return copyWith(
      status: SelectionStatus.failed,
      completedAt: DateTime.now(),
      metadata: {...metadata, 'failure_reason': reason},
    );
  }

  /// Mark selection as cancelled
  FrameSelectionSession markCancelled() {
    return copyWith(
      status: SelectionStatus.cancelled,
      completedAt: DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'registrationSessionId': registrationSessionId,
      'status': status.name,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'candidateFrames': candidateFrames.map((frame) => frame.toJson()).toList(),
      'selectedFrames': selectedFrames.map((frame) => frame.toJson()).toList(),
      'requiredPoses': requiredPoses.map((pose) => pose.index).toList(),
      'qualityThreshold': qualityThreshold,
      'framesPerPose': framesPerPose,
      'selectionMetrics': selectionMetrics,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory FrameSelectionSession.fromJson(Map<String, dynamic> json) {
    return FrameSelectionSession(
      id: json['id'] as String,
      registrationSessionId: json['registrationSessionId'] as String,
      status: SelectionStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      candidateFrames: (json['candidateFrames'] as List<dynamic>?)
          ?.map((e) => CapturedFrame.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      selectedFrames: (json['selectedFrames'] as List<dynamic>?)
          ?.map((e) => SelectedFrame.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      requiredPoses: (json['requiredPoses'] as List<dynamic>?)
          ?.map((e) => PoseType.values[e as int])
          .toList() ?? [],
      qualityThreshold: (json['qualityThreshold'] as num?)?.toDouble() ?? 0.7,
      framesPerPose: json['framesPerPose'] as int? ?? 3,
      selectionMetrics: json['selectionMetrics'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  String toString() {
    return 'FrameSelectionSession(id: $id, registrationSessionId: $registrationSessionId, '
           'status: $status, progress: ${(progress * 100).toStringAsFixed(1)}%)';
  }
}
