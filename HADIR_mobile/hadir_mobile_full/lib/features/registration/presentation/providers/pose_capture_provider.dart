import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hadir_mobile_full/shared/domain/entities/selected_frame.dart';
import 'package:hadir_mobile_full/core/computer_vision/yolov7_pose_detector.dart';

/// Pose capture state
class PoseCaptureState {
  const PoseCaptureState({
    this.currentPose = PoseType.frontal,
    this.detectedPose,
    this.confidenceScore,
    this.isCapturing = false,
    this.isCameraReady = false,
    this.error,
    this.capturedFrame,
  });

  final PoseType currentPose;
  final PoseType? detectedPose;
  final double? confidenceScore;
  final bool isCapturing;
  final bool isCameraReady;
  final String? error;
  final SelectedFrame? capturedFrame;

  bool get isPoseCorrect => detectedPose == currentPose;
  bool get hasGoodConfidence => confidenceScore != null && confidenceScore! >= 0.9;

  PoseCaptureState copyWith({
    PoseType? currentPose,
    PoseType? detectedPose,
    double? confidenceScore,
    bool? isCapturing,
    bool? isCameraReady,
    String? error,
    SelectedFrame? capturedFrame,
  }) {
    return PoseCaptureState(
      currentPose: currentPose ?? this.currentPose,
      detectedPose: detectedPose,
      confidenceScore: confidenceScore,
      isCapturing: isCapturing ?? this.isCapturing,
      isCameraReady: isCameraReady ?? this.isCameraReady,
      error: error,
      capturedFrame: capturedFrame,
    );
  }
}

/// Pose capture provider
class PoseCaptureNotifier extends StateNotifier<PoseCaptureState> {
  PoseCaptureNotifier(this._poseDetector) : super(const PoseCaptureState());

  final YOLOv7PoseDetector _poseDetector;

  /// Initialize camera and pose detector
  Future<void> initialize() async {
    state = state.copyWith(error: null);

    try {
      // Initialize pose detector
      if (!_poseDetector.isInitialized) {
        await _poseDetector.initialize();
      }

      // Initialize camera (simulated)
      await Future.delayed(const Duration(seconds: 1));

      state = state.copyWith(isCameraReady: true);
    } catch (e) {
      state = state.copyWith(error: 'Failed to initialize: ${e.toString()}');
    }
  }

  /// Set current pose target
  void setCurrentPose(PoseType pose) {
    state = state.copyWith(
      currentPose: pose,
      detectedPose: null,
      confidenceScore: null,
      capturedFrame: null,
      error: null,
    );
  }

  /// Process camera frame for pose detection
  Future<void> processFrame(List<int> imageData) async {
    if (!state.isCameraReady || state.isCapturing) return;

    try {
      final result = await _poseDetector.detectPose(Uint8List.fromList(imageData));
      
      state = state.copyWith(
        detectedPose: result.poseType,
        confidenceScore: result.confidenceScore,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: 'Detection failed: ${e.toString()}');
    }
  }

  /// Capture current frame
  Future<SelectedFrame?> captureFrame(
    String sessionId,
    List<int> imageData,
  ) async {
    if (!state.isCameraReady || state.isCapturing) return null;

    state = state.copyWith(isCapturing: true, error: null);

    try {
      final result = await _poseDetector.detectPose(Uint8List.fromList(imageData));
      
      // Generate face embedding
      final embedding = await _poseDetector.generateFaceEmbedding(result);
      
      // Create selected frame
      final now = DateTime.now();
      final frame = SelectedFrame(
        id: 'FRM${now.millisecondsSinceEpoch.toString().padLeft(8, '0')}',
        registrationSessionId: sessionId,
        imagePath: 'frames/frame_${now.millisecondsSinceEpoch}.jpg',
        poseType: result.poseType,
        confidenceScore: result.confidenceScore,
        quality: result.quality,
        faceEmbedding: embedding,
        faceBoundingBox: result.faceBoundingBox,
        keyPoints: result.keyPoints,
        capturedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      state = state.copyWith(
        capturedFrame: frame,
        isCapturing: false,
      );

      return frame;
    } catch (e) {
      state = state.copyWith(
        isCapturing: false,
        error: 'Capture failed: ${e.toString()}',
      );
      return null;
    }
  }

  /// Reset state
  void reset() {
    state = const PoseCaptureState();
  }

  /// Dispose resources
  @override
  void dispose() {
    _poseDetector.dispose();
    super.dispose();
  }
}

/// Pose capture provider
final poseCaptureProvider = StateNotifierProvider<PoseCaptureNotifier, PoseCaptureState>((ref) {
  // This would be injected with actual dependencies
  throw UnimplementedError('PoseCaptureNotifier requires YOLOv7PoseDetector dependency');
});