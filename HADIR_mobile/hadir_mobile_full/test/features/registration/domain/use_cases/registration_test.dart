import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:hadir_mobile_full/features/registration/domain/use_cases/registration_use_cases.dart';
import 'package:hadir_mobile_full/features/registration/domain/repositories/registration_repository.dart';
import 'package:hadir_mobile_full/features/registration/domain/repositories/student_repository.dart';
import 'package:hadir_mobile_full/shared/domain/entities/student.dart';
import 'package:hadir_mobile_full/shared/domain/entities/registration_session.dart';
import 'package:hadir_mobile_full/shared/domain/entities/selected_frame.dart';
import 'package:hadir_mobile_full/features/registration/data/models/registration_requests.dart';
import 'package:hadir_mobile_full/shared/exceptions/registration_exceptions.dart';
import 'package:hadir_mobile_full/core/computer_vision/yolov7_pose_detector.dart';

import 'registration_test.mocks.dart';

// Generate mocks
@GenerateMocks([RegistrationRepository, StudentRepository, YOLOv7PoseDetector])
void main() {
  group('Registration Use Cases', () {
    late RegistrationUseCases registrationUseCases;
    late MockRegistrationRepository mockRegistrationRepository;
    late MockStudentRepository mockStudentRepository;
    late MockYOLOv7PoseDetector mockPoseDetector;
    
    setUp(() {
      mockRegistrationRepository = MockRegistrationRepository();
      mockStudentRepository = MockStudentRepository();
      mockPoseDetector = MockYOLOv7PoseDetector();
      registrationUseCases = RegistrationUseCases(
        registrationRepository: mockRegistrationRepository,
        studentRepository: mockStudentRepository,
        poseDetector: mockPoseDetector,
      );
    });

    group('StartRegistrationSessionUseCase', () {
      test('should start new registration session with valid student data', () async {
        // Arrange
        const registrationRequest = StartRegistrationRequest(
          studentId: 'STU20240001',
          firstName: 'Ahmed',
          lastName: 'Hassan',
          email: 'ahmed.hassan@student.university.edu',
          phoneNumber: '+962781234567',
          dateOfBirth: '1999-03-15',
          gender: 'Male',
          nationality: 'Jordanian',
          major: 'Computer Science',
          enrollmentYear: 2024,
          academicLevel: 'Undergraduate',
          administratorId: 'admin-uuid-123',
        );
        
        final expectedSession = RegistrationSession(
          id: 'session-uuid-456',
          studentId: 'STU20240001',
          administratorId: 'admin-uuid-123',
          status: SessionStatus.inProgress,
          startedAt: DateTime.now(),
          poseTargets: const [
            PoseTarget.frontalFace,
            PoseTarget.leftProfile,
            PoseTarget.rightProfile,
            PoseTarget.upwardAngle,
            PoseTarget.downwardAngle,
          ],
          capturedFrames: const [],
          qualityMetrics: QualityMetrics.initial(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        when(mockRegistrationRepository.startSession(registrationRequest))
            .thenAnswer((_) async => expectedSession);
        
        // Act
        final result = await registrationUseCases.startRegistrationSession(registrationRequest);
        
        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, equals(expectedSession));
        expect(result.data?.studentId, equals('STU20240001'));
        expect(result.data?.status, equals(SessionStatus.inProgress));
        expect(result.data?.poseTargets.length, equals(5));
        verify(mockRegistrationRepository.startSession(registrationRequest)).called(1);
      });

      test('should validate student data before starting session', () async {
        // Arrange
        const invalidRequest = StartRegistrationRequest(
          studentId: '', // Invalid: empty student ID
          firstName: 'Ahmed',
          lastName: 'Hassan',
          email: 'invalid-email', // Invalid email format
          phoneNumber: '+962781234567',
          dateOfBirth: '1999-03-15',
          gender: 'Male',
          nationality: 'Jordanian',
          major: 'Computer Science',
          enrollmentYear: 2024,
          academicLevel: 'Undergraduate',
          administratorId: 'admin-uuid-123',
        );
        
        // Act
        final result = await registrationUseCases.startRegistrationSession(invalidRequest);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<ValidationException>());
        expect(result.error?.message, contains('Student ID cannot be empty'));
        verifyNever(mockRegistrationRepository.startSession(any));
      });

      test('should handle duplicate session creation attempt', () async {
        // Arrange
        const duplicateRequest = StartRegistrationRequest(
          studentId: 'STU20240002',
          firstName: 'Fatima',
          lastName: 'Al-Zahra',
          email: 'fatima.alzahra@student.university.edu',
          phoneNumber: '+962781234568',
          dateOfBirth: '2000-07-22',
          gender: 'Female',
          nationality: 'Jordanian',
          major: 'Information Technology',
          enrollmentYear: 2024,
          academicLevel: 'Undergraduate',
          administratorId: 'admin-uuid-123',
        );
        
        when(mockRegistrationRepository.startSession(duplicateRequest))
            .thenThrow(const DuplicateSessionException('Active registration session already exists for this student'));
        
        // Act
        final result = await registrationUseCases.startRegistrationSession(duplicateRequest);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<DuplicateSessionException>());
        expect(result.error?.message, equals('Active registration session already exists for this student'));
        verify(mockRegistrationRepository.startSession(duplicateRequest)).called(1);
      });

      test('should initialize YOLOv7-Pose detector for session', () async {
        // Arrange
        const request = StartRegistrationRequest(
          studentId: 'STU20240003',
          firstName: 'Mohammad',
          lastName: 'Khaled',
          email: 'mohammad.khaled@student.university.edu',
          phoneNumber: '+962781234569',
          dateOfBirth: '1998-11-08',
          gender: 'Male',
          nationality: 'Jordanian',
          major: 'Software Engineering',
          enrollmentYear: 2024,
          academicLevel: 'Undergraduate',
          administratorId: 'admin-uuid-456',
        );
        
        final session = RegistrationSession(
          id: 'session-uuid-789',
          studentId: 'STU20240003',
          administratorId: 'admin-uuid-456',
          status: SessionStatus.inProgress,
          startedAt: DateTime.now(),
          poseTargets: const [
            PoseTarget.frontalFace,
            PoseTarget.leftProfile,
            PoseTarget.rightProfile,
            PoseTarget.upwardAngle,
            PoseTarget.downwardAngle,
          ],
          capturedFrames: const [],
          qualityMetrics: QualityMetrics.initial(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        when(mockRegistrationRepository.startSession(request))
            .thenAnswer((_) async => session);
        when(mockPoseDetector.initialize())
            .thenAnswer((_) async => true);
        
        // Act
        final result = await registrationUseCases.startRegistrationSession(request);
        
        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRegistrationRepository.startSession(request)).called(1);
        verify(mockPoseDetector.initialize()).called(1);
      });

      test('should handle YOLOv7-Pose initialization failure', () async {
        // Arrange
        const request = StartRegistrationRequest(
          studentId: 'STU20240004',
          firstName: 'Layla',
          lastName: 'Omar',
          email: 'layla.omar@student.university.edu',
          phoneNumber: '+962781234570',
          dateOfBirth: '2001-04-12',
          gender: 'Female',
          nationality: 'Jordanian',
          major: 'Data Science',
          enrollmentYear: 2024,
          academicLevel: 'Undergraduate',
          administratorId: 'admin-uuid-789',
        );
        
        when(mockPoseDetector.initialize())
            .thenThrow(const PoseDetectorException('Failed to initialize YOLOv7-Pose model'));
        
        // Act
        final result = await registrationUseCases.startRegistrationSession(request);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<PoseDetectorException>());
        expect(result.error?.message, equals('Failed to initialize YOLOv7-Pose model'));
        verify(mockPoseDetector.initialize()).called(1);
        verifyNever(mockRegistrationRepository.startSession(any));
      });
    });

    group('CaptureFrameUseCase', () {
      test('should capture and validate frame with YOLOv7-Pose detection', () async {
        // Arrange
        const sessionId = 'session-uuid-123';
        const poseTarget = PoseTarget.frontalFace;
        final frameData = CaptureFrameRequest(
          sessionId: sessionId,
          poseTarget: poseTarget,
          imageBytes: Uint8List.fromList([1, 2, 3, 4, 5]), // Mock image data
          capturedAt: DateTime.now(),
        );
        
        final expectedPoseResult = PoseDetectionResult(
          confidence: 0.95,
          keypoints: const [
            Keypoint(id: 0, x: 320.5, y: 240.3, confidence: 0.98), // Nose
            Keypoint(id: 1, x: 315.2, y: 235.7, confidence: 0.94), // Left eye
            Keypoint(id: 2, x: 325.8, y: 235.9, confidence: 0.96), // Right eye
            // Additional keypoints...
          ],
          angles: const PoseAngles(
            yaw: 2.3,
            pitch: -1.8,
            roll: 0.5,
          ),
          faceMetrics: const FaceMetrics(
            width: 145.6,
            height: 180.4,
            aspectRatio: 0.807,
            area: 26284.2,
          ),
          boundingBox: const BoundingBox(
            x: 248.0,
            y: 150.0,
            width: 145.6,
            height: 180.4,
          ),
          qualityScore: 0.89,
          timestamp: DateTime.now(),
        );
        
        final selectedFrame = SelectedFrame(
          id: 'frame-uuid-456',
          sessionId: sessionId,
          poseTarget: poseTarget,
          imageUrl: 'storage/frames/frame-uuid-456.jpg',
          capturedAt: DateTime.now(),
          poseResult: expectedPoseResult,
          qualityMetrics: FrameQualityMetrics(
            sharpness: 0.85,
            brightness: 0.72,
            contrast: 0.68,
            faceVisibility: 0.96,
            poseAccuracy: 0.89,
            overallQuality: 0.82,
          ),
          isSelected: true,
          processingTime: 1250,
          createdAt: DateTime.now(),
        );
        
        when(mockPoseDetector.detectPose(frameData.imageBytes, poseTarget))
            .thenAnswer((_) async => expectedPoseResult);
        when(mockRegistrationRepository.saveFrame(sessionId, selectedFrame))
            .thenAnswer((_) async => selectedFrame);
        
        // Act
        final result = await registrationUseCases.captureFrame(frameData);
        
        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, equals(selectedFrame));
        expect(result.data?.poseResult.confidence, equals(0.95));
        expect(result.data?.qualityMetrics.overallQuality, greaterThan(0.8));
        verify(mockPoseDetector.detectPose(frameData.imageBytes, poseTarget)).called(1);
        verify(mockRegistrationRepository.saveFrame(sessionId, selectedFrame)).called(1);
      });

      test('should reject frame with low confidence YOLOv7-Pose detection', () async {
        // Arrange
        const sessionId = 'session-uuid-456';
        const poseTarget = PoseTarget.leftProfile;
        final frameData = CaptureFrameRequest(
          sessionId: sessionId,
          poseTarget: poseTarget,
          imageBytes: Uint8List.fromList([6, 7, 8, 9, 10]),
          capturedAt: DateTime.now(),
        );
        
        final lowConfidencePoseResult = PoseDetectionResult(
          confidence: 0.65, // Below 90% threshold
          keypoints: const [
            Keypoint(id: 0, x: 180.2, y: 240.1, confidence: 0.62),
            Keypoint(id: 1, x: 185.5, y: 235.3, confidence: 0.59),
            // Additional low-confidence keypoints...
          ],
          angles: const PoseAngles(
            yaw: -48.7, // Left profile
            pitch: 3.2,
            roll: -1.8,
          ),
          faceMetrics: const FaceMetrics(
            width: 98.3,
            height: 127.8,
            aspectRatio: 0.769,
            area: 12571.7,
          ),
          boundingBox: const BoundingBox(
            x: 131.1,
            y: 176.1,
            width: 98.3,
            height: 127.8,
          ),
          qualityScore: 0.63,
          timestamp: DateTime.now(),
        );
        
        when(mockPoseDetector.detectPose(frameData.imageBytes, poseTarget))
            .thenAnswer((_) async => lowConfidencePoseResult);
        
        // Act
        final result = await registrationUseCases.captureFrame(frameData);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<LowQualityFrameException>());
        expect(result.error?.message, contains('YOLOv7-Pose confidence too low'));
        verify(mockPoseDetector.detectPose(frameData.imageBytes, poseTarget)).called(1);
        verifyNever(mockRegistrationRepository.saveFrame(any, any));
      });

      test('should validate pose angle alignment for target pose', () async {
        // Arrange
        const sessionId = 'session-uuid-789';
        const poseTarget = PoseTarget.rightProfile;
        final frameData = CaptureFrameRequest(
          sessionId: sessionId,
          poseTarget: poseTarget,
          imageBytes: Uint8List.fromList([11, 12, 13, 14, 15]),
          capturedAt: DateTime.now(),
        );
        
        final incorrectAnglePoseResult = PoseDetectionResult(
          confidence: 0.93, // Good confidence
          keypoints: const [
            Keypoint(id: 0, x: 460.3, y: 240.5, confidence: 0.95),
            Keypoint(id: 2, x: 455.1, y: 235.8, confidence: 0.91), // Right eye more visible
            // Additional keypoints for right profile...
          ],
          angles: const PoseAngles(
            yaw: -15.2, // Should be around +45° for right profile
            pitch: 2.1,
            roll: 0.8,
          ),
          faceMetrics: const FaceMetrics(
            width: 112.7,
            height: 148.9,
            aspectRatio: 0.757,
            area: 16784.0,
          ),
          boundingBox: const BoundingBox(
            x: 403.65,
            y: 165.55,
            width: 112.7,
            height: 148.9,
          ),
          qualityScore: 0.87,
          timestamp: DateTime.now(),
        );
        
        when(mockPoseDetector.detectPose(frameData.imageBytes, poseTarget))
            .thenAnswer((_) async => incorrectAnglePoseResult);
        
        // Act
        final result = await registrationUseCases.captureFrame(frameData);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<IncorrectPoseAngleException>());
        expect(result.error?.message, contains('Pose angle does not match target'));
        verify(mockPoseDetector.detectPose(frameData.imageBytes, poseTarget)).called(1);
        verifyNever(mockRegistrationRepository.saveFrame(any, any));
      });

      test('should handle YOLOv7-Pose detection timeout', () async {
        // Arrange
        const sessionId = 'session-uuid-timeout';
        const poseTarget = PoseTarget.upwardAngle;
        final frameData = CaptureFrameRequest(
          sessionId: sessionId,
          poseTarget: poseTarget,
          imageBytes: Uint8List.fromList([16, 17, 18, 19, 20]),
          capturedAt: DateTime.now(),
        );
        
        when(mockPoseDetector.detectPose(frameData.imageBytes, poseTarget))
            .thenThrow(const ProcessingTimeoutException('YOLOv7-Pose detection timeout'));
        
        // Act
        final result = await registrationUseCases.captureFrame(frameData);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<ProcessingTimeoutException>());
        expect(result.error?.message, equals('YOLOv7-Pose detection timeout'));
        verify(mockPoseDetector.detectPose(frameData.imageBytes, poseTarget)).called(1);
        verifyNever(mockRegistrationRepository.saveFrame(any, any));
      });

      test('should calculate frame quality metrics correctly', () async {
        // Arrange
        const sessionId = 'session-quality-test';
        const poseTarget = PoseTarget.downwardAngle;
        final frameData = CaptureFrameRequest(
          sessionId: sessionId,
          poseTarget: poseTarget,
          imageBytes: Uint8List.fromList([21, 22, 23, 24, 25]),
          capturedAt: DateTime.now(),
        );
        
        final poseResult = PoseDetectionResult(
          confidence: 0.91,
          keypoints: const [
            Keypoint(id: 0, x: 320.0, y: 280.5, confidence: 0.93), // Nose (downward)
            Keypoint(id: 1, x: 315.3, y: 275.2, confidence: 0.89), // Left eye
            Keypoint(id: 2, x: 324.7, y: 275.4, confidence: 0.90), // Right eye
            // Additional keypoints for downward angle...
          ],
          angles: const PoseAngles(
            yaw: 1.5,
            pitch: -25.8, // Downward tilt
            roll: -0.3,
          ),
          faceMetrics: const FaceMetrics(
            width: 128.4,
            height: 156.7,
            aspectRatio: 0.819,
            area: 20124.3,
          ),
          boundingBox: const BoundingBox(
            x: 255.8,
            y: 202.15,
            width: 128.4,
            height: 156.7,
          ),
          qualityScore: 0.85,
          timestamp: DateTime.now(),
        );
        
        final highQualityFrame = SelectedFrame(
          id: 'quality-frame-uuid',
          sessionId: sessionId,
          poseTarget: poseTarget,
          imageUrl: 'storage/frames/quality-frame-uuid.jpg',
          capturedAt: DateTime.now(),
          poseResult: poseResult,
          qualityMetrics: FrameQualityMetrics(
            sharpness: 0.92, // High sharpness
            brightness: 0.78, // Good brightness
            contrast: 0.84, // Good contrast
            faceVisibility: 0.91, // Excellent visibility
            poseAccuracy: 0.85, // Good pose accuracy
            overallQuality: 0.86, // Overall high quality
          ),
          isSelected: true,
          processingTime: 980,
          createdAt: DateTime.now(),
        );
        
        when(mockPoseDetector.detectPose(frameData.imageBytes, poseTarget))
            .thenAnswer((_) async => poseResult);
        when(mockRegistrationRepository.saveFrame(sessionId, highQualityFrame))
            .thenAnswer((_) async => highQualityFrame);
        
        // Act
        final result = await registrationUseCases.captureFrame(frameData);
        
        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data?.qualityMetrics.sharpness, greaterThan(0.9));
        expect(result.data?.qualityMetrics.faceVisibility, greaterThan(0.9));
        expect(result.data?.qualityMetrics.overallQuality, greaterThan(0.8));
        verify(mockPoseDetector.detectPose(frameData.imageBytes, poseTarget)).called(1);
        verify(mockRegistrationRepository.saveFrame(sessionId, highQualityFrame)).called(1);
      });
    });

    group('CompleteRegistrationSessionUseCase', () {
      test('should complete session with all 5 poses captured successfully', () async {
        // Arrange
        const sessionId = 'complete-session-uuid';
        
        final completedSession = RegistrationSession(
          id: sessionId,
          studentId: 'STU20240005',
          administratorId: 'admin-uuid-complete',
          status: SessionStatus.completed,
          startedAt: DateTime.now().subtract(const Duration(minutes: 15)),
          completedAt: DateTime.now(),
          poseTargets: const [
            PoseTarget.frontalFace,
            PoseTarget.leftProfile,
            PoseTarget.rightProfile,
            PoseTarget.upwardAngle,
            PoseTarget.downwardAngle,
          ],
          capturedFrames: List.generate(5, (index) => 'frame-uuid-$index'),
          qualityMetrics: QualityMetrics(
            averageConfidence: 0.92,
            averageSharpness: 0.87,
            averageBrightness: 0.75,
            averageContrast: 0.81,
            averageFaceVisibility: 0.94,
            overallSessionQuality: 0.86,
            completionRate: 1.0, // All 5 poses captured
            processingTime: 14500, // 14.5 seconds total
          ),
          createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
          updatedAt: DateTime.now(),
        );
        
        final registeredStudent = Student(
          id: 'STU20240005',
          firstName: 'Sara',
          lastName: 'Abdullah',
          email: 'sara.abdullah@student.university.edu',
          phoneNumber: '+962781234571',
          dateOfBirth: DateTime.parse('2000-09-18'),
          gender: Gender.female,
          nationality: 'Jordanian',
          major: 'Cybersecurity',
          enrollmentYear: 2024,
          academicLevel: AcademicLevel.undergraduate,
          status: StudentStatus.active,
          registrationSessionId: sessionId,
          faceEmbeddings: const [
            // Face embeddings from YOLOv7-Pose would be stored here
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        when(mockRegistrationRepository.getSessionById(sessionId))
            .thenAnswer((_) async => completedSession);
        when(mockRegistrationRepository.completeSession(sessionId))
            .thenAnswer((_) async => completedSession);
        when(mockStudentRepository.createStudent(any))
            .thenAnswer((_) async => registeredStudent);
        
        // Act
        final result = await registrationUseCases.completeRegistrationSession(sessionId);
        
        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data?.status, equals(SessionStatus.completed));
        expect(result.data?.completedAt, isNotNull);
        expect(result.data?.qualityMetrics.completionRate, equals(1.0));
        expect(result.data?.capturedFrames.length, equals(5));
        verify(mockRegistrationRepository.getSessionById(sessionId)).called(1);
        verify(mockRegistrationRepository.completeSession(sessionId)).called(1);
        verify(mockStudentRepository.createStudent(any)).called(1);
      });

      test('should reject completion when not all pose targets are captured', () async {
        // Arrange
        const incompleteSessionId = 'incomplete-session-uuid';
        
        final incompleteSession = RegistrationSession(
          id: incompleteSessionId,
          studentId: 'STU20240006',
          administratorId: 'admin-uuid-incomplete',
          status: SessionStatus.inProgress,
          startedAt: DateTime.now().subtract(const Duration(minutes: 10)),
          poseTargets: const [
            PoseTarget.frontalFace,
            PoseTarget.leftProfile,
            PoseTarget.rightProfile,
            PoseTarget.upwardAngle,
            PoseTarget.downwardAngle,
          ],
          capturedFrames: const ['frame-uuid-1', 'frame-uuid-2', 'frame-uuid-3'], // Only 3 of 5
          qualityMetrics: QualityMetrics(
            averageConfidence: 0.90,
            averageSharpness: 0.83,
            averageBrightness: 0.74,
            averageContrast: 0.79,
            averageFaceVisibility: 0.92,
            overallSessionQuality: 0.84,
            completionRate: 0.6, // Only 60% complete
            processingTime: 8200,
          ),
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
          updatedAt: DateTime.now().subtract(const Duration(minutes: 2)),
        );
        
        when(mockRegistrationRepository.getSessionById(incompleteSessionId))
            .thenAnswer((_) async => incompleteSession);
        
        // Act
        final result = await registrationUseCases.completeRegistrationSession(incompleteSessionId);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<IncompleteSessionException>());
        expect(result.error?.message, contains('Not all pose targets have been captured'));
        verify(mockRegistrationRepository.getSessionById(incompleteSessionId)).called(1);
        verifyNever(mockRegistrationRepository.completeSession(any));
        verifyNever(mockStudentRepository.createStudent(any));
      });

      test('should validate minimum quality requirements before completion', () async {
        // Arrange
        const lowQualitySessionId = 'low-quality-session-uuid';
        
        final lowQualitySession = RegistrationSession(
          id: lowQualitySessionId,
          studentId: 'STU20240007',
          administratorId: 'admin-uuid-quality',
          status: SessionStatus.inProgress,
          startedAt: DateTime.now().subtract(const Duration(minutes: 20)),
          poseTargets: const [
            PoseTarget.frontalFace,
            PoseTarget.leftProfile,
            PoseTarget.rightProfile,
            PoseTarget.upwardAngle,
            PoseTarget.downwardAngle,
          ],
          capturedFrames: List.generate(5, (index) => 'low-quality-frame-$index'),
          qualityMetrics: QualityMetrics(
            averageConfidence: 0.72, // Below 80% threshold
            averageSharpness: 0.65, // Below 70% threshold
            averageBrightness: 0.58,
            averageContrast: 0.61,
            averageFaceVisibility: 0.74,
            overallSessionQuality: 0.66, // Below minimum quality
            completionRate: 1.0,
            processingTime: 18700,
          ),
          createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
          updatedAt: DateTime.now().subtract(const Duration(minutes: 1)),
        );
        
        when(mockRegistrationRepository.getSessionById(lowQualitySessionId))
            .thenAnswer((_) async => lowQualitySession);
        
        // Act
        final result = await registrationUseCases.completeRegistrationSession(lowQualitySessionId);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<QualityThresholdException>());
        expect(result.error?.message, contains('Session quality below minimum requirements'));
        verify(mockRegistrationRepository.getSessionById(lowQualitySessionId)).called(1);
        verifyNever(mockRegistrationRepository.completeSession(any));
        verifyNever(mockStudentRepository.createStudent(any));
      });

      test('should generate face embeddings during completion', () async {
        // Arrange
        const embeddingSessionId = 'embedding-session-uuid';
        
        final sessionForEmbedding = RegistrationSession(
          id: embeddingSessionId,
          studentId: 'STU20240008',
          administratorId: 'admin-uuid-embedding',
          status: SessionStatus.inProgress,
          startedAt: DateTime.now().subtract(const Duration(minutes: 12)),
          poseTargets: const [
            PoseTarget.frontalFace,
            PoseTarget.leftProfile,
            PoseTarget.rightProfile,
            PoseTarget.upwardAngle,
            PoseTarget.downwardAngle,
          ],
          capturedFrames: List.generate(5, (index) => 'embedding-frame-$index'),
          qualityMetrics: QualityMetrics(
            averageConfidence: 0.94,
            averageSharpness: 0.89,
            averageBrightness: 0.77,
            averageContrast: 0.83,
            averageFaceVisibility: 0.96,
            overallSessionQuality: 0.88,
            completionRate: 1.0,
            processingTime: 11200,
          ),
          createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
          updatedAt: DateTime.now().subtract(const Duration(seconds: 30)),
        );
        
        final completedSessionWithEmbeddings = sessionForEmbedding.copyWith(
          status: SessionStatus.completed,
          completedAt: DateTime.now(),
        );
        
        final studentWithEmbeddings = Student(
          id: 'STU20240008',
          firstName: 'Khalil',
          lastName: 'Mahmoud',
          email: 'khalil.mahmoud@student.university.edu',
          phoneNumber: '+962781234572',
          dateOfBirth: DateTime.parse('1999-12-03'),
          gender: Gender.male,
          nationality: 'Jordanian',
          major: 'Artificial Intelligence',
          enrollmentYear: 2024,
          academicLevel: AcademicLevel.undergraduate,
          status: StudentStatus.active,
          registrationSessionId: embeddingSessionId,
          faceEmbeddings: const [
            // Mock face embeddings generated by YOLOv7-Pose
            [0.12, 0.45, 0.67, 0.89, 0.23, /* ... 507 more values */],
            [0.11, 0.43, 0.68, 0.91, 0.21, /* ... 507 more values */],
            [0.13, 0.47, 0.65, 0.87, 0.25, /* ... 507 more values */],
            [0.10, 0.44, 0.69, 0.90, 0.22, /* ... 507 more values */],
            [0.14, 0.46, 0.66, 0.88, 0.24, /* ... 507 more values */],
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        when(mockRegistrationRepository.getSessionById(embeddingSessionId))
            .thenAnswer((_) async => sessionForEmbedding);
        when(mockPoseDetector.generateFaceEmbeddings(any))
            .thenAnswer((_) async => studentWithEmbeddings.faceEmbeddings);
        when(mockRegistrationRepository.completeSession(embeddingSessionId))
            .thenAnswer((_) async => completedSessionWithEmbeddings);
        when(mockStudentRepository.createStudent(any))
            .thenAnswer((_) async => studentWithEmbeddings);
        
        // Act
        final result = await registrationUseCases.completeRegistrationSession(embeddingSessionId);
        
        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data?.status, equals(SessionStatus.completed));
        verify(mockRegistrationRepository.getSessionById(embeddingSessionId)).called(1);
        verify(mockPoseDetector.generateFaceEmbeddings(any)).called(1);
        verify(mockRegistrationRepository.completeSession(embeddingSessionId)).called(1);
        verify(mockStudentRepository.createStudent(any)).called(1);
      });
    });

    group('CancelRegistrationSessionUseCase', () {
      test('should cancel active registration session successfully', () async {
        // Arrange
        const sessionId = 'cancel-session-uuid';
        const reason = 'Student request cancellation';
        
        final cancelledSession = RegistrationSession(
          id: sessionId,
          studentId: 'STU20240009',
          administratorId: 'admin-uuid-cancel',
          status: SessionStatus.cancelled,
          startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
          cancelledAt: DateTime.now(),
          cancellationReason: reason,
          poseTargets: const [
            PoseTarget.frontalFace,
            PoseTarget.leftProfile,
            PoseTarget.rightProfile,
            PoseTarget.upwardAngle,
            PoseTarget.downwardAngle,
          ],
          capturedFrames: const ['partial-frame-1', 'partial-frame-2'],
          qualityMetrics: QualityMetrics(
            averageConfidence: 0.88,
            averageSharpness: 0.82,
            averageBrightness: 0.71,
            averageContrast: 0.76,
            averageFaceVisibility: 0.89,
            overallSessionQuality: 0.81,
            completionRate: 0.4, // Partial completion before cancel
            processingTime: 4800,
          ),
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          updatedAt: DateTime.now(),
        );
        
        when(mockRegistrationRepository.cancelSession(sessionId, reason))
            .thenAnswer((_) async => cancelledSession);
        
        // Act
        final result = await registrationUseCases.cancelRegistrationSession(sessionId, reason);
        
        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data?.status, equals(SessionStatus.cancelled));
        expect(result.data?.cancelledAt, isNotNull);
        expect(result.data?.cancellationReason, equals(reason));
        verify(mockRegistrationRepository.cancelSession(sessionId, reason)).called(1);
      });

      test('should clean up captured frames when cancelling session', () async {
        // Arrange
        const sessionId = 'cleanup-session-uuid';
        const reason = 'Technical issues during capture';
        
        final sessionWithFrames = RegistrationSession(
          id: sessionId,
          studentId: 'STU20240010',
          administratorId: 'admin-uuid-cleanup',
          status: SessionStatus.cancelled,
          startedAt: DateTime.now().subtract(const Duration(minutes: 8)),
          cancelledAt: DateTime.now(),
          cancellationReason: reason,
          poseTargets: const [
            PoseTarget.frontalFace,
            PoseTarget.leftProfile,
            PoseTarget.rightProfile,
            PoseTarget.upwardAngle,
            PoseTarget.downwardAngle,
          ],
          capturedFrames: const [
            'cleanup-frame-1',
            'cleanup-frame-2',
            'cleanup-frame-3',
          ],
          qualityMetrics: QualityMetrics(
            averageConfidence: 0.85,
            averageSharpness: 0.79,
            averageBrightness: 0.68,
            averageContrast: 0.73,
            averageFaceVisibility: 0.86,
            overallSessionQuality: 0.78,
            completionRate: 0.6,
            processingTime: 7200,
          ),
          createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
          updatedAt: DateTime.now(),
        );
        
        when(mockRegistrationRepository.cancelSession(sessionId, reason))
            .thenAnswer((_) async => sessionWithFrames);
        when(mockRegistrationRepository.cleanupSessionFrames(sessionId))
            .thenAnswer((_) async => {});
        
        // Act
        final result = await registrationUseCases.cancelRegistrationSession(sessionId, reason);
        
        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRegistrationRepository.cancelSession(sessionId, reason)).called(1);
        verify(mockRegistrationRepository.cleanupSessionFrames(sessionId)).called(1);
      });

      test('should handle cancellation of already completed session', () async {
        // Arrange
        const completedSessionId = 'already-completed-session-uuid';
        const reason = 'Accidental completion';
        
        when(mockRegistrationRepository.cancelSession(completedSessionId, reason))
            .thenThrow(const InvalidSessionStateException('Cannot cancel completed session'));
        
        // Act
        final result = await registrationUseCases.cancelRegistrationSession(completedSessionId, reason);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<InvalidSessionStateException>());
        expect(result.error?.message, equals('Cannot cancel completed session'));
        verify(mockRegistrationRepository.cancelSession(completedSessionId, reason)).called(1);
      });

      test('should require cancellation reason', () async {
        // Arrange
        const sessionId = 'no-reason-session-uuid';
        const emptyReason = '';
        
        // Act
        final result = await registrationUseCases.cancelRegistrationSession(sessionId, emptyReason);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<ValidationException>());
        expect(result.error?.message, contains('Cancellation reason is required'));
        verifyNever(mockRegistrationRepository.cancelSession(any, any));
      });
    });

    group('GetRegistrationSessionUseCase', () {
      test('should retrieve registration session with all details', () async {
        // Arrange
        const sessionId = 'retrieve-session-uuid';
        
        final detailedSession = RegistrationSession(
          id: sessionId,
          studentId: 'STU20240011',
          administratorId: 'admin-uuid-retrieve',
          status: SessionStatus.inProgress,
          startedAt: DateTime.now().subtract(const Duration(minutes: 7)),
          poseTargets: const [
            PoseTarget.frontalFace,
            PoseTarget.leftProfile,
            PoseTarget.rightProfile,
            PoseTarget.upwardAngle,
            PoseTarget.downwardAngle,
          ],
          capturedFrames: const [
            'retrieve-frame-1',
            'retrieve-frame-2',
            'retrieve-frame-3',
            'retrieve-frame-4',
          ],
          qualityMetrics: QualityMetrics(
            averageConfidence: 0.91,
            averageSharpness: 0.85,
            averageBrightness: 0.73,
            averageContrast: 0.80,
            averageFaceVisibility: 0.93,
            overallSessionQuality: 0.84,
            completionRate: 0.8, // 4 of 5 poses captured
            processingTime: 6300,
          ),
          createdAt: DateTime.now().subtract(const Duration(minutes: 7)),
          updatedAt: DateTime.now().subtract(const Duration(seconds: 15)),
        );
        
        when(mockRegistrationRepository.getSessionById(sessionId))
            .thenAnswer((_) async => detailedSession);
        
        // Act
        final result = await registrationUseCases.getRegistrationSession(sessionId);
        
        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, equals(detailedSession));
        expect(result.data?.capturedFrames.length, equals(4));
        expect(result.data?.qualityMetrics.completionRate, equals(0.8));
        verify(mockRegistrationRepository.getSessionById(sessionId)).called(1);
      });

      test('should handle session not found error', () async {
        // Arrange
        const nonExistentSessionId = 'non-existent-session-uuid';
        
        when(mockRegistrationRepository.getSessionById(nonExistentSessionId))
            .thenThrow(const NotFoundException('Registration session not found'));
        
        // Act
        final result = await registrationUseCases.getRegistrationSession(nonExistentSessionId);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<NotFoundException>());
        expect(result.error?.message, equals('Registration session not found'));
        verify(mockRegistrationRepository.getSessionById(nonExistentSessionId)).called(1);
      });

      test('should validate session ID parameter', () async {
        // Arrange
        const emptySessionId = '';
        
        // Act
        final result = await registrationUseCases.getRegistrationSession(emptySessionId);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<ValidationException>());
        expect(result.error?.message, contains('Session ID cannot be empty'));
        verifyNever(mockRegistrationRepository.getSessionById(any));
      });
    });

    group('Performance and Error Handling', () {
      test('should handle concurrent frame capture attempts gracefully', () async {
        // Arrange
        const sessionId = 'concurrent-session-uuid';
        const poseTarget = PoseTarget.frontalFace;
        final frameData = CaptureFrameRequest(
          sessionId: sessionId,
          poseTarget: poseTarget,
          imageBytes: Uint8List.fromList([31, 32, 33, 34, 35]),
          capturedAt: DateTime.now(),
        );
        
        when(mockPoseDetector.detectPose(frameData.imageBytes, poseTarget))
            .thenThrow(const ConcurrencyException('Another frame capture is in progress'));
        
        // Act
        final result = await registrationUseCases.captureFrame(frameData);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<ConcurrencyException>());
        expect(result.error?.message, equals('Another frame capture is in progress'));
        verify(mockPoseDetector.detectPose(frameData.imageBytes, poseTarget)).called(1);
      });

      test('should handle memory constraints during YOLOv7-Pose processing', () async {
        // Arrange
        const sessionId = 'memory-test-session';
        const poseTarget = PoseTarget.leftProfile;
        final largeFrameData = CaptureFrameRequest(
          sessionId: sessionId,
          poseTarget: poseTarget,
          imageBytes: Uint8List.fromList(List.generate(10000000, (i) => i % 256)), // 10MB image
          capturedAt: DateTime.now(),
        );
        
        when(mockPoseDetector.detectPose(largeFrameData.imageBytes, poseTarget))
            .thenThrow(const MemoryException('Insufficient memory for YOLOv7-Pose processing'));
        
        // Act
        final result = await registrationUseCases.captureFrame(largeFrameData);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<MemoryException>());
        expect(result.error?.message, equals('Insufficient memory for YOLOv7-Pose processing'));
        verify(mockPoseDetector.detectPose(largeFrameData.imageBytes, poseTarget)).called(1);
      });

      test('should complete operations within acceptable performance thresholds', () async {
        // Arrange
        const sessionId = 'performance-session-uuid';
        const poseTarget = PoseTarget.frontalFace;
        final frameData = CaptureFrameRequest(
          sessionId: sessionId,
          poseTarget: poseTarget,
          imageBytes: Uint8List.fromList([41, 42, 43, 44, 45]),
          capturedAt: DateTime.now(),
        );
        
        final poseResult = PoseDetectionResult(
          confidence: 0.93,
          keypoints: const [
            Keypoint(id: 0, x: 320.0, y: 240.0, confidence: 0.95),
            // Additional keypoints...
          ],
          angles: const PoseAngles(yaw: 0.0, pitch: 0.0, roll: 0.0),
          faceMetrics: const FaceMetrics(width: 120.0, height: 150.0, aspectRatio: 0.8, area: 18000.0),
          boundingBox: const BoundingBox(x: 260.0, y: 165.0, width: 120.0, height: 150.0),
          qualityScore: 0.88,
          timestamp: DateTime.now(),
        );
        
        final selectedFrame = SelectedFrame(
          id: 'performance-frame-uuid',
          sessionId: sessionId,
          poseTarget: poseTarget,
          imageUrl: 'storage/frames/performance-frame-uuid.jpg',
          capturedAt: DateTime.now(),
          poseResult: poseResult,
          qualityMetrics: FrameQualityMetrics(
            sharpness: 0.86,
            brightness: 0.74,
            contrast: 0.79,
            faceVisibility: 0.92,
            poseAccuracy: 0.88,
            overallQuality: 0.84,
          ),
          isSelected: true,
          processingTime: 850, // Fast processing
          createdAt: DateTime.now(),
        );
        
        when(mockPoseDetector.detectPose(frameData.imageBytes, poseTarget))
            .thenAnswer((_) async {
          // Simulate YOLOv7-Pose processing time
          await Future.delayed(const Duration(milliseconds: 800));
          return poseResult;
        });
        when(mockRegistrationRepository.saveFrame(sessionId, selectedFrame))
            .thenAnswer((_) async => selectedFrame);
        
        // Act
        final stopwatch = Stopwatch()..start();
        final result = await registrationUseCases.captureFrame(frameData);
        stopwatch.stop();
        
        // Assert
        expect(result.isSuccess, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // Should complete within 3 seconds
        expect(result.data?.processingTime, lessThan(2000)); // Processing should be under 2 seconds
        verify(mockPoseDetector.detectPose(frameData.imageBytes, poseTarget)).called(1);
        verify(mockRegistrationRepository.saveFrame(sessionId, selectedFrame)).called(1);
      });

      test('should handle network failures during frame upload gracefully', () async {
        // Arrange
        const sessionId = 'network-fail-session';
        const poseTarget = PoseTarget.rightProfile;
        final frameData = CaptureFrameRequest(
          sessionId: sessionId,
          poseTarget: poseTarget,
          imageBytes: Uint8List.fromList([51, 52, 53, 54, 55]),
          capturedAt: DateTime.now(),
        );
        
        final poseResult = PoseDetectionResult(
          confidence: 0.90,
          keypoints: const [Keypoint(id: 0, x: 400.0, y: 240.0, confidence: 0.92)],
          angles: const PoseAngles(yaw: 45.0, pitch: 0.0, roll: 0.0),
          faceMetrics: const FaceMetrics(width: 110.0, height: 140.0, aspectRatio: 0.786, area: 15400.0),
          boundingBox: const BoundingBox(x: 345.0, y: 170.0, width: 110.0, height: 140.0),
          qualityScore: 0.86,
          timestamp: DateTime.now(),
        );
        
        final networkFailFrame = SelectedFrame(
          id: 'network-fail-frame-uuid',
          sessionId: sessionId,
          poseTarget: poseTarget,
          imageUrl: 'storage/frames/network-fail-frame-uuid.jpg',
          capturedAt: DateTime.now(),
          poseResult: poseResult,
          qualityMetrics: FrameQualityMetrics(
            sharpness: 0.83,
            brightness: 0.71,
            contrast: 0.77,
            faceVisibility: 0.89,
            poseAccuracy: 0.86,
            overallQuality: 0.81,
          ),
          isSelected: true,
          processingTime: 1100,
          createdAt: DateTime.now(),
        );
        
        when(mockPoseDetector.detectPose(frameData.imageBytes, poseTarget))
            .thenAnswer((_) async => poseResult);
        when(mockRegistrationRepository.saveFrame(sessionId, networkFailFrame))
            .thenThrow(const NetworkException('Failed to upload frame to server'));
        
        // Act
        final result = await registrationUseCases.captureFrame(frameData);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isA<NetworkException>());
        expect(result.error?.message, equals('Failed to upload frame to server'));
        verify(mockPoseDetector.detectPose(frameData.imageBytes, poseTarget)).called(1);
        verify(mockRegistrationRepository.saveFrame(sessionId, networkFailFrame)).called(1);
      });
    });
  });
}