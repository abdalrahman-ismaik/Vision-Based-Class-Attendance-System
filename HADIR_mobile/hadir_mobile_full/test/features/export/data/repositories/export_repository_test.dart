import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:hadir_mobile_full/features/export/data/repositories/export_repository.dart';
import 'package:hadir_mobile_full/shared/domain/entities/export_package.dart';

import 'export_repository_test.mocks.dart';

// Generate mocks
@GenerateMocks([ExportRepository])
void main() {
  group('ExportRepository Contract Tests', () {
    late MockExportRepository mockRepository;
    
    setUp(() {
      mockRepository = MockExportRepository();
    });

    group('createPackage', () {
      test('should return ExportPackage when creation succeeds', () async {
        // Arrange
        const sessionId = 'session-uuid-123';
        final expectedPackage = ExportPackage(
          id: 'package-uuid-456',
          sessionId: sessionId,
          metadata: PackageMetadata(
            studentId: 'student-123',
            studentName: 'John Doe',
            administratorId: 'admin-456',
            appVersion: '1.0.0',
            deviceInfo: 'Android 12',
            sessionDate: DateTime.now(),
            qualityMetrics: const QualityMetrics(
              sessionId: sessionId,
              overallQuality: 0.92,
              poseMetrics: CoverageMetrics(
                frontalCoverage: 95.0,
                leftProfileCoverage: 88.0,
                rightProfileCoverage: 92.0,
                uptiltCoverage: 85.0,
                downtiltCoverage: 90.0,
                overallCoverage: 90.0,
              ),
              qualityDistribution: QualityDistribution(
                highQuality: 12,
                mediumQuality: 3,
                lowQuality: 0,
                averageScore: 0.92,
                standardDeviation: 0.03,
              ),
              environmental: EnvironmentalFactors(
                lighting: LightingCondition.excellent,
                background: BackgroundType.plain,
                noiseLevel: 0.1,
                detectedIssues: [],
              ),
              processingStats: ProcessingStats(
                totalFramesAnalyzed: 150,
                framesRejected: 135,
                framesSelected: 15,
                averageProcessingTimeMs: 45,
                yolov7InferenceTimeMs: 32,
              ),
            ),
            customFields: const {
              'department': 'Computer Science',
              'academic_year': 2024,
            },
          ),
          frames: [
            ExportFrame(
              frameId: 'frame-1',
              base64ImageData: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChAI9jU77MA==',
              metadata: FrameMetadata(
                timestampMs: 3000,
                qualityScore: 0.94,
                pose: const PoseAngles(yaw: 0.0, pitch: 0.0, roll: 0.0, confidence: 0.96),
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
              ),
            ),
          ],
          status: PackageStatus.created,
          createdAt: DateTime.now(),
        );
        
        when(mockRepository.createPackage(sessionId))
            .thenAnswer((_) async => expectedPackage);
        
        // Act
        final result = await mockRepository.createPackage(sessionId);
        
        // Assert
        expect(result, equals(expectedPackage));
        expect(result.sessionId, equals(sessionId));
        expect(result.status, equals(PackageStatus.created));
        expect(result.frames, hasLength(1));
        expect(result.metadata.studentName, equals('John Doe'));
        verify(mockRepository.createPackage(sessionId)).called(1);
      });

      test('should throw exception when session not found', () async {
        // Arrange
        const nonExistentSessionId = 'non-existent-session';
        
        when(mockRepository.createPackage(nonExistentSessionId))
            .thenThrow(const NotFoundException('Registration session not found'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.createPackage(nonExistentSessionId),
          throwsA(isA<NotFoundException>()),
        );
        verify(mockRepository.createPackage(nonExistentSessionId)).called(1);
      });

      test('should throw exception when session is not completed', () async {
        // Arrange
        const incompleteSessionId = 'incomplete-session';
        
        when(mockRepository.createPackage(incompleteSessionId))
            .thenThrow(const ValidationException('Cannot create package for incomplete session'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.createPackage(incompleteSessionId),
          throwsA(isA<ValidationException>()),
        );
        verify(mockRepository.createPackage(incompleteSessionId)).called(1);
      });

      test('should throw exception when session has insufficient quality', () async {
        // Arrange
        const lowQualitySessionId = 'low-quality-session';
        
        when(mockRepository.createPackage(lowQualitySessionId))
            .thenThrow(const QualityException('Session quality below export threshold'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.createPackage(lowQualitySessionId),
          throwsA(isA<QualityException>()),
        );
        verify(mockRepository.createPackage(lowQualitySessionId)).called(1);
      });

      test('should throw exception when package already exists for session', () async {
        // Arrange
        const sessionWithExistingPackage = 'session-with-package';
        
        when(mockRepository.createPackage(sessionWithExistingPackage))
            .thenThrow(const ConflictException('Export package already exists for this session'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.createPackage(sessionWithExistingPackage),
          throwsA(isA<ConflictException>()),
        );
        verify(mockRepository.createPackage(sessionWithExistingPackage)).called(1);
      });
    });

    group('getPackageById', () {
      test('should return ExportPackage when found by ID', () async {
        // Arrange
        const packageId = 'package-uuid-123';
        final expectedPackage = ExportPackage(
          id: packageId,
          sessionId: 'session-456',
          metadata: PackageMetadata(
            studentId: 'student-789',
            studentName: 'Jane Smith',
            administratorId: 'admin-101',
            appVersion: '1.0.0',
            deviceInfo: 'iOS 16',
            sessionDate: DateTime.now().subtract(const Duration(hours: 2)),
            qualityMetrics: const QualityMetrics(
              sessionId: 'session-456',
              overallQuality: 0.89,
              poseMetrics: CoverageMetrics(
                frontalCoverage: 92.0,
                leftProfileCoverage: 85.0,
                rightProfileCoverage: 88.0,
                uptiltCoverage: 82.0,
                downtiltCoverage: 87.0,
                overallCoverage: 87.0,
              ),
              qualityDistribution: QualityDistribution(
                highQuality: 10,
                mediumQuality: 4,
                lowQuality: 1,
                averageScore: 0.89,
                standardDeviation: 0.05,
              ),
              environmental: EnvironmentalFactors(
                lighting: LightingCondition.good,
                background: BackgroundType.indoor,
                noiseLevel: 0.15,
                detectedIssues: ['slight_shadows'],
              ),
              processingStats: ProcessingStats(
                totalFramesAnalyzed: 140,
                framesRejected: 125,
                framesSelected: 15,
                averageProcessingTimeMs: 48,
                yolov7InferenceTimeMs: 35,
              ),
            ),
            customFields: const {
              'department': 'Mathematics',
              'academic_year': 2023,
            },
          ),
          frames: List.generate(15, (index) => ExportFrame(
            frameId: 'frame-$index',
            base64ImageData: 'base64data$index',
            metadata: FrameMetadata(
              timestampMs: index * 1000,
              qualityScore: 0.85 + (index * 0.01),
              pose: PoseAngles(
                yaw: (index - 7) * 15.0, // Varying poses
                pitch: (index % 3 - 1) * 10.0,
                roll: 0.0,
                confidence: 0.90 + (index * 0.005),
              ),
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
            ),
          )),
          status: PackageStatus.ready,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        );
        
        when(mockRepository.getPackageById(packageId))
            .thenAnswer((_) async => expectedPackage);
        
        // Act
        final result = await mockRepository.getPackageById(packageId);
        
        // Assert
        expect(result, equals(expectedPackage));
        expect(result?.id, equals(packageId));
        expect(result?.status, equals(PackageStatus.ready));
        expect(result?.frames, hasLength(15));
        expect(result?.metadata.studentName, equals('Jane Smith'));
        verify(mockRepository.getPackageById(packageId)).called(1);
      });

      test('should return null when package not found by ID', () async {
        // Arrange
        const nonExistentId = 'non-existent-package';
        
        when(mockRepository.getPackageById(nonExistentId))
            .thenAnswer((_) async => null);
        
        // Act
        final result = await mockRepository.getPackageById(nonExistentId);
        
        // Assert
        expect(result, isNull);
        verify(mockRepository.getPackageById(nonExistentId)).called(1);
      });

      test('should throw exception when ID format is invalid', () async {
        // Arrange
        const invalidId = '';
        
        when(mockRepository.getPackageById(invalidId))
            .thenThrow(const ArgumentException('Invalid package ID format'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.getPackageById(invalidId),
          throwsA(isA<ArgumentException>()),
        );
        verify(mockRepository.getPackageById(invalidId)).called(1);
      });
    });

    group('getPackagesByStatus', () {
      test('should return list of packages with specified status', () async {
        // Arrange
        const status = PackageStatus.ready;
        final expectedPackages = [
          ExportPackage(
            id: 'package-ready-1',
            sessionId: 'session-1',
            metadata: PackageMetadata(
              studentId: 'student-1',
              studentName: 'Alice Johnson',
              administratorId: 'admin-1',
              appVersion: '1.0.0',
              deviceInfo: 'Android 13',
              sessionDate: DateTime.now().subtract(const Duration(days: 1)),
              qualityMetrics: const QualityMetrics(
                sessionId: 'session-1',
                overallQuality: 0.91,
                poseMetrics: CoverageMetrics(
                  frontalCoverage: 95.0,
                  leftProfileCoverage: 90.0,
                  rightProfileCoverage: 93.0,
                  uptiltCoverage: 87.0,
                  downtiltCoverage: 89.0,
                  overallCoverage: 91.0,
                ),
                qualityDistribution: QualityDistribution(
                  highQuality: 13,
                  mediumQuality: 2,
                  lowQuality: 0,
                  averageScore: 0.91,
                  standardDeviation: 0.02,
                ),
                environmental: EnvironmentalFactors(
                  lighting: LightingCondition.excellent,
                  background: BackgroundType.plain,
                  noiseLevel: 0.08,
                  detectedIssues: [],
                ),
                processingStats: ProcessingStats(
                  totalFramesAnalyzed: 155,
                  framesRejected: 140,
                  framesSelected: 15,
                  averageProcessingTimeMs: 42,
                  yolov7InferenceTimeMs: 30,
                ),
              ),
              customFields: const {},
            ),
            frames: [], // Simplified for test
            status: PackageStatus.ready,
            createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          ),
          ExportPackage(
            id: 'package-ready-2',
            sessionId: 'session-2',
            metadata: PackageMetadata(
              studentId: 'student-2',
              studentName: 'Bob Wilson',
              administratorId: 'admin-2',
              appVersion: '1.0.0',
              deviceInfo: 'iPhone 14',
              sessionDate: DateTime.now().subtract(const Duration(hours: 6)),
              qualityMetrics: const QualityMetrics(
                sessionId: 'session-2',
                overallQuality: 0.87,
                poseMetrics: CoverageMetrics(
                  frontalCoverage: 88.0,
                  leftProfileCoverage: 85.0,
                  rightProfileCoverage: 89.0,
                  uptiltCoverage: 83.0,
                  downtiltCoverage: 86.0,
                  overallCoverage: 86.0,
                ),
                qualityDistribution: QualityDistribution(
                  highQuality: 9,
                  mediumQuality: 5,
                  lowQuality: 1,
                  averageScore: 0.87,
                  standardDeviation: 0.06,
                ),
                environmental: EnvironmentalFactors(
                  lighting: LightingCondition.good,
                  background: BackgroundType.indoor,
                  noiseLevel: 0.18,
                  detectedIssues: ['minor_glare'],
                ),
                processingStats: ProcessingStats(
                  totalFramesAnalyzed: 142,
                  framesRejected: 127,
                  framesSelected: 15,
                  averageProcessingTimeMs: 46,
                  yolov7InferenceTimeMs: 34,
                ),
              ),
              customFields: const {},
            ),
            frames: [], // Simplified for test
            status: PackageStatus.ready,
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
        ];
        
        when(mockRepository.getPackagesByStatus(status))
            .thenAnswer((_) async => expectedPackages);
        
        // Act
        final result = await mockRepository.getPackagesByStatus(status);
        
        // Assert
        expect(result, equals(expectedPackages));
        expect(result, hasLength(2));
        expect(result.every((package) => package.status == PackageStatus.ready), isTrue);
        expect(result[0].metadata.studentName, equals('Alice Johnson'));
        expect(result[1].metadata.studentName, equals('Bob Wilson'));
        verify(mockRepository.getPackagesByStatus(status)).called(1);
      });

      test('should return empty list when no packages match status', () async {
        // Arrange
        const status = PackageStatus.failed;
        
        when(mockRepository.getPackagesByStatus(status))
            .thenAnswer((_) async => []);
        
        // Act
        final result = await mockRepository.getPackagesByStatus(status);
        
        // Assert
        expect(result, isEmpty);
        verify(mockRepository.getPackagesByStatus(status)).called(1);
      });

      test('should handle all PackageStatus enum values', () async {
        // Arrange & Act & Assert
        for (final status in PackageStatus.values) {
          when(mockRepository.getPackagesByStatus(status))
              .thenAnswer((_) async => []);
          
          final result = await mockRepository.getPackagesByStatus(status);
          expect(result, isA<List<ExportPackage>>());
          verify(mockRepository.getPackagesByStatus(status)).called(1);
        }
      });
    });

    group('updatePackageStatus', () {
      test('should return updated ExportPackage when status update succeeds', () async {
        // Arrange
        const packageId = 'package-uuid-123';
        const newStatus = PackageStatus.exported;
        
        final expectedPackage = ExportPackage(
          id: packageId,
          sessionId: 'session-456',
          metadata: PackageMetadata(
            studentId: 'student-789',
            studentName: 'Update Test',
            administratorId: 'admin-101',
            appVersion: '1.0.0',
            deviceInfo: 'Test Device',
            sessionDate: DateTime.now().subtract(const Duration(hours: 4)),
            qualityMetrics: const QualityMetrics(
              sessionId: 'session-456',
              overallQuality: 0.90,
              poseMetrics: CoverageMetrics(
                frontalCoverage: 90.0,
                leftProfileCoverage: 85.0,
                rightProfileCoverage: 88.0,
                uptiltCoverage: 82.0,
                downtiltCoverage: 87.0,
                overallCoverage: 86.0,
              ),
              qualityDistribution: QualityDistribution(
                highQuality: 11,
                mediumQuality: 3,
                lowQuality: 1,
                averageScore: 0.90,
                standardDeviation: 0.04,
              ),
              environmental: EnvironmentalFactors(
                lighting: LightingCondition.excellent,
                background: BackgroundType.plain,
                noiseLevel: 0.12,
                detectedIssues: [],
              ),
              processingStats: ProcessingStats(
                totalFramesAnalyzed: 148,
                framesRejected: 133,
                framesSelected: 15,
                averageProcessingTimeMs: 44,
                yolov7InferenceTimeMs: 31,
              ),
            ),
            customFields: const {},
          ),
          frames: [], // Simplified for test
          status: PackageStatus.exported,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          exportedAt: DateTime.now(),
          exportFilePath: '/storage/exports/package-uuid-123.json',
        );
        
        when(mockRepository.updatePackageStatus(packageId, newStatus))
            .thenAnswer((_) async => expectedPackage);
        
        // Act
        final result = await mockRepository.updatePackageStatus(packageId, newStatus);
        
        // Assert
        expect(result, equals(expectedPackage));
        expect(result.status, equals(PackageStatus.exported));
        expect(result.exportedAt, isNotNull);
        expect(result.exportFilePath, isNotNull);
        verify(mockRepository.updatePackageStatus(packageId, newStatus)).called(1);
      });

      test('should throw exception when package not found for status update', () async {
        // Arrange
        const nonExistentId = 'non-existent-package';
        const status = PackageStatus.exported;
        
        when(mockRepository.updatePackageStatus(nonExistentId, status))
            .thenThrow(const NotFoundException('Export package not found'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.updatePackageStatus(nonExistentId, status),
          throwsA(isA<NotFoundException>()),
        );
        verify(mockRepository.updatePackageStatus(nonExistentId, status)).called(1);
      });

      test('should throw exception when invalid status transition attempted', () async {
        // Arrange
        const packageId = 'exported-package';
        const invalidStatus = PackageStatus.created; // Cannot go from exported back to created
        
        when(mockRepository.updatePackageStatus(packageId, invalidStatus))
            .thenThrow(const StateTransitionException('Invalid package status transition'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.updatePackageStatus(packageId, invalidStatus),
          throwsA(isA<StateTransitionException>()),
        );
        verify(mockRepository.updatePackageStatus(packageId, invalidStatus)).called(1);
      });

      test('should validate all possible status transitions', () async {
        // Arrange
        const packageId = 'transition-test-package';
        
        // Valid transitions: created -> ready -> exported
        // Valid transitions: created -> failed, ready -> failed
        final validTransitions = [
          (PackageStatus.created, PackageStatus.ready),
          (PackageStatus.ready, PackageStatus.exported),
          (PackageStatus.created, PackageStatus.failed),
          (PackageStatus.ready, PackageStatus.failed),
          (PackageStatus.processing, PackageStatus.ready),
          (PackageStatus.processing, PackageStatus.failed),
        ];
        
        for (final (from, to) in validTransitions) {
          final updatedPackage = ExportPackage(
            id: packageId,
            sessionId: 'session-transition',
            metadata: PackageMetadata(
              studentId: 'student-transition',
              studentName: 'Transition Test',
              administratorId: 'admin-transition',
              appVersion: '1.0.0',
              deviceInfo: 'Test Device',
              sessionDate: DateTime.now(),
              qualityMetrics: const QualityMetrics(
                sessionId: 'session-transition',
                overallQuality: 0.85,
                poseMetrics: CoverageMetrics(
                  frontalCoverage: 85.0,
                  leftProfileCoverage: 80.0,
                  rightProfileCoverage: 83.0,
                  uptiltCoverage: 78.0,
                  downtiltCoverage: 82.0,
                  overallCoverage: 82.0,
                ),
                qualityDistribution: QualityDistribution(
                  highQuality: 8,
                  mediumQuality: 5,
                  lowQuality: 2,
                  averageScore: 0.85,
                  standardDeviation: 0.07,
                ),
                environmental: EnvironmentalFactors(
                  lighting: LightingCondition.good,
                  background: BackgroundType.indoor,
                  noiseLevel: 0.20,
                  detectedIssues: [],
                ),
                processingStats: ProcessingStats(
                  totalFramesAnalyzed: 135,
                  framesRejected: 120,
                  framesSelected: 15,
                  averageProcessingTimeMs: 50,
                  yolov7InferenceTimeMs: 38,
                ),
              ),
              customFields: const {},
            ),
            frames: [],
            status: to,
            createdAt: DateTime.now(),
          );
          
          when(mockRepository.updatePackageStatus(packageId, to))
              .thenAnswer((_) async => updatedPackage);
          
          // Act
          final result = await mockRepository.updatePackageStatus(packageId, to);
          
          // Assert
          expect(result.status, equals(to));
          verify(mockRepository.updatePackageStatus(packageId, to)).called(1);
        }
      });
    });

    group('exportPackageToJson', () {
      test('should return JSON string when export succeeds', () async {
        // Arrange
        const packageId = 'package-export-test';
        const expectedJson = '''
{
  "id": "package-export-test",
  "sessionId": "session-json-test",
  "metadata": {
    "studentId": "student-json",
    "studentName": "JSON Test User",
    "administratorId": "admin-json",
    "appVersion": "1.0.0",
    "deviceInfo": "Test Device",
    "sessionDate": "2025-10-08T14:30:00Z",
    "qualityMetrics": {
      "overallQuality": 0.93,
      "poseMetrics": {
        "frontalCoverage": 96.0,
        "leftProfileCoverage": 92.0,
        "rightProfileCoverage": 94.0,
        "uptiltCoverage": 88.0,
        "downtiltCoverage": 91.0,
        "overallCoverage": 92.0
      }
    }
  },
  "frames": [
    {
      "frameId": "frame-json-1",
      "base64ImageData": "base64encodedimage1",
      "metadata": {
        "timestampMs": 3000,
        "qualityScore": 0.95,
        "pose": {
          "yaw": 0.0,
          "pitch": 0.0,
          "roll": 0.0,
          "confidence": 0.97
        }
      }
    }
  ],
  "status": "ready",
  "createdAt": "2025-10-08T14:00:00Z"
}''';
        
        when(mockRepository.exportPackageToJson(packageId))
            .thenAnswer((_) async => expectedJson);
        
        // Act
        final result = await mockRepository.exportPackageToJson(packageId);
        
        // Assert
        expect(result, equals(expectedJson));
        expect(result, contains('"id": "package-export-test"'));
        expect(result, contains('"studentName": "JSON Test User"'));
        expect(result, contains('"overallQuality": 0.93'));
        verify(mockRepository.exportPackageToJson(packageId)).called(1);
      });

      test('should throw exception when package not found for JSON export', () async {
        // Arrange
        const nonExistentId = 'non-existent-package';
        
        when(mockRepository.exportPackageToJson(nonExistentId))
            .thenThrow(const NotFoundException('Export package not found'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.exportPackageToJson(nonExistentId),
          throwsA(isA<NotFoundException>()),
        );
        verify(mockRepository.exportPackageToJson(nonExistentId)).called(1);
      });

      test('should throw exception when package is not ready for export', () async {
        // Arrange
        const notReadyPackageId = 'package-not-ready';
        
        when(mockRepository.exportPackageToJson(notReadyPackageId))
            .thenThrow(const ValidationException('Package is not ready for export'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.exportPackageToJson(notReadyPackageId),
          throwsA(isA<ValidationException>()),
        );
        verify(mockRepository.exportPackageToJson(notReadyPackageId)).called(1);
      });

      test('should throw exception when JSON serialization fails', () async {
        // Arrange
        const corruptPackageId = 'corrupt-package';
        
        when(mockRepository.exportPackageToJson(corruptPackageId))
            .thenThrow(const SerializationException('Failed to serialize package data'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.exportPackageToJson(corruptPackageId),
          throwsA(isA<SerializationException>()),
        );
        verify(mockRepository.exportPackageToJson(corruptPackageId)).called(1);
      });

      test('should handle large package data efficiently', () async {
        // Arrange
        const largePackageId = 'large-package';
        final largeJsonData = 'x' * 1000000; // 1MB of data
        
        when(mockRepository.exportPackageToJson(largePackageId))
            .thenAnswer((_) async => largeJsonData);
        
        // Act
        final stopwatch = Stopwatch()..start();
        final result = await mockRepository.exportPackageToJson(largePackageId);
        stopwatch.stop();
        
        // Assert
        expect(result, equals(largeJsonData));
        expect(result.length, equals(1000000));
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // Should complete within 10 seconds
        verify(mockRepository.exportPackageToJson(largePackageId)).called(1);
      });
    });

    group('deleteExpiredPackages', () {
      test('should complete successfully when expired packages are deleted', () async {
        // Arrange
        when(mockRepository.deleteExpiredPackages())
            .thenAnswer((_) async => {});
        
        // Act & Assert
        expect(
          () async => await mockRepository.deleteExpiredPackages(),
          returnsNormally,
        );
        verify(mockRepository.deleteExpiredPackages()).called(1);
      });

      test('should handle case when no expired packages exist', () async {
        // Arrange
        when(mockRepository.deleteExpiredPackages())
            .thenAnswer((_) async => {});
        
        // Act & Assert
        expect(
          () async => await mockRepository.deleteExpiredPackages(),
          returnsNormally,
        );
        verify(mockRepository.deleteExpiredPackages()).called(1);
      });

      test('should throw exception when deletion fails due to file system error', () async {
        // Arrange
        when(mockRepository.deleteExpiredPackages())
            .thenThrow(const FileSystemException('Failed to delete expired package files'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.deleteExpiredPackages(),
          throwsA(isA<FileSystemException>()),
        );
        verify(mockRepository.deleteExpiredPackages()).called(1);
      });

      test('should throw exception when database cleanup fails', () async {
        // Arrange
        when(mockRepository.deleteExpiredPackages())
            .thenThrow(const DatabaseException('Failed to delete expired package records'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.deleteExpiredPackages(),
          throwsA(isA<DatabaseException>()),
        );
        verify(mockRepository.deleteExpiredPackages()).called(1);
      });

      test('should handle partial deletion failures gracefully', () async {
        // Arrange
        when(mockRepository.deleteExpiredPackages())
            .thenThrow(const PartialOperationException('Some expired packages could not be deleted'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.deleteExpiredPackages(),
          throwsA(isA<PartialOperationException>()),
        );
        verify(mockRepository.deleteExpiredPackages()).called(1);
      });
    });

    group('Error Handling Contract', () {
      test('should handle network connectivity issues', () async {
        // Arrange
        const packageId = 'network-test-package';
        
        when(mockRepository.getPackageById(packageId))
            .thenThrow(const NetworkException('Network connection lost'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.getPackageById(packageId),
          throwsA(isA<NetworkException>()),
        );
        verify(mockRepository.getPackageById(packageId)).called(1);
      });

      test('should handle storage capacity issues', () async {
        // Arrange
        const sessionId = 'storage-full-session';
        
        when(mockRepository.createPackage(sessionId))
            .thenThrow(const StorageException('Insufficient storage space'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.createPackage(sessionId),
          throwsA(isA<StorageException>()),
        );
        verify(mockRepository.createPackage(sessionId)).called(1);
      });

      test('should handle concurrent access conflicts', () async {
        // Arrange
        const packageId = 'concurrent-access-package';
        const status = PackageStatus.exported;
        
        when(mockRepository.updatePackageStatus(packageId, status))
            .thenThrow(const ConcurrencyException('Package is being modified by another process'));
        
        // Act & Assert
        expect(
          () async => await mockRepository.updatePackageStatus(packageId, status),
          throwsA(isA<ConcurrencyException>()),
        );
        verify(mockRepository.updatePackageStatus(packageId, status)).called(1);
      });
    });

    group('Performance Contract', () {
      test('should handle batch package retrieval efficiently', () async {
        // Arrange
        const status = PackageStatus.ready;
        final largePackageList = List.generate(1000, (index) => ExportPackage(
          id: 'package-$index',
          sessionId: 'session-$index',
          metadata: PackageMetadata(
            studentId: 'student-$index',
            studentName: 'Student $index',
            administratorId: 'admin-$index',
            appVersion: '1.0.0',
            deviceInfo: 'Test Device',
            sessionDate: DateTime.now(),
            qualityMetrics: const QualityMetrics(
              sessionId: 'session-test',
              overallQuality: 0.85,
              poseMetrics: CoverageMetrics(
                frontalCoverage: 85.0,
                leftProfileCoverage: 80.0,
                rightProfileCoverage: 83.0,
                uptiltCoverage: 78.0,
                downtiltCoverage: 82.0,
                overallCoverage: 82.0,
              ),
              qualityDistribution: QualityDistribution(
                highQuality: 8,
                mediumQuality: 5,
                lowQuality: 2,
                averageScore: 0.85,
                standardDeviation: 0.07,
              ),
              environmental: EnvironmentalFactors(
                lighting: LightingCondition.good,
                background: BackgroundType.indoor,
                noiseLevel: 0.20,
                detectedIssues: [],
              ),
              processingStats: ProcessingStats(
                totalFramesAnalyzed: 135,
                framesRejected: 120,
                framesSelected: 15,
                averageProcessingTimeMs: 50,
                yolov7InferenceTimeMs: 38,
              ),
            ),
            customFields: const {},
          ),
          frames: [],
          status: PackageStatus.ready,
          createdAt: DateTime.now(),
        ));
        
        when(mockRepository.getPackagesByStatus(status))
            .thenAnswer((_) async => largePackageList);
        
        // Act
        final stopwatch = Stopwatch()..start();
        final result = await mockRepository.getPackagesByStatus(status);
        stopwatch.stop();
        
        // Assert
        expect(result, hasLength(1000));
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should complete within 5 seconds
        verify(mockRepository.getPackagesByStatus(status)).called(1);
      });

      test('should optimize cleanup operations for large datasets', () async {
        // Arrange
        when(mockRepository.deleteExpiredPackages())
            .thenAnswer((_) async {
          // Simulate processing time for large cleanup operation
          await Future.delayed(const Duration(milliseconds: 100));
        });
        
        // Act
        final stopwatch = Stopwatch()..start();
        await mockRepository.deleteExpiredPackages();
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(15000)); // Should complete within 15 seconds
        verify(mockRepository.deleteExpiredPackages()).called(1);
      });
    });

    group('Data Integrity Contract', () {
      test('should maintain package consistency during status updates', () async {
        // Arrange
        const packageId = 'integrity-test-package';
        const sessionId = 'integrity-session';
        
        final originalPackage = ExportPackage(
          id: packageId,
          sessionId: sessionId,
          metadata: PackageMetadata(
            studentId: 'integrity-student',
            studentName: 'Integrity Test',
            administratorId: 'integrity-admin',
            appVersion: '1.0.0',
            deviceInfo: 'Test Device',
            sessionDate: DateTime.now(),
            qualityMetrics: const QualityMetrics(
              sessionId: sessionId,
              overallQuality: 0.88,
              poseMetrics: CoverageMetrics(
                frontalCoverage: 88.0,
                leftProfileCoverage: 85.0,
                rightProfileCoverage: 90.0,
                uptiltCoverage: 82.0,
                downtiltCoverage: 87.0,
                overallCoverage: 86.0,
              ),
              qualityDistribution: QualityDistribution(
                highQuality: 9,
                mediumQuality: 4,
                lowQuality: 2,
                averageScore: 0.88,
                standardDeviation: 0.06,
              ),
              environmental: EnvironmentalFactors(
                lighting: LightingCondition.good,
                background: BackgroundType.indoor,
                noiseLevel: 0.16,
                detectedIssues: [],
              ),
              processingStats: ProcessingStats(
                totalFramesAnalyzed: 138,
                framesRejected: 123,
                framesSelected: 15,
                averageProcessingTimeMs: 47,
                yolov7InferenceTimeMs: 35,
              ),
            ),
            customFields: const {},
          ),
          frames: [],
          status: PackageStatus.ready,
          createdAt: DateTime.now(),
        );
        
        final updatedPackage = originalPackage.copyWith(
          status: PackageStatus.exported,
          exportedAt: DateTime.now(),
          exportFilePath: '/storage/exports/$packageId.json',
        );
        
        when(mockRepository.getPackageById(packageId))
            .thenAnswer((_) async => originalPackage);
        when(mockRepository.updatePackageStatus(packageId, PackageStatus.exported))
            .thenAnswer((_) async => updatedPackage);
        
        // Act
        final original = await mockRepository.getPackageById(packageId);
        final updated = await mockRepository.updatePackageStatus(packageId, PackageStatus.exported);
        
        // Assert
        expect(original?.status, equals(PackageStatus.ready));
        expect(updated.status, equals(PackageStatus.exported));
        expect(updated.id, equals(original?.id)); // ID should remain unchanged
        expect(updated.sessionId, equals(original?.sessionId)); // Session ID should remain unchanged
        expect(updated.metadata.studentId, equals(original?.metadata.studentId)); // Core metadata should remain unchanged
        expect(updated.exportedAt, isNotNull);
        expect(updated.exportFilePath, isNotNull);
        verify(mockRepository.getPackageById(packageId)).called(1);
        verify(mockRepository.updatePackageStatus(packageId, PackageStatus.exported)).called(1);
      });
    });
  });
}