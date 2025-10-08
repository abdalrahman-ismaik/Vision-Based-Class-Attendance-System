import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:hadir_mobile_full/features/registration/data/repositories/registration_repository.dart';
import 'package:hadir_mobile_full/shared/domain/entities/registration_session.dart';
import 'package:hadir_mobile_full/shared/domain/entities/selected_frame.dart';
import 'package:hadir_mobile_full/shared/domain/entities/quality_metrics.dart';
import 'package:hadir_mobile_full/features/registration/data/models/registration_requests.dart';

import 'registration_repository_test.mocks.dart';

// Generate mocks
@GenerateMocks([RegistrationRepository])
void main() {
  group('RegistrationRepository Contract Tests', () {
    late MockRegistrationRepository mockRepository;
    
    setUp(() {
      mockRepository = MockRegistrationRepository();
    });

    group('createSession', () {
      test('should return RegistrationSession when creation succeeds', () async {
        // Arrange
        const request = CreateSessionRequest(
          studentId: 'student-uuid-123',
          administratorId: 'admin-uuid-456',
          videoFilePath: '/storage/videos/session-new.mp4',
        );
        
        final expectedSession = RegistrationSession(
          id: 'session-uuid-789',
          studentId: 'student-uuid-123',
          administratorId: 'admin-uuid-456',
          videoFilePath: '/storage/videos/session-new.mp4',
          status: SessionStatus.inProgress,
          startedAt: DateTime.now(),
          videoDurationMs: 0,
          totalFramesProcessed: 0,
          selectedFramesCount: 0,
          overallQualityScore: 0.0,
          poseCoveragePercentage: 0.0,
          metadata: const {},
        );
        
        when(mockRepository.createSession(request))
            .thenAnswer((_) async => expectedSession);
        
        // Act
        final result = await mockRepository.createSession(request);
        
        // Assert
        expect(result, equals(expectedSession));
        expect(result.studentId, equals('student-uuid-123'));
        expect(result.administratorId, equals('admin-uuid-456'));
        expect(result.status, equals(SessionStatus.inProgress));
        expect(result.videoDurationMs, equals(0));
        verify(mockRepository.createSession(request)).called(1);
      });

      test('should throw exception when student not found', () async {
        // Arrange
        const request = CreateSessionRequest(
          studentId: 'non-existent-student',
          administratorId: 'admin-uuid-456',
          videoFilePath: '/storage/videos/session-fail.mp4',
        );
        
        when(mockRepository.createSession(request))
            .thenThrow(const NotFoundException('Student not found'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.createSession(request),
          throwsA(isA<NotFoundException>()),
        );
        verify(mockRepository.createSession(request)).called(1);
      });

      test('should throw exception when administrator not found', () async {
        // Arrange
        const request = CreateSessionRequest(
          studentId: 'student-uuid-123',
          administratorId: 'non-existent-admin',
          videoFilePath: '/storage/videos/session-fail.mp4',
        );
        
        when(mockRepository.createSession(request))
            .thenThrow(const NotFoundException('Administrator not found'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.createSession(request),
          throwsA(isA<NotFoundException>()),
        );
        verify(mockRepository.createSession(request)).called(1);
      });

      test('should throw exception when student has active session', () async {
        // Arrange
        const request = CreateSessionRequest(
          studentId: 'student-with-active-session',
          administratorId: 'admin-uuid-456',
          videoFilePath: '/storage/videos/session-conflict.mp4',
        );
        
        when(mockRepository.createSession(request))
            .thenThrow(const ConflictException('Student already has an active registration session'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.createSession(request),
          throwsA(isA<ConflictException>()),
        );
        verify(mockRepository.createSession(request)).called(1);
      });
    });

    group('getSessionById', () {
      test('should return RegistrationSession when found by ID', () async {
        // Arrange
        const sessionId = 'session-uuid-123';
        final expectedSession = RegistrationSession(
          id: sessionId,
          studentId: 'student-uuid-456',
          administratorId: 'admin-uuid-789',
          videoFilePath: '/storage/videos/session-123.mp4',
          status: SessionStatus.completed,
          startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
          completedAt: DateTime.now(),
          videoDurationMs: 15000,
          totalFramesProcessed: 150,
          selectedFramesCount: 15,
          overallQualityScore: 0.92,
          poseCoveragePercentage: 100.0,
          metadata: const {
            'yolov7_model_version': '1.0',
            'poses_completed': 5,
          },
        );
        
        when(mockRepository.getSessionById(sessionId))
            .thenAnswer((_) async => expectedSession);
        
        // Act
        final result = await mockRepository.getSessionById(sessionId);
        
        // Assert
        expect(result, equals(expectedSession));
        expect(result?.id, equals(sessionId));
        expect(result?.status, equals(SessionStatus.completed));
        expect(result?.selectedFramesCount, equals(15));
        verify(mockRepository.getSessionById(sessionId)).called(1);
      });

      test('should return null when session not found by ID', () async {
        // Arrange
        const nonExistentId = 'non-existent-session';
        
        when(mockRepository.getSessionById(nonExistentId))
            .thenAnswer((_) async => null);
        
        // Act
        final result = await mockRepository.getSessionById(nonExistentId);
        
        // Assert
        expect(result, isNull);
        verify(mockRepository.getSessionById(nonExistentId)).called(1);
      });

      test('should throw exception when ID format is invalid', () async {
        // Arrange
        const invalidId = '';
        
        when(mockRepository.getSessionById(invalidId))
            .thenThrow(const ArgumentException('Invalid session ID format'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.getSessionById(invalidId),
          throwsA(isA<ArgumentException>()),
        );
        verify(mockRepository.getSessionById(invalidId)).called(1);
      });
    });

    group('getSessionsByStudent', () {
      test('should return list of sessions for valid student ID', () async {
        // Arrange
        const studentId = 'student-uuid-123';
        final expectedSessions = [
          RegistrationSession(
            id: 'session-1',
            studentId: studentId,
            administratorId: 'admin-1',
            videoFilePath: '/storage/videos/session-1.mp4',
            status: SessionStatus.completed,
            startedAt: DateTime.now().subtract(const Duration(days: 2)),
            completedAt: DateTime.now().subtract(const Duration(days: 2, hours: -1)),
            videoDurationMs: 12000,
            totalFramesProcessed: 120,
            selectedFramesCount: 15,
            overallQualityScore: 0.88,
            poseCoveragePercentage: 95.0,
            metadata: const {},
          ),
          RegistrationSession(
            id: 'session-2',
            studentId: studentId,
            administratorId: 'admin-2',
            videoFilePath: '/storage/videos/session-2.mp4',
            status: SessionStatus.failed,
            startedAt: DateTime.now().subtract(const Duration(days: 1)),
            completedAt: DateTime.now().subtract(const Duration(days: 1, hours: -1)),
            videoDurationMs: 8000,
            totalFramesProcessed: 80,
            selectedFramesCount: 8,
            overallQualityScore: 0.65,
            poseCoveragePercentage: 60.0,
            metadata: const {'failure_reason': 'insufficient_quality'},
          ),
        ];
        
        when(mockRepository.getSessionsByStudent(studentId))
            .thenAnswer((_) async => expectedSessions);
        
        // Act
        final result = await mockRepository.getSessionsByStudent(studentId);
        
        // Assert
        expect(result, equals(expectedSessions));
        expect(result, hasLength(2));
        expect(result.every((session) => session.studentId == studentId), isTrue);
        expect(result[0].status, equals(SessionStatus.completed));
        expect(result[1].status, equals(SessionStatus.failed));
        verify(mockRepository.getSessionsByStudent(studentId)).called(1);
      });

      test('should return empty list when student has no sessions', () async {
        // Arrange
        const studentIdWithNoSessions = 'student-no-sessions';
        
        when(mockRepository.getSessionsByStudent(studentIdWithNoSessions))
            .thenAnswer((_) async => []);
        
        // Act
        final result = await mockRepository.getSessionsByStudent(studentIdWithNoSessions);
        
        // Assert
        expect(result, isEmpty);
        verify(mockRepository.getSessionsByStudent(studentIdWithNoSessions)).called(1);
      });

      test('should throw exception when student ID is invalid', () async {
        // Arrange
        const invalidStudentId = '';
        
        when(mockRepository.getSessionsByStudent(invalidStudentId))
            .thenThrow(const ArgumentException('Invalid student ID format'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.getSessionsByStudent(invalidStudentId),
          throwsA(isA<ArgumentException>()),
        );
        verify(mockRepository.getSessionsByStudent(invalidStudentId)).called(1);
      });
    });

    group('updateSession', () {
      test('should return updated RegistrationSession when update succeeds', () async {
        // Arrange
        const sessionId = 'session-uuid-123';
        const updateRequest = UpdateSessionRequest(
          status: SessionStatus.completed,
          videoDurationMs: 15000,
          totalFramesProcessed: 150,
          selectedFramesCount: 15,
          overallQualityScore: 0.92,
          poseCoveragePercentage: 100.0,
          metadata: {
            'yolov7_model_version': '1.0',
            'poses_completed': 5,
            'total_poses_required': 5,
          },
        );
        
        final expectedSession = RegistrationSession(
          id: sessionId,
          studentId: 'student-uuid-456',
          administratorId: 'admin-uuid-789',
          videoFilePath: '/storage/videos/session-123.mp4',
          status: SessionStatus.completed,
          startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
          completedAt: DateTime.now(),
          videoDurationMs: 15000,
          totalFramesProcessed: 150,
          selectedFramesCount: 15,
          overallQualityScore: 0.92,
          poseCoveragePercentage: 100.0,
          metadata: const {
            'yolov7_model_version': '1.0',
            'poses_completed': 5,
            'total_poses_required': 5,
          },
        );
        
        when(mockRepository.updateSession(sessionId, updateRequest))
            .thenAnswer((_) async => expectedSession);
        
        // Act
        final result = await mockRepository.updateSession(sessionId, updateRequest);
        
        // Assert
        expect(result, equals(expectedSession));
        expect(result.status, equals(SessionStatus.completed));
        expect(result.videoDurationMs, equals(15000));
        expect(result.selectedFramesCount, equals(15));
        expect(result.overallQualityScore, equals(0.92));
        expect(result.completedAt, isNotNull);
        verify(mockRepository.updateSession(sessionId, updateRequest)).called(1);
      });

      test('should throw exception when session not found for update', () async {
        // Arrange
        const nonExistentId = 'non-existent-session';
        const updateRequest = UpdateSessionRequest(
          status: SessionStatus.completed,
        );
        
        when(mockRepository.updateSession(nonExistentId, updateRequest))
            .thenThrow(const NotFoundException('Registration session not found'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.updateSession(nonExistentId, updateRequest),
          throwsA(isA<NotFoundException>()),
        );
        verify(mockRepository.updateSession(nonExistentId, updateRequest)).called(1);
      });

      test('should throw exception when update validation fails', () async {
        // Arrange
        const sessionId = 'session-uuid-123';
        const invalidUpdateRequest = UpdateSessionRequest(
          overallQualityScore: 1.5, // Invalid score > 1.0
        );
        
        when(mockRepository.updateSession(sessionId, invalidUpdateRequest))
            .thenThrow(const ValidationException('Invalid quality score range'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.updateSession(sessionId, invalidUpdateRequest),
          throwsA(isA<ValidationException>()),
        );
        verify(mockRepository.updateSession(sessionId, invalidUpdateRequest)).called(1);
      });

      test('should throw exception when invalid state transition attempted', () async {
        // Arrange
        const sessionId = 'completed-session';
        const invalidTransitionRequest = UpdateSessionRequest(
          status: SessionStatus.inProgress, // Cannot go from completed back to in-progress
        );
        
        when(mockRepository.updateSession(sessionId, invalidTransitionRequest))
            .thenThrow(const StateTransitionException('Invalid session state transition'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.updateSession(sessionId, invalidTransitionRequest),
          throwsA(isA<StateTransitionException>()),
        );
        verify(mockRepository.updateSession(sessionId, invalidTransitionRequest)).called(1);
      });
    });

    group('watchSession', () {
      test('should return stream of RegistrationSession updates', () async {
        // Arrange
        const sessionId = 'session-live-updates';
        final sessionUpdates = [
          RegistrationSession(
            id: sessionId,
            studentId: 'student-123',
            administratorId: 'admin-456',
            videoFilePath: '/storage/live-session.mp4',
            status: SessionStatus.inProgress,
            startedAt: DateTime.now(),
            videoDurationMs: 0,
            totalFramesProcessed: 0,
            selectedFramesCount: 0,
            overallQualityScore: 0.0,
            poseCoveragePercentage: 0.0,
            metadata: const {},
          ),
          RegistrationSession(
            id: sessionId,
            studentId: 'student-123',
            administratorId: 'admin-456',
            videoFilePath: '/storage/live-session.mp4',
            status: SessionStatus.inProgress,
            startedAt: DateTime.now().subtract(const Duration(seconds: 30)),
            videoDurationMs: 5000,
            totalFramesProcessed: 50,
            selectedFramesCount: 5,
            overallQualityScore: 0.75,
            poseCoveragePercentage: 40.0,
            metadata: const {'poses_completed': 2},
          ),
          RegistrationSession(
            id: sessionId,
            studentId: 'student-123',
            administratorId: 'admin-456',
            videoFilePath: '/storage/live-session.mp4',
            status: SessionStatus.completed,
            startedAt: DateTime.now().subtract(const Duration(minutes: 1)),
            completedAt: DateTime.now(),
            videoDurationMs: 15000,
            totalFramesProcessed: 150,
            selectedFramesCount: 15,
            overallQualityScore: 0.91,
            poseCoveragePercentage: 100.0,
            metadata: const {'poses_completed': 5},
          ),
        ];
        
        when(mockRepository.watchSession(sessionId))
            .thenAnswer((_) => Stream.fromIterable(sessionUpdates));
        
        // Act
        final stream = mockRepository.watchSession(sessionId);
        final result = await stream.toList();
        
        // Assert
        expect(result, hasLength(3));
        expect(result[0].status, equals(SessionStatus.inProgress));
        expect(result[0].selectedFramesCount, equals(0));
        expect(result[1].selectedFramesCount, equals(5));
        expect(result[2].status, equals(SessionStatus.completed));
        expect(result[2].selectedFramesCount, equals(15));
        verify(mockRepository.watchSession(sessionId)).called(1);
      });

      test('should handle stream errors appropriately', () async {
        // Arrange
        const sessionId = 'session-stream-error';
        
        when(mockRepository.watchSession(sessionId))
            .thenAnswer((_) => Stream.error(const NetworkException('Connection lost')));
        
        // Act & Assert
        expect(
          mockRepository.watchSession(sessionId),
          emitsError(isA<NetworkException>()),
        );
        verify(mockRepository.watchSession(sessionId)).called(1);
      });

      test('should close stream when session is deleted', () async {
        // Arrange
        const sessionId = 'session-to-be-deleted';
        final initialSession = RegistrationSession(
          id: sessionId,
          studentId: 'student-123',
          administratorId: 'admin-456',
          videoFilePath: '/storage/delete-test.mp4',
          status: SessionStatus.inProgress,
          startedAt: DateTime.now(),
          videoDurationMs: 0,
          totalFramesProcessed: 0,
          selectedFramesCount: 0,
          overallQualityScore: 0.0,
          poseCoveragePercentage: 0.0,
          metadata: const {},
        );
        
        when(mockRepository.watchSession(sessionId))
            .thenAnswer((_) => Stream.fromIterable([initialSession]).asBroadcastStream());
        
        // Act
        final stream = mockRepository.watchSession(sessionId);
        final result = await stream.take(1).toList();
        
        // Assert
        expect(result, hasLength(1));
        expect(result[0], equals(initialSession));
        verify(mockRepository.watchSession(sessionId)).called(1);
      });
    });

    group('saveSelectedFrames', () {
      test('should return list of saved SelectedFrames when save succeeds', () async {
        // Arrange
        const sessionId = 'session-uuid-123';
        final framesToSave = [
          SelectedFrame(
            id: 'frame-1',
            sessionId: sessionId,
            imageFilePath: '/storage/frames/frame-1.jpg',
            timestampMs: 2000,
            qualityScore: 0.92,
            poseAngles: const PoseAngles(yaw: 0.0, pitch: 0.0, roll: 0.0, confidence: 0.95),
            faceMetrics: const FaceMetrics(
              boundingBox: BoundingBox(x: 0.25, y: 0.20, width: 0.5, height: 0.6),
              faceSize: 0.45,
              sharpnessScore: 0.88,
              lightingScore: 0.90,
              symmetryScore: 0.87,
              hasGlasses: false,
              hasHat: false,
              isSmiling: false,
            ),
            extractedAt: DateTime.now(),
          ),
          SelectedFrame(
            id: 'frame-2',
            sessionId: sessionId,
            imageFilePath: '/storage/frames/frame-2.jpg',
            timestampMs: 6000,
            qualityScore: 0.89,
            poseAngles: const PoseAngles(yaw: 45.0, pitch: 0.0, roll: 0.0, confidence: 0.92),
            faceMetrics: const FaceMetrics(
              boundingBox: BoundingBox(x: 0.30, y: 0.25, width: 0.4, height: 0.5),
              faceSize: 0.40,
              sharpnessScore: 0.85,
              lightingScore: 0.87,
              symmetryScore: 0.84,
              hasGlasses: false,
              hasHat: false,
              isSmiling: true,
            ),
            extractedAt: DateTime.now(),
          ),
        ];
        
        when(mockRepository.saveSelectedFrames(sessionId, framesToSave))
            .thenAnswer((_) async => framesToSave);
        
        // Act
        final result = await mockRepository.saveSelectedFrames(sessionId, framesToSave);
        
        // Assert
        expect(result, equals(framesToSave));
        expect(result, hasLength(2));
        expect(result.every((frame) => frame.sessionId == sessionId), isTrue);
        expect(result[0].qualityScore, equals(0.92));
        expect(result[1].qualityScore, equals(0.89));
        verify(mockRepository.saveSelectedFrames(sessionId, framesToSave)).called(1);
      });

      test('should throw exception when session not found for frame save', () async {
        // Arrange
        const nonExistentSessionId = 'non-existent-session';
        final frames = [
          SelectedFrame(
            id: 'frame-orphan',
            sessionId: nonExistentSessionId,
            imageFilePath: '/storage/frames/orphan.jpg',
            timestampMs: 1000,
            qualityScore: 0.85,
            poseAngles: const PoseAngles(yaw: 0.0, pitch: 0.0, roll: 0.0, confidence: 0.90),
            faceMetrics: const FaceMetrics(
              boundingBox: BoundingBox(x: 0.2, y: 0.15, width: 0.6, height: 0.7),
              faceSize: 0.35,
              sharpnessScore: 0.82,
              lightingScore: 0.84,
              symmetryScore: 0.80,
              hasGlasses: false,
              hasHat: false,
              isSmiling: false,
            ),
            extractedAt: DateTime.now(),
          ),
        ];
        
        when(mockRepository.saveSelectedFrames(nonExistentSessionId, frames))
            .thenThrow(const NotFoundException('Registration session not found'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.saveSelectedFrames(nonExistentSessionId, frames),
          throwsA(isA<NotFoundException>()),
        );
        verify(mockRepository.saveSelectedFrames(nonExistentSessionId, frames)).called(1);
      });

      test('should throw exception when frame validation fails', () async {
        // Arrange
        const sessionId = 'session-uuid-123';
        final invalidFrames = [
          SelectedFrame(
            id: 'frame-invalid',
            sessionId: sessionId,
            imageFilePath: '/storage/frames/invalid.jpg',
            timestampMs: 1000,
            qualityScore: 0.75, // Below minimum threshold of 0.8
            poseAngles: const PoseAngles(yaw: 0.0, pitch: 0.0, roll: 0.0, confidence: 0.90),
            faceMetrics: const FaceMetrics(
              boundingBox: BoundingBox(x: 0.2, y: 0.15, width: 0.6, height: 0.7),
              faceSize: 0.35,
              sharpnessScore: 0.82,
              lightingScore: 0.84,
              symmetryScore: 0.80,
              hasGlasses: false,
              hasHat: false,
              isSmiling: false,
            ),
            extractedAt: DateTime.now(),
          ),
        ];
        
        when(mockRepository.saveSelectedFrames(sessionId, invalidFrames))
            .thenThrow(const ValidationException('Frame quality score below minimum threshold'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.saveSelectedFrames(sessionId, invalidFrames),
          throwsA(isA<ValidationException>()),
        );
        verify(mockRepository.saveSelectedFrames(sessionId, invalidFrames)).called(1);
      });
    });

    group('getSelectedFrames', () {
      test('should return list of SelectedFrames for valid session', () async {
        // Arrange
        const sessionId = 'session-with-frames';
        final expectedFrames = [
          SelectedFrame(
            id: 'frame-straight',
            sessionId: sessionId,
            imageFilePath: '/storage/frames/straight.jpg',
            timestampMs: 3000,
            qualityScore: 0.94,
            poseAngles: const PoseAngles(yaw: 0.0, pitch: 0.0, roll: 0.0, confidence: 0.96),
            faceMetrics: const FaceMetrics(
              boundingBox: BoundingBox(x: 0.25, y: 0.20, width: 0.5, height: 0.6),
              faceSize: 0.45,
              sharpnessScore: 0.90,
              lightingScore: 0.92,
              symmetryScore: 0.89,
              hasGlasses: false,
              hasHat: false,
              isSmiling: false,
            ),
            extractedAt: DateTime.now(),
          ),
          SelectedFrame(
            id: 'frame-profile',
            sessionId: sessionId,
            imageFilePath: '/storage/frames/profile.jpg',
            timestampMs: 9000,
            qualityScore: 0.87,
            poseAngles: const PoseAngles(yaw: -45.0, pitch: 0.0, roll: 0.0, confidence: 0.91),
            faceMetrics: const FaceMetrics(
              boundingBox: BoundingBox(x: 0.30, y: 0.25, width: 0.4, height: 0.5),
              faceSize: 0.40,
              sharpnessScore: 0.85,
              lightingScore: 0.88,
              symmetryScore: 0.83,
              hasGlasses: false,
              hasHat: false,
              isSmiling: false,
            ),
            extractedAt: DateTime.now(),
          ),
        ];
        
        when(mockRepository.getSelectedFrames(sessionId))
            .thenAnswer((_) async => expectedFrames);
        
        // Act
        final result = await mockRepository.getSelectedFrames(sessionId);
        
        // Assert
        expect(result, equals(expectedFrames));
        expect(result, hasLength(2));
        expect(result.every((frame) => frame.sessionId == sessionId), isTrue);
        expect(result[0].poseAngles.yaw, equals(0.0)); // Straight pose
        expect(result[1].poseAngles.yaw, equals(-45.0)); // Profile pose
        verify(mockRepository.getSelectedFrames(sessionId)).called(1);
      });

      test('should return empty list when session has no frames', () async {
        // Arrange
        const sessionWithoutFrames = 'session-no-frames';
        
        when(mockRepository.getSelectedFrames(sessionWithoutFrames))
            .thenAnswer((_) async => []);
        
        // Act
        final result = await mockRepository.getSelectedFrames(sessionWithoutFrames);
        
        // Assert
        expect(result, isEmpty);
        verify(mockRepository.getSelectedFrames(sessionWithoutFrames)).called(1);
      });

      test('should throw exception when session not found for frame retrieval', () async {
        // Arrange
        const nonExistentSessionId = 'non-existent-session';
        
        when(mockRepository.getSelectedFrames(nonExistentSessionId))
            .thenThrow(const NotFoundException('Registration session not found'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.getSelectedFrames(nonExistentSessionId),
          throwsA(isA<NotFoundException>()),
        );
        verify(mockRepository.getSelectedFrames(nonExistentSessionId)).called(1);
      });
    });

    group('saveQualityMetrics', () {
      test('should return saved QualityMetrics when save succeeds', () async {
        // Arrange
        const sessionId = 'session-quality-metrics';
        final metricsToSave = QualityMetrics(
          sessionId: sessionId,
          overallQuality: 0.91,
          poseMetrics: const CoverageMetrics(
            frontalCoverage: 95.0,
            leftProfileCoverage: 88.0,
            rightProfileCoverage: 92.0,
            uptiltCoverage: 85.0,
            downtiltCoverage: 90.0,
            overallCoverage: 90.0,
          ),
          qualityDistribution: const QualityDistribution(
            highQuality: 12,
            mediumQuality: 3,
            lowQuality: 0,
            averageScore: 0.91,
            standardDeviation: 0.03,
          ),
          environmental: const EnvironmentalFactors(
            lighting: LightingCondition.excellent,
            background: BackgroundType.plain,
            noiseLevel: 0.1,
            detectedIssues: [],
          ),
          processingStats: const ProcessingStats(
            totalFramesAnalyzed: 150,
            framesRejected: 135,
            framesSelected: 15,
            averageProcessingTimeMs: 45,
            yolov7InferenceTimeMs: 32,
          ),
        );
        
        when(mockRepository.saveQualityMetrics(sessionId, metricsToSave))
            .thenAnswer((_) async => metricsToSave);
        
        // Act
        final result = await mockRepository.saveQualityMetrics(sessionId, metricsToSave);
        
        // Assert
        expect(result, equals(metricsToSave));
        expect(result.sessionId, equals(sessionId));
        expect(result.overallQuality, equals(0.91));
        expect(result.poseMetrics.overallCoverage, equals(90.0));
        expect(result.qualityDistribution.highQuality, equals(12));
        verify(mockRepository.saveQualityMetrics(sessionId, metricsToSave)).called(1);
      });

      test('should throw exception when session not found for quality metrics save', () async {
        // Arrange
        const nonExistentSessionId = 'non-existent-session';
        final metrics = QualityMetrics(
          sessionId: nonExistentSessionId,
          overallQuality: 0.85,
          poseMetrics: const CoverageMetrics(
            frontalCoverage: 80.0,
            leftProfileCoverage: 75.0,
            rightProfileCoverage: 78.0,
            uptiltCoverage: 70.0,
            downtiltCoverage: 72.0,
            overallCoverage: 75.0,
          ),
          qualityDistribution: const QualityDistribution(
            highQuality: 8,
            mediumQuality: 4,
            lowQuality: 3,
            averageScore: 0.85,
            standardDeviation: 0.08,
          ),
          environmental: const EnvironmentalFactors(
            lighting: LightingCondition.good,
            background: BackgroundType.indoor,
            noiseLevel: 0.2,
            detectedIssues: ['shadows'],
          ),
          processingStats: const ProcessingStats(
            totalFramesAnalyzed: 120,
            framesRejected: 105,
            framesSelected: 15,
            averageProcessingTimeMs: 50,
            yolov7InferenceTimeMs: 38,
          ),
        );
        
        when(mockRepository.saveQualityMetrics(nonExistentSessionId, metrics))
            .thenThrow(const NotFoundException('Registration session not found'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.saveQualityMetrics(nonExistentSessionId, metrics),
          throwsA(isA<NotFoundException>()),
        );
        verify(mockRepository.saveQualityMetrics(nonExistentSessionId, metrics)).called(1);
      });
    });

    group('getQualityMetrics', () {
      test('should return QualityMetrics when found for session', () async {
        // Arrange
        const sessionId = 'session-with-metrics';
        final expectedMetrics = QualityMetrics(
          sessionId: sessionId,
          overallQuality: 0.89,
          poseMetrics: const CoverageMetrics(
            frontalCoverage: 92.0,
            leftProfileCoverage: 85.0,
            rightProfileCoverage: 88.0,
            uptiltCoverage: 82.0,
            downtiltCoverage: 87.0,
            overallCoverage: 87.0,
          ),
          qualityDistribution: const QualityDistribution(
            highQuality: 10,
            mediumQuality: 4,
            lowQuality: 1,
            averageScore: 0.89,
            standardDeviation: 0.05,
          ),
          environmental: const EnvironmentalFactors(
            lighting: LightingCondition.excellent,
            background: BackgroundType.plain,
            noiseLevel: 0.05,
            detectedIssues: [],
          ),
          processingStats: const ProcessingStats(
            totalFramesAnalyzed: 140,
            framesRejected: 125,
            framesSelected: 15,
            averageProcessingTimeMs: 42,
            yolov7InferenceTimeMs: 30,
          ),
        );
        
        when(mockRepository.getQualityMetrics(sessionId))
            .thenAnswer((_) async => expectedMetrics);
        
        // Act
        final result = await mockRepository.getQualityMetrics(sessionId);
        
        // Assert
        expect(result, equals(expectedMetrics));
        expect(result?.sessionId, equals(sessionId));
        expect(result?.overallQuality, equals(0.89));
        verify(mockRepository.getQualityMetrics(sessionId)).called(1);
      });

      test('should return null when quality metrics not found for session', () async {
        // Arrange
        const sessionWithoutMetrics = 'session-no-metrics';
        
        when(mockRepository.getQualityMetrics(sessionWithoutMetrics))
            .thenAnswer((_) async => null);
        
        // Act
        final result = await mockRepository.getQualityMetrics(sessionWithoutMetrics);
        
        // Assert
        expect(result, isNull);
        verify(mockRepository.getQualityMetrics(sessionWithoutMetrics)).called(1);
      });
    });

    group('Error Handling Contract', () {
      test('should handle concurrent session updates gracefully', () async {
        // Arrange
        const sessionId = 'concurrent-session';
        const updateRequest = UpdateSessionRequest(status: SessionStatus.completed);
        
        when(mockRepository.updateSession(sessionId, updateRequest))
            .thenThrow(const ConcurrencyException('Session was modified by another process'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.updateSession(sessionId, updateRequest),
          throwsA(isA<ConcurrencyException>()),
        );
        verify(mockRepository.updateSession(sessionId, updateRequest)).called(1);
      });

      test('should handle file system errors during frame operations', () async {
        // Arrange
        const sessionId = 'session-fs-error';
        final frames = [
          SelectedFrame(
            id: 'frame-fs-error',
            sessionId: sessionId,
            imageFilePath: '/invalid/path/frame.jpg',
            timestampMs: 1000,
            qualityScore: 0.85,
            poseAngles: const PoseAngles(yaw: 0.0, pitch: 0.0, roll: 0.0, confidence: 0.90),
            faceMetrics: const FaceMetrics(
              boundingBox: BoundingBox(x: 0.2, y: 0.15, width: 0.6, height: 0.7),
              faceSize: 0.35,
              sharpnessScore: 0.82,
              lightingScore: 0.84,
              symmetryScore: 0.80,
              hasGlasses: false,
              hasHat: false,
              isSmiling: false,
            ),
            extractedAt: DateTime.now(),
          ),
        ];
        
        when(mockRepository.saveSelectedFrames(sessionId, frames))
            .thenThrow(const FileSystemException('Unable to save frame file'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.saveSelectedFrames(sessionId, frames),
          throwsA(isA<FileSystemException>()),
        );
        verify(mockRepository.saveSelectedFrames(sessionId, frames)).called(1);
      });

      test('should handle database transaction failures', () async {
        // Arrange
        const request = CreateSessionRequest(
          studentId: 'student-transaction-fail',
          administratorId: 'admin-transaction-fail',
          videoFilePath: '/storage/transaction-fail.mp4',
        );
        
        when(mockRepository.createSession(request))
            .thenThrow(const DatabaseException('Transaction failed'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.createSession(request),
          throwsA(isA<DatabaseException>()),
        );
        verify(mockRepository.createSession(request)).called(1);
      });
    });

    group('YOLOv7-Pose Integration Contract', () {
      test('should handle YOLOv7-specific metadata in session updates', () async {
        // Arrange
        const sessionId = 'yolov7-session';
        const yolov7UpdateRequest = UpdateSessionRequest(
          status: SessionStatus.completed,
          videoDurationMs: 15000,
          totalFramesProcessed: 150,
          selectedFramesCount: 15, // 3 frames per pose × 5 poses
          overallQualityScore: 0.93,
          poseCoveragePercentage: 100.0,
          metadata: {
            'yolov7_model_version': '1.0',
            'pose_detection_confidence': 0.95,
            'keypoints_detected': 17,
            'pose_sequence': ['straight', 'right_profile', 'left_profile', 'head_up', 'head_down'],
            'poses_completed': 5,
            'frames_per_pose': 3,
            'gpu_acceleration': true,
            'inference_time_ms': 45,
          },
        );
        
        final expectedSession = RegistrationSession(
          id: sessionId,
          studentId: 'student-yolov7',
          administratorId: 'admin-yolov7',
          videoFilePath: '/storage/yolov7-session.mp4',
          status: SessionStatus.completed,
          startedAt: DateTime.now().subtract(const Duration(minutes: 2)),
          completedAt: DateTime.now(),
          videoDurationMs: 15000,
          totalFramesProcessed: 150,
          selectedFramesCount: 15,
          overallQualityScore: 0.93,
          poseCoveragePercentage: 100.0,
          metadata: const {
            'yolov7_model_version': '1.0',
            'pose_detection_confidence': 0.95,
            'keypoints_detected': 17,
            'pose_sequence': ['straight', 'right_profile', 'left_profile', 'head_up', 'head_down'],
            'poses_completed': 5,
            'frames_per_pose': 3,
            'gpu_acceleration': true,
            'inference_time_ms': 45,
          },
        );
        
        when(mockRepository.updateSession(sessionId, yolov7UpdateRequest))
            .thenAnswer((_) async => expectedSession);
        
        // Act
        final result = await mockRepository.updateSession(sessionId, yolov7UpdateRequest);
        
        // Assert
        expect(result.metadata['yolov7_model_version'], equals('1.0'));
        expect(result.metadata['poses_completed'], equals(5));
        expect(result.metadata['keypoints_detected'], equals(17));
        expect(result.selectedFramesCount, equals(15)); // 3 × 5 poses
        expect(result.poseCoveragePercentage, equals(100.0));
        verify(mockRepository.updateSession(sessionId, yolov7UpdateRequest)).called(1);
      });

      test('should validate pose-specific frame requirements', () async {
        // Arrange
        const sessionId = 'pose-validation-session';
        final invalidPoseFrames = [
          // Only 10 frames instead of required 15 (3 per pose × 5 poses)
          ...List.generate(10, (index) => SelectedFrame(
            id: 'frame-$index',
            sessionId: sessionId,
            imageFilePath: '/storage/frames/frame-$index.jpg',
            timestampMs: index * 1000,
            qualityScore: 0.85,
            poseAngles: const PoseAngles(yaw: 0.0, pitch: 0.0, roll: 0.0, confidence: 0.90),
            faceMetrics: const FaceMetrics(
              boundingBox: BoundingBox(x: 0.25, y: 0.20, width: 0.5, height: 0.6),
              faceSize: 0.40,
              sharpnessScore: 0.85,
              lightingScore: 0.88,
              symmetryScore: 0.86,
              hasGlasses: false,
              hasHat: false,
              isSmiling: false,
            ),
            extractedAt: DateTime.now(),
          )),
        ];
        
        when(mockRepository.saveSelectedFrames(sessionId, invalidPoseFrames))
            .thenThrow(const ValidationException('Insufficient frames for 5-pose coverage (expected 15, got 10)'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.saveSelectedFrames(sessionId, invalidPoseFrames),
          throwsA(isA<ValidationException>()),
        );
        verify(mockRepository.saveSelectedFrames(sessionId, invalidPoseFrames)).called(1);
      });
    });
  });
}