/// Sync-related models for mobile-to-backend synchronization
/// 
/// These models define the data structures used during the sync process
/// between the HADIR mobile app and the backend face processing system.

/// Sync status enum - represents the current state of a student's sync
enum SyncStatus {
  /// Student has not been synced to backend yet
  notSynced('not_synced'),
  
  /// Sync is currently in progress (uploading data)
  syncing('syncing'),
  
  /// Successfully synced to backend (data received by server)
  synced('synced'),
  
  /// Sync failed (see sync_error for details)
  failed('failed');

  final String value;
  const SyncStatus(this.value);

  /// Convert string to SyncStatus enum
  static SyncStatus fromString(String? status) {
    switch (status) {
      case 'not_synced':
        return SyncStatus.notSynced;
      case 'syncing':
        return SyncStatus.syncing;
      case 'synced':
        return SyncStatus.synced;
      case 'failed':
        return SyncStatus.failed;
      default:
        return SyncStatus.notSynced;
    }
  }

  /// Get user-friendly display text
  String get displayText {
    switch (this) {
      case SyncStatus.notSynced:
        return 'Not Synced';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.failed:
        return 'Failed';
    }
  }

  /// Get icon name for UI display
  String get iconName {
    switch (this) {
      case SyncStatus.notSynced:
        return 'cloud_upload'; // Orange cloud
      case SyncStatus.syncing:
        return 'sync'; // Blue spinning
      case SyncStatus.synced:
        return 'cloud_done'; // Green check
      case SyncStatus.failed:
        return 'error'; // Red exclamation
    }
  }
}

/// Processing status enum - represents backend processing state
/// These values come from the backend's processing_status field
enum ProcessingStatus {
  /// Not yet sent to backend
  notStarted('not_started'),
  
  /// Backend is processing the images (face detection, etc.)
  pending('pending'),
  
  /// Backend completed processing successfully
  completed('completed'),
  
  /// Backend processing failed
  failed('failed');

  final String value;
  const ProcessingStatus(this.value);

  /// Convert string to ProcessingStatus enum
  static ProcessingStatus fromString(String? status) {
    switch (status) {
      case 'pending':
        return ProcessingStatus.pending;
      case 'completed':
        return ProcessingStatus.completed;
      case 'failed':
        return ProcessingStatus.failed;
      default:
        return ProcessingStatus.notStarted;
    }
  }

  /// Get user-friendly display text
  String get displayText {
    switch (this) {
      case ProcessingStatus.notStarted:
        return 'Not Started';
      case ProcessingStatus.pending:
        return 'Processing...';
      case ProcessingStatus.completed:
        return 'Ready';
      case ProcessingStatus.failed:
        return 'Failed';
    }
  }

  /// Get icon name for UI display
  String get iconName {
    switch (this) {
      case ProcessingStatus.notStarted:
        return 'schedule';
      case ProcessingStatus.pending:
        return 'hourglass_empty'; // Purple pulse
      case ProcessingStatus.completed:
        return 'check_circle'; // Green check
      case ProcessingStatus.failed:
        return 'cancel'; // Red X
    }
  }
}

/// Result of a sync operation
class SyncResult {
  /// Whether the sync was successful
  final bool success;
  
  /// Backend student ID if sync was successful
  final String? backendStudentId;
  
  /// Error message if sync failed
  final String? error;
  
  /// Additional metadata (response data, timing, etc.)
  final Map<String, dynamic>? metadata;
  
  /// Timestamp when sync completed
  final DateTime timestamp;

  SyncResult({
    required this.success,
    this.backendStudentId,
    this.error,
    this.metadata,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create a successful sync result
  factory SyncResult.success({
    required String backendStudentId,
    Map<String, dynamic>? metadata,
  }) {
    return SyncResult(
      success: true,
      backendStudentId: backendStudentId,
      metadata: metadata,
    );
  }

  /// Create a failed sync result
  factory SyncResult.failed({
    required String error,
    Map<String, dynamic>? metadata,
  }) {
    return SyncResult(
      success: false,
      error: error,
      metadata: metadata,
    );
  }

  @override
  String toString() {
    if (success) {
      return 'SyncResult(success: true, backendStudentId: $backendStudentId)';
    } else {
      return 'SyncResult(success: false, error: $error)';
    }
  }
}

/// Batch sync result for multiple students
class BatchSyncResult {
  /// Number of successful syncs
  final int successful;
  
  /// Number of failed syncs
  final int failed;
  
  /// Total students processed
  final int total;
  
  /// List of student IDs that succeeded
  final List<String> successfulIds;
  
  /// List of student IDs that failed
  final List<String> failedIds;
  
  /// Total duration of batch sync
  final Duration duration;

  BatchSyncResult({
    required this.successful,
    required this.failed,
    required this.successfulIds,
    required this.failedIds,
    required this.duration,
  }) : total = successful + failed;

  /// Success rate as percentage
  double get successRate => total > 0 ? (successful / total) * 100 : 0;

  @override
  String toString() {
    return 'BatchSyncResult(total: $total, successful: $successful, failed: $failed, rate: ${successRate.toStringAsFixed(1)}%)';
  }
}

/// Sync request payload for backend API
class SyncRequest {
  /// Student ID from mobile app
  final String studentId;
  
  /// Full name
  final String fullName;
  
  /// Email address
  final String email;
  
  /// Department
  final String department;
  
  /// Enrollment year
  final int? enrollmentYear;
  
  /// Image file path (local path on device)
  final String imagePath;
  
  /// Additional metadata
  final Map<String, dynamic>? metadata;

  SyncRequest({
    required this.studentId,
    required this.fullName,
    required this.email,
    required this.department,
    this.enrollmentYear,
    required this.imagePath,
    this.metadata,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'name': fullName,
      'email': email,
      'department': department,
      if (enrollmentYear != null) 'year': enrollmentYear,
      if (metadata != null) ...metadata!,
    };
  }

  @override
  String toString() {
    return 'SyncRequest(studentId: $studentId, name: $fullName, email: $email)';
  }
}

/// Sync error types for better error handling
enum SyncErrorType {
  /// Network connection issues (timeout, no internet, DNS failure)
  network,
  
  /// Backend server errors (500, 503, etc.)
  server,
  
  /// Client errors (400, 409, etc.)
  client,
  
  /// File/image related errors (missing file, corrupted image)
  file,
  
  /// Unknown/unexpected errors
  unknown;

  /// Get user-friendly error message
  String getUserMessage() {
    switch (this) {
      case SyncErrorType.network:
        return 'Network connection error. Please check your internet connection.';
      case SyncErrorType.server:
        return 'Server error. Please try again later.';
      case SyncErrorType.client:
        return 'Invalid data. Please check student information.';
      case SyncErrorType.file:
        return 'Image file error. Please re-capture the image.';
      case SyncErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Whether this error type should trigger automatic retry
  bool get shouldRetry {
    switch (this) {
      case SyncErrorType.network:
      case SyncErrorType.server:
        return true; // Network and server errors are retriable
      case SyncErrorType.client:
      case SyncErrorType.file:
      case SyncErrorType.unknown:
        return false; // Client/file errors need manual intervention
    }
  }
}

/// Sync error with type and context
class SyncError {
  /// Type of error
  final SyncErrorType type;
  
  /// Technical error message (for logging)
  final String message;
  
  /// User-friendly error message
  final String userMessage;
  
  /// Original exception (if any)
  final Exception? exception;
  
  /// HTTP status code (if applicable)
  final int? statusCode;

  SyncError({
    required this.type,
    required this.message,
    String? userMessage,
    this.exception,
    this.statusCode,
  }) : userMessage = userMessage ?? type.getUserMessage();

  /// Whether this error should trigger automatic retry
  bool get shouldRetry => type.shouldRetry;

  @override
  String toString() {
    return 'SyncError(type: $type, message: $message, statusCode: $statusCode)';
  }
}
