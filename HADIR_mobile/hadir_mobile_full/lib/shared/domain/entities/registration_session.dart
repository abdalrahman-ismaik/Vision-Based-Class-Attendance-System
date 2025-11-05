import 'package:equatable/equatable.dart';
import 'captured_frame.dart';
import 'selected_frame.dart';
import '../../../core/computer_vision/pose_type.dart';

/// Enumeration for registration session status
enum SessionStatus {
  /// Initial state - capturing images
  capturingInProgress,
  /// Image capture completed successfully
  captureCompleted,
  /// Frame selection in progress
  selectionInProgress,
  /// Frame selection completed - registration finished
  completed,
  /// Session failed during capture or selection
  failed,
  /// Session expired (took too long)
  expired,
  /// Session was cancelled by user
  cancelled;

  @override
  String toString() {
    switch (this) {
      case SessionStatus.capturingInProgress:
        return 'Capturing Images';
      case SessionStatus.captureCompleted:
        return 'Capture Completed';
      case SessionStatus.selectionInProgress:
        return 'Selecting Frames';
      case SessionStatus.completed:
        return 'Completed';
      case SessionStatus.failed:
        return 'Failed';
      case SessionStatus.expired:
        return 'Expired';
      case SessionStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Check if session is in capture phase
  bool get isCapturing => this == SessionStatus.capturingInProgress;

  /// Check if capture is done
  bool get isCaptureComplete => this == SessionStatus.captureCompleted || 
                                 this == SessionStatus.selectionInProgress || 
                                 this == SessionStatus.completed;

  /// Check if selection is in progress
  bool get isSelecting => this == SessionStatus.selectionInProgress;

  /// Check if session is finalized
  bool get isFinalized => this == SessionStatus.completed || 
                          this == SessionStatus.failed || 
                          this == SessionStatus.expired || 
                          this == SessionStatus.cancelled;
}

// PoseType is imported from selected_frame.dart

/// Domain entity representing a registration session for capturing student face data
class RegistrationSession extends Equatable {
  RegistrationSession({
    required this.id,
    required this.studentId,
    required this.administratorId,
    required this.videoFilePath,
    required this.status,
    required this.startedAt,
    this.completedAt,
    required this.videoDurationMs,
    required this.totalFramesProcessed,
    required this.capturedFramesCount,
    required this.selectedFramesCount,
    required this.overallQualityScore,
    required this.poseCoveragePercentage,
    this.capturedFrames = const [],
    this.selectedFrames = const [],
    this.currentPoseIndex = 0,
    this.maxRetries = 3,
    this.retryCount = 0,
    this.metadata = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Unique identifier for the registration session
  final String id;
  /// ID of the student this session belongs to
  final String studentId;
  /// ID of the administrator who initiated the session
  final String administratorId;
  /// Path to the video file for this session
  final String videoFilePath;
  /// Current status of the registration session
  final SessionStatus status;
  /// Duration of the video in milliseconds
  final int videoDurationMs;
  /// Total number of frames processed
  final int totalFramesProcessed;
  /// Number of captured frames (raw captures before selection)
  final int capturedFramesCount;
  /// Number of selected frames (final selected after processing)
  final int selectedFramesCount;
  /// Overall quality score (0.0 to 1.0)
  final double overallQualityScore;
  /// Pose coverage percentage (0.0 to 100.0)
  final double poseCoveragePercentage;
  /// When the registration session was started
  final DateTime startedAt;
  /// When the registration session was completed (if completed)
  final DateTime? completedAt;
  /// List of captured frames during the session (raw captures)
  final List<CapturedFrame> capturedFrames;
  /// List of selected frames after frame selection process
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
    return capturedFrames.length >= requiredPoses.length &&
           requiredPoses.every((pose) => 
               capturedFrames.any((frame) => frame.poseType == pose));
  }

  /// Check if frame selection is complete
  bool get isFrameSelectionComplete {
    return selectedFrames.length >= requiredPoses.length &&
           requiredPoses.every((pose) => 
               selectedFrames.any((frame) => frame.poseType == pose));
  }

  /// Check if session is still active and can accept more captures
  bool get canCapture {
    return status == SessionStatus.capturingInProgress && 
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

  /// Get capture progress percentage (0.0 to 1.0)
  double get captureProgress {
    if (capturedFrames.isEmpty) return 0.0;
    return capturedFrames.length / requiredPoses.length;
  }

  /// Get selection progress percentage (0.0 to 1.0)
  double get selectionProgress {
    if (selectedFrames.isEmpty) return 0.0;
    return selectedFrames.length / requiredPoses.length;
  }

  /// Get overall progress percentage (0.0 to 1.0)
  double get progress {
    // If capture is not complete, return capture progress
    if (!status.isCaptureComplete) {
      return captureProgress * 0.5; // Capture is 50% of total progress
    }
    // If capture is complete, add selection progress
    return 0.5 + (selectionProgress * 0.5);
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
           status == SessionStatus.capturingInProgress;
  }

  /// Create a copy of this session with updated fields
  RegistrationSession copyWith({
    String? id,
    String? studentId,
    String? administratorId,
    String? videoFilePath,
    SessionStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    int? videoDurationMs,
    int? totalFramesProcessed,
    int? capturedFramesCount,
    int? selectedFramesCount,
    double? overallQualityScore,
    double? poseCoveragePercentage,
    List<CapturedFrame>? capturedFrames,
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
      administratorId: administratorId ?? this.administratorId,
      videoFilePath: videoFilePath ?? this.videoFilePath,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      videoDurationMs: videoDurationMs ?? this.videoDurationMs,
      totalFramesProcessed: totalFramesProcessed ?? this.totalFramesProcessed,
      capturedFramesCount: capturedFramesCount ?? this.capturedFramesCount,
      selectedFramesCount: selectedFramesCount ?? this.selectedFramesCount,
      overallQualityScore: overallQualityScore ?? this.overallQualityScore,
      poseCoveragePercentage: poseCoveragePercentage ?? this.poseCoveragePercentage,
      capturedFrames: capturedFrames ?? this.capturedFrames,
      selectedFrames: selectedFrames ?? this.selectedFrames,
      currentPoseIndex: currentPoseIndex ?? this.currentPoseIndex,
      maxRetries: maxRetries ?? this.maxRetries,
      retryCount: retryCount ?? this.retryCount,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Add a captured frame to the session during capture phase
  RegistrationSession addCapturedFrame(CapturedFrame frame) {
    final updatedFrames = List<CapturedFrame>.from(capturedFrames)..add(frame);
    final nextIndex = currentPoseIndex < requiredPoses.length - 1 
        ? currentPoseIndex + 1 
        : currentPoseIndex;
    
    final newStatus = updatedFrames.length >= requiredPoses.length
        ? SessionStatus.captureCompleted
        : status;
    
    return copyWith(
      capturedFrames: updatedFrames,
      capturedFramesCount: updatedFrames.length,
      currentPoseIndex: nextIndex,
      status: newStatus,
      completedAt: newStatus == SessionStatus.captureCompleted 
          ? DateTime.now() 
          : completedAt,
    );
  }

  /// Add selected frames after frame selection process
  RegistrationSession addSelectedFrames(List<SelectedFrame> frames) {
    final updatedFrames = List<SelectedFrame>.from(selectedFrames)..addAll(frames);
    
    final newStatus = SessionStatus.completed;
    
    return copyWith(
      selectedFrames: updatedFrames,
      selectedFramesCount: updatedFrames.length,
      status: newStatus,
      completedAt: DateTime.now(),
    );
  }

  /// Mark capture as complete and ready for selection
  RegistrationSession markCaptureComplete() {
    return copyWith(
      status: SessionStatus.captureCompleted,
      completedAt: DateTime.now(),
    );
  }

  /// Start frame selection process
  RegistrationSession startFrameSelection() {
    if (!status.isCaptureComplete) {
      throw StateError('Cannot start frame selection before capture is complete');
    }
    return copyWith(
      status: SessionStatus.selectionInProgress,
    );
  }

  /// Increment retry count
  RegistrationSession incrementRetry() {
    final newRetryCount = retryCount + 1;
    final newStatus = newRetryCount >= maxRetries 
        ? SessionStatus.failed 
        : status;
    
    return copyWith(
      retryCount: newRetryCount,
      status: newStatus,
      completedAt: newStatus == SessionStatus.failed 
          ? DateTime.now() 
          : completedAt,
    );
  }

  /// Mark session as expired
  RegistrationSession markExpired() {
    return copyWith(
      status: SessionStatus.expired,
      completedAt: DateTime.now(),
    );
  }

  /// Mark session as cancelled
  RegistrationSession markCancelled() {
    return copyWith(
      status: SessionStatus.cancelled,
      completedAt: DateTime.now(),
    );
  }

  /// Convert session to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'administratorId': administratorId,
      'videoFilePath': videoFilePath,
      'status': status.name,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'videoDurationMs': videoDurationMs,
      'totalFramesProcessed': totalFramesProcessed,
      'capturedFramesCount': capturedFramesCount,
      'selectedFramesCount': selectedFramesCount,
      'overallQualityScore': overallQualityScore,
      'poseCoveragePercentage': poseCoveragePercentage,
      'capturedFrames': capturedFrames.map((frame) => frame.toJson()).toList(),
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
      administratorId: json['administratorId'] as String,
      videoFilePath: json['videoFilePath'] as String,
      status: SessionStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String) 
          : null,
      videoDurationMs: json['videoDurationMs'] as int,
      totalFramesProcessed: json['totalFramesProcessed'] as int,
      capturedFramesCount: json['capturedFramesCount'] as int? ?? 0,
      selectedFramesCount: json['selectedFramesCount'] as int,
      overallQualityScore: (json['overallQualityScore'] as num).toDouble(),
      poseCoveragePercentage: (json['poseCoveragePercentage'] as num).toDouble(),
      capturedFrames: (json['capturedFrames'] as List<dynamic>?)
          ?.map((e) => CapturedFrame.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
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
      throw ArgumentError('Registration session ID must follow format: REG1000#####');
    }

    // Validate student ID format
    if (!RegExp(r'^STU\d{8}$').hasMatch(studentId)) {
      throw ArgumentError('Student ID must follow format: 1000#####');
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
    capturedFrames,
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
