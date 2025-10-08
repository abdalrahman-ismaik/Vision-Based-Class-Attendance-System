import 'package:flutter_test/flutter_test.dart';
import 'package:hadir_mobile_full/shared/domain/entities/selected_frame.dart';

void main() {
  group('SelectedFrame Entity', () {
    test('should create SelectedFrame instance with complete data', () {
      // Arrange
      const id = 'frame-123';
      const sessionId = 'session-456';
      const imageFilePath = '/storage/frames/frame-123.jpg';
      const timestampMs = 5000; // 5 seconds into video
      const qualityScore = 0.92;
      
      const poseAngles = PoseAngles(
        yaw: 15.5,
        pitch: -8.2,
        roll: 2.1,
        confidence: 0.95,
      );
      
      const boundingBox = BoundingBox(
        x: 0.2,
        y: 0.15,
        width: 0.6,
        height: 0.7,
      );
      
      const faceMetrics = FaceMetrics(
        boundingBox: boundingBox,
        faceSize: 0.45,
        sharpnessScore: 0.88,
        lightingScore: 0.91,
        symmetryScore: 0.87,
        hasGlasses: false,
        hasHat: false,
        isSmiling: true,
      );
      
      final extractedAt = DateTime.now();
      
      // Act
      final frame = SelectedFrame(
        id: id,
        sessionId: sessionId,
        imageFilePath: imageFilePath,
        timestampMs: timestampMs,
        qualityScore: qualityScore,
        poseAngles: poseAngles,
        faceMetrics: faceMetrics,
        extractedAt: extractedAt,
      );
      
      // Assert
      expect(frame.id, equals(id));
      expect(frame.sessionId, equals(sessionId));
      expect(frame.imageFilePath, equals(imageFilePath));
      expect(frame.timestampMs, equals(timestampMs));
      expect(frame.qualityScore, equals(qualityScore));
      expect(frame.poseAngles, equals(poseAngles));
      expect(frame.faceMetrics, equals(faceMetrics));
      expect(frame.extractedAt, equals(extractedAt));
    });

    test('should create SelectedFrame with minimal required data', () {
      // Arrange
      const id = 'frame-minimal';
      const sessionId = 'session-minimal';
      const imageFilePath = '/storage/frames/minimal.jpg';
      const timestampMs = 1000;
      const qualityScore = 0.80; // Minimum threshold
      
      const poseAngles = PoseAngles(
        yaw: 0.0,
        pitch: 0.0,
        roll: 0.0,
        confidence: 0.85,
      );
      
      const boundingBox = BoundingBox(
        x: 0.3,
        y: 0.2,
        width: 0.4,
        height: 0.6,
      );
      
      const faceMetrics = FaceMetrics(
        boundingBox: boundingBox,
        faceSize: 0.30,
        sharpnessScore: 0.80,
        lightingScore: 0.85,
        symmetryScore: 0.82,
        hasGlasses: false,
        hasHat: false,
        isSmiling: false,
      );
      
      final extractedAt = DateTime.now();
      
      // Act
      final frame = SelectedFrame(
        id: id,
        sessionId: sessionId,
        imageFilePath: imageFilePath,
        timestampMs: timestampMs,
        qualityScore: qualityScore,
        poseAngles: poseAngles,
        faceMetrics: faceMetrics,
        extractedAt: extractedAt,
      );
      
      // Assert
      expect(frame.qualityScore, equals(0.80));
      expect(frame.poseAngles.yaw, equals(0.0));
      expect(frame.poseAngles.pitch, equals(0.0));
      expect(frame.faceMetrics.faceSize, equals(0.30));
      expect(frame.faceMetrics.hasGlasses, isFalse);
      expect(frame.faceMetrics.isSmiling, isFalse);
    });

    test('should support equality comparison', () {
      // Arrange
      final extractedAt = DateTime.now();
      const poseAngles = PoseAngles(yaw: 10.0, pitch: -5.0, roll: 1.0, confidence: 0.90);
      const boundingBox = BoundingBox(x: 0.25, y: 0.20, width: 0.5, height: 0.6);
      const faceMetrics = FaceMetrics(
        boundingBox: boundingBox,
        faceSize: 0.40,
        sharpnessScore: 0.85,
        lightingScore: 0.88,
        symmetryScore: 0.86,
        hasGlasses: true,
        hasHat: false,
        isSmiling: false,
      );
      
      final frame1 = SelectedFrame(
        id: 'frame-equal-1',
        sessionId: 'session-equal',
        imageFilePath: '/storage/equal.jpg',
        timestampMs: 3000,
        qualityScore: 0.89,
        poseAngles: poseAngles,
        faceMetrics: faceMetrics,
        extractedAt: extractedAt,
      );
      
      final frame2 = SelectedFrame(
        id: 'frame-equal-1',
        sessionId: 'session-equal',
        imageFilePath: '/storage/equal.jpg',
        timestampMs: 3000,
        qualityScore: 0.89,
        poseAngles: poseAngles,
        faceMetrics: faceMetrics,
        extractedAt: extractedAt,
      );
      
      // Act & Assert
      expect(frame1, equals(frame2));
      expect(frame1.hashCode, equals(frame2.hashCode));
    });

    test('should have different hash codes for different frames', () {
      // Arrange
      final now = DateTime.now();
      const poseAngles1 = PoseAngles(yaw: 15.0, pitch: -8.0, roll: 2.0, confidence: 0.92);
      const poseAngles2 = PoseAngles(yaw: -20.0, pitch: 12.0, roll: -1.5, confidence: 0.88);
      
      const boundingBox1 = BoundingBox(x: 0.2, y: 0.15, width: 0.6, height: 0.7);
      const boundingBox2 = BoundingBox(x: 0.3, y: 0.25, width: 0.4, height: 0.5);
      
      const faceMetrics1 = FaceMetrics(
        boundingBox: boundingBox1,
        faceSize: 0.45,
        sharpnessScore: 0.90,
        lightingScore: 0.92,
        symmetryScore: 0.89,
        hasGlasses: false,
        hasHat: false,
        isSmiling: true,
      );
      
      const faceMetrics2 = FaceMetrics(
        boundingBox: boundingBox2,
        faceSize: 0.35,
        sharpnessScore: 0.82,
        lightingScore: 0.85,
        symmetryScore: 0.83,
        hasGlasses: true,
        hasHat: true,
        isSmiling: false,
      );
      
      final frame1 = SelectedFrame(
        id: 'frame-different-1',
        sessionId: 'session-1',
        imageFilePath: '/storage/frame1.jpg',
        timestampMs: 2000,
        qualityScore: 0.91,
        poseAngles: poseAngles1,
        faceMetrics: faceMetrics1,
        extractedAt: now,
      );
      
      final frame2 = SelectedFrame(
        id: 'frame-different-2',
        sessionId: 'session-2',
        imageFilePath: '/storage/frame2.jpg',
        timestampMs: 7000,
        qualityScore: 0.84,
        poseAngles: poseAngles2,
        faceMetrics: faceMetrics2,
        extractedAt: now,
      );
      
      // Act & Assert
      expect(frame1, isNot(equals(frame2)));
      expect(frame1.hashCode, isNot(equals(frame2.hashCode)));
    });

    test('should validate quality score range (0.8-1.0)', () {
      // Arrange
      final now = DateTime.now();
      const poseAngles = PoseAngles(yaw: 0.0, pitch: 0.0, roll: 0.0, confidence: 0.90);
      const boundingBox = BoundingBox(x: 0.2, y: 0.15, width: 0.6, height: 0.7);
      const faceMetrics = FaceMetrics(
        boundingBox: boundingBox,
        faceSize: 0.40,
        sharpnessScore: 0.85,
        lightingScore: 0.88,
        symmetryScore: 0.86,
        hasGlasses: false,
        hasHat: false,
        isSmiling: false,
      );
      
      const validQualityScores = [0.80, 0.85, 0.90, 0.95, 1.0];
      
      for (double score in validQualityScores) {
        // Act
        final frame = SelectedFrame(
          id: 'frame-quality-${score.toString().replaceAll('.', '_')}',
          sessionId: 'session-quality',
          imageFilePath: '/storage/quality-test.jpg',
          timestampMs: 5000,
          qualityScore: score,
          poseAngles: poseAngles,
          faceMetrics: faceMetrics,
          extractedAt: now,
        );
        
        // Assert
        expect(frame.qualityScore, equals(score));
        expect(frame.qualityScore, greaterThanOrEqualTo(0.8));
        expect(frame.qualityScore, lessThanOrEqualTo(1.0));
      }
    });

    test('should validate pose angle ranges', () {
      // Arrange
      final now = DateTime.now();
      const boundingBox = BoundingBox(x: 0.2, y: 0.15, width: 0.6, height: 0.7);
      const faceMetrics = FaceMetrics(
        boundingBox: boundingBox,
        faceSize: 0.40,
        sharpnessScore: 0.85,
        lightingScore: 0.88,
        symmetryScore: 0.86,
        hasGlasses: false,
        hasHat: false,
        isSmiling: false,
      );
      
      // Valid angle ranges according to specifications
      const validYawAngles = [-90.0, -45.0, 0.0, 30.0, 90.0];  // -90 to +90
      const validPitchAngles = [-90.0, -30.0, 0.0, 15.0, 90.0]; // -90 to +90
      const validRollAngles = [-180.0, -90.0, 0.0, 45.0, 180.0]; // -180 to +180
      
      for (double yaw in validYawAngles) {
        for (double pitch in validPitchAngles) {
          for (double roll in validRollAngles) {
            // Act
            final poseAngles = PoseAngles(
              yaw: yaw,
              pitch: pitch,
              roll: roll,
              confidence: 0.90,
            );
            
            final frame = SelectedFrame(
              id: 'frame-pose-${yaw}_${pitch}_${roll}',
              sessionId: 'session-pose',
              imageFilePath: '/storage/pose-test.jpg',
              timestampMs: 4000,
              qualityScore: 0.87,
              poseAngles: poseAngles,
              faceMetrics: faceMetrics,
              extractedAt: now,
            );
            
            // Assert
            expect(frame.poseAngles.yaw, inInclusiveRange(-90.0, 90.0));
            expect(frame.poseAngles.pitch, inInclusiveRange(-90.0, 90.0));
            expect(frame.poseAngles.roll, inInclusiveRange(-180.0, 180.0));
            expect(frame.poseAngles.confidence, inInclusiveRange(0.0, 1.0));
          }
        }
      }
    });

    test('should validate face size range (0.1-1.0)', () {
      // Arrange
      final now = DateTime.now();
      const poseAngles = PoseAngles(yaw: 0.0, pitch: 0.0, roll: 0.0, confidence: 0.90);
      const boundingBox = BoundingBox(x: 0.2, y: 0.15, width: 0.6, height: 0.7);
      
      const validFaceSizes = [0.10, 0.25, 0.40, 0.65, 1.0]; // Minimum 10% of frame
      
      for (double faceSize in validFaceSizes) {
        // Act
        final faceMetrics = FaceMetrics(
          boundingBox: boundingBox,
          faceSize: faceSize,
          sharpnessScore: 0.85,
          lightingScore: 0.88,
          symmetryScore: 0.86,
          hasGlasses: false,
          hasHat: false,
          isSmiling: false,
        );
        
        final frame = SelectedFrame(
          id: 'frame-size-${faceSize.toString().replaceAll('.', '_')}',
          sessionId: 'session-size',
          imageFilePath: '/storage/size-test.jpg',
          timestampMs: 3000,
          qualityScore: 0.88,
          poseAngles: poseAngles,
          faceMetrics: faceMetrics,
          extractedAt: now,
        );
        
        // Assert
        expect(frame.faceMetrics.faceSize, equals(faceSize));
        expect(frame.faceMetrics.faceSize, greaterThanOrEqualTo(0.1));
        expect(frame.faceMetrics.faceSize, lessThanOrEqualTo(1.0));
      }
    });

    test('should validate bounding box coordinates (0.0-1.0)', () {
      // Arrange
      final now = DateTime.now();
      const poseAngles = PoseAngles(yaw: 5.0, pitch: -3.0, roll: 1.0, confidence: 0.92);
      
      const validBoundingBoxes = [
        BoundingBox(x: 0.0, y: 0.0, width: 1.0, height: 1.0),   // Full frame
        BoundingBox(x: 0.1, y: 0.1, width: 0.8, height: 0.8),   // Centered
        BoundingBox(x: 0.25, y: 0.2, width: 0.5, height: 0.6),  // Typical face
        BoundingBox(x: 0.5, y: 0.3, width: 0.4, height: 0.5),   // Right side
      ];
      
      for (int i = 0; i < validBoundingBoxes.length; i++) {
        final boundingBox = validBoundingBoxes[i];
        
        // Act
        final faceMetrics = FaceMetrics(
          boundingBox: boundingBox,
          faceSize: 0.35,
          sharpnessScore: 0.83,
          lightingScore: 0.86,
          symmetryScore: 0.84,
          hasGlasses: false,
          hasHat: false,
          isSmiling: false,
        );
        
        final frame = SelectedFrame(
          id: 'frame-bbox-$i',
          sessionId: 'session-bbox',
          imageFilePath: '/storage/bbox-test.jpg',
          timestampMs: 2500,
          qualityScore: 0.86,
          poseAngles: poseAngles,
          faceMetrics: faceMetrics,
          extractedAt: now,
        );
        
        // Assert
        expect(frame.faceMetrics.boundingBox.x, inInclusiveRange(0.0, 1.0));
        expect(frame.faceMetrics.boundingBox.y, inInclusiveRange(0.0, 1.0));
        expect(frame.faceMetrics.boundingBox.width, inInclusiveRange(0.0, 1.0));
        expect(frame.faceMetrics.boundingBox.height, inInclusiveRange(0.0, 1.0));
        
        // Ensure bounding box doesn't exceed frame boundaries
        expect(frame.faceMetrics.boundingBox.x + frame.faceMetrics.boundingBox.width, lessThanOrEqualTo(1.0));
        expect(frame.faceMetrics.boundingBox.y + frame.faceMetrics.boundingBox.height, lessThanOrEqualTo(1.0));
      }
    });

    test('should validate all score metrics range (0.0-1.0)', () {
      // Arrange
      final now = DateTime.now();
      const poseAngles = PoseAngles(yaw: 8.0, pitch: -6.0, roll: 2.5, confidence: 0.94);
      const boundingBox = BoundingBox(x: 0.2, y: 0.15, width: 0.6, height: 0.7);
      
      const validScores = [0.0, 0.25, 0.5, 0.75, 1.0];
      
      for (double score in validScores) {
        // Act
        final faceMetrics = FaceMetrics(
          boundingBox: boundingBox,
          faceSize: 0.40,
          sharpnessScore: score,
          lightingScore: score,
          symmetryScore: score,
          hasGlasses: false,
          hasHat: false,
          isSmiling: true,
        );
        
        final frame = SelectedFrame(
          id: 'frame-scores-${score.toString().replaceAll('.', '_')}',
          sessionId: 'session-scores',
          imageFilePath: '/storage/scores-test.jpg',
          timestampMs: 4500,
          qualityScore: 0.85,
          poseAngles: poseAngles,
          faceMetrics: faceMetrics,
          extractedAt: now,
        );
        
        // Assert
        expect(frame.faceMetrics.sharpnessScore, inInclusiveRange(0.0, 1.0));
        expect(frame.faceMetrics.lightingScore, inInclusiveRange(0.0, 1.0));
        expect(frame.faceMetrics.symmetryScore, inInclusiveRange(0.0, 1.0));
        expect(frame.poseAngles.confidence, inInclusiveRange(0.0, 1.0));
      }
    });

    test('should handle boolean face attributes correctly', () {
      // Arrange
      final now = DateTime.now();
      const poseAngles = PoseAngles(yaw: -12.0, pitch: 7.0, roll: -3.0, confidence: 0.89);
      const boundingBox = BoundingBox(x: 0.25, y: 0.20, width: 0.5, height: 0.6);
      
      const booleanCombinations = [
        [false, false, false], // No accessories, not smiling
        [true, false, false],  // Has glasses
        [false, true, false],  // Has hat
        [false, false, true],  // Is smiling
        [true, true, false],   // Glasses and hat
        [true, false, true],   // Glasses and smiling
        [false, true, true],   // Hat and smiling
        [true, true, true],    // All attributes true
      ];
      
      for (int i = 0; i < booleanCombinations.length; i++) {
        final combo = booleanCombinations[i];
        
        // Act
        final faceMetrics = FaceMetrics(
          boundingBox: boundingBox,
          faceSize: 0.42,
          sharpnessScore: 0.87,
          lightingScore: 0.89,
          symmetryScore: 0.85,
          hasGlasses: combo[0],
          hasHat: combo[1],
          isSmiling: combo[2],
        );
        
        final frame = SelectedFrame(
          id: 'frame-bool-$i',
          sessionId: 'session-bool',
          imageFilePath: '/storage/bool-test.jpg',
          timestampMs: 3500,
          qualityScore: 0.88,
          poseAngles: poseAngles,
          faceMetrics: faceMetrics,
          extractedAt: now,
        );
        
        // Assert
        expect(frame.faceMetrics.hasGlasses, isA<bool>());
        expect(frame.faceMetrics.hasHat, isA<bool>());
        expect(frame.faceMetrics.isSmiling, isA<bool>());
        expect(frame.faceMetrics.hasGlasses, equals(combo[0]));
        expect(frame.faceMetrics.hasHat, equals(combo[1]));
        expect(frame.faceMetrics.isSmiling, equals(combo[2]));
      }
    });

    test('should create copyWith method for immutable updates', () {
      // Arrange
      const originalPoseAngles = PoseAngles(yaw: 10.0, pitch: -5.0, roll: 2.0, confidence: 0.90);
      const originalBoundingBox = BoundingBox(x: 0.2, y: 0.15, width: 0.6, height: 0.7);
      const originalFaceMetrics = FaceMetrics(
        boundingBox: originalBoundingBox,
        faceSize: 0.40,
        sharpnessScore: 0.85,
        lightingScore: 0.88,
        symmetryScore: 0.86,
        hasGlasses: false,
        hasHat: false,
        isSmiling: false,
      );
      
      final original = SelectedFrame(
        id: 'frame-update',
        sessionId: 'session-update',
        imageFilePath: '/storage/original.jpg',
        timestampMs: 3000,
        qualityScore: 0.85,
        poseAngles: originalPoseAngles,
        faceMetrics: originalFaceMetrics,
        extractedAt: DateTime.now(),
      );
      
      const updatedPoseAngles = PoseAngles(yaw: 15.0, pitch: -8.0, roll: 3.0, confidence: 0.95);
      const updatedBoundingBox = BoundingBox(x: 0.25, y: 0.20, width: 0.5, height: 0.6);
      const updatedFaceMetrics = FaceMetrics(
        boundingBox: updatedBoundingBox,
        faceSize: 0.45,
        sharpnessScore: 0.90,
        lightingScore: 0.92,
        symmetryScore: 0.89,
        hasGlasses: true,
        hasHat: false,
        isSmiling: true,
      );
      
      // Act
      final updated = original.copyWith(
        qualityScore: 0.92,
        poseAngles: updatedPoseAngles,
        faceMetrics: updatedFaceMetrics,
      );
      
      // Assert
      expect(updated.id, equals(original.id));
      expect(updated.sessionId, equals(original.sessionId));
      expect(updated.imageFilePath, equals(original.imageFilePath));
      expect(updated.timestampMs, equals(original.timestampMs));
      expect(updated.extractedAt, equals(original.extractedAt));
      
      expect(updated.qualityScore, equals(0.92));
      expect(updated.poseAngles, equals(updatedPoseAngles));
      expect(updated.faceMetrics, equals(updatedFaceMetrics));
      
      // Original should remain unchanged
      expect(original.qualityScore, equals(0.85));
      expect(original.poseAngles, equals(originalPoseAngles));
      expect(original.faceMetrics.hasGlasses, isFalse);
      expect(original.faceMetrics.isSmiling, isFalse);
    });

    test('should support JSON serialization', () {
      // Arrange
      const poseAngles = PoseAngles(yaw: 12.5, pitch: -7.3, roll: 1.8, confidence: 0.93);
      const boundingBox = BoundingBox(x: 0.22, y: 0.18, width: 0.56, height: 0.64);
      const faceMetrics = FaceMetrics(
        boundingBox: boundingBox,
        faceSize: 0.42,
        sharpnessScore: 0.87,
        lightingScore: 0.89,
        symmetryScore: 0.85,
        hasGlasses: true,
        hasHat: false,
        isSmiling: true,
      );
      
      final frame = SelectedFrame(
        id: 'frame-json',
        sessionId: 'session-json',
        imageFilePath: '/storage/json-test.jpg',
        timestampMs: 4200,
        qualityScore: 0.91,
        poseAngles: poseAngles,
        faceMetrics: faceMetrics,
        extractedAt: DateTime.parse('2025-10-08T14:30:00Z'),
      );
      
      // Act
      final json = frame.toJson();
      final fromJson = SelectedFrame.fromJson(json);
      
      // Assert
      expect(fromJson, equals(frame));
      expect(json['id'], equals('frame-json'));
      expect(json['timestampMs'], equals(4200));
      expect(json['qualityScore'], equals(0.91));
      expect(json['poseAngles']['yaw'], equals(12.5));
      expect(json['faceMetrics']['hasGlasses'], isTrue);
      expect(json['faceMetrics']['boundingBox']['width'], equals(0.56));
    });

    test('should handle timestamp validation for video frames', () {
      // Arrange
      final now = DateTime.now();
      const poseAngles = PoseAngles(yaw: 0.0, pitch: 0.0, roll: 0.0, confidence: 0.90);
      const boundingBox = BoundingBox(x: 0.2, y: 0.15, width: 0.6, height: 0.7);
      const faceMetrics = FaceMetrics(
        boundingBox: boundingBox,
        faceSize: 0.40,
        sharpnessScore: 0.85,
        lightingScore: 0.88,
        symmetryScore: 0.86,
        hasGlasses: false,
        hasHat: false,
        isSmiling: false,
      );
      
      // Valid timestamps for typical registration video (0-30 seconds)
      const validTimestamps = [0, 1000, 5000, 10000, 15000, 25000, 30000];
      
      for (int timestamp in validTimestamps) {
        // Act
        final frame = SelectedFrame(
          id: 'frame-time-$timestamp',
          sessionId: 'session-time',
          imageFilePath: '/storage/time-test.jpg',
          timestampMs: timestamp,
          qualityScore: 0.86,
          poseAngles: poseAngles,
          faceMetrics: faceMetrics,
          extractedAt: now,
        );
        
        // Assert
        expect(frame.timestampMs, equals(timestamp));
        expect(frame.timestampMs, greaterThanOrEqualTo(0));
        expect(frame.timestampMs, lessThanOrEqualTo(30000)); // 30-second max
      }
    });

    test('should validate YOLOv7-Pose specific frame selection criteria', () {
      // Arrange
      final now = DateTime.now();
      
      // Test frames representing the 5 required poses for YOLOv7-Pose guided capture
      const poseFrames = [
        // Straight pose
        PoseAngles(yaw: 0.0, pitch: 0.0, roll: 0.0, confidence: 0.95),
        // Right profile
        PoseAngles(yaw: 45.0, pitch: 0.0, roll: 0.0, confidence: 0.92),
        // Left profile
        PoseAngles(yaw: -45.0, pitch: 0.0, roll: 0.0, confidence: 0.90),
        // Head up
        PoseAngles(yaw: 0.0, pitch: -15.0, roll: 0.0, confidence: 0.88),
        // Head down
        PoseAngles(yaw: 0.0, pitch: 15.0, roll: 0.0, confidence: 0.91),
      ];
      
      const poseNames = ['straight', 'right_profile', 'left_profile', 'head_up', 'head_down'];
      const boundingBox = BoundingBox(x: 0.25, y: 0.20, width: 0.5, height: 0.6);
      
      for (int i = 0; i < poseFrames.length; i++) {
        final poseAngles = poseFrames[i];
        final poseName = poseNames[i];
        
        // Act
        final faceMetrics = FaceMetrics(
          boundingBox: boundingBox,
          faceSize: 0.45,
          sharpnessScore: 0.88,
          lightingScore: 0.90,
          symmetryScore: 0.87,
          hasGlasses: false,
          hasHat: false,
          isSmiling: false,
        );
        
        final frame = SelectedFrame(
          id: 'frame-pose-$poseName',
          sessionId: 'session-yolov7',
          imageFilePath: '/storage/yolov7-$poseName.jpg',
          timestampMs: (i + 1) * 3000, // 3s intervals
          qualityScore: 0.89,
          poseAngles: poseAngles,
          faceMetrics: faceMetrics,
          extractedAt: now,
        );
        
        // Assert
        expect(frame.poseAngles.confidence, greaterThanOrEqualTo(0.85)); // High confidence required
        expect(frame.qualityScore, greaterThanOrEqualTo(0.85)); // High quality required
        expect(frame.faceMetrics.faceSize, greaterThanOrEqualTo(0.30)); // Adequate face size
        expect(frame.faceMetrics.sharpnessScore, greaterThanOrEqualTo(0.80)); // Sharp images
        
        // Verify pose angles are within expected ranges for guided capture
        if (poseName == 'straight') {
          expect(frame.poseAngles.yaw.abs(), lessThanOrEqualTo(15.0));
          expect(frame.poseAngles.pitch.abs(), lessThanOrEqualTo(10.0));
        } else if (poseName == 'right_profile') {
          expect(frame.poseAngles.yaw, greaterThanOrEqualTo(30.0));
        } else if (poseName == 'left_profile') {
          expect(frame.poseAngles.yaw, lessThanOrEqualTo(-30.0));
        } else if (poseName == 'head_up') {
          expect(frame.poseAngles.pitch, lessThanOrEqualTo(-10.0));
        } else if (poseName == 'head_down') {
          expect(frame.poseAngles.pitch, greaterThanOrEqualTo(10.0));
        }
      }
    });
  });

  group('PoseAngles', () {
    test('should create PoseAngles with valid ranges', () {
      // Act
      const poseAngles = PoseAngles(
        yaw: 30.5,
        pitch: -15.2,
        roll: 8.7,
        confidence: 0.94,
      );
      
      // Assert
      expect(poseAngles.yaw, equals(30.5));
      expect(poseAngles.pitch, equals(-15.2));
      expect(poseAngles.roll, equals(8.7));
      expect(poseAngles.confidence, equals(0.94));
    });

    test('should support equality comparison', () {
      // Arrange
      const angles1 = PoseAngles(yaw: 15.0, pitch: -8.0, roll: 2.0, confidence: 0.90);
      const angles2 = PoseAngles(yaw: 15.0, pitch: -8.0, roll: 2.0, confidence: 0.90);
      
      // Act & Assert
      expect(angles1, equals(angles2));
      expect(angles1.hashCode, equals(angles2.hashCode));
    });
  });

  group('FaceMetrics', () {
    test('should create FaceMetrics with all properties', () {
      // Arrange
      const boundingBox = BoundingBox(x: 0.25, y: 0.20, width: 0.5, height: 0.6);
      
      // Act
      const faceMetrics = FaceMetrics(
        boundingBox: boundingBox,
        faceSize: 0.42,
        sharpnessScore: 0.87,
        lightingScore: 0.89,
        symmetryScore: 0.85,
        hasGlasses: true,
        hasHat: false,
        isSmiling: true,
      );
      
      // Assert
      expect(faceMetrics.boundingBox, equals(boundingBox));
      expect(faceMetrics.faceSize, equals(0.42));
      expect(faceMetrics.sharpnessScore, equals(0.87));
      expect(faceMetrics.lightingScore, equals(0.89));
      expect(faceMetrics.symmetryScore, equals(0.85));
      expect(faceMetrics.hasGlasses, isTrue);
      expect(faceMetrics.hasHat, isFalse);
      expect(faceMetrics.isSmiling, isTrue);
    });
  });

  group('BoundingBox', () {
    test('should create BoundingBox with normalized coordinates', () {
      // Act
      const boundingBox = BoundingBox(
        x: 0.22,
        y: 0.18,
        width: 0.56,
        height: 0.64,
      );
      
      // Assert
      expect(boundingBox.x, equals(0.22));
      expect(boundingBox.y, equals(0.18));
      expect(boundingBox.width, equals(0.56));
      expect(boundingBox.height, equals(0.64));
      
      // Verify normalized coordinates (0.0-1.0)
      expect(boundingBox.x, inInclusiveRange(0.0, 1.0));
      expect(boundingBox.y, inInclusiveRange(0.0, 1.0));
      expect(boundingBox.width, inInclusiveRange(0.0, 1.0));
      expect(boundingBox.height, inInclusiveRange(0.0, 1.0));
    });

    test('should validate bounding box does not exceed frame boundaries', () {
      // Arrange
      const validBoundingBoxes = [
        BoundingBox(x: 0.0, y: 0.0, width: 1.0, height: 1.0),
        BoundingBox(x: 0.5, y: 0.5, width: 0.5, height: 0.5),
        BoundingBox(x: 0.1, y: 0.2, width: 0.8, height: 0.7),
      ];
      
      for (final bbox in validBoundingBoxes) {
        // Assert
        expect(bbox.x + bbox.width, lessThanOrEqualTo(1.0));
        expect(bbox.y + bbox.height, lessThanOrEqualTo(1.0));
      }
    });
  });
}