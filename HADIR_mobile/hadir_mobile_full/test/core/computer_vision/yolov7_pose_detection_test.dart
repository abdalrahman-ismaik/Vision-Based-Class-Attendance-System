import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'dart:typed_data';
import 'package:hadir_mobile_full/core/computer_vision/yolov7_pose_detector.dart';
import 'package:hadir_mobile_full/core/computer_vision/models/pose_detection_result.dart';
import 'package:hadir_mobile_full/core/computer_vision/models/keypoint.dart';
import 'package:hadir_mobile_full/core/computer_vision/models/pose_angles.dart';
import 'package:hadir_mobile_full/core/computer_vision/models/face_metrics.dart';
import 'package:hadir_mobile_full/core/computer_vision/models/bounding_box.dart';
import 'package:hadir_mobile_full/shared/domain/entities/pose_target.dart';
import 'package:hadir_mobile_full/core/computer_vision/exceptions/pose_detection_exceptions.dart';
import 'package:hadir_mobile_full/core/services/model_loading_service.dart';
import 'package:hadir_mobile_full/core/services/image_preprocessing_service.dart';

import 'yolov7_pose_detection_test.mocks.dart';

// Generate mocks
@GenerateMocks([ModelLoadingService, ImagePreprocessingService])
void main() {
  group('YOLOv7-Pose Detection Pipeline', () {
    late YOLOv7PoseDetector poseDetector;
    late MockModelLoadingService mockModelLoadingService;
    late MockImagePreprocessingService mockImagePreprocessingService;
    
    setUp(() {
      mockModelLoadingService = MockModelLoadingService();
      mockImagePreprocessingService = MockImagePreprocessingService();
      poseDetector = YOLOv7PoseDetector(
        modelLoadingService: mockModelLoadingService,
        imagePreprocessingService: mockImagePreprocessingService,
      );
    });

    group('Model Initialization', () {
      test('should initialize YOLOv7-Pose model successfully', () async {
        // Arrange
        when(mockModelLoadingService.loadYOLOv7PoseModel())
            .thenAnswer((_) async => true);
        when(mockModelLoadingService.validateModelIntegrity())
            .thenAnswer((_) async => true);
        
        // Act
        final result = await poseDetector.initialize();
        
        // Assert
        expect(result, isTrue);
        expect(poseDetector.isInitialized, isTrue);
        verify(mockModelLoadingService.loadYOLOv7PoseModel()).called(1);
        verify(mockModelLoadingService.validateModelIntegrity()).called(1);
      });

      test('should handle model loading failure', () async {
        // Arrange
        when(mockModelLoadingService.loadYOLOv7PoseModel())
            .thenThrow(const ModelLoadingException('Failed to load YOLOv7-Pose model'));
        
        // Act & Assert
        expect(
          () => poseDetector.initialize(),
          throwsA(isA<ModelLoadingException>()),
        );
        verify(mockModelLoadingService.loadYOLOv7PoseModel()).called(1);
        expect(poseDetector.isInitialized, isFalse);
      });

      test('should validate model integrity after loading', () async {
        // Arrange
        when(mockModelLoadingService.loadYOLOv7PoseModel())
            .thenAnswer((_) async => true);
        when(mockModelLoadingService.validateModelIntegrity())
            .thenAnswer((_) async => false); // Model integrity check fails
        
        // Act & Assert
        expect(
          () => poseDetector.initialize(),
          throwsA(isA<ModelIntegrityException>()),
        );
        verify(mockModelLoadingService.loadYOLOv7PoseModel()).called(1);
        verify(mockModelLoadingService.validateModelIntegrity()).called(1);
        expect(poseDetector.isInitialized, isFalse);
      });

      test('should handle insufficient memory during model loading', () async {
        // Arrange
        when(mockModelLoadingService.loadYOLOv7PoseModel())
            .thenThrow(const InsufficientMemoryException('Not enough memory to load YOLOv7-Pose model'));
        
        // Act & Assert
        expect(
          () => poseDetector.initialize(),
          throwsA(isA<InsufficientMemoryException>()),
        );
        verify(mockModelLoadingService.loadYOLOv7PoseModel()).called(1);
        expect(poseDetector.isInitialized, isFalse);
      });
    });

    group('Frontal Face Detection', () {
      setUp(() async {
        when(mockModelLoadingService.loadYOLOv7PoseModel()).thenAnswer((_) async => true);
        when(mockModelLoadingService.validateModelIntegrity()).thenAnswer((_) async => true);
        await poseDetector.initialize();
      });

      test('should detect frontal face pose with high confidence', () async {
        // Arrange
        final frontalFaceImage = Uint8List.fromList(List.generate(640 * 480 * 3, (i) => i % 256));
        const poseTarget = PoseTarget.frontalFace;
        
        final preprocessedImage = Uint8List.fromList(List.generate(416 * 416 * 3, (i) => i % 256));
        when(mockImagePreprocessingService.preprocessImage(frontalFaceImage, 416, 416))
            .thenAnswer((_) async => preprocessedImage);
        
        final expectedResult = PoseDetectionResult(
          confidence: 0.96,
          keypoints: const [
            Keypoint(id: 0, x: 208.0, y: 186.4, confidence: 0.98), // Nose
            Keypoint(id: 1, x: 198.2, y: 179.6, confidence: 0.95), // Left eye
            Keypoint(id: 2, x: 217.8, y: 179.8, confidence: 0.97), // Right eye
            Keypoint(id: 3, x: 185.4, y: 182.1, confidence: 0.91), // Left ear
            Keypoint(id: 4, x: 230.6, y: 182.3, confidence: 0.93), // Right ear
            Keypoint(id: 5, x: 175.0, y: 220.0, confidence: 0.89), // Left shoulder
            Keypoint(id: 6, x: 241.0, y: 220.2, confidence: 0.90), // Right shoulder
            Keypoint(id: 7, x: 168.5, y: 260.8, confidence: 0.85), // Left elbow
            Keypoint(id: 8, x: 247.5, y: 261.0, confidence: 0.87), // Right elbow
            Keypoint(id: 9, x: 162.0, y: 301.6, confidence: 0.82), // Left wrist
            Keypoint(id: 10, x: 254.0, y: 301.8, confidence: 0.84), // Right wrist
            Keypoint(id: 11, x: 188.0, y: 320.0, confidence: 0.88), // Left hip
            Keypoint(id: 12, x: 228.0, y: 320.2, confidence: 0.89), // Right hip
            Keypoint(id: 13, x: 185.5, y: 380.4, confidence: 0.81), // Left knee
            Keypoint(id: 14, x: 230.5, y: 380.6, confidence: 0.83), // Right knee
            Keypoint(id: 15, x: 183.0, y: 400.8, confidence: 0.78), // Left ankle
            Keypoint(id: 16, x: 233.0, y: 401.0, confidence: 0.80), // Right ankle
          ],
          angles: const PoseAngles(
            yaw: 1.2, // Nearly frontal
            pitch: -2.1, // Slight downward tilt
            roll: 0.8, // Minimal head tilt
          ),
          faceMetrics: const FaceMetrics(
            width: 126.4,
            height: 158.2,
            aspectRatio: 0.799,
            area: 20005.0,
          ),
          boundingBox: const BoundingBox(
            x: 145.0,
            y: 107.0,
            width: 126.4,
            height: 158.2,
          ),
          qualityScore: 0.92,
          timestamp: DateTime.now(),
        );
        
        // Mock the actual YOLOv7-Pose inference
        when(mockModelLoadingService.runInference(preprocessedImage))
            .thenAnswer((_) async => expectedResult);
        
        // Act
        final result = await poseDetector.detectPose(frontalFaceImage, poseTarget);
        
        // Assert
        expect(result.confidence, greaterThanOrEqualTo(0.90)); // ≥90% confidence requirement
        expect(result.keypoints.length, equals(17)); // YOLOv7-Pose has 17 keypoints
        expect(result.angles.yaw.abs(), lessThan(15.0)); // Frontal face: |yaw| < 15°
        expect(result.angles.pitch.abs(), lessThan(20.0)); // Acceptable pitch range
        expect(result.angles.roll.abs(), lessThan(15.0)); // Acceptable roll range
        expect(result.qualityScore, greaterThan(0.8)); // High quality score
        expect(result.faceMetrics.aspectRatio, closeTo(0.8, 0.2)); // Typical face aspect ratio
        
        verify(mockImagePreprocessingService.preprocessImage(frontalFaceImage, 416, 416)).called(1);
        verify(mockModelLoadingService.runInference(preprocessedImage)).called(1);
      });

      test('should reject frontal face with insufficient confidence', () async {
        // Arrange
        final blurryFrontalImage = Uint8List.fromList(List.generate(640 * 480 * 3, (i) => 128)); // Uniform gray
        const poseTarget = PoseTarget.frontalFace;
        
        final preprocessedImage = Uint8List.fromList(List.generate(416 * 416 * 3, (i) => 128));
        when(mockImagePreprocessingService.preprocessImage(blurryFrontalImage, 416, 416))
            .thenAnswer((_) async => preprocessedImage);
        
        final lowConfidenceResult = PoseDetectionResult(
          confidence: 0.67, // Below 90% threshold
          keypoints: const [
            Keypoint(id: 0, x: 208.0, y: 186.4, confidence: 0.65),
            Keypoint(id: 1, x: 198.2, y: 179.6, confidence: 0.62),
            // Additional low-confidence keypoints...
          ],
          angles: const PoseAngles(yaw: 2.1, pitch: -1.8, roll: 1.2),
          faceMetrics: const FaceMetrics(width: 98.2, height: 124.8, aspectRatio: 0.787, area: 12255.4),
          boundingBox: const BoundingBox(x: 159.0, y: 124.0, width: 98.2, height: 124.8),
          qualityScore: 0.63,
          timestamp: DateTime.now(),
        );
        
        when(mockModelLoadingService.runInference(preprocessedImage))
            .thenAnswer((_) async => lowConfidenceResult);
        
        // Act & Assert
        expect(
          () => poseDetector.detectPose(blurryFrontalImage, poseTarget),
          throwsA(isA<LowConfidenceDetectionException>()),
        );
        
        verify(mockImagePreprocessingService.preprocessImage(blurryFrontalImage, 416, 416)).called(1);
        verify(mockModelLoadingService.runInference(preprocessedImage)).called(1);
      });
    });

    group('Left Profile Detection', () {
      setUp(() async {
        when(mockModelLoadingService.loadYOLOv7PoseModel()).thenAnswer((_) async => true);
        when(mockModelLoadingService.validateModelIntegrity()).thenAnswer((_) async => true);
        await poseDetector.initialize();
      });

      test('should detect left profile pose with correct angle validation', () async {
        // Arrange
        final leftProfileImage = Uint8List.fromList(List.generate(640 * 480 * 3, (i) => (i * 7) % 256));
        const poseTarget = PoseTarget.leftProfile;
        
        final preprocessedImage = Uint8List.fromList(List.generate(416 * 416 * 3, (i) => (i * 7) % 256));
        when(mockImagePreprocessingService.preprocessImage(leftProfileImage, 416, 416))
            .thenAnswer((_) async => preprocessedImage);
        
        final expectedLeftProfileResult = PoseDetectionResult(
          confidence: 0.94,
          keypoints: const [
            Keypoint(id: 0, x: 158.6, y: 188.2, confidence: 0.96), // Nose (left profile)
            Keypoint(id: 1, x: 168.4, y: 181.5, confidence: 0.93), // Left eye (more visible)
            Keypoint(id: 2, x: 148.2, y: 181.8, confidence: 0.71), // Right eye (less visible)
            Keypoint(id: 3, x: 175.8, y: 184.0, confidence: 0.90), // Left ear (visible)
            Keypoint(id: 4, x: 141.2, y: 184.2, confidence: 0.45), // Right ear (hidden)
            Keypoint(id: 5, x: 180.5, y: 222.5, confidence: 0.87), // Left shoulder
            Keypoint(id: 6, x: 135.5, y: 222.8, confidence: 0.68), // Right shoulder (partially hidden)
            // Additional keypoints for left profile...
          ],
          angles: const PoseAngles(
            yaw: -47.3, // Left profile: yaw ≈ -45°
            pitch: 1.8,
            roll: -2.1,
          ),
          faceMetrics: const FaceMetrics(
            width: 89.4,
            height: 142.6,
            aspectRatio: 0.627, // Profile faces are narrower
            area: 12751.4,
          ),
          boundingBox: const BoundingBox(
            x: 114.0,
            y: 116.9,
            width: 89.4,
            height: 142.6,
          ),
          qualityScore: 0.88,
          timestamp: DateTime.now(),
        );
        
        when(mockModelLoadingService.runInference(preprocessedImage))
            .thenAnswer((_) async => expectedLeftProfileResult);
        
        // Act
        final result = await poseDetector.detectPose(leftProfileImage, poseTarget);
        
        // Assert
        expect(result.confidence, greaterThanOrEqualTo(0.90));
        expect(result.angles.yaw, lessThan(-30.0)); // Left profile: yaw < -30°
        expect(result.angles.yaw, greaterThan(-60.0)); // Left profile: yaw > -60°
        expect(result.angles.pitch.abs(), lessThan(25.0)); // Acceptable pitch range
        expect(result.keypoints[1].confidence, greaterThan(result.keypoints[2].confidence)); // Left eye more visible
        expect(result.keypoints[3].confidence, greaterThan(result.keypoints[4].confidence)); // Left ear more visible
        expect(result.faceMetrics.aspectRatio, lessThan(0.7)); // Profile faces are narrower
        
        verify(mockImagePreprocessingService.preprocessImage(leftProfileImage, 416, 416)).called(1);
        verify(mockModelLoadingService.runInference(preprocessedImage)).called(1);
      });

      test('should reject incorrect angle for left profile pose', () async {
        // Arrange
        final incorrectAngleImage = Uint8List.fromList(List.generate(640 * 480 * 3, (i) => (i * 11) % 256));
        const poseTarget = PoseTarget.leftProfile;
        
        final preprocessedImage = Uint8List.fromList(List.generate(416 * 416 * 3, (i) => (i * 11) % 256));
        when(mockImagePreprocessingService.preprocessImage(incorrectAngleImage, 416, 416))
            .thenAnswer((_) async => preprocessedImage);
        
        final incorrectAngleResult = PoseDetectionResult(
          confidence: 0.91, // Good confidence
          keypoints: const [
            Keypoint(id: 0, x: 208.0, y: 186.4, confidence: 0.93),
            // Keypoints suggest frontal pose, not left profile...
          ],
          angles: const PoseAngles(
            yaw: 5.2, // Should be around -45° for left profile
            pitch: -1.5,
            roll: 0.8,
          ),
          faceMetrics: const FaceMetrics(width: 118.6, height: 152.4, aspectRatio: 0.778, area: 18073.4),
          boundingBox: const BoundingBox(x: 149.0, y: 110.0, width: 118.6, height: 152.4),
          qualityScore: 0.85,
          timestamp: DateTime.now(),
        );
        
        when(mockModelLoadingService.runInference(preprocessedImage))
            .thenAnswer((_) async => incorrectAngleResult);
        
        // Act & Assert
        expect(
          () => poseDetector.detectPose(incorrectAngleImage, poseTarget),
          throwsA(isA<IncorrectPoseAngleException>()),
        );
        
        verify(mockImagePreprocessingService.preprocessImage(incorrectAngleImage, 416, 416)).called(1);
        verify(mockModelLoadingService.runInference(preprocessedImage)).called(1);
      });
    });

    group('Right Profile Detection', () {
      setUp(() async {
        when(mockModelLoadingService.loadYOLOv7PoseModel()).thenAnswer((_) async => true);
        when(mockModelLoadingService.validateModelIntegrity()).thenAnswer((_) async => true);
        await poseDetector.initialize();
      });

      test('should detect right profile pose with correct keypoint visibility', () async {
        // Arrange
        final rightProfileImage = Uint8List.fromList(List.generate(640 * 480 * 3, (i) => (i * 13) % 256));
        const poseTarget = PoseTarget.rightProfile;
        
        final preprocessedImage = Uint8List.fromList(List.generate(416 * 416 * 3, (i) => (i * 13) % 256));
        when(mockImagePreprocessingService.preprocessImage(rightProfileImage, 416, 416))
            .thenAnswer((_) async => preprocessedImage);
        
        final expectedRightProfileResult = PoseDetectionResult(
          confidence: 0.93,
          keypoints: const [
            Keypoint(id: 0, x: 258.4, y: 187.6, confidence: 0.95), // Nose (right profile)
            Keypoint(id: 1, x: 248.2, y: 180.8, confidence: 0.73), // Left eye (less visible)
            Keypoint(id: 2, x: 268.6, y: 181.2, confidence: 0.92), // Right eye (more visible)
            Keypoint(id: 3, x: 241.4, y: 183.5, confidence: 0.48), // Left ear (hidden)
            Keypoint(id: 4, x: 275.8, y: 183.8, confidence: 0.89), // Right ear (visible)
            Keypoint(id: 5, x: 236.0, y: 221.8, confidence: 0.70), // Left shoulder (partially hidden)
            Keypoint(id: 6, x: 281.0, y: 222.2, confidence: 0.86), // Right shoulder
            // Additional keypoints for right profile...
          ],
          angles: const PoseAngles(
            yaw: 44.7, // Right profile: yaw ≈ +45°
            pitch: 2.3,
            roll: 1.6,
          ),
          faceMetrics: const FaceMetrics(
            width: 91.8,
            height: 144.2,
            aspectRatio: 0.637, // Profile faces are narrower
            area: 13237.6,
          ),
          boundingBox: const BoundingBox(
            x: 212.5,
            y: 115.5,
            width: 91.8,
            height: 144.2,
          ),
          qualityScore: 0.89,
          timestamp: DateTime.now(),
        );
        
        when(mockModelLoadingService.runInference(preprocessedImage))
            .thenAnswer((_) async => expectedRightProfileResult);
        
        // Act
        final result = await poseDetector.detectPose(rightProfileImage, poseTarget);
        
        // Assert
        expect(result.confidence, greaterThanOrEqualTo(0.90));
        expect(result.angles.yaw, greaterThan(30.0)); // Right profile: yaw > 30°
        expect(result.angles.yaw, lessThan(60.0)); // Right profile: yaw < 60°
        expect(result.angles.pitch.abs(), lessThan(25.0)); // Acceptable pitch range
        expect(result.keypoints[2].confidence, greaterThan(result.keypoints[1].confidence)); // Right eye more visible
        expect(result.keypoints[4].confidence, greaterThan(result.keypoints[3].confidence)); // Right ear more visible
        expect(result.faceMetrics.aspectRatio, lessThan(0.7)); // Profile faces are narrower
        
        verify(mockImagePreprocessingService.preprocessImage(rightProfileImage, 416, 416)).called(1);
        verify(mockModelLoadingService.runInference(preprocessedImage)).called(1);
      });
    });

    group('Upward Angle Detection', () {
      setUp(() async {
        when(mockModelLoadingService.loadYOLOv7PoseModel()).thenAnswer((_) async => true);
        when(mockModelLoadingService.validateModelIntegrity()).thenAnswer((_) async => true);
        await poseDetector.initialize();
      });

      test('should detect upward angle pose with correct pitch validation', () async {
        // Arrange
        final upwardAngleImage = Uint8List.fromList(List.generate(640 * 480 * 3, (i) => (i * 17) % 256));
        const poseTarget = PoseTarget.upwardAngle;
        
        final preprocessedImage = Uint8List.fromList(List.generate(416 * 416 * 3, (i) => (i * 17) % 256));
        when(mockImagePreprocessingService.preprocessImage(upwardAngleImage, 416, 416))
            .thenAnswer((_) async => preprocessedImage);
        
        final expectedUpwardAngleResult = PoseDetectionResult(
          confidence: 0.91,
          keypoints: const [
            Keypoint(id: 0, x: 208.2, y: 156.8, confidence: 0.94), // Nose (upward angle)
            Keypoint(id: 1, x: 198.6, y: 164.2, confidence: 0.89), // Left eye
            Keypoint(id: 2, x: 217.8, y: 164.5, confidence: 0.90), // Right eye
            Keypoint(id: 3, x: 185.4, y: 168.8, confidence: 0.85), // Left ear
            Keypoint(id: 4, x: 230.6, y: 169.1, confidence: 0.87), // Right ear
            // Chin and lower face keypoints less visible due to upward angle
            // Additional keypoints for upward angle...
          ],
          angles: const PoseAngles(
            yaw: -1.4, // Nearly frontal yaw
            pitch: 22.6, // Upward tilt: pitch > 15°
            roll: 0.9,
          ),
          faceMetrics: const FaceMetrics(
            width: 134.2,
            height: 166.8,
            aspectRatio: 0.805,
            area: 22396.6,
          ),
          boundingBox: const BoundingBox(
            x: 141.1,
            y: 89.4,
            width: 134.2,
            height: 166.8,
          ),
          qualityScore: 0.86,
          timestamp: DateTime.now(),
        );
        
        when(mockModelLoadingService.runInference(preprocessedImage))
            .thenAnswer((_) async => expectedUpwardAngleResult);
        
        // Act
        final result = await poseDetector.detectPose(upwardAngleImage, poseTarget);
        
        // Assert
        expect(result.confidence, greaterThanOrEqualTo(0.90));
        expect(result.angles.pitch, greaterThan(15.0)); // Upward angle: pitch > 15°
        expect(result.angles.pitch, lessThan(45.0)); // Upward angle: pitch < 45°
        expect(result.angles.yaw.abs(), lessThan(20.0)); // Maintain roughly frontal yaw
        expect(result.angles.roll.abs(), lessThan(20.0)); // Acceptable roll range
        
        verify(mockImagePreprocessingService.preprocessImage(upwardAngleImage, 416, 416)).called(1);
        verify(mockModelLoadingService.runInference(preprocessedImage)).called(1);
      });
    });

    group('Downward Angle Detection', () {
      setUp(() async {
        when(mockModelLoadingService.loadYOLOv7PoseModel()).thenAnswer((_) async => true);
        when(mockModelLoadingService.validateModelIntegrity()).thenAnswer((_) async => true);
        await poseDetector.initialize();
      });

      test('should detect downward angle pose with correct pitch validation', () async {
        // Arrange
        final downwardAngleImage = Uint8List.fromList(List.generate(640 * 480 * 3, (i) => (i * 19) % 256));
        const poseTarget = PoseTarget.downwardAngle;
        
        final preprocessedImage = Uint8List.fromList(List.generate(416 * 416 * 3, (i) => (i * 19) % 256));
        when(mockImagePreprocessingService.preprocessImage(downwardAngleImage, 416, 416))
            .thenAnswer((_) async => preprocessedImage);
        
        final expectedDownwardAngleResult = PoseDetectionResult(
          confidence: 0.92,
          keypoints: const [
            Keypoint(id: 0, x: 208.6, y: 218.4, confidence: 0.95), // Nose (downward angle)
            Keypoint(id: 1, x: 198.2, y: 211.6, confidence: 0.91), // Left eye
            Keypoint(id: 2, x: 219.0, y: 211.8, confidence: 0.93), // Right eye
            Keypoint(id: 3, x: 185.8, y: 208.2, confidence: 0.87), // Left ear
            Keypoint(id: 4, x: 231.4, y: 208.5, confidence: 0.89), // Right ear
            // Forehead and upper face features less visible due to downward angle
            // Additional keypoints for downward angle...
          ],
          angles: const PoseAngles(
            yaw: 0.8, // Nearly frontal yaw
            pitch: -28.3, // Downward tilt: pitch < -15°
            roll: -1.2,
          ),
          faceMetrics: const FaceMetrics(
            width: 128.6,
            height: 154.2,
            aspectRatio: 0.834,
            area: 19831.1,
          ),
          boundingBox: const BoundingBox(
            x: 144.3,
            y: 141.3,
            width: 128.6,
            height: 154.2,
          ),
          qualityScore: 0.87,
          timestamp: DateTime.now(),
        );
        
        when(mockModelLoadingService.runInference(preprocessedImage))
            .thenAnswer((_) async => expectedDownwardAngleResult);
        
        // Act
        final result = await poseDetector.detectPose(downwardAngleImage, poseTarget);
        
        // Assert
        expect(result.confidence, greaterThanOrEqualTo(0.90));
        expect(result.angles.pitch, lessThan(-15.0)); // Downward angle: pitch < -15°
        expect(result.angles.pitch, greaterThan(-45.0)); // Downward angle: pitch > -45°
        expect(result.angles.yaw.abs(), lessThan(20.0)); // Maintain roughly frontal yaw
        expect(result.angles.roll.abs(), lessThan(20.0)); // Acceptable roll range
        
        verify(mockImagePreprocessingService.preprocessImage(downwardAngleImage, 416, 416)).called(1);
        verify(mockModelLoadingService.runInference(preprocessedImage)).called(1);
      });
    });

    group('Face Embedding Generation', () {
      setUp(() async {
        when(mockModelLoadingService.loadYOLOv7PoseModel()).thenAnswer((_) async => true);
        when(mockModelLoadingService.validateModelIntegrity()).thenAnswer((_) async => true);
        await poseDetector.initialize();
      });

      test('should generate 512-dimensional face embeddings from multiple poses', () async {
        // Arrange
        final faceImages = [
          Uint8List.fromList(List.generate(640 * 480 * 3, (i) => (i * 2) % 256)), // Frontal
          Uint8List.fromList(List.generate(640 * 480 * 3, (i) => (i * 3) % 256)), // Left profile
          Uint8List.fromList(List.generate(640 * 480 * 3, (i) => (i * 5) % 256)), // Right profile
          Uint8List.fromList(List.generate(640 * 480 * 3, (i) => (i * 7) % 256)), // Upward
          Uint8List.fromList(List.generate(640 * 480 * 3, (i) => (i * 11) % 256)), // Downward
        ];
        
        final expectedEmbeddings = [
          List.generate(512, (i) => (i * 0.01) % 1.0), // Frontal embedding
          List.generate(512, (i) => ((i + 100) * 0.01) % 1.0), // Left profile embedding
          List.generate(512, (i) => ((i + 200) * 0.01) % 1.0), // Right profile embedding
          List.generate(512, (i) => ((i + 300) * 0.01) % 1.0), // Upward embedding
          List.generate(512, (i) => ((i + 400) * 0.01) % 1.0), // Downward embedding
        ];
        
        // Mock preprocessing for each image
        for (int i = 0; i < faceImages.length; i++) {
          final preprocessed = Uint8List.fromList(List.generate(416 * 416 * 3, (j) => (j * (i + 2)) % 256));
          when(mockImagePreprocessingService.preprocessImage(faceImages[i], 416, 416))
              .thenAnswer((_) async => preprocessed);
        }
        
        when(mockModelLoadingService.generateFaceEmbedding(any))
            .thenAnswer((invocation) async {
          // Return different embeddings based on input
          final inputImage = invocation.positionalArguments[0] as Uint8List;
          final hashCode = inputImage.hashCode;
          final index = hashCode % expectedEmbeddings.length;
          return expectedEmbeddings[index];
        });
        
        // Act
        final result = await poseDetector.generateFaceEmbeddings(faceImages);
        
        // Assert
        expect(result.length, equals(5)); // One embedding per pose
        for (final embedding in result) {
          expect(embedding.length, equals(512)); // 512-dimensional embeddings
          expect(embedding.every((value) => value >= -1.0 && value <= 1.0), isTrue); // Valid range
        }
        
        // Verify all images were processed
        for (final image in faceImages) {
          verify(mockImagePreprocessingService.preprocessImage(image, 416, 416)).called(1);
        }
        verify(mockModelLoadingService.generateFaceEmbedding(any)).called(5);
      });

      test('should handle face embedding generation failure', () async {
        // Arrange
        final corruptedImages = [
          Uint8List.fromList([1, 2, 3]), // Too small
          Uint8List.fromList(List.generate(100, (i) => 255)), // Invalid format
        ];
        
        when(mockImagePreprocessingService.preprocessImage(any, any, any))
            .thenThrow(const ImageProcessingException('Invalid image format'));
        
        // Act & Assert
        expect(
          () => poseDetector.generateFaceEmbeddings(corruptedImages),
          throwsA(isA<ImageProcessingException>()),
        );
      });

      test('should validate embedding consistency across poses', () async {
        // Arrange
        final samePersonImages = [
          Uint8List.fromList(List.generate(640 * 480 * 3, (i) => (i * 23) % 256)),
          Uint8List.fromList(List.generate(640 * 480 * 3, (i) => (i * 29) % 256)),
          Uint8List.fromList(List.generate(640 * 480 * 3, (i) => (i * 31) % 256)),
        ];
        
        // Mock consistent embeddings for the same person
        final baseEmbedding = List.generate(512, (i) => (i * 0.01) % 1.0);
        final similarEmbeddings = [
          baseEmbedding,
          baseEmbedding.map((v) => v + 0.02).toList(), // Slight variation
          baseEmbedding.map((v) => v - 0.01).toList(), // Slight variation
        ];
        
        for (int i = 0; i < samePersonImages.length; i++) {
          final preprocessed = Uint8List.fromList(List.generate(416 * 416 * 3, (j) => (j * (i + 23)) % 256));
          when(mockImagePreprocessingService.preprocessImage(samePersonImages[i], 416, 416))
              .thenAnswer((_) async => preprocessed);
        }
        
        when(mockModelLoadingService.generateFaceEmbedding(any))
            .thenAnswer((invocation) async {
          // Return similar embeddings for the same person
          static int callCount = 0;
          final embedding = similarEmbeddings[callCount % similarEmbeddings.length];
          callCount++;
          return embedding;
        });
        
        // Act
        final result = await poseDetector.generateFaceEmbeddings(samePersonImages);
        
        // Assert
        expect(result.length, equals(3));
        
        // Calculate cosine similarity between embeddings
        final similarity1_2 = _calculateCosineSimilarity(result[0], result[1]);
        final similarity1_3 = _calculateCosineSimilarity(result[0], result[2]);
        final similarity2_3 = _calculateCosineSimilarity(result[1], result[2]);
        
        // Embeddings from the same person should be highly similar
        expect(similarity1_2, greaterThan(0.85)); // High similarity threshold
        expect(similarity1_3, greaterThan(0.85));
        expect(similarity2_3, greaterThan(0.85));
        
        verify(mockModelLoadingService.generateFaceEmbedding(any)).called(3);
      });
    });

    group('Performance and Resource Management', () {
      setUp(() async {
        when(mockModelLoadingService.loadYOLOv7PoseModel()).thenAnswer((_) async => true);
        when(mockModelLoadingService.validateModelIntegrity()).thenAnswer((_) async => true);
        await poseDetector.initialize();
      });

      test('should complete pose detection within acceptable time limits', () async {
        // Arrange
        final performanceTestImage = Uint8List.fromList(List.generate(640 * 480 * 3, (i) => i % 256));
        const poseTarget = PoseTarget.frontalFace;
        
        final preprocessedImage = Uint8List.fromList(List.generate(416 * 416 * 3, (i) => i % 256));
        when(mockImagePreprocessingService.preprocessImage(performanceTestImage, 416, 416))
            .thenAnswer((_) async {
          // Simulate preprocessing time
          await Future.delayed(const Duration(milliseconds: 50));
          return preprocessedImage;
        });
        
        final fastResult = PoseDetectionResult(
          confidence: 0.94,
          keypoints: const [Keypoint(id: 0, x: 208.0, y: 186.4, confidence: 0.95)],
          angles: const PoseAngles(yaw: 0.0, pitch: 0.0, roll: 0.0),
          faceMetrics: const FaceMetrics(width: 120.0, height: 150.0, aspectRatio: 0.8, area: 18000.0),
          boundingBox: const BoundingBox(x: 148.0, y: 111.4, width: 120.0, height: 150.0),
          qualityScore: 0.90,
          timestamp: DateTime.now(),
        );
        
        when(mockModelLoadingService.runInference(preprocessedImage))
            .thenAnswer((_) async {
          // Simulate YOLOv7-Pose inference time
          await Future.delayed(const Duration(milliseconds: 800));
          return fastResult;
        });
        
        // Act
        final stopwatch = Stopwatch()..start();
        final result = await poseDetector.detectPose(performanceTestImage, poseTarget);
        stopwatch.stop();
        
        // Assert
        expect(result.confidence, greaterThanOrEqualTo(0.90));
        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // Should complete within 2 seconds
        
        verify(mockImagePreprocessingService.preprocessImage(performanceTestImage, 416, 416)).called(1);
        verify(mockModelLoadingService.runInference(preprocessedImage)).called(1);
      });

      test('should handle memory cleanup after detection', () async {
        // Arrange
        final memoryTestImages = List.generate(10, (i) => 
          Uint8List.fromList(List.generate(640 * 480 * 3, (j) => (i * j) % 256))
        );
        const poseTarget = PoseTarget.frontalFace;
        
        for (final image in memoryTestImages) {
          final preprocessed = Uint8List.fromList(List.generate(416 * 416 * 3, (j) => j % 256));
          when(mockImagePreprocessingService.preprocessImage(image, 416, 416))
              .thenAnswer((_) async => preprocessed);
        }
        
        final standardResult = PoseDetectionResult(
          confidence: 0.91,
          keypoints: const [Keypoint(id: 0, x: 208.0, y: 186.4, confidence: 0.93)],
          angles: const PoseAngles(yaw: 0.0, pitch: 0.0, roll: 0.0),
          faceMetrics: const FaceMetrics(width: 115.0, height: 145.0, aspectRatio: 0.793, area: 16675.0),
          boundingBox: const BoundingBox(x: 150.5, y: 113.9, width: 115.0, height: 145.0),
          qualityScore: 0.87,
          timestamp: DateTime.now(),
        );
        
        when(mockModelLoadingService.runInference(any))
            .thenAnswer((_) async => standardResult);
        when(mockModelLoadingService.cleanupMemory())
            .thenAnswer((_) async => {});
        
        // Act
        for (final image in memoryTestImages) {
          final result = await poseDetector.detectPose(image, poseTarget);
          expect(result.confidence, greaterThanOrEqualTo(0.90));
        }
        
        // Cleanup after batch processing
        await poseDetector.cleanupMemory();
        
        // Assert
        verify(mockModelLoadingService.runInference(any)).called(10);
        verify(mockModelLoadingService.cleanupMemory()).called(1);
      });

      test('should handle concurrent detection requests gracefully', () async {
        // Arrange
        final concurrentImages = List.generate(5, (i) => 
          Uint8List.fromList(List.generate(640 * 480 * 3, (j) => (i * 37 + j) % 256))
        );
        const poseTarget = PoseTarget.frontalFace;
        
        for (final image in concurrentImages) {
          final preprocessed = Uint8List.fromList(List.generate(416 * 416 * 3, (j) => j % 256));
          when(mockImagePreprocessingService.preprocessImage(image, 416, 416))
              .thenAnswer((_) async => preprocessed);
        }
        
        final concurrentResult = PoseDetectionResult(
          confidence: 0.90,
          keypoints: const [Keypoint(id: 0, x: 208.0, y: 186.4, confidence: 0.92)],
          angles: const PoseAngles(yaw: 0.0, pitch: 0.0, roll: 0.0),
          faceMetrics: const FaceMetrics(width: 118.0, height: 148.0, aspectRatio: 0.797, area: 17464.0),
          boundingBox: const BoundingBox(x: 149.0, y: 112.0, width: 118.0, height: 148.0),
          qualityScore: 0.86,
          timestamp: DateTime.now(),
        );
        
        when(mockModelLoadingService.runInference(any))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 500));
          return concurrentResult;
        });
        
        // Act
        final futures = concurrentImages.map((image) => 
          poseDetector.detectPose(image, poseTarget)
        ).toList();
        
        final results = await Future.wait(futures);
        
        // Assert
        expect(results.length, equals(5));
        for (final result in results) {
          expect(result.confidence, greaterThanOrEqualTo(0.90));
        }
        
        verify(mockModelLoadingService.runInference(any)).called(5);
      });

      test('should handle processing timeout appropriately', () async {
        // Arrange
        final timeoutImage = Uint8List.fromList(List.generate(640 * 480 * 3, (i) => i % 256));
        const poseTarget = PoseTarget.frontalFace;
        
        final preprocessedImage = Uint8List.fromList(List.generate(416 * 416 * 3, (i) => i % 256));
        when(mockImagePreprocessingService.preprocessImage(timeoutImage, 416, 416))
            .thenAnswer((_) async => preprocessedImage);
        
        when(mockModelLoadingService.runInference(preprocessedImage))
            .thenAnswer((_) async {
          // Simulate timeout scenario
          await Future.delayed(const Duration(seconds: 10));
          throw const ProcessingTimeoutException('YOLOv7-Pose inference timeout');
        });
        
        // Act & Assert
        expect(
          () => poseDetector.detectPose(timeoutImage, poseTarget),
          throwsA(isA<ProcessingTimeoutException>()),
        );
        
        verify(mockImagePreprocessingService.preprocessImage(timeoutImage, 416, 416)).called(1);
        verify(mockModelLoadingService.runInference(preprocessedImage)).called(1);
      });
    });

    group('Model Disposal and Cleanup', () {
      test('should dispose resources properly', () async {
        // Arrange
        when(mockModelLoadingService.loadYOLOv7PoseModel()).thenAnswer((_) async => true);
        when(mockModelLoadingService.validateModelIntegrity()).thenAnswer((_) async => true);
        when(mockModelLoadingService.disposeModel()).thenAnswer((_) async => {});
        
        await poseDetector.initialize();
        
        // Act
        await poseDetector.dispose();
        
        // Assert
        expect(poseDetector.isInitialized, isFalse);
        verify(mockModelLoadingService.disposeModel()).called(1);
      });

      test('should handle disposal when model is not initialized', () async {
        // Arrange
        when(mockModelLoadingService.disposeModel()).thenAnswer((_) async => {});
        
        // Act
        await poseDetector.dispose();
        
        // Assert
        expect(poseDetector.isInitialized, isFalse);
        verifyNever(mockModelLoadingService.disposeModel());
      });
    });
  });

  /// Helper function to calculate cosine similarity between two embeddings
  double _calculateCosineSimilarity(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) {
      throw ArgumentError('Embeddings must have the same length');
    }
    
    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;
    
    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      norm1 += embedding1[i] * embedding1[i];
      norm2 += embedding2[i] * embedding2[i];
    }
    
    if (norm1 == 0.0 || norm2 == 0.0) {
      return 0.0;
    }
    
    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }
}