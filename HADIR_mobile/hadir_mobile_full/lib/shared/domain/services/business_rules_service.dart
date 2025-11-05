import '../../domain/entities/student.dart';
import '../../domain/entities/registration_session.dart';

/// Business rules service for HADIR mobile app
/// Encapsulates business logic rules and policies
class BusinessRulesService {
  const BusinessRulesService._();
  
  static const BusinessRulesService instance = BusinessRulesService._();

  // Registration session business rules
  static const int maxRetryAttempts = 3;
  static const int sessionTimeoutMinutes = 30;
  static const int requiredFramesCount = 5;
  static const double minimumQualityThreshold = 0.7;
  static const double minimumConfidenceThreshold = 0.9;
  
  // Student validation rules
  static const int minimumAge = 16;
  static const int maximumAge = 100;
  static const int maxConcurrentSessions = 1;
  
  // Frame quality requirements
  static const double requiredBrightness = 0.4;
  static const double requiredSharpness = 0.5;
  static const double maxBlurThreshold = 0.3;

  /// Check if a registration session can be started for a student
  BusinessRuleResult canStartRegistrationSession(String studentId, List<RegistrationSession> existingSessions) {
    // Check for existing active sessions
    final activeSessions = existingSessions.where(
      (session) => session.status == SessionStatus.inProgress,
    ).toList();
    
    if (activeSessions.length >= maxConcurrentSessions) {
      return BusinessRuleResult.denied(
        'Student already has an active registration session. Complete or cancel the existing session first.',
      );
    }
    
    // Check for recently completed sessions (prevent spamming)
    final recentSessions = existingSessions.where((session) {
      final timeDifference = DateTime.now().difference(session.createdAt);
      return timeDifference.inMinutes < 5 && session.status == SessionStatus.completed;
    }).toList();
    
    if (recentSessions.isNotEmpty) {
      return BusinessRuleResult.denied(
        'Please wait before starting a new registration session.',
      );
    }
    
    return BusinessRuleResult.allowed();
  }

  /// Check if a registration session has expired
  bool isSessionExpired(RegistrationSession session) {
    final elapsedTime = DateTime.now().difference(session.startedAt);
    return elapsedTime.inMinutes > sessionTimeoutMinutes;
  }

  /// Check if a session has exceeded maximum retry attempts
  bool hasExceededMaxRetries(RegistrationSession session) {
    return session.retryCount >= maxRetryAttempts;
  }

  /// Check if a session can be completed
  BusinessRuleResult canCompleteSession(RegistrationSession session) {
    if (session.status != SessionStatus.inProgress) {
      return BusinessRuleResult.denied(
        'Session is not in progress and cannot be completed.',
      );
    }
    
    if (isSessionExpired(session)) {
      return BusinessRuleResult.denied(
        'Session has expired and cannot be completed.',
      );
    }
    
    if (session.selectedFramesCount < requiredFramesCount) {
      return BusinessRuleResult.denied(
        'Insufficient frames captured. At least $requiredFramesCount frames are required.',
      );
    }
    
    if (session.overallQualityScore < minimumQualityThreshold) {
      return BusinessRuleResult.denied(
        'Frame quality does not meet minimum requirements.',
      );
    }
    
    // Check pose coverage
    if (session.poseCoveragePercentage < 80.0) {
      return BusinessRuleResult.denied(
        'Insufficient pose coverage. Please capture frames from different angles.',
      );
    }
    
    return BusinessRuleResult.allowed();
  }

  /// Check if a frame meets quality requirements
  BusinessRuleResult isFrameQualityAcceptable(double qualityScore, double confidenceScore) {
    if (qualityScore < minimumQualityThreshold) {
      return BusinessRuleResult.denied(
        'Frame quality is too low. Please ensure good lighting and face visibility.',
      );
    }
    
    if (confidenceScore < minimumConfidenceThreshold) {
      return BusinessRuleResult.denied(
        'Face detection confidence is too low. Please position your face clearly in the frame.',
      );
    }
    
    return BusinessRuleResult.allowed();
  }

  /// Check if student data is complete for registration
  BusinessRuleResult isStudentDataComplete(Map<String, dynamic> studentData) {
    final requiredFields = [
      'id',
      'fullName',
      'email',
      'dateOfBirth',
      'department',
      'program',
    ];
    
    for (final field in requiredFields) {
      if (!studentData.containsKey(field) || 
          studentData[field] == null || 
          studentData[field].toString().trim().isEmpty) {
        return BusinessRuleResult.denied(
          'Required field "$field" is missing or empty.',
        );
      }
    }
    
    // Validate age requirement
    if (studentData.containsKey('dateOfBirth')) {
      try {
        final dateOfBirth = DateTime.parse(studentData['dateOfBirth'].toString());
        final age = DateTime.now().year - dateOfBirth.year;
        
        if (age < minimumAge) {
          return BusinessRuleResult.denied(
            'Student must be at least $minimumAge years old.',
          );
        }
        
        if (age > maximumAge) {
          return BusinessRuleResult.denied(
            'Please verify the date of birth.',
          );
        }
      } catch (e) {
        return BusinessRuleResult.denied(
          'Invalid date of birth format.',
        );
      }
    }
    
    return BusinessRuleResult.allowed();
  }

  /// Check if student can be updated
  BusinessRuleResult canUpdateStudent(Student student, Map<String, dynamic> updates) {
    // Prevent updating critical fields after registration
    final protectedFields = ['id', 'registrationSessionId'];
    
    for (final field in protectedFields) {
      if (updates.containsKey(field) && 
          updates[field] != null && 
          updates[field].toString() != student.id) {
        return BusinessRuleResult.denied(
          'Cannot modify protected field "$field" after registration.',
        );
      }
    }
    
    // Check if student is in a state that allows updates
    if (student.status == StudentStatus.archived) {
      return BusinessRuleResult.denied(
        'Cannot update archived student records.',
      );
    }
    
    return BusinessRuleResult.allowed();
  }

  /// Check if student can be deleted
  BusinessRuleResult canDeleteStudent(Student student) {
    // Only allow deletion of students in certain states
    final allowedStatuses = [
      StudentStatus.pending,
      StudentStatus.incomplete,
    ];
    
    if (!allowedStatuses.contains(student.status)) {
      return BusinessRuleResult.denied(
        'Cannot delete student with status "${student.status}". Only pending or incomplete students can be deleted.',
      );
    }
    
    return BusinessRuleResult.allowed();
  }

  /// Get maximum allowed concurrent sessions per student
  int getMaxConcurrentSessions() => maxConcurrentSessions;

  /// Get session timeout in minutes
  int getSessionTimeoutMinutes() => sessionTimeoutMinutes;

  /// Get required frames count for successful registration
  int getRequiredFramesCount() => requiredFramesCount;

  /// Get minimum quality threshold
  double getMinimumQualityThreshold() => minimumQualityThreshold;

  /// Get minimum confidence threshold
  double getMinimumConfidenceThreshold() => minimumConfidenceThreshold;

  /// Calculate overall session quality score
  double calculateSessionQuality(List<double> frameQualities) {
    if (frameQualities.isEmpty) return 0.0;
    
    // Use weighted average with higher weight for better frames
    final sortedQualities = List<double>.from(frameQualities)..sort((a, b) => b.compareTo(a));
    
    double weightedSum = 0.0;
    double totalWeight = 0.0;
    
    for (int i = 0; i < sortedQualities.length; i++) {
      final weight = 1.0 - (i * 0.1); // Decrease weight for lower quality frames
      weightedSum += sortedQualities[i] * weight;
      totalWeight += weight;
    }
    
    return totalWeight > 0 ? weightedSum / totalWeight : 0.0;
  }

  /// Calculate pose coverage percentage
  double calculatePoseCoverage(List<String> capturedPoseTypes) {
    const requiredPoses = ['frontal', 'leftProfile', 'rightProfile', 'upward', 'downward'];
    final uniquePoses = capturedPoseTypes.toSet();
    return (uniquePoses.length / requiredPoses.length) * 100.0;
  }
}

/// Result of a business rule evaluation
class BusinessRuleResult {
  const BusinessRuleResult._({
    required this.isAllowed,
    this.reason,
  });

  const BusinessRuleResult._allowed() : this._(isAllowed: true);
  
  const BusinessRuleResult._denied(String reason) : this._(
    isAllowed: false,
    reason: reason,
  );

  final bool isAllowed;
  final String? reason;

  /// Create an allowed result
  factory BusinessRuleResult.allowed() => const BusinessRuleResult._allowed();

  /// Create a denied result
  factory BusinessRuleResult.denied(String reason) => BusinessRuleResult._denied(reason);

  /// Check if the action is denied
  bool get isDenied => !isAllowed;

  /// Get the reason for denial or empty string if allowed
  String get message => reason ?? '';

  @override
  String toString() => isAllowed ? 'Allowed' : 'Denied: $reason';
}