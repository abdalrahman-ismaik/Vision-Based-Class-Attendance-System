import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hadir_mobile_full/shared/domain/entities/selected_frame.dart';
import 'package:hadir_mobile_full/core/computer_vision/ml_kit_face_detector.dart';
import 'package:hadir_mobile_full/core/computer_vision/pose_type.dart';

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
  PoseCaptureNotifier(this._faceDetector) : super(const PoseCaptureState());

  final MLKitFaceDetector _faceDetector;

  /// Initialize camera and ML Kit face detector
  Future<void> initialize() async {
    state = state.copyWith(error: null);

    try {
      // Initialize face detector
      if (!_faceDetector.isInitialized) {
        await _faceDetector.initialize();
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

  /// Process camera frame for face and pose detection
  Future<void> processFrame(List<int> imageData) async {
    if (!state.isCameraReady || state.isCapturing) return;

    try {
      final result = await _faceDetector.detectPose(Uint8List.fromList(imageData));
      
      state = state.copyWith(
        detectedPose: result.poseType,
        confidenceScore: result.confidenceScore,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: 'Detection failed: ${e.toString()}');
    }
  }

  /// Capture current frame using ML Kit face detection
  Future<SelectedFrame?> captureFrame(
    String sessionId,
    List<int> imageData,
  ) async {
    if (!state.isCameraReady || state.isCapturing) return null;

    state = state.copyWith(isCapturing: true, error: null);

    try {
      final result = await _faceDetector.detectPose(Uint8List.fromList(imageData));
      
      // Create selected frame with ML Kit detection results
      final now = DateTime.now();
      final frame = SelectedFrame(
        id: 'FRM${now.millisecondsSinceEpoch.toString().padLeft(8, '0')}',
        sessionId: sessionId,
        imageFilePath: 'frames/frame_${now.millisecondsSinceEpoch}.jpg',
        timestampMs: now.millisecondsSinceEpoch,
        qualityScore: result.faceMetrics.sharpnessScore,
        poseAngles: result.angles,
        faceMetrics: result.faceMetrics,
        extractedAt: now,
        boundingBox: result.boundingBox,
        poseType: result.poseType,
        confidenceScore: result.confidenceScore,
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
    _faceDetector.dispose();
    super.dispose();
  }
}

/// Pose capture provider
final poseCaptureProvider = StateNotifierProvider<PoseCaptureNotifier, PoseCaptureState>((ref) {
  // Create ML Kit face detector instance
  return PoseCaptureNotifier(MLKitFaceDetector());
});