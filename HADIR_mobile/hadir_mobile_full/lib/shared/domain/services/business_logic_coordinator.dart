import '../entities/student.dart';
import '../entities/registration_session.dart';
import '../entities/administrator.dart';
import '../services/validation_service.dart';
import '../services/business_rules_service.dart';
import '../../../features/registration/domain/use_cases/registration_use_cases.dart';
import '../../../features/auth/domain/use_cases/authentication_use_cases.dart';

/// Central coordinator for all business logic operations
/// Provides high-level business operations by coordinating use cases and services
class BusinessLogicCoordinator {
  const BusinessLogicCoordinator({
    required this.registrationUseCases,
    required this.authenticationUseCases,
    required this.validationService,
    required this.businessRulesService,
  });

  final RegistrationUseCases registrationUseCases;
  final AuthenticationUseCases authenticationUseCases;
  final ValidationService validationService;
  final BusinessRulesService businessRulesService;

  /// Complete student registration workflow
  /// Validates data, starts session, captures frames, and completes registration
  Future<BusinessOperationResult<Student>> registerStudent({
    required Map<String, dynamic> studentData,
    required List<List<int>> capturedFrames,
    required List<String> expectedPoseTypes,
  }) async {
    try {
      // Step 1: Validate student data
      final dataValidation = businessRulesService.isStudentDataComplete(studentData);
      if (dataValidation.isDenied) {
        return BusinessOperationResult.failure(dataValidation.message);
      }

      // Step 2: Validate individual fields
      final validationResults = [
        validationService.validateStudentId(studentData['id'] ?? ''),
        validationService.validateFullName(studentData['fullName'] ?? ''),
        validationService.validateEmail(studentData['email'] ?? ''),
        validationService.validateDepartment(studentData['department'] ?? ''),
        validationService.validateProgram(studentData['program'] ?? ''),
      ];

      for (final result in validationResults) {
        if (!result.isValid) {
          return BusinessOperationResult.failure(result.message);
        }
      }

      // Step 3: Start registration session
      final sessionResult = await registrationUseCases.startRegistrationSession(
        StartRegistrationSessionParams(studentData: studentData),
      );

      if (sessionResult.isLeft()) {
        return BusinessOperationResult.failure('Failed to start registration session');
      }

      final session = sessionResult.getOrElse(() => throw Exception('Unexpected error'));

      // Step 4: Process captured frames
      if (capturedFrames.length != expectedPoseTypes.length) {
        return BusinessOperationResult.failure('Mismatch between captured frames and expected poses');
      }

      for (int i = 0; i < capturedFrames.length; i++) {
        final frameResult = await registrationUseCases.captureFrame(
          CaptureFrameParams(
            sessionId: session.id,
            imageData: capturedFrames[i],
            expectedPoseType: PoseType.values.firstWhere(
              (type) => type.toString().split('.').last == expectedPoseTypes[i],
              orElse: () => PoseType.frontal,
            ),
          ),
        );

        if (frameResult.isLeft()) {
          return BusinessOperationResult.failure('Failed to process frame ${i + 1}');
        }
      }

      // Step 5: Complete registration
      final completionResult = await registrationUseCases.completeRegistrationSession(
        CompleteRegistrationSessionParams(sessionId: session.id),
      );

      if (completionResult.isLeft()) {
        return BusinessOperationResult.failure('Failed to complete registration');
      }

      final student = completionResult.getOrElse(() => throw Exception('Unexpected error'));
      return BusinessOperationResult.success(student);

    } catch (e) {
      return BusinessOperationResult.failure('Registration failed: ${e.toString()}');
    }
  }

  /// Authenticate administrator with comprehensive validation
  Future<BusinessOperationResult<Administrator>> authenticateAdministrator({
    required String username,
    required String password,
  }) async {
    try {
      // Validate input format
      final usernameValidation = validationService.validateUsername(username);
      if (!usernameValidation.isValid) {
        return BusinessOperationResult.failure(usernameValidation.message);
      }

      final passwordValidation = validationService.validatePassword(password);
      if (!passwordValidation.isValid) {
        return BusinessOperationResult.failure(passwordValidation.message);
      }

      // Perform authentication
      final authResult = await authenticationUseCases.login(
        LoginParams(username: username, password: password),
      );

      if (authResult.isLeft()) {
        return BusinessOperationResult.failure('Authentication failed');
      }

      final administrator = authResult.getOrElse(() => throw Exception('Unexpected error'));
      return BusinessOperationResult.success(administrator);

    } catch (e) {
      return BusinessOperationResult.failure('Authentication error: ${e.toString()}');
    }
  }

  /// Validate and update student information
  Future<BusinessOperationResult<Student>> updateStudentInfo({
    required Student currentStudent,
    required Map<String, dynamic> updates,
  }) async {
    try {
      // Check business rules for updates
      final updateRules = businessRulesService.canUpdateStudent(currentStudent, updates);
      if (updateRules.isDenied) {
        return BusinessOperationResult.failure(updateRules.message);
      }

      // Validate updated fields
      if (updates.containsKey('fullName')) {
        final nameValidation = validationService.validateFullName(updates['fullName'] ?? '');
        if (!nameValidation.isValid) {
          return BusinessOperationResult.failure(nameValidation.message);
        }
      }

      if (updates.containsKey('email')) {
        final emailValidation = validationService.validateEmail(updates['email'] ?? '');
        if (!emailValidation.isValid) {
          return BusinessOperationResult.failure(emailValidation.message);
        }
      }

      if (updates.containsKey('phoneNumber')) {
        final phoneValidation = validationService.validatePhoneNumber(updates['phoneNumber']);
        if (!phoneValidation.isValid) {
          return BusinessOperationResult.failure(phoneValidation.message);
        }
      }

      // Apply updates (this would typically involve a repository call)
      final updatedStudent = currentStudent.copyWith(
        fullName: updates['fullName'] ?? currentStudent.fullName,
        email: updates['email'] ?? currentStudent.email,
        phoneNumber: updates['phoneNumber'] ?? currentStudent.phoneNumber,
        lastUpdatedAt: DateTime.now(),
      );

      return BusinessOperationResult.success(updatedStudent);

    } catch (e) {
      return BusinessOperationResult.failure('Update failed: ${e.toString()}');
    }
  }

  /// Validate registration session status and provide recommendations
  BusinessOperationResult<SessionRecommendation> analyzeRegistrationSession(
    RegistrationSession session,
  ) {
    try {
      final recommendations = <String>[];
      
      // Check session timeout
      if (businessRulesService.isSessionExpired(session)) {
        return BusinessOperationResult.failure('Session has expired and needs to be restarted');
      }

      // Check retry limit
      if (businessRulesService.hasExceededMaxRetries(session)) {
        return BusinessOperationResult.failure('Maximum retry attempts exceeded');
      }

      // Check frame count
      if (session.selectedFramesCount < businessRulesService.getRequiredFramesCount()) {
        recommendations.add(
          'Need ${businessRulesService.getRequiredFramesCount() - session.selectedFramesCount} more frames',
        );
      }

      // Check quality
      if (session.overallQualityScore < businessRulesService.getMinimumQualityThreshold()) {
        recommendations.add('Improve lighting and face positioning for better quality');
      }

      // Check pose coverage
      if (session.poseCoveragePercentage < 80.0) {
        recommendations.add('Capture frames from different angles for better coverage');
      }

      // Check if ready for completion
      final completionCheck = businessRulesService.canCompleteSession(session);
      final canComplete = completionCheck.isAllowed;

      return BusinessOperationResult.success(
        SessionRecommendation(
          canComplete: canComplete,
          recommendations: recommendations,
          qualityScore: session.overallQualityScore,
          coveragePercentage: session.poseCoveragePercentage,
          framesCount: session.selectedFramesCount,
          retryCount: session.retryCount,
        ),
      );

    } catch (e) {
      return BusinessOperationResult.failure('Analysis failed: ${e.toString()}');
    }
  }

  /// Validate frame capture parameters
  ValidationResult validateFrameCapture({
    required String sessionId,
    required List<int> imageData,
    required String expectedPoseType,
  }) {
    // Validate session ID
    final sessionValidation = validationService.validateSessionId(sessionId);
    if (!sessionValidation.isValid) {
      return sessionValidation;
    }

    // Validate image data
    if (imageData.isEmpty) {
      return ValidationResult.error('Image data is empty');
    }

    if (imageData.length < 1000) { // Minimum reasonable image size
      return ValidationResult.error('Image data appears to be too small');
    }

    // Validate pose type
    final validPoseTypes = ['frontal', 'leftProfile', 'rightProfile', 'upward', 'downward'];
    if (!validPoseTypes.contains(expectedPoseType)) {
      return ValidationResult.error('Invalid pose type: $expectedPoseType');
    }

    return ValidationResult.valid();
  }
}

/// Result of a business operation
class BusinessOperationResult<T> {
  const BusinessOperationResult._({
    required this.isSuccess,
    this.data,
    this.errorMessage,
  });

  const BusinessOperationResult._success(T data) : this._(
    isSuccess: true,
    data: data,
  );

  const BusinessOperationResult._failure(String message) : this._(
    isSuccess: false,
    errorMessage: message,
  );

  final bool isSuccess;
  final T? data;
  final String? errorMessage;

  /// Create a success result
  factory BusinessOperationResult.success(T data) => BusinessOperationResult._success(data);

  /// Create a failure result
  factory BusinessOperationResult.failure(String message) => BusinessOperationResult._failure(message);

  /// Check if the operation failed
  bool get isFailure => !isSuccess;

  /// Get the error message or empty string if successful
  String get message => errorMessage ?? '';

  /// Get the data or throw if operation failed
  T get result {
    if (isFailure) {
      throw Exception(errorMessage ?? 'Operation failed');
    }
    return data!;
  }

  @override
  String toString() => isSuccess ? 'Success: $data' : 'Failure: $errorMessage';
}

/// Recommendations for a registration session
class SessionRecommendation {
  const SessionRecommendation({
    required this.canComplete,
    required this.recommendations,
    required this.qualityScore,
    required this.coveragePercentage,
    required this.framesCount,
    required this.retryCount,
  });

  final bool canComplete;
  final List<String> recommendations;
  final double qualityScore;
  final double coveragePercentage;
  final int framesCount;
  final int retryCount;

  /// Get a summary of the session status
  String get statusSummary {
    if (canComplete) {
      return 'Registration session is ready for completion';
    } else {
      return 'Registration session needs ${recommendations.length} improvements';
    }
  }
}

/// Factory for creating business logic coordinator
class BusinessLogicFactory {
  static BusinessLogicCoordinator create({
    required RegistrationUseCases registrationUseCases,
    required AuthenticationUseCases authenticationUseCases,
  }) {
    return BusinessLogicCoordinator(
      registrationUseCases: registrationUseCases,
      authenticationUseCases: authenticationUseCases,
      validationService: ValidationService.instance,
      businessRulesService: BusinessRulesService.instance,
    );
  }
}