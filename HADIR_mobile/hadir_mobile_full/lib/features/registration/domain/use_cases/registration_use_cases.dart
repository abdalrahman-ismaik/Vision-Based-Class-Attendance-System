import 'package:dartz/dartz.dart';
import 'package:hadir_mobile_full/shared/domain/entities/registration_session.dart';
import 'package:hadir_mobile_full/shared/domain/entities/selected_frame.dart';
import 'package:hadir_mobile_full/shared/domain/entities/student.dart';
import 'package:hadir_mobile_full/shared/domain/exceptions/hadir_exceptions.dart';
import 'package:hadir_mobile_full/features/registration/domain/repositories/registration_repository.dart';
import 'package:hadir_mobile_full/features/registration/domain/repositories/student_repository.dart';

/// Result type for use case operations
typedef UseCaseResult<T> = Either<HadirException, T>;

/// Abstract interface for YOLOv7-Pose detector
abstract class YOLOv7PoseDetector {
  /// Initialize the pose detection model
  Future<void> initialize();
  
  /// Detect pose in the given image data
  Future<PoseDetectionResult> detectPose(List<int> imageData);
  
  /// Generate face embedding from detected pose
  Future<List<double>> generateFaceEmbedding(PoseDetectionResult result);
  
  /// Check if detector is initialized
  bool get isInitialized;
}

/// Result of pose detection
class PoseDetectionResult {
  const PoseDetectionResult({
    required this.poseType,
    required this.confidenceScore,
    required this.faceBoundingBox,
    required this.keyPoints,
    required this.quality,
  });

  final PoseType poseType;
  final double confidenceScore;
  final List<double> faceBoundingBox;
  final List<List<double>> keyPoints;
  final FrameQuality quality;
}

/// Parameters for starting registration session
class StartRegistrationSessionParams {
  const StartRegistrationSessionParams({
    required this.studentData,
  });

  final Map<String, dynamic> studentData;
}

/// Parameters for capturing frame
class CaptureFrameParams {
  const CaptureFrameParams({
    required this.sessionId,
    required this.imageData,
    required this.expectedPoseType,
  });

  final String sessionId;
  final List<int> imageData;
  final PoseType expectedPoseType;
}

/// Parameters for completing registration session
class CompleteRegistrationSessionParams {
  const CompleteRegistrationSessionParams({
    required this.sessionId,
  });

  final String sessionId;
}

/// Use case for starting a registration session
class StartRegistrationSessionUseCase {
  const StartRegistrationSessionUseCase(
    this._registrationRepository,
    this._studentRepository,
  );

  final RegistrationRepository _registrationRepository;
  final StudentRepository _studentRepository;

  /// Execute start registration session operation
  Future<UseCaseResult<RegistrationSession>> call(StartRegistrationSessionParams params) async {
    try {
      // Validate student data
      final studentData = params.studentData;
      
      if (studentData['id'] == null || (studentData['id'] as String).isEmpty) {
        return Left(const FieldRequiredException('id'));
      }
      
      if (studentData['firstName'] == null || (studentData['firstName'] as String).trim().isEmpty) {
        return Left(const FieldRequiredException('firstName'));
      }
      
      if (studentData['lastName'] == null || (studentData['lastName'] as String).trim().isEmpty) {
        return Left(const FieldRequiredException('lastName'));
      }
      
      if (studentData['email'] == null || (studentData['email'] as String).trim().isEmpty) {
        return Left(const FieldRequiredException('email'));
      }

      final studentId = studentData['id'] as String;

      // Check if student already exists
      final existingStudent = await _studentRepository.getById(studentId);
      if (existingStudent != null) {
        return Left(const StudentAlreadyExistsException());
      }

      // Check if there's already an active registration session for this student
      final activeSession = await _registrationRepository.getActiveSessionByStudentId(studentId);
      if (activeSession != null) {
        return Left(const RegistrationSessionCompletedException());
      }

      // Create new registration session
      final now = DateTime.now();
      final sessionId = 'REG${now.millisecondsSinceEpoch.toString().padLeft(8, '0')}';
      
      final session = RegistrationSession(
        id: sessionId,
        studentId: studentId,
        status: RegistrationSessionStatus.active,
        startedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final createdSession = await _registrationRepository.createSession(session);
      return Right(createdSession);
    } on RegistrationException catch (e) {
      return Left(e);
    } on ValidationException catch (e) {
      return Left(e);
    } on Exception catch (e) {
      return Left(GenericHadirException('Failed to start registration session: ${e.toString()}'));
    }
  }
}

/// Use case for capturing and processing frames
class CaptureFrameUseCase {
  const CaptureFrameUseCase(
    this._registrationRepository,
    this._poseDetector,
  );

  final RegistrationRepository _registrationRepository;
  final YOLOv7PoseDetector _poseDetector;

  /// Execute frame capture operation
  Future<UseCaseResult<SelectedFrame>> call(CaptureFrameParams params) async {
    try {
      // Validate parameters
      if (params.sessionId.isEmpty) {
        return Left(const FieldRequiredException('sessionId'));
      }
      
      if (params.imageData.isEmpty) {
        return Left(const FieldRequiredException('imageData'));
      }

      // Get registration session
      final session = await _registrationRepository.getSessionById(params.sessionId);
      if (session == null) {
        return Left(const RegistrationSessionNotFoundException());
      }

      // Check session status
      if (session.status != RegistrationSessionStatus.active) {
        if (session.status == RegistrationSessionStatus.expired) {
          return Left(const RegistrationSessionExpiredException());
        } else if (session.status == RegistrationSessionStatus.completed) {
          return Left(const RegistrationSessionCompletedException());
        } else if (session.status == RegistrationSessionStatus.failed) {
          return Left(const RegistrationSessionFailedException());
        }
      }

      // Check if session has exceeded max retries
      if (session.hasExceededRetries) {
        return Left(const MaxRetriesExceededException());
      }

      // Initialize pose detector if needed
      if (!_poseDetector.isInitialized) {
        await _poseDetector.initialize();
      }

      // Detect pose in the image
      final detectionResult = await _poseDetector.detectPose(params.imageData);

      // Validate detection confidence
      if (detectionResult.confidenceScore < 0.9) {
        // Increment retry count
        await _registrationRepository.incrementSessionRetryCount(params.sessionId);
        return Left(const LowConfidenceException());
      }

      // Validate pose type matches expected
      if (detectionResult.poseType != params.expectedPoseType) {
        // Increment retry count
        await _registrationRepository.incrementSessionRetryCount(params.sessionId);
        return Left(IncorrectPoseException(params.expectedPoseType.toString()));
      }

      // Validate face quality
      if (detectionResult.quality == FrameQuality.poor) {
        // Increment retry count
        await _registrationRepository.incrementSessionRetryCount(params.sessionId);
        return Left(const InsufficientFaceQualityException());
      }

      // Generate face embedding
      final faceEmbedding = await _poseDetector.generateFaceEmbedding(detectionResult);

      // Create selected frame
      final now = DateTime.now();
      final frameId = 'FRM${now.millisecondsSinceEpoch.toString().padLeft(8, '0')}';
      
      final selectedFrame = SelectedFrame(
        id: frameId,
        registrationSessionId: params.sessionId,
        imagePath: 'frames/$frameId.jpg', // This would be set by the storage service
        poseType: detectionResult.poseType,
        confidenceScore: detectionResult.confidenceScore,
        quality: detectionResult.quality,
        faceEmbedding: faceEmbedding,
        faceBoundingBox: detectionResult.faceBoundingBox,
        keyPoints: detectionResult.keyPoints,
        capturedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      // Add frame to session
      await _registrationRepository.addFrameToSession(params.sessionId, selectedFrame);

      // Reset retry count on successful capture
      await _registrationRepository.resetSessionRetryCount(params.sessionId);

      return Right(selectedFrame);
    } on PoseDetectionException catch (e) {
      return Left(e);
    } on RegistrationException catch (e) {
      return Left(e);
    } on ValidationException catch (e) {
      return Left(e);
    } on Exception catch (e) {
      return Left(GenericHadirException('Failed to capture frame: ${e.toString()}'));
    }
  }
}

/// Use case for completing registration session
class CompleteRegistrationSessionUseCase {
  const CompleteRegistrationSessionUseCase(
    this._registrationRepository,
    this._studentRepository,
  );

  final RegistrationRepository _registrationRepository;
  final StudentRepository _studentRepository;

  /// Execute complete registration session operation
  Future<UseCaseResult<Student>> call(CompleteRegistrationSessionParams params) async {
    try {
      // Validate parameters
      if (params.sessionId.isEmpty) {
        return Left(const FieldRequiredException('sessionId'));
      }

      // Get registration session
      final session = await _registrationRepository.getSessionById(params.sessionId);
      if (session == null) {
        return Left(const RegistrationSessionNotFoundException());
      }

      // Check if session can be completed
      if (!session.isAllPosesCaptured) {
        return Left(const RegistrationSessionFailedException('Not all required poses have been captured'));
      }

      // Validate all frames meet quality threshold
      for (final frame in session.selectedFrames) {
        if (!frame.meetsQualityThreshold) {
          return Left(const InsufficientFaceQualityException('One or more frames do not meet quality requirements'));
        }
      }

      // Complete the session
      await _registrationRepository.completeSession(params.sessionId);

      // Create student with face embeddings
      final faceEmbeddings = session.selectedFrames
          .map((frame) => frame.faceEmbedding)
          .toList();

      final now = DateTime.now();
      final student = Student(
        id: session.studentId,
        firstName: 'Student', // This would come from session metadata
        lastName: 'User', // This would come from session metadata
        email: 'student@example.com', // This would come from session metadata
        phoneNumber: '+1234567890', // This would come from session metadata
        dateOfBirth: DateTime(2000, 1, 1), // This would come from session metadata
        gender: Gender.other, // This would come from session metadata
        nationality: 'Unknown', // This would come from session metadata
        major: 'Computer Science', // This would come from session metadata
        enrollmentYear: DateTime.now().year,
        academicLevel: AcademicLevel.undergraduate,
        status: StudentStatus.registered,
        registrationSessionId: session.id,
        faceEmbeddings: faceEmbeddings,
        createdAt: now,
        updatedAt: now,
      );

      final createdStudent = await _studentRepository.create(student);
      return Right(createdStudent);
    } on RegistrationException catch (e) {
      return Left(e);
    } on ValidationException catch (e) {
      return Left(e);
    } on Exception catch (e) {
      return Left(GenericHadirException('Failed to complete registration: ${e.toString()}'));
    }
  }
}

/// Container class for all registration use cases
class RegistrationUseCases {
  const RegistrationUseCases({
    required this.startRegistrationSession,
    required this.captureFrame,
    required this.completeRegistrationSession,
  });

  final StartRegistrationSessionUseCase startRegistrationSession;
  final CaptureFrameUseCase captureFrame;
  final CompleteRegistrationSessionUseCase completeRegistrationSession;

  /// Factory method to create registration use cases
  factory RegistrationUseCases.create(
    RegistrationRepository registrationRepository,
    StudentRepository studentRepository,
    YOLOv7PoseDetector poseDetector,
  ) {
    return RegistrationUseCases(
      startRegistrationSession: StartRegistrationSessionUseCase(
        registrationRepository,
        studentRepository,
      ),
      captureFrame: CaptureFrameUseCase(
        registrationRepository,
        poseDetector,
      ),
      completeRegistrationSession: CompleteRegistrationSessionUseCase(
        registrationRepository,
        studentRepository,
      ),
    );
  }
}