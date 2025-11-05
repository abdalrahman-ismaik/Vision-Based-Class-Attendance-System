/// Base class for all HADIR application exceptions
abstract class HadirException implements Exception {
  const HadirException(this.message, {this.code});

  /// Human-readable error message
  final String message;

  /// Optional error code for programmatic handling
  final String? code;

  @override
  String toString() => 'HadirException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Generic HADIR exception for general errors
class GenericHadirException extends HadirException {
  const GenericHadirException(super.message, {super.code});
}

/// Base class for authentication-related exceptions
abstract class AuthenticationException extends HadirException {
  const AuthenticationException(super.message, {super.code});

  @override
  String toString() => 'AuthenticationException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception thrown when login credentials are invalid
class InvalidCredentialsException extends AuthenticationException {
  const InvalidCredentialsException([String? message]) 
      : super(message ?? 'Invalid username or password', code: 'AUTH_001');
}

/// Exception thrown when user account is locked
class AccountLockedException extends AuthenticationException {
  const AccountLockedException([String? message]) 
      : super(message ?? 'Account is temporarily locked due to too many failed attempts', code: 'AUTH_002');
}

/// Exception thrown when user session is expired
class SessionExpiredException extends AuthenticationException {
  const SessionExpiredException([String? message]) 
      : super(message ?? 'Session has expired. Please log in again', code: 'AUTH_003');
}

/// Exception thrown when user lacks required permissions
class InsufficientPermissionsException extends AuthenticationException {
  const InsufficientPermissionsException([String? message]) 
      : super(message ?? 'Insufficient permissions to perform this action', code: 'AUTH_004');
}

/// Exception thrown when authentication token is invalid
class InvalidTokenException extends AuthenticationException {
  const InvalidTokenException([String? message]) 
      : super(message ?? 'Authentication token is invalid or malformed', code: 'AUTH_005');
}

/// Exception thrown when user account is disabled
class AccountDisabledException extends AuthenticationException {
  const AccountDisabledException([String? message]) 
      : super(message ?? 'User account has been disabled', code: 'AUTH_006');
}

/// Base class for registration-related exceptions
abstract class RegistrationException extends HadirException {
  const RegistrationException(super.message, {super.code});

  @override
  String toString() => 'RegistrationException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception thrown when student already exists
class StudentAlreadyExistsException extends RegistrationException {
  const StudentAlreadyExistsException([String? message]) 
      : super(message ?? 'Student with this ID or email already exists', code: 'REG_001');
}

/// Exception thrown when registration session is not found
class RegistrationSessionNotFoundException extends RegistrationException {
  const RegistrationSessionNotFoundException([String? message]) 
      : super(message ?? 'Registration session not found or has expired', code: 'REG_002');
}

/// Exception thrown when registration session has expired
class RegistrationSessionExpiredException extends RegistrationException {
  const RegistrationSessionExpiredException([String? message]) 
      : super(message ?? 'Registration session has expired. Please start a new session', code: 'REG_003');
}

/// Exception thrown when registration session is already completed
class RegistrationSessionCompletedException extends RegistrationException {
  const RegistrationSessionCompletedException([String? message]) 
      : super(message ?? 'Registration session is already completed', code: 'REG_004');
}

/// Exception thrown when registration session has failed
class RegistrationSessionFailedException extends RegistrationException {
  const RegistrationSessionFailedException([String? message]) 
      : super(message ?? 'Registration session has failed and cannot continue', code: 'REG_005');
}

/// Exception thrown when maximum retry attempts are exceeded
class MaxRetriesExceededException extends RegistrationException {
  const MaxRetriesExceededException([String? message]) 
      : super(message ?? 'Maximum retry attempts exceeded for registration', code: 'REG_006');
}

/// Exception thrown when invalid student data is provided
class InvalidStudentDataException extends RegistrationException {
  const InvalidStudentDataException([String? message]) 
      : super(message ?? 'Invalid student data provided', code: 'REG_007');
}

/// Base class for pose detection related exceptions  
abstract class PoseDetectionException extends HadirException {
  const PoseDetectionException(super.message, {super.code});

  @override
  String toString() => 'PoseDetectionException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Generic pose detection exception
class GenericPoseDetectionException extends PoseDetectionException {
  const GenericPoseDetectionException(super.message, {super.code});
}

/// Exception thrown when ML Kit Face Detection model fails to initialize
class ModelInitializationException extends PoseDetectionException {
  const ModelInitializationException([String? message]) 
      : super(message ?? 'Failed to initialize ML Kit Face Detection model', code: 'POSE_001');
}

/// Exception thrown when no face is detected in the frame
class NoFaceDetectedException extends PoseDetectionException {
  const NoFaceDetectedException([String? message]) 
      : super(message ?? 'No face detected in the captured frame', code: 'POSE_002');
}

/// Exception thrown when multiple faces are detected
class MultipleFacesDetectedException extends PoseDetectionException {
  const MultipleFacesDetectedException([String? message]) 
      : super(message ?? 'Multiple faces detected. Please ensure only one person is in frame', code: 'POSE_003');
}

/// Exception thrown when pose confidence is too low
class LowConfidenceException extends PoseDetectionException {
  const LowConfidenceException([String? message]) 
      : super(message ?? 'Pose detection confidence is too low. Please try again', code: 'POSE_004');
}

/// Exception thrown when incorrect pose type is detected
class IncorrectPoseException extends PoseDetectionException {
  const IncorrectPoseException(String expectedPose, [String? message]) 
      : super(message ?? 'Incorrect pose detected. Expected: $expectedPose', code: 'POSE_005');
}

/// Exception thrown when face quality is insufficient
class InsufficientFaceQualityException extends PoseDetectionException {
  const InsufficientFaceQualityException([String? message]) 
      : super(message ?? 'Face quality is insufficient for registration', code: 'POSE_006');
}

/// Exception thrown when face embedding generation fails
class FaceEmbeddingException extends PoseDetectionException {
  const FaceEmbeddingException([String? message]) 
      : super(message ?? 'Failed to generate face embedding from the captured frame', code: 'POSE_007');
}

/// Exception thrown when pose detection times out
class PoseDetectionTimeoutException extends PoseDetectionException {
  const PoseDetectionTimeoutException([String? message]) 
      : super(message ?? 'Pose detection operation timed out', code: 'POSE_008');
}

/// Base class for camera-related exceptions
abstract class CameraException extends HadirException {
  const CameraException(super.message, {super.code});

  @override
  String toString() => 'CameraException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception thrown when camera permissions are denied
class CameraPermissionDeniedException extends CameraException {
  const CameraPermissionDeniedException([String? message]) 
      : super(message ?? 'Camera permission denied. Please grant camera access', code: 'CAM_001');
}

/// Exception thrown when camera initialization fails
class CameraInitializationException extends CameraException {
  const CameraInitializationException([String? message]) 
      : super(message ?? 'Failed to initialize camera', code: 'CAM_002');
}

/// Exception thrown when frame capture fails
class FrameCaptureException extends CameraException {
  const FrameCaptureException([String? message]) 
      : super(message ?? 'Failed to capture frame from camera', code: 'CAM_003');
}

/// Exception thrown when camera is not available
class CameraNotAvailableException extends CameraException {
  const CameraNotAvailableException([String? message]) 
      : super(message ?? 'Camera is not available on this device', code: 'CAM_004');
}

/// Base class for validation exceptions
abstract class ValidationException extends HadirException {
  const ValidationException(super.message, {super.code, this.field});

  /// The field that failed validation
  final String? field;

  @override
  String toString() => 'ValidationException: $message${field != null ? ' (Field: $field)' : ''}${code != null ? ' (Code: $code)' : ''}';
}

/// Exception thrown when required field is empty
class FieldRequiredException extends ValidationException {
  const FieldRequiredException(String field, [String? message]) 
      : super(message ?? '$field is required', code: 'VAL_001', field: field);
}

/// Exception thrown when field format is invalid
class InvalidFormatException extends ValidationException {
  const InvalidFormatException(String field, [String? message]) 
      : super(message ?? '$field has invalid format', code: 'VAL_002', field: field);
}

/// Exception thrown when field value is out of range
class ValueOutOfRangeException extends ValidationException {
  const ValueOutOfRangeException(String field, String range, [String? message]) 
      : super(message ?? '$field value is out of range: $range', code: 'VAL_003', field: field);
}

/// Exception thrown when field value is too short
class ValueTooShortException extends ValidationException {
  const ValueTooShortException(String field, int minLength, [String? message]) 
      : super(message ?? '$field must be at least $minLength characters', code: 'VAL_004', field: field);
}

/// Exception thrown when field value is too long
class ValueTooLongException extends ValidationException {
  const ValueTooLongException(String field, int maxLength, [String? message]) 
      : super(message ?? '$field must not exceed $maxLength characters', code: 'VAL_005', field: field);
}

/// Base class for repository exceptions
abstract class RepositoryException extends HadirException {
  const RepositoryException(super.message, {super.code});

  @override
  String toString() => 'RepositoryException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception thrown when entity is not found
class EntityNotFoundException extends RepositoryException {
  const EntityNotFoundException(String entity, String id, [String? message]) 
      : super(message ?? '$entity with ID $id not found', code: 'REPO_001');
}

/// Exception thrown when database operation fails
class DatabaseException extends RepositoryException {
  const DatabaseException([String? message]) 
      : super(message ?? 'Database operation failed', code: 'REPO_002');
}

/// Exception thrown when database connection fails
class DatabaseConnectionException extends RepositoryException {
  const DatabaseConnectionException([String? message]) 
      : super(message ?? 'Failed to connect to database', code: 'REPO_003');
}

/// Exception thrown when database transaction fails
class TransactionException extends RepositoryException {
  const TransactionException([String? message]) 
      : super(message ?? 'Database transaction failed', code: 'REPO_004');
}

/// Exception thrown when entity already exists (constraint violation)
class EntityAlreadyExistsException extends RepositoryException {
  const EntityAlreadyExistsException(String entity, [String? message]) 
      : super(message ?? '$entity already exists', code: 'REPO_005');
}

/// Exception thrown when repository operation times out
class RepositoryTimeoutException extends RepositoryException {
  const RepositoryTimeoutException([String? message]) 
      : super(message ?? 'Repository operation timed out', code: 'REPO_006');
}

/// Base class for file system exceptions
abstract class FileSystemException extends HadirException {
  const FileSystemException(super.message, {super.code});

  @override
  String toString() => 'FileSystemException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception thrown when file is not found
class FileNotFoundException extends FileSystemException {
  const FileNotFoundException(String path, [String? message]) 
      : super(message ?? 'File not found: $path', code: 'FILE_001');
}

/// Exception thrown when file access is denied
class FileAccessDeniedException extends FileSystemException {
  const FileAccessDeniedException(String path, [String? message]) 
      : super(message ?? 'Access denied to file: $path', code: 'FILE_002');
}

/// Exception thrown when file operation fails
class FileOperationException extends FileSystemException {
  const FileOperationException(String operation, [String? message]) 
      : super(message ?? 'File operation failed: $operation', code: 'FILE_003');
}

/// Exception thrown when storage space is insufficient
class InsufficientStorageException extends FileSystemException {
  const InsufficientStorageException([String? message]) 
      : super(message ?? 'Insufficient storage space available', code: 'FILE_004');
}

/// Base class for network exceptions
abstract class NetworkException extends HadirException {
  const NetworkException(super.message, {super.code});

  @override
  String toString() => 'NetworkException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception thrown when network connection is unavailable
class NoNetworkConnectionException extends NetworkException {
  const NoNetworkConnectionException([String? message]) 
      : super(message ?? 'No network connection available', code: 'NET_001');
}

/// Exception thrown when network request times out
class NetworkTimeoutException extends NetworkException {
  const NetworkTimeoutException([String? message]) 
      : super(message ?? 'Network request timed out', code: 'NET_002');
}

/// Exception thrown when server returns an error
class ServerException extends NetworkException {
  const ServerException(int statusCode, [String? message]) 
      : super(message ?? 'Server error: HTTP $statusCode', code: 'NET_003');
}

/// Exception thrown when API response is invalid
class InvalidResponseException extends NetworkException {
  const InvalidResponseException([String? message]) 
      : super(message ?? 'Invalid response received from server', code: 'NET_004');
}

/// Base class for export-related exceptions
abstract class ExportException extends HadirException {
  const ExportException(super.message, {super.code});

  @override
  String toString() => 'ExportException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception thrown when export operation fails
class ExportOperationException extends ExportException {
  const ExportOperationException([String? message]) 
      : super(message ?? 'Export operation failed', code: 'EXP_001');
}

/// Exception thrown when export format is not supported
class UnsupportedExportFormatException extends ExportException {
  const UnsupportedExportFormatException(String format, [String? message]) 
      : super(message ?? 'Export format not supported: $format', code: 'EXP_002');
}

/// Exception thrown when exported data is too large
class ExportDataTooLargeException extends ExportException {
  const ExportDataTooLargeException([String? message]) 
      : super(message ?? 'Export data size exceeds maximum limit', code: 'EXP_003');
}

/// Exception thrown when export destination is invalid
class InvalidExportDestinationException extends ExportException {
  const InvalidExportDestinationException(String destination, [String? message]) 
      : super(message ?? 'Invalid export destination: $destination', code: 'EXP_004');
}