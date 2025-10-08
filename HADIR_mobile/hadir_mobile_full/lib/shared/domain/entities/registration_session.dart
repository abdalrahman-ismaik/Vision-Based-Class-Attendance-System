import 'package:equatable/equatable.dart';
import 'selected_frame.dart';

/// Enumeration for registration session status
enum RegistrationSessionStatus {
  active,
  completed,
  failed,
  expired,
  cancelled;

  @override
  String toString() {
    switch (this) {
      case RegistrationSessionStatus.active:
        return 'Active';
      case RegistrationSessionStatus.completed:
        return 'Completed';
      case RegistrationSessionStatus.failed:
        return 'Failed';
      case RegistrationSessionStatus.expired:
        return 'Expired';
      case RegistrationSessionStatus.cancelled:
        return 'Cancelled';
    }
  }
}

// PoseType is imported from selected_frame.dart

/// Domain entity representing a registration session for capturing student face data
class RegistrationSession extends Equatable {
  const RegistrationSession({
    required this.id,
    required this.studentId,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.selectedFrames = const [],
    this.currentPoseIndex = 0,
    this.maxRetries = 3,
    this.retryCount = 0,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique identifier for the registration session
  final String id;

  /// ID of the student this session belongs to
  final String studentId;

  /// Current status of the registration session
  final RegistrationSessionStatus status;

  /// When the registration session was started
  final DateTime startedAt;

  /// When the registration session was completed (if completed)
  final DateTime? completedAt;

  /// List of selected frames captured during the session
  final List<SelectedFrame> selectedFrames;

  /// Current pose index being captured (0-4 for the 5 required poses)
  final int currentPoseIndex;

  /// Maximum number of retries allowed for failed captures
  final int maxRetries;

  /// Current retry count for failed captures
  final int retryCount;

  /// Additional metadata for the session
  final Map<String, dynamic> metadata;

  /// When the session record was created
  final DateTime createdAt;

  /// When the session record was last updated
  final DateTime updatedAt;

  /// Get all required pose types
  static List<PoseType> get requiredPoses => PoseType.values;

  /// Get the current pose type being captured
  PoseType get currentPose {
    if (currentPoseIndex < 0 || currentPoseIndex >= requiredPoses.length) {
      return PoseType.frontal;
    }
    return requiredPoses[currentPoseIndex];
  }

  /// Get the next pose type to be captured
  PoseType? get nextPose {
    final nextIndex = currentPoseIndex + 1;
    if (nextIndex >= requiredPoses.length) {
      return null;
    }
    return requiredPoses[nextIndex];
  }

  /// Check if all required poses have been captured
  bool get isAllPosesCaptured {
    return selectedFrames.length >= requiredPoses.length &&
           requiredPoses.every((pose) => 
               selectedFrames.any((frame) => frame.poseType == pose));
  }

  /// Check if session is still active and can accept more captures
  bool get canCapture {
    return status == RegistrationSessionStatus.active && 
           !isAllPosesCaptured &&
           retryCount < maxRetries;
  }

  /// Check if session has failed due to too many retries
  bool get hasExceededRetries => retryCount >= maxRetries;

  /// Get session duration
  Duration get duration {
    final endTime = completedAt ?? DateTime.now();
    return endTime.difference(startedAt);
  }

  /// Get progress percentage (0.0 to 1.0)
  double get progress {
    if (selectedFrames.isEmpty) return 0.0;
    return selectedFrames.length / requiredPoses.length;
  }

  /// Get frames for a specific pose type
  List<SelectedFrame> getFramesForPose(PoseType poseType) {
    return selectedFrames.where((frame) => frame.poseType == poseType).toList();
  }

  /// Get the best frame for a specific pose type (highest confidence)
  SelectedFrame? getBestFrameForPose(PoseType poseType) {
    final frames = getFramesForPose(poseType);
    if (frames.isEmpty) return null;
    
    frames.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
    return frames.first;
  }

  /// Check if session is expired (more than 30 minutes old)
  bool get isExpired {
    final now = DateTime.now();
    const maxDuration = Duration(minutes: 30);
    return now.difference(startedAt) > maxDuration && 
           status == RegistrationSessionStatus.active;
  }

  /// Create a copy of this session with updated fields
  RegistrationSession copyWith({
    String? id,
    String? studentId,
    RegistrationSessionStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    List<SelectedFrame>? selectedFrames,
    int? currentPoseIndex,
    int? maxRetries,
    int? retryCount,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RegistrationSession(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      selectedFrames: selectedFrames ?? this.selectedFrames,
      currentPoseIndex: currentPoseIndex ?? this.currentPoseIndex,
      maxRetries: maxRetries ?? this.maxRetries,
      retryCount: retryCount ?? this.retryCount,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Add a selected frame to the session
  RegistrationSession addFrame(SelectedFrame frame) {
    final updatedFrames = List<SelectedFrame>.from(selectedFrames)..add(frame);
    final nextIndex = currentPoseIndex < requiredPoses.length - 1 
        ? currentPoseIndex + 1 
        : currentPoseIndex;
    
    final newStatus = updatedFrames.length >= requiredPoses.length
        ? RegistrationSessionStatus.completed
        : status;
    
    return copyWith(
      selectedFrames: updatedFrames,
      currentPoseIndex: nextIndex,
      status: newStatus,
      completedAt: newStatus == RegistrationSessionStatus.completed 
          ? DateTime.now() 
          : completedAt,
    );
  }

  /// Increment retry count
  RegistrationSession incrementRetry() {
    final newRetryCount = retryCount + 1;
    final newStatus = newRetryCount >= maxRetries 
        ? RegistrationSessionStatus.failed 
        : status;
    
    return copyWith(
      retryCount: newRetryCount,
      status: newStatus,
      completedAt: newStatus == RegistrationSessionStatus.failed 
          ? DateTime.now() 
          : completedAt,
    );
  }

  /// Mark session as expired
  RegistrationSession markExpired() {
    return copyWith(
      status: RegistrationSessionStatus.expired,
      completedAt: DateTime.now(),
    );
  }

  /// Mark session as cancelled
  RegistrationSession markCancelled() {
    return copyWith(
      status: RegistrationSessionStatus.cancelled,
      completedAt: DateTime.now(),
    );
  }

  /// Convert session to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'status': status.name,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'selectedFrames': selectedFrames.map((frame) => frame.toJson()).toList(),
      'currentPoseIndex': currentPoseIndex,
      'maxRetries': maxRetries,
      'retryCount': retryCount,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create session from JSON
  factory RegistrationSession.fromJson(Map<String, dynamic> json) {
    return RegistrationSession(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      status: RegistrationSessionStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String) 
          : null,
      selectedFrames: (json['selectedFrames'] as List<dynamic>?)
          ?.map((e) => SelectedFrame.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      currentPoseIndex: json['currentPoseIndex'] as int? ?? 0,
      maxRetries: json['maxRetries'] as int? ?? 3,
      retryCount: json['retryCount'] as int? ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Validate session data
  static void validate({
    required String id,
    required String studentId,
    required DateTime startedAt,
    int maxRetries = 3,
  }) {
    // Validate ID format (REG followed by 8 digits)
    if (!RegExp(r'^REG\d{8}$').hasMatch(id)) {
      throw ArgumentError('Registration session ID must follow format: REG########');
    }

    // Validate student ID format
    if (!RegExp(r'^STU\d{8}$').hasMatch(studentId)) {
      throw ArgumentError('Student ID must follow format: STU########');
    }

    // Validate start time
    final now = DateTime.now();
    if (startedAt.isAfter(now)) {
      throw ArgumentError('Start time cannot be in the future');
    }

    // Validate max retries
    if (maxRetries < 1 || maxRetries > 10) {
      throw ArgumentError('Max retries must be between 1 and 10');
    }
  }

  @override
  List<Object?> get props => [
    id,
    studentId,
    status,
    startedAt,
    completedAt,
    selectedFrames,
    currentPoseIndex,
    maxRetries,
    retryCount,
    metadata,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'RegistrationSession(id: $id, studentId: $studentId, status: $status, progress: ${(progress * 100).toStringAsFixed(1)}%)';
  }
}