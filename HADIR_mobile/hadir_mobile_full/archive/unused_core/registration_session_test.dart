import 'package:flutter_test/flutter_test.dart';
import 'package:hadir_mobile_full/shared/domain/entities/registration_session.dart';

void main() {
  group('RegistrationSession Entity', () {
    test('should create RegistrationSession instance with complete data', () {
      // Arrange
      const id = 'session-123';
      const studentId = 'student-456';
      const administratorId = 'admin-789';
      const videoFilePath = '/storage/videos/session-123.mp4';
      const status = SessionStatus.completed;
      final startedAt = DateTime.now().subtract(const Duration(minutes: 5));
      final completedAt = DateTime.now();
      const videoDurationMs = 15000; // 15 seconds for 5-pose capture
      const totalFramesProcessed = 150; // 30 FPS × 5 seconds
      const selectedFramesCount = 15; // 3 frames per pose × 5 poses
      const overallQualityScore = 0.92;
      const poseCoveragePercentage = 100.0; // All 5 poses captured
      final metadata = {
        'yolov7_model_version': '1.0',
        'pose_sequence': ['straight', 'right_profile', 'left_profile', 'head_up', 'head_down'],
        'poses_completed': 5,
        'total_poses_required': 5,
        'device_info': 'Android 12',
        'camera_resolution': '1920x1080',
      };
      
      // Act
      final session = RegistrationSession(
        id: id,
        studentId: studentId,
        administratorId: administratorId,
        videoFilePath: videoFilePath,
        status: status,
        startedAt: startedAt,
        completedAt: completedAt,
        videoDurationMs: videoDurationMs,
        totalFramesProcessed: totalFramesProcessed,
        selectedFramesCount: selectedFramesCount,
        overallQualityScore: overallQualityScore,
        poseCoveragePercentage: poseCoveragePercentage,
        metadata: metadata,
      );
      
      // Assert
      expect(session.id, equals(id));
      expect(session.studentId, equals(studentId));
      expect(session.administratorId, equals(administratorId));
      expect(session.videoFilePath, equals(videoFilePath));
      expect(session.status, equals(status));
      expect(session.startedAt, equals(startedAt));
      expect(session.completedAt, equals(completedAt));
      expect(session.videoDurationMs, equals(videoDurationMs));
      expect(session.totalFramesProcessed, equals(totalFramesProcessed));
      expect(session.selectedFramesCount, equals(selectedFramesCount));
      expect(session.overallQualityScore, equals(overallQualityScore));
      expect(session.poseCoveragePercentage, equals(poseCoveragePercentage));
      expect(session.metadata, equals(metadata));
      expect(session.metadata['poses_completed'], equals(5));
    });

    test('should create RegistrationSession with minimal required data', () {
      // Arrange
      const id = 'session-minimal';
      const studentId = 'student-001';
      const administratorId = 'admin-001';
      const videoFilePath = '/storage/videos/session-minimal.mp4';
      const status = SessionStatus.inProgress;
      final startedAt = DateTime.now();
      const videoDurationMs = 0; // Session just started
      const totalFramesProcessed = 0;
      const selectedFramesCount = 0;
      const overallQualityScore = 0.0;
      const poseCoveragePercentage = 0.0;
      const metadata = <String, dynamic>{};
      
      // Act
      final session = RegistrationSession(
        id: id,
        studentId: studentId,
        administratorId: administratorId,
        videoFilePath: videoFilePath,
        status: status,
        startedAt: startedAt,
        videoDurationMs: videoDurationMs,
        totalFramesProcessed: totalFramesProcessed,
        selectedFramesCount: selectedFramesCount,
        overallQualityScore: overallQualityScore,
        poseCoveragePercentage: poseCoveragePercentage,
        metadata: metadata,
      );
      
      // Assert
      expect(session.id, equals(id));
      expect(session.status, equals(SessionStatus.inProgress));
      expect(session.videoDurationMs, equals(0));
      expect(session.selectedFramesCount, equals(0));
      expect(session.completedAt, isNull);
      expect(session.metadata, isEmpty);
    });

    test('should support equality comparison', () {
      // Arrange
      final startedAt = DateTime.now();
      final completedAt = startedAt.add(const Duration(minutes: 2));
      const metadata = {'test': 'data'};
      
      final session1 = RegistrationSession(
        id: 'session-equal-1',
        studentId: 'student-123',
        administratorId: 'admin-123',
        videoFilePath: '/storage/test.mp4',
        status: SessionStatus.completed,
        startedAt: startedAt,
        completedAt: completedAt,
        videoDurationMs: 12000,
        totalFramesProcessed: 120,
        selectedFramesCount: 15,
        overallQualityScore: 0.85,
        poseCoveragePercentage: 90.0,
        metadata: metadata,
      );
      
      final session2 = RegistrationSession(
        id: 'session-equal-1',
        studentId: 'student-123',
        administratorId: 'admin-123',
        videoFilePath: '/storage/test.mp4',
        status: SessionStatus.completed,
        startedAt: startedAt,
        completedAt: completedAt,
        videoDurationMs: 12000,
        totalFramesProcessed: 120,
        selectedFramesCount: 15,
        overallQualityScore: 0.85,
        poseCoveragePercentage: 90.0,
        metadata: metadata,
      );
      
      // Act & Assert
      expect(session1, equals(session2));
      expect(session1.hashCode, equals(session2.hashCode));
    });

    test('should have different hash codes for different sessions', () {
      // Arrange
      final now = DateTime.now();
      final session1 = RegistrationSession(
        id: 'session-different-1',
        studentId: 'student-111',
        administratorId: 'admin-111',
        videoFilePath: '/storage/video1.mp4',
        status: SessionStatus.completed,
        startedAt: now,
        videoDurationMs: 10000,
        totalFramesProcessed: 100,
        selectedFramesCount: 12,
        overallQualityScore: 0.80,
        poseCoveragePercentage: 80.0,
        metadata: const {},
      );
      
      final session2 = RegistrationSession(
        id: 'session-different-2',
        studentId: 'student-222',
        administratorId: 'admin-222',
        videoFilePath: '/storage/video2.mp4',
        status: SessionStatus.failed,
        startedAt: now,
        videoDurationMs: 8000,
        totalFramesProcessed: 80,
        selectedFramesCount: 8,
        overallQualityScore: 0.65,
        poseCoveragePercentage: 60.0,
        metadata: const {},
      );
      
      // Act & Assert
      expect(session1, isNot(equals(session2)));
      expect(session1.hashCode, isNot(equals(session2.hashCode)));
    });

    test('should validate SessionStatus enum values', () {
      // Assert
      expect(SessionStatus.values, hasLength(5));
      expect(SessionStatus.values, contains(SessionStatus.inProgress));
      expect(SessionStatus.values, contains(SessionStatus.completed));
      expect(SessionStatus.values, contains(SessionStatus.failed));
      expect(SessionStatus.values, contains(SessionStatus.cancelled));
      expect(SessionStatus.values, contains(SessionStatus.expired));
    });

    test('should handle completedAt as optional field', () {
      // Arrange
      final session = RegistrationSession(
        id: 'session-in-progress',
        studentId: 'student-progress',
        administratorId: 'admin-progress',
        videoFilePath: '/storage/in-progress.mp4',
        status: SessionStatus.inProgress,
        startedAt: DateTime.now(),
        videoDurationMs: 0,
        totalFramesProcessed: 0,
        selectedFramesCount: 0,
        overallQualityScore: 0.0,
        poseCoveragePercentage: 0.0,
        metadata: const {},
      );
      
      // Act & Assert
      expect(session.completedAt, isNull);
      expect(session.status, equals(SessionStatus.inProgress));
    });

    test('should create copyWith method for immutable updates', () {
      // Arrange
      final original = RegistrationSession(
        id: 'session-update',
        studentId: 'student-update',
        administratorId: 'admin-update',
        videoFilePath: '/storage/update.mp4',
        status: SessionStatus.inProgress,
        startedAt: DateTime.now(),
        videoDurationMs: 5000,
        totalFramesProcessed: 50,
        selectedFramesCount: 5,
        overallQualityScore: 0.70,
        poseCoveragePercentage: 40.0,
        metadata: const {'poses_completed': 2},
      );
      
      final completedAt = DateTime.now();
      final updatedMetadata = {
        'poses_completed': 5,
        'yolov7_confidence': 0.95,
      };
      
      // Act
      final updated = original.copyWith(
        status: SessionStatus.completed,
        completedAt: completedAt,
        videoDurationMs: 15000,
        totalFramesProcessed: 150,
        selectedFramesCount: 15,
        overallQualityScore: 0.92,
        poseCoveragePercentage: 100.0,
        metadata: updatedMetadata,
      );
      
      // Assert
      expect(updated.id, equals(original.id));
      expect(updated.studentId, equals(original.studentId));
      expect(updated.administratorId, equals(original.administratorId));
      expect(updated.videoFilePath, equals(original.videoFilePath));
      expect(updated.startedAt, equals(original.startedAt));
      
      expect(updated.status, equals(SessionStatus.completed));
      expect(updated.completedAt, equals(completedAt));
      expect(updated.videoDurationMs, equals(15000));
      expect(updated.totalFramesProcessed, equals(150));
      expect(updated.selectedFramesCount, equals(15));
      expect(updated.overallQualityScore, equals(0.92));
      expect(updated.poseCoveragePercentage, equals(100.0));
      expect(updated.metadata, equals(updatedMetadata));
      
      // Original should remain unchanged
      expect(original.status, equals(SessionStatus.inProgress));
      expect(original.completedAt, isNull);
      expect(original.videoDurationMs, equals(5000));
      expect(original.metadata['poses_completed'], equals(2));
    });

    test('should support JSON serialization', () {
      // Arrange
      final session = RegistrationSession(
        id: 'session-json',
        studentId: 'student-json',
        administratorId: 'admin-json',
        videoFilePath: '/storage/json-test.mp4',
        status: SessionStatus.completed,
        startedAt: DateTime.parse('2025-01-01T10:00:00Z'),
        completedAt: DateTime.parse('2025-01-01T10:02:30Z'),
        videoDurationMs: 15000,
        totalFramesProcessed: 150,
        selectedFramesCount: 15,
        overallQualityScore: 0.88,
        poseCoveragePercentage: 95.5,
        metadata: const {
          'yolov7_version': '1.0',
          'poses_completed': 5,
          'device': 'Android',
        },
      );
      
      // Act
      final json = session.toJson();
      final fromJson = RegistrationSession.fromJson(json);
      
      // Assert
      expect(fromJson, equals(session));
      expect(json['id'], equals('session-json'));
      expect(json['status'], equals('completed'));
      expect(json['selectedFramesCount'], equals(15));
      expect(json['poseCoveragePercentage'], equals(95.5));
      expect(json['metadata']['poses_completed'], equals(5));
    });

    test('should validate video duration constraints for YOLOv7-Pose guided capture', () {
      // Arrange
      final now = DateTime.now();
      
      // Test valid duration range for 5-pose guided capture (5-30 seconds)
      const validDurations = [5000, 15000, 30000]; // 5s, 15s, 30s
      
      for (int duration in validDurations) {
        // Act & Assert - should not throw
        expect(
          () => RegistrationSession(
            id: 'session-duration-$duration',
            studentId: 'student-test',
            administratorId: 'admin-test',
            videoFilePath: '/storage/test.mp4',
            status: SessionStatus.completed,
            startedAt: now,
            videoDurationMs: duration,
            totalFramesProcessed: duration ~/ 100, // Approximate frame count
            selectedFramesCount: 15, // 3 per pose × 5 poses
            overallQualityScore: 0.85,
            poseCoveragePercentage: 100.0,
            metadata: const {},
          ),
          returnsNormally,
        );
      }
    });

    test('should validate selected frames count for multi-pose capture', () {
      // Arrange
      final now = DateTime.now();
      
      // Valid frame counts for YOLOv7-Pose (3 frames per pose × 5 poses = 15 frames)
      const validFrameCounts = [15]; // Exactly 15 frames for 5-pose capture
      
      for (int frameCount in validFrameCounts) {
        // Act
        final session = RegistrationSession(
          id: 'session-frames-$frameCount',
          studentId: 'student-frames',
          administratorId: 'admin-frames',
          videoFilePath: '/storage/frames-test.mp4',
          status: SessionStatus.completed,
          startedAt: now,
          videoDurationMs: 15000,
          totalFramesProcessed: 150,
          selectedFramesCount: frameCount,
          overallQualityScore: 0.90,
          poseCoveragePercentage: 100.0,
          metadata: const {'poses_completed': 5},
        );
        
        // Assert
        expect(session.selectedFramesCount, equals(frameCount));
        expect(session.selectedFramesCount, equals(15)); // 3 × 5 poses
      }
    });

    test('should validate quality score range', () {
      // Arrange
      final now = DateTime.now();
      const validQualityScores = [0.0, 0.5, 0.8, 0.95, 1.0];
      
      for (double score in validQualityScores) {
        // Act
        final session = RegistrationSession(
          id: 'session-quality-${score.toString().replaceAll('.', '_')}',
          studentId: 'student-quality',
          administratorId: 'admin-quality',
          videoFilePath: '/storage/quality-test.mp4',
          status: SessionStatus.completed,
          startedAt: now,
          videoDurationMs: 15000,
          totalFramesProcessed: 150,
          selectedFramesCount: 15,
          overallQualityScore: score,
          poseCoveragePercentage: 90.0,
          metadata: const {},
        );
        
        // Assert
        expect(session.overallQualityScore, equals(score));
        expect(session.overallQualityScore, inInclusiveRange(0.0, 1.0));
      }
    });

    test('should validate pose coverage percentage range', () {
      // Arrange
      final now = DateTime.now();
      const validCoveragePercentages = [0.0, 25.5, 50.0, 75.8, 100.0];
      
      for (double coverage in validCoveragePercentages) {
        // Act
        final session = RegistrationSession(
          id: 'session-coverage-${coverage.toString().replaceAll('.', '_')}',
          studentId: 'student-coverage',
          administratorId: 'admin-coverage',
          videoFilePath: '/storage/coverage-test.mp4',
          status: SessionStatus.completed,
          startedAt: now,
          videoDurationMs: 15000,
          totalFramesProcessed: 150,
          selectedFramesCount: 15,
          overallQualityScore: 0.85,
          poseCoveragePercentage: coverage,
          metadata: const {},
        );
        
        // Assert
        expect(session.poseCoveragePercentage, equals(coverage));
        expect(session.poseCoveragePercentage, inInclusiveRange(0.0, 100.0));
      }
    });

    test('should support state transitions validation', () {
      // Arrange
      final now = DateTime.now();
      final session = RegistrationSession(
        id: 'session-transitions',
        studentId: 'student-transitions',
        administratorId: 'admin-transitions',
        videoFilePath: '/storage/transitions.mp4',
        status: SessionStatus.inProgress,
        startedAt: now,
        videoDurationMs: 0,
        totalFramesProcessed: 0,
        selectedFramesCount: 0,
        overallQualityScore: 0.0,
        poseCoveragePercentage: 0.0,
        metadata: const {},
      );
      
      // Act - Test valid state transitions
      final completed = session.copyWith(
        status: SessionStatus.completed,
        completedAt: now.add(const Duration(minutes: 2)),
        videoDurationMs: 15000,
        selectedFramesCount: 15,
        poseCoveragePercentage: 100.0,
      );
      
      final failed = session.copyWith(
        status: SessionStatus.failed,
        completedAt: now.add(const Duration(minutes: 1)),
        metadata: const {'failure_reason': 'insufficient_quality'},
      );
      
      final cancelled = session.copyWith(
        status: SessionStatus.cancelled,
        completedAt: now.add(const Duration(seconds: 30)),
        metadata: const {'cancelled_by': 'administrator'},
      );
      
      // Assert
      expect(completed.status, equals(SessionStatus.completed));
      expect(failed.status, equals(SessionStatus.failed));
      expect(cancelled.status, equals(SessionStatus.cancelled));
      
      // Verify original state is preserved
      expect(session.status, equals(SessionStatus.inProgress));
    });

    test('should handle YOLOv7-Pose specific metadata', () {
      // Arrange
      final yolov7Metadata = {
        'yolov7_model_version': '1.0',
        'pose_detection_confidence': 0.95,
        'keypoints_detected': 17, // COCO keypoints
        'pose_sequence': ['straight', 'right_profile', 'left_profile', 'head_up', 'head_down'],
        'poses_completed': 5,
        'frames_per_pose': 3,
        'gpu_acceleration': true,
        'inference_time_ms': 45,
        'device_capabilities': {
          'gpu_available': true,
          'cpu_cores': 8,
          'memory_gb': 6,
        },
      };
      
      // Act
      final session = RegistrationSession(
        id: 'session-yolov7',
        studentId: 'student-yolov7',
        administratorId: 'admin-yolov7',
        videoFilePath: '/storage/yolov7-test.mp4',
        status: SessionStatus.completed,
        startedAt: DateTime.now(),
        videoDurationMs: 15000,
        totalFramesProcessed: 150,
        selectedFramesCount: 15,
        overallQualityScore: 0.93,
        poseCoveragePercentage: 100.0,
        metadata: yolov7Metadata,
      );
      
      // Assert
      expect(session.metadata['yolov7_model_version'], equals('1.0'));
      expect(session.metadata['poses_completed'], equals(5));
      expect(session.metadata['keypoints_detected'], equals(17));
      expect(session.metadata['pose_sequence'], hasLength(5));
      expect(session.metadata['gpu_acceleration'], isTrue);
      expect(session.metadata['device_capabilities'], isA<Map<String, dynamic>>());
    });
  });
}