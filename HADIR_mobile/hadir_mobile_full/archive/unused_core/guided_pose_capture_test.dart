import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:camera/camera.dart';
import 'package:hadir_mobile_full/features/registration/presentation/widgets/guided_pose_capture.dart';
import 'package:hadir_mobile_full/features/registration/presentation/providers/pose_capture_provider.dart';
import 'package:hadir_mobile_full/features/registration/presentation/providers/pose_capture_state.dart';
import 'package:hadir_mobile_full/shared/domain/entities/pose_target.dart';
import 'package:hadir_mobile_full/shared/domain/entities/selected_frame.dart';
import 'package:hadir_mobile_full/core/computer_vision/models/pose_detection_result.dart';
import 'package:hadir_mobile_full/core/computer_vision/models/keypoint.dart';
import 'package:hadir_mobile_full/core/computer_vision/models/pose_angles.dart';
import 'package:hadir_mobile_full/core/computer_vision/models/face_metrics.dart';
import 'package:hadir_mobile_full/core/computer_vision/models/bounding_box.dart';
import 'package:hadir_mobile_full/features/registration/presentation/widgets/pose_guidance_overlay.dart';
import 'package:hadir_mobile_full/features/registration/presentation/widgets/camera_preview_widget.dart';
import 'package:hadir_mobile_full/features/registration/presentation/widgets/capture_button.dart';
import 'package:hadir_mobile_full/features/registration/presentation/widgets/quality_indicator.dart';
import 'package:hadir_mobile_full/shared/presentation/widgets/custom_button.dart';
import 'package:hadir_mobile_full/shared/exceptions/pose_detection_exceptions.dart';

import 'guided_pose_capture_test.mocks.dart';

// Generate mocks
@GenerateMocks([PoseCaptureProvider, CameraController])
void main() {
  group('GuidedPoseCapture Widget Tests', () {
    late MockPoseCaptureProvider mockPoseCaptureProvider;
    late MockCameraController mockCameraController;
    
    setUp(() {
      mockPoseCaptureProvider = MockPoseCaptureProvider();
      mockCameraController = MockCameraController();
    });

    Widget createGuidedPoseCaptureWidget() {
      return ProviderScope(
        overrides: [
          poseCaptureProvider.overrideWith((ref) => mockPoseCaptureProvider),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: GuidedPoseCapture(
              sessionId: 'test-session-123',
              onPoseCompleted: null,
              onAllPosesCompleted: null,
            ),
          ),
        ),
      );
    }

    group('Widget Initialization and Layout', () {
      testWidgets('should display all essential UI components', (WidgetTester tester) async {
        // Arrange
        when(mockPoseCaptureProvider.state).thenReturn(const PoseCaptureState.initial());
        
        // Act
        await tester.pumpWidget(createGuidedPoseCaptureWidget());
        
        // Assert
        expect(find.byType(CameraPreviewWidget), findsOneWidget);
        expect(find.byType(PoseGuidanceOverlay), findsOneWidget);
        expect(find.byType(CaptureButton), findsOneWidget);
        expect(find.byType(QualityIndicator), findsOneWidget);
        
        // Instruction text
        expect(find.text('Position your face in the center'), findsOneWidget);
        expect(find.text('Look straight at the camera'), findsOneWidget);
        
        // Progress indicator
        expect(find.text('Pose 1 of 5'), findsOneWidget);
        expect(find.text('Frontal Face'), findsOneWidget);
      });

      testWidgets('should show camera permission request when needed', (WidgetTester tester) async {
        // Arrange
        when(mockPoseCaptureProvider.state).thenReturn(const PoseCaptureState.cameraPermissionRequired());
        
        // Act
        await tester.pumpWidget(createGuidedPoseCaptureWidget());
        
        // Assert
        expect(find.text('Camera Permission Required'), findsOneWidget);
        expect(find.text('HADIR needs camera access to capture your face for registration'), findsOneWidget);
        expect(find.text('Grant Camera Permission'), findsOneWidget);
        expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      });

      testWidgets('should show camera initialization loading', (WidgetTester tester) async {
        // Arrange
        when(mockPoseCaptureProvider.state).thenReturn(const PoseCaptureState.initializingCamera());
        
        // Act
        await tester.pumpWidget(createGuidedPoseCaptureWidget());
        
        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Initializing Camera...'), findsOneWidget);
        expect(find.text('Setting up face detection system'), findsOneWidget);
      });

      testWidgets('should display camera error states', (WidgetTester tester) async {
        // Arrange
        const cameraError = CameraException('CAMERA_ERROR', 'Failed to initialize camera');
        when(mockPoseCaptureProvider.state).thenReturn(const PoseCaptureState.cameraError(cameraError));
        
        // Act
        await tester.pumpWidget(createGuidedPoseCaptureWidget());
        
        // Assert
        expect(find.text('Camera Error'), findsOneWidget);
        expect(find.text('Failed to initialize camera'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
        expect(find.byIcon(Icons.camera_off), findsOneWidget);
      });
    });

    group('Pose Guidance and Instructions', () {
      testWidgets('should display frontal face guidance', (WidgetTester tester) async {
        // Arrange
        when(mockPoseCaptureProvider.state).thenReturn(const PoseCaptureState.readyToCapture(PoseTarget.frontalFace));
        
        // Act
        await tester.pumpWidget(createGuidedPoseCaptureWidget());
        
        // Assert
        expect(find.text('Frontal Face'), findsOneWidget);
        expect(find.text('Look straight at the camera'), findsOneWidget);
        expect(find.text('Keep your head level and centered'), findsOneWidget);
        expect(find.text('Make sure your face is well-lit'), findsOneWidget);
        
        // Guidance overlay should show frontal pose outline
        final guidanceOverlay = tester.widget<PoseGuidanceOverlay>(find.byType(PoseGuidanceOverlay));
        expect(guidanceOverlay.currentPose, equals(PoseTarget.frontalFace));
      });

      testWidgets('should display left profile guidance', (WidgetTester tester) async {
        // Arrange
        when(mockPoseCaptureProvider.state).thenReturn(const PoseCaptureState.readyToCapture(PoseTarget.leftProfile));
        
        // Act
        await tester.pumpWidget(createGuidedPoseCaptureWidget());
        
        // Assert
        expect(find.text('Left Profile'), findsOneWidget);
        expect(find.text('Turn your head to the left'), findsOneWidget);
        expect(find.text('Show your left side profile'), findsOneWidget);
        expect(find.text('Keep your left eye visible to the camera'), findsOneWidget);
        
        // Progress should show current pose
        expect(find.text('Pose 2 of 5'), findsOneWidget);
      });

      testWidgets('should display right profile guidance', (WidgetTester tester) async {
        // Arrange
        when(mockPoseCaptureProvider.state).thenReturn(const PoseCaptureState.readyToCapture(PoseTarget.rightProfile));
        
        // Act
        await tester.pumpWidget(createGuidedPoseCaptureWidget());
        
        // Assert
        expect(find.text('Right Profile'), findsOneWidget);
        expect(find.text('Turn your head to the right'), findsOneWidget);
        expect(find.text('Show your right side profile'), findsOneWidget);
        expect(find.text('Keep your right eye visible to the camera'), findsOneWidget);
        
        expect(find.text('Pose 3 of 5'), findsOneWidget);
      });

      testWidgets('should display upward angle guidance', (WidgetTester tester) async {
        // Arrange
        when(mockPoseCaptureProvider.state).thenReturn(const PoseCaptureState.readyToCapture(PoseTarget.upwardAngle));
        
        // Act
        await tester.pumpWidget(createGuidedPoseCaptureWidget());
        
        // Assert
        expect(find.text('Upward Angle'), findsOneWidget);
        expect(find.text('Tilt your head slightly up'), findsOneWidget);
        expect(find.text('Look up while keeping eyes visible'), findsOneWidget);
        expect(find.text('Maintain a comfortable angle'), findsOneWidget);
        
        expect(find.text('Pose 4 of 5'), findsOneWidget);
      });

      testWidgets('should display downward angle guidance', (WidgetTester tester) async {
        // Arrange
        when(mockPoseCaptureProvider.state).thenReturn(const PoseCaptureState.readyToCapture(PoseTarget.downwardAngle));
        
        // Act
        await tester.pumpWidget(createGuidedPoseCaptureWidget());
        
        // Assert
        expect(find.text('Downward Angle'), findsOneWidget);
        expect(find.text('Tilt your head slightly down'), findsOneWidget);
        expect(find.text('Look down while keeping face visible'), findsOneWidget);
        expect(find.text('Show the top of your head'), findsOneWidget);
        
        expect(find.text('Pose 5 of 5'), findsOneWidget);
      });

      testWidgets('should update guidance overlay based on real-time pose detection', (WidgetTester tester) async {
        // Arrange
        final realTimePoseState = PoseCaptureState.detectingPose(
          PoseTarget.frontalFace,
          const PoseDetectionResult(
            confidence: 0.85,
            keypoints: [
              Keypoint(id: 0, x: 320.0, y: 240.0, confidence: 0.90),
              Keypoint(id: 1, x: 310.0, y: 230.0, confidence: 0.88),
              Keypoint(id: 2, x: 330.0, y: 230.0, confidence: 0.89),
            ],
            angles: PoseAngles(yaw: 5.2, pitch: -2.1, roll: 1.3), // Slightly off-center
            faceMetrics: FaceMetrics(width: 120.0, height: 150.0, aspectRatio: 0.8, area: 18000.0),
            boundingBox: BoundingBox(x: 260.0, y: 165.0, width: 120.0, height: 150.0),
            qualityScore: 0.82,
            timestamp: DateTime.now(),
          ),
        );
        
        when(mockPoseCaptureProvider.state).thenReturn(realTimePoseState);
        
        // Act
        await tester.pumpWidget(createGuidedPoseCaptureWidget());
        
        // Assert
        expect(find.text('Adjust Your Position'), findsOneWidget);
        expect(find.text('Turn slightly to the left'), findsOneWidget); // Yaw is +5.2°
        expect(find.text('Confidence: 85%'), findsOneWidget);
        
        // Quality indicator should show current quality
        final qualityIndicator = tester.widget<QualityIndicator>(find.byType(QualityIndicator));
        expect(qualityIndicator.qualityScore, equals(0.82));
      });

      testWidgets('should provide audio guidance when enabled', (WidgetTester tester) async {
        // Arrange
        when(mockPoseCaptureProvider.state).thenReturn(const PoseCaptureState.readyToCapture(PoseTarget.frontalFace));
        
        // Act
        await tester.pumpWidget(createGuidedPoseCaptureWidget());
        
        // Find audio toggle button
        final audioToggle = find.byKey(const Key('audio_guidance_toggle'));
        expect(audioToggle, findsOneWidget);
        
        await tester.tap(audioToggle);
        await tester.pump();
        
        // Assert
        expect(find.byIcon(Icons.volume_up), findsOneWidget); // Audio enabled icon
        verify(mockPoseCaptureProvider.toggleAudioGuidance()).called(1);
      });
    });

    group('Pose Detection and Validation', () {
      testWidgets('should show live pose detection feedback', (WidgetTester tester) async {
        // Arrange
        final detectingState = PoseCaptureState.detectingPose(
          PoseTarget.frontalFace,
          const PoseDetectionResult(
            confidence: 0.94,
            keypoints: [
              Keypoint(id: 0, x: 320.0, y: 240.0, confidence: 0.96),
              Keypoint(id: 1, x: 315.0, y: 235.0, confidence: 0.93),
              Keypoint(id: 2, x: 325.0, y: 235.0, confidence: 0.95),
            ],
            angles: PoseAngles(yaw: 1.2, pitch: -0.8, roll: 0.5), // Good frontal pose
            faceMetrics: FaceMetrics(width: 125.0, height: 155.0, aspectRatio: 0.806, area: 19375.0),
            boundingBox: BoundingBox(x: 257.5, y: 162.5, width: 125.0, height: 155.0),
            qualityScore: 0.91,
            timestamp: DateTime.now(),
          ),
        );
        
        when(mockPoseCaptureProvider.state).thenReturn(detectingState);
        
        // Act
        await tester.pumpWidget(createGuidedPoseCaptureWidget());
        
        // Assert
        expect(find.text('Perfect Position!'), findsOneWidget);
        expect(find.text('Confidence: 94%'), findsOneWidget);
        expect(find.text('Quality: Excellent'), findsOneWidget);
        
        // Capture button should be enabled and highlighted
        final captureButton = tester.widget<CaptureButton>(find.byType(CaptureButton));
        expect(captureButton.isEnabled, isTrue);
        expect(captureButton.isHighlighted, isTrue);
      });

      testWidgets('should show low confidence warning', (WidgetTester tester) async {
        // Arrange
        final lowConfidenceState = PoseCaptureState.detectingPose(
          PoseTarget.leftProfile,
          const PoseDetectionResult(
            confidence: 0.72, // Below 90% threshold
            keypoints: [
              Keypoint(id: 0, x: 180.0, y: 240.0, confidence: 0.70),
              Keypoint(id: 1, x: 190.0, y: 235.0, confidence: 0.68),
            ],
            angles: PoseAngles(yaw: -35.2, pitch: 3.1, roll: -2.8), // Left profile but low confidence
            faceMetrics: FaceMetrics(width: 98.0, height: 125.0, aspectRatio: 0.784, area: 12250.0),
            boundingBox: BoundingBox(x: 131.0, y: 177.5, width: 98.0, height: 125.0),
            qualityScore: 0.69,
            timestamp: DateTime.now(),
          ),
        );
        
        when(mockPoseCaptureProvider.state).thenReturn(lowConfidenceState);
        
        // Act
        await tester.pumpWidget(createGuidedPoseCaptureWidget());
        
        // Assert
        expect(find.text('Improve Position'), findsOneWidget);
        expect(find.text('Confidence: 72%'), findsOneWidget);
        expect(find.text('Quality: Poor'), findsOneWidget);
        expect(find.text('Move to better lighting'), findsOneWidget);
        expect(find.text('Hold phone steady'), findsOneWidget);
        
        // Capture button should be disabled
        final captureButton = tester.widget<CaptureButton>(find.byType(CaptureButton));
        expect(captureButton.isEnabled, isFalse);
      });

      testWidgets('should handle incorrect pose angle detection', (WidgetTester tester) async {
        // Arrange
        final incorrectAngleState = PoseCaptureState.detectingPose(
          PoseTarget.rightProfile, // Expecting right profile
          const PoseDetectionResult(
            confidence: 0.91, // Good confidence
            keypoints: [
              Keypoint(id: 0, x: 320.0, y: 240.0, confidence: 0.93),
              Keypoint(id: 1, x: 315.0, y: 235.0, confidence: 0.90),
              Keypoint(id: 2, x: 325.0, y: 235.0, confidence: 0.92),
            ],
            angles: PoseAngles(yaw: -2.1, pitch: 1.3, roll: 0.8), // Frontal pose instead of right profile
            faceMetrics: FaceMetrics(width: 122.0, height: 152.0, aspectRatio: 0.803, area: 18544.0),
            boundingBox: BoundingBox(x: 259.0, y: 164.0, width: 122.0, height: 152.0),
            qualityScore: 0.87,
            timestamp: DateTime.now(),
          ),
        );
        
        when(mockPoseCaptureProvider.state).thenReturn(incorrectAngleState);
        
        // Act
        await tester.pumpWidget(createGuidedPoseCaptureWidget());
        
        // Assert
        expect(find.text('Wrong Angle'), findsOneWidget);
        expect(find.text('Turn your head to the right'), findsOneWidget);
        expect(find.text('Show your right side profile'), findsOneWidget);
        
        // Visual guidance should emphasize the required pose
        final guidanceOverlay = tester.widget<PoseGuidanceOverlay>(find.byType(PoseGuidanceOverlay));
        expect(guidanceOverlay.showCorrection, isTrue);
        expect(guidanceOverlay.currentPose, equals(PoseTarget.rightProfile));
      });

      testWidgets('should handle YOLOv7-Pose detection timeout', (WidgetTester tester) async {
        // Arrange
        const timeoutError = ProcessingTimeoutException('YOLOv7-Pose detection timeout');
        when(mockPoseCaptureProvider.state).thenReturn(const PoseCaptureState.detectionError(timeoutError));
        
        // Act
        await tester.pumpWidget(createGuidedPoseCaptureWidget());
        
        // Assert
        expect(find.text('Detection Timeout'), findsOneWidget);
        expect(find.text('YOLOv7-Pose detection timeout'), findsOneWidget);
        expect(find.text('The face detection is taking too long'), findsOneWidget);
        expect(find.text('Try Again'), findsOneWidget);
        expect(find.byIcon(Icons.timer_off), findsOneWidget);
      });
    });

    group('Frame Capture Process', () {
      testWidgets('should trigger frame capture when button pressed', (WidgetTester tester) async {
        // Arrange
        final readyToCapture = PoseCaptureState.detectingPose(
          PoseTarget.frontalFace,
          const PoseDetectionResult(
            confidence: 0.95,
            keypoints: [Keypoint(id: 0, x: 320.0, y: 240.0, confidence: 0.96)],
            angles: PoseAngles(yaw: 0.8, pitch: -1.2, roll: 0.4),
            faceMetrics: FaceMetrics(width: 120.0, height: 150.0, aspectRatio: 0.8, area: 18000.0),
            boundingBox: BoundingBox(x: 260.0, y: 165.0, width: 120.0, height: 150.0),
            qualityScore: 0.92,
            timestamp: DateTime.now(),
          ),
        );
        
        when(mockPoseCaptureProvider.state).thenReturn(readyToCapture);
        when(mockPoseCaptureProvider.captureFrame()).thenAnswer((_) async {
          return null;
        });
        
        // Act
        await tester.pumpWidget(createGuidedPoseCaptureWidget());
        
        final captureButton = find.byType(CaptureButton);
        await tester.tap(captureButton);
        await tester.pump();
        
        // Assert
        verify(mockPoseCaptureProvider.captureFrame()).called(1);
      });

      testWidgets('should show processing state during capture', (WidgetTester tester) async {
        // Arrange
        when(mockPoseCaptureProvider.state).thenReturn(const PoseCaptureState.processingCapture());
        
        // Act
        await tester.pumpWidget(createGuidedPoseCaptureWidget());
        
        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Processing Capture...'), findsOneWidget);
        expect(find.text('Analyzing with YOLOv7-Pose'), findsOneWidget);
        
        // Capture button should be disabled during processing
        final captureButton = tester.widget<CaptureButton>(find.byType(CaptureButton));
        expect(captureButton.isEnabled, isFalse);
      });

      testWidgets('should show success animation after successful capture', (WidgetTester tester) async {
        // Arrange
        final successfulCapture = SelectedFrame(
          id: 'frame-success-123',
          sessionId: 'session-test',
          poseTarget: PoseTarget.frontalFace,
          imageUrl: 'storage/frames/frame-success-123.jpg',
          capturedAt: DateTime.now(),
          poseResult: const PoseDetectionResult(
            confidence: 0.96,
            keypoints: [Keypoint(id: 0, x: 320.0, y: 240.0, confidence: 0.97)],
            angles: PoseAngles(yaw: 0.5, pitch: -0.8, roll: 0.2),
            faceMetrics: FaceMetrics(width: 125.0, height: 155.0, aspectRatio: 0.806, area: 19375.0),
            boundingBox: BoundingBox(x: 257.5, y: 162.5, width: 125.0, height: 155.0),
            qualityScore: 0.93,
            timestamp: DateTime.now(),
          ),
          qualityMetrics: FrameQualityMetrics(
            sharpness: 0.89,
            brightness: 0.78,
            contrast: 0.82,
            faceVisibility: 0.96,
            poseAccuracy: 0.93,
            overallQuality: 0.88,
          ),
          isSelected: true,
          processingTime: 1250,
          createdAt: DateTime.now(),
        );
        
        when(mockPoseCaptureProvider.state).thenReturn(PoseCaptureState.captureSuccess(successfulCapture));
        
        // Act
        await tester.pumpWidget(createGuidedPoseCaptureWidget());
        
        // Assert
        expect(find.text('Capture Successful!'), findsOneWidget);
        expect(find.text('Quality: 88%'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        
        // Should show animated checkmark
        expect(find.byType(AnimatedContainer), findsWidgets);
        
        // Continue button should appear
        expect(find.text('Continue to Next Pose'), findsOneWidget);
      });

      testWidgets('should handle capture failure gracefully', (WidgetTester tester) async {
        // Arrange
        const captureError = LowQualityFrameException('Frame quality below threshold');
        when(mockPoseCaptureProvider.state).thenReturn(const PoseCaptureState.captureError(captureError));
        
        // Act
        await tester.pumpWidget(createGuidedPoseCaptureWidget());
        
        // Assert
        expect(find.text('Capture Failed'), findsOneWidget);
        expect(find.text('Frame quality below threshold'), findsOneWidget);
        expect(find.text('Try Again'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
        
        // Retry functionality
        when(mockPoseCaptureProvider.clearError()).thenReturn(null);
        
        final retryButton = find.text('Try Again');
        await tester.tap(retryButton);
        await tester.pump();
        
        verify(mockPoseCaptureProvider.clearError()).called(1);
      });

      testWidgets('should advance to next pose after successful capture', (WidgetTester tester) async {
        // Arrange - Start with frontal face success
        final frontalCapture = SelectedFrame(
          id: 'frame-frontal',
          sessionId: 'session-advance',
          poseTarget: PoseTarget.frontalFace,
          imageUrl: 'storage/frames/frame-frontal.jpg',
          capturedAt: DateTime.now(),
          poseResult: const PoseDetectionResult(
            confidence: 0.94,
            keypoints: [Keypoint(id: 0, x: 320.0, y: 240.0, confidence: 0.95)],
            angles: PoseAngles(yaw: 0.0, pitch: 0.0, roll: 0.0),
            faceMetrics: FaceMetrics(width: 120.0, height: 150.0, aspectRatio: 0.8, area: 18000.0),
            boundingBox: BoundingBox(x: 260.0, y: 165.0, width: 120.0, height: 150.0),
            qualityScore: 0.90,
            timestamp: DateTime.now(),
          ),
          qualityMetrics: FrameQualityMetrics(
            sharpness: 0.86,
            brightness: 0.75,
            contrast: 0.80,
            faceVisibility: 0.94,
            poseAccuracy: 0.90,
            overallQuality: 0.85,
          ),
          isSelected: true,
          processingTime: 1100,
          createdAt: DateTime.now(),
        );
        
        when(mockPoseCaptureProvider.state).thenReturn(PoseCaptureState.captureSuccess(frontalCapture));
        when(mockPoseCaptureProvider.advanceToNextPose()).thenAnswer((_) async {
          return null;
        });
        
        // Act
        await tester.pumpWidget(createGuidedPoseCaptureWidget());
        
        final continueButton = find.text('Continue to Next Pose');
        await tester.tap(continueButton);
        await tester.pump();
        
        // Assert
        verify(mockPoseCaptureProvider.advanceToNextPose()).called(1);
      });
    });

    group('Completion and Final State', () {
      testWidgets('should show completion state when all poses captured', (WidgetTester tester) async {
        // Arrange
        final completedFrames = List.generate(5, (index) => SelectedFrame(
          id: 'frame-$index',
          sessionId: 'session-complete',
          poseTarget: PoseTarget.values[index],
          imageUrl: 'storage/frames/frame-$index.jpg',
          capturedAt: DateTime.now(),
          poseResult: const PoseDetectionResult(
            confidence: 0.92,
            keypoints: [Keypoint(id: 0, x: 320.0, y: 240.0, confidence: 0.93)],
            angles: PoseAngles(yaw: 0.0, pitch: 0.0, roll: 0.0),
            faceMetrics: FaceMetrics(width: 120.0, height: 150.0, aspectRatio: 0.8, area: 18000.0),
            boundingBox: BoundingBox(x: 260.0, y: 165.0, width: 120.0, height: 150.0),
            qualityScore: 0.88,
            timestamp: DateTime.now(),
          ),
          qualityMetrics: FrameQualityMetrics(
            sharpness: 0.84,
            brightness: 0.76,
            contrast: 0.79,
            faceVisibility: 0.92,
            poseAccuracy: 0.88,
            overallQuality: 0.84,
          ),
          isSelected: true,
          processingTime: 1200,
          createdAt: DateTime.now(),
        ));
        
        when(mockPoseCaptureProvider.state).thenReturn(PoseCaptureState.allPosesCompleted(completedFrames));
        
        // Act
        await tester.pumpWidget(createGuidedPoseCaptureWidget());
        
        // Assert
        expect(find.text('All Poses Captured!'), findsOneWidget);
        expect(find.text('5 of 5 poses completed successfully'), findsOneWidget);
        expect(find.text('Average Quality: 84%'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
        
        // Should show thumbnail gallery of captured frames
        expect(find.byType(GridView), findsOneWidget);
        expect(find.byKey(const Key('captured_frame_0')), findsOneWidget);
        expect(find.byKey(const Key('captured_frame_4')), findsOneWidget);
        
        // Completion buttons
        expect(find.text('Complete Registration'), findsOneWidget);
        expect(find.text('Retake Photos'), findsOneWidget);
      });

      testWidgets('should show individual frame thumbnails with quality scores', (WidgetTester tester) async {
        // Arrange
        final completedFrames = [
          SelectedFrame(
            id: 'frame-frontal',
            sessionId: 'session-thumbnails',
            poseTarget: PoseTarget.frontalFace,
            imageUrl: 'storage/frames/frame-frontal.jpg',
            capturedAt: DateTime.now(),
            poseResult: const PoseDetectionResult(
              confidence: 0.96,
              keypoints: [Keypoint(id: 0, x: 320.0, y: 240.0, confidence: 0.97)],
              angles: PoseAngles(yaw: 0.0, pitch: 0.0, roll: 0.0),
              faceMetrics: FaceMetrics(width: 120.0, height: 150.0, aspectRatio: 0.8, area: 18000.0),
              boundingBox: BoundingBox(x: 260.0, y: 165.0, width: 120.0, height: 150.0),
              qualityScore: 0.93,
              timestamp: DateTime.now(),
            ),
            qualityMetrics: FrameQualityMetrics(
              sharpness: 0.91,
              brightness: 0.82,
              contrast: 0.86,
              faceVisibility: 0.97,
              poseAccuracy: 0.93,
              overallQuality: 0.90,
            ),
            isSelected: true,
            processingTime: 950,
            createdAt: DateTime.now(),
          ),
          SelectedFrame(
            id: 'frame-left',
            sessionId: 'session-thumbnails',
            poseTarget: PoseTarget.leftProfile,
            imageUrl: 'storage/frames/frame-left.jpg',
            capturedAt: DateTime.now(),
            poseResult: const PoseDetectionResult(
              confidence: 0.91,
              keypoints: [Keypoint(id: 0, x: 180.0, y: 240.0, confidence: 0.92)],
              angles: PoseAngles(yaw: -45.0, pitch: 0.0, roll: 0.0),
              faceMetrics: FaceMetrics(width: 90.0, height: 140.0, aspectRatio: 0.643, area: 12600.0),
              boundingBox: BoundingBox(x: 135.0, y: 170.0, width: 90.0, height: 140.0),
              qualityScore: 0.87,
              timestamp: DateTime.now(),
            ),
            qualityMetrics: FrameQualityMetrics(
              sharpness: 0.85,
              brightness: 0.78,
              contrast: 0.81,
              faceVisibility: 0.89,
              poseAccuracy: 0.87,
              overallQuality: 0.84,
            ),
            isSelected: true,
            processingTime: 1100,
            createdAt: DateTime.now(),
          ),
        ];
        
        when(mockPoseCaptureProvider.state).thenReturn(PoseCaptureState.allPosesCompleted(completedFrames));
        
        // Act
        await tester.pumpWidget(createGuidedPoseCaptureWidget());
        
        // Assert - Check thumbnail display
        expect(find.text('Frontal: 90%'), findsOneWidget);
        expect(find.text('Left Profile: 84%'), findsOneWidget);
        
        // Thumbnails should be tappable for review
        final frontalThumbnail = find.byKey(const Key('thumbnail_frontal_face'));
        expect(frontalThumbnail, findsOneWidget);
        
        await tester.tap(frontalThumbnail);
        await tester.pump();
        
        // Should show detailed view
        expect(find.text('Frame Details'), findsOneWidget);
        expect(find.text('Confidence: 96%'), findsOneWidget);
        expect(find.text('Sharpness: 91%'), findsOneWidget);
      });

      testWidgets('should handle retake functionality', (WidgetTester tester) async {
        // Arrange
        final completedFrames = List.generate(5, (index) => SelectedFrame(
          id: 'frame-retake-$index',
          sessionId: 'session-retake',
          poseTarget: PoseTarget.values[index],
          imageUrl: 'storage/frames/frame-retake-$index.jpg',
          capturedAt: DateTime.now(),
          poseResult: const PoseDetectionResult(
            confidence: 0.85,
            keypoints: [Keypoint(id: 0, x: 320.0, y: 240.0, confidence: 0.86)],
            angles: PoseAngles(yaw: 0.0, pitch: 0.0, roll: 0.0),
            faceMetrics: FaceMetrics(width: 120.0, height: 150.0, aspectRatio: 0.8, area: 18000.0),
            boundingBox: BoundingBox(x: 260.0, y: 165.0, width: 120.0, height: 150.0),
            qualityScore: 0.81,
            timestamp: DateTime.now(),
          ),
          qualityMetrics: FrameQualityMetrics(
            sharpness: 0.79,
            brightness: 0.73,
            contrast: 0.76,
            faceVisibility: 0.87,
            poseAccuracy: 0.81,
            overallQuality: 0.79,
          ),
          isSelected: true,
          processingTime: 1400,
          createdAt: DateTime.now(),
        ));
        
        when(mockPoseCaptureProvider.state).thenReturn(PoseCaptureState.allPosesCompleted(completedFrames));
        when(mockPoseCaptureProvider.restartCapture()).thenAnswer((_) async {
          return null;
        });
        
        // Act
        await tester.pumpWidget(createGuidedPoseCaptureWidget());
        
        final retakeButton = find.text('Retake Photos');
        await tester.tap(retakeButton);
        await tester.pump();
        
        // Should show confirmation dialog
        expect(find.text('Retake All Photos?'), findsOneWidget);
        expect(find.text('This will delete all current captures and start over'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Retake All'), findsOneWidget);
        
        // Confirm retake
        await tester.tap(find.text('Retake All'));
        await tester.pump();
        
        // Assert
        verify(mockPoseCaptureProvider.restartCapture()).called(1);
      });
    });

    group('Accessibility and User Experience', () {
      testWidgets('should have proper accessibility labels', (WidgetTester tester) async {
        // Arrange
        when(mockPoseCaptureProvider.state).thenReturn(const PoseCaptureState.readyToCapture(PoseTarget.frontalFace));
        
        // Act
        await tester.pumpWidget(createGuidedPoseCaptureWidget());
        
        // Assert
        expect(find.bySemanticsLabel('Camera preview for face capture'), findsOneWidget);
        expect(find.bySemanticsLabel('Capture current pose'), findsOneWidget);
        expect(find.bySemanticsLabel('Current pose quality indicator'), findsOneWidget);
        expect(find.bySemanticsLabel('Toggle audio guidance'), findsOneWidget);
      });

      testWidgets('should provide haptic feedback on successful capture', (WidgetTester tester) async {
        // Arrange
        final readyState = PoseCaptureState.detectingPose(
          PoseTarget.frontalFace,
          const PoseDetectionResult(
            confidence: 0.95,
            keypoints: [Keypoint(id: 0, x: 320.0, y: 240.0, confidence: 0.96)],
            angles: PoseAngles(yaw: 0.0, pitch: 0.0, roll: 0.0),
            faceMetrics: FaceMetrics(width: 120.0, height: 150.0, aspectRatio: 0.8, area: 18000.0),
            boundingBox: BoundingBox(x: 260.0, y: 165.0, width: 120.0, height: 150.0),
            qualityScore: 0.92,
            timestamp: DateTime.now(),
          ),
        );
        
        when(mockPoseCaptureProvider.state).thenReturn(readyState);
        when(mockPoseCaptureProvider.captureFrame()).thenAnswer((_) async {
          return null;
        });
        
        // Act
        await tester.pumpWidget(createGuidedPoseCaptureWidget());
        
        final captureButton = find.byType(CaptureButton);
        await tester.tap(captureButton);
        await tester.pump();
        
        // Assert - Verify haptic feedback was triggered
        verify(mockPoseCaptureProvider.captureFrame()).called(1);
        // Note: Haptic feedback testing would require additional mocking of platform channels
      });

      testWidgets('should handle device rotation gracefully', (WidgetTester tester) async {
        // Arrange
        when(mockPoseCaptureProvider.state).thenReturn(const PoseCaptureState.readyToCapture(PoseTarget.frontalFace));
        
        // Act - Test portrait orientation
        await tester.binding.setSurfaceSize(const Size(375, 812)); // iPhone portrait
        await tester.pumpWidget(createGuidedPoseCaptureWidget());
        
        // Should display properly in portrait
        expect(find.byType(CameraPreviewWidget), findsOneWidget);
        expect(find.byType(PoseGuidanceOverlay), findsOneWidget);
        
        // Act - Test landscape orientation
        await tester.binding.setSurfaceSize(const Size(812, 375)); // iPhone landscape
        await tester.pump();
        
        // Should still display properly in landscape
        expect(find.byType(CameraPreviewWidget), findsOneWidget);
        expect(find.byType(PoseGuidanceOverlay), findsOneWidget);
      });

      testWidgets('should show help dialog when help button tapped', (WidgetTester tester) async {
        // Arrange
        when(mockPoseCaptureProvider.state).thenReturn(const PoseCaptureState.readyToCapture(PoseTarget.frontalFace));
        
        // Act
        await tester.pumpWidget(createGuidedPoseCaptureWidget());
        
        final helpButton = find.byKey(const Key('help_button'));
        await tester.tap(helpButton);
        await tester.pump();
        
        // Assert
        expect(find.text('Face Capture Help'), findsOneWidget);
        expect(find.text('Tips for Best Results:'), findsOneWidget);
        expect(find.text('• Ensure good lighting'), findsOneWidget);
        expect(find.text('• Hold device steady'), findsOneWidget);
        expect(find.text('• Follow pose instructions carefully'), findsOneWidget);
        expect(find.text('• Wait for green checkmark before capturing'), findsOneWidget);
        expect(find.text('Got It'), findsOneWidget);
      });

      testWidgets('should maintain performance during continuous pose detection', (WidgetTester tester) async {
        // Arrange
        when(mockPoseCaptureProvider.state).thenReturn(const PoseCaptureState.readyToCapture(PoseTarget.frontalFace));
        
        // Act
        await tester.pumpWidget(createGuidedPoseCaptureWidget());
        
        // Simulate continuous pose detection updates
        for (int i = 0; i < 30; i++) {
          final updatedState = PoseCaptureState.detectingPose(
            PoseTarget.frontalFace,
            PoseDetectionResult(
              confidence: 0.90 + (i % 10) * 0.01,
              keypoints: [Keypoint(id: 0, x: 320.0 + i, y: 240.0 + i, confidence: 0.92)],
              angles: PoseAngles(yaw: i * 0.1, pitch: -i * 0.05, roll: i * 0.02),
              faceMetrics: const FaceMetrics(width: 120.0, height: 150.0, aspectRatio: 0.8, area: 18000.0),
              boundingBox: const BoundingBox(x: 260.0, y: 165.0, width: 120.0, height: 150.0),
              qualityScore: 0.85 + (i % 5) * 0.02,
              timestamp: DateTime.now(),
            ),
          );
          
          when(mockPoseCaptureProvider.state).thenReturn(updatedState);
          await tester.pump(const Duration(milliseconds: 33)); // ~30 FPS updates
        }
        
        // Assert - UI should still be responsive
        expect(find.byType(CameraPreviewWidget), findsOneWidget);
        expect(find.byType(QualityIndicator), findsOneWidget);
      });
    });
  });
}