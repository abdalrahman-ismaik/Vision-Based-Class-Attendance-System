import 'package:hadir_mobile_full/shared/domain/entities/registration_session.dart';
import 'package:hadir_mobile_full/shared/domain/entities/selected_frame.dart';

/// Abstract repository interface for registration session data operations
abstract class RegistrationRepository {
  /// Create a new registration session
  /// 
  /// Throws [RegistrationSessionAlreadyExistsException] if active session exists for student
  /// Throws [ValidationException] if session data is invalid
  /// Throws [DatabaseException] if database operation fails
  Future<RegistrationSession> createSession(RegistrationSession session);

  /// Get a registration session by its ID
  /// 
  /// Returns null if session is not found
  /// Throws [DatabaseException] if database operation fails
  Future<RegistrationSession?> getSessionById(String sessionId);

  /// Get active registration session for a student
  /// 
  /// Returns null if no active session exists for the student
  /// Throws [DatabaseException] if database operation fails
  Future<RegistrationSession?> getActiveSessionByStudentId(String studentId);

  /// Update an existing registration session
  /// 
  /// Throws [EntityNotFoundException] if session is not found
  /// Throws [ValidationException] if session data is invalid
  /// Throws [DatabaseException] if database operation fails
  Future<RegistrationSession> updateSession(RegistrationSession session);

  /// Delete a registration session
  /// 
  /// Throws [EntityNotFoundException] if session is not found
  /// Throws [DatabaseException] if database operation fails
  Future<void> deleteSession(String sessionId);

  /// Get all registration sessions with optional filtering and pagination
  /// 
  /// [limit] - Maximum number of sessions to return (default: 50)
  /// [offset] - Number of sessions to skip (default: 0)
  /// [status] - Filter by session status (optional)
  /// [studentId] - Filter by student ID (optional)
  /// [startDate] - Filter sessions started after this date (optional)
  /// [endDate] - Filter sessions started before this date (optional)
  /// 
  /// Returns a list of registration sessions matching the criteria
  /// Throws [DatabaseException] if database operation fails
  Future<List<RegistrationSession>> getSessions({
    int limit = 50,
    int offset = 0,
    SessionStatus? status,
    String? studentId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get the total count of registration sessions with optional filtering
  /// 
  /// [status] - Filter by session status (optional)
  /// [studentId] - Filter by student ID (optional)
  /// [startDate] - Filter sessions started after this date (optional)
  /// [endDate] - Filter sessions started before this date (optional)
  /// 
  /// Returns the total number of sessions matching the criteria
  /// Throws [DatabaseException] if database operation fails
  Future<int> getSessionCount({
    SessionStatus? status,
    String? studentId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get sessions by status
  /// 
  /// [status] - The status to filter by
  /// [limit] - Maximum number of sessions to return (default: 50)
  /// [offset] - Number of sessions to skip (default: 0)
  /// 
  /// Returns a list of sessions with the specified status
  /// Throws [DatabaseException] if database operation fails
  Future<List<RegistrationSession>> getSessionsByStatus(
    SessionStatus status, {
    int limit = 50,
    int offset = 0,
  });

  /// Get sessions for a specific student
  /// 
  /// [studentId] - ID of the student
  /// [limit] - Maximum number of sessions to return (default: 50)
  /// [offset] - Number of sessions to skip (default: 0)
  /// 
  /// Returns a list of sessions for the specified student
  /// Throws [DatabaseException] if database operation fails
  Future<List<RegistrationSession>> getSessionsByStudentId(
    String studentId, {
    int limit = 50,
    int offset = 0,
  });

  /// Add a selected frame to a registration session
  /// 
  /// [sessionId] - ID of the registration session
  /// [frame] - The selected frame to add
  /// 
  /// Returns the updated registration session
  /// Throws [EntityNotFoundException] if session is not found
  /// Throws [ValidationException] if frame data is invalid
  /// Throws [DatabaseException] if database operation fails
  Future<RegistrationSession> addFrameToSession(
    String sessionId,
    SelectedFrame frame,
  );

  /// Remove a selected frame from a registration session
  /// 
  /// [sessionId] - ID of the registration session
  /// [frameId] - ID of the frame to remove
  /// 
  /// Returns the updated registration session
  /// Throws [EntityNotFoundException] if session or frame is not found
  /// Throws [DatabaseException] if database operation fails
  Future<RegistrationSession> removeFrameFromSession(
    String sessionId,
    String frameId,
  );

  /// Get all frames for a registration session
  /// 
  /// [sessionId] - ID of the registration session
  /// 
  /// Returns a list of selected frames for the session
  /// Throws [EntityNotFoundException] if session is not found
  /// Throws [DatabaseException] if database operation fails
  Future<List<SelectedFrame>> getSessionFrames(String sessionId);

  /// Complete a registration session
  /// 
  /// [sessionId] - ID of the session to complete
  /// 
  /// Returns the completed registration session
  /// Throws [EntityNotFoundException] if session is not found
  /// Throws [InvalidSessionStateException] if session cannot be completed
  /// Throws [DatabaseException] if database operation fails
  Future<RegistrationSession> completeSession(String sessionId);

  /// Cancel a registration session
  /// 
  /// [sessionId] - ID of the session to cancel
  /// 
  /// Returns the cancelled registration session
  /// Throws [EntityNotFoundException] if session is not found
  /// Throws [InvalidSessionStateException] if session cannot be cancelled
  /// Throws [DatabaseException] if database operation fails
  Future<RegistrationSession> cancelSession(String sessionId);

  /// Mark a registration session as failed
  /// 
  /// [sessionId] - ID of the session to mark as failed
  /// [reason] - Optional reason for failure
  /// 
  /// Returns the failed registration session
  /// Throws [EntityNotFoundException] if session is not found
  /// Throws [DatabaseException] if database operation fails
  Future<RegistrationSession> failSession(String sessionId, {String? reason});

  /// Expire old active sessions
  /// 
  /// [expirationThreshold] - Sessions older than this duration will be expired
  /// 
  /// Returns the number of sessions expired
  /// Throws [DatabaseException] if database operation fails
  Future<int> expireOldSessions(Duration expirationThreshold);

  /// Get session statistics
  /// 
  /// Returns a map containing various session statistics
  /// Throws [DatabaseException] if database operation fails
  Future<Map<String, dynamic>> getSessionStatistics();

  /// Get sessions grouped by status
  /// 
  /// Returns a map where keys are status values and values are session counts
  /// Throws [DatabaseException] if database operation fails
  Future<Map<SessionStatus, int>> getSessionCountByStatus();

  /// Get sessions created within a date range
  /// 
  /// [startDate] - Start of the date range (inclusive)
  /// [endDate] - End of the date range (inclusive)
  /// [limit] - Maximum number of sessions to return (default: 50)
  /// [offset] - Number of sessions to skip (default: 0)
  /// 
  /// Returns a list of sessions created within the date range
  /// Throws [DatabaseException] if database operation fails
  Future<List<RegistrationSession>> getSessionsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int limit = 50,
    int offset = 0,
  });

  /// Get average session duration by status
  /// 
  /// Returns a map where keys are status values and values are average durations in minutes
  /// Throws [DatabaseException] if database operation fails
  Future<Map<SessionStatus, double>> getAverageSessionDurationByStatus();

  /// Get sessions with retry count above threshold
  /// 
  /// [retryThreshold] - Minimum retry count to filter by
  /// [limit] - Maximum number of sessions to return (default: 50)
  /// [offset] - Number of sessions to skip (default: 0)
  /// 
  /// Returns a list of sessions with high retry counts
  /// Throws [DatabaseException] if database operation fails
  Future<List<RegistrationSession>> getHighRetrySessions(
    int retryThreshold, {
    int limit = 50,
    int offset = 0,
  });

  /// Update session's current pose index
  /// 
  /// [sessionId] - ID of the session to update
  /// [poseIndex] - New pose index
  /// 
  /// Returns the updated registration session
  /// Throws [EntityNotFoundException] if session is not found
  /// Throws [ValidationException] if pose index is invalid
  /// Throws [DatabaseException] if database operation fails
  Future<RegistrationSession> updateSessionPoseIndex(
    String sessionId,
    int poseIndex,
  );

  /// Increment session retry count
  /// 
  /// [sessionId] - ID of the session to update
  /// 
  /// Returns the updated registration session
  /// Throws [EntityNotFoundException] if session is not found
  /// Throws [MaxRetriesExceededException] if max retries exceeded
  /// Throws [DatabaseException] if database operation fails
  Future<RegistrationSession> incrementSessionRetryCount(String sessionId);

  /// Reset session retry count
  /// 
  /// [sessionId] - ID of the session to update
  /// 
  /// Returns the updated registration session
  /// Throws [EntityNotFoundException] if session is not found
  /// Throws [DatabaseException] if database operation fails
  Future<RegistrationSession> resetSessionRetryCount(String sessionId);

  /// Get sessions that need cleanup (old completed/failed sessions)
  /// 
  /// [cleanupThreshold] - Sessions older than this duration will be included
  /// [limit] - Maximum number of sessions to return (default: 100)
  /// 
  /// Returns a list of sessions that can be cleaned up
  /// Throws [DatabaseException] if database operation fails
  Future<List<RegistrationSession>> getSessionsForCleanup(
    Duration cleanupThreshold, {
    int limit = 100,
  });

  /// Bulk delete registration sessions
  /// 
  /// [sessionIds] - List of session IDs to delete
  /// 
  /// Returns the number of sessions successfully deleted
  /// Throws [DatabaseException] if database operation fails
  Future<int> bulkDeleteSessions(List<String> sessionIds);
}