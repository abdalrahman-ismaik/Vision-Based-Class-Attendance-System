import 'package:equatable/equatable.dart';
import 'package:hadir_mobile_full/shared/domain/entities/selected_frame.dart';
import 'package:hadir_mobile_full/core/computer_vision/pose_detection_result.dart';
import 'package:hadir_mobile_full/core/computer_vision/pose_type.dart';

/// Simple union-like class representing the pose capture provider state.
class PoseCaptureState extends Equatable {
  final PoseCaptureStatus status;
  final Object? data;

  const PoseCaptureState._(this.status, [this.data]);

  const PoseCaptureState.readyToCapture(PoseTarget pose) : this._(PoseCaptureStatus.readyToCapture, pose);
  const PoseCaptureState.detectingPose(PoseDetectionResult result) : this._(PoseCaptureStatus.detectingPose, result);
  const PoseCaptureState.processingCapture() : this._(PoseCaptureStatus.processingCapture);
  const PoseCaptureState.captureSuccess(SelectedFrame frame) : this._(PoseCaptureStatus.captureSuccess, frame);
  const PoseCaptureState.cameraError(Object error) : this._(PoseCaptureStatus.cameraError, error);
  const PoseCaptureState.detectionError(Object error) : this._(PoseCaptureStatus.detectionError, error);
  const PoseCaptureState.captureError(Object error) : this._(PoseCaptureStatus.captureError, error);
  const PoseCaptureState.allPosesCompleted(List<SelectedFrame> frames) : this._(PoseCaptureStatus.allPosesCompleted, frames);

  PoseTarget? get poseTarget => data is PoseTarget ? data as PoseTarget : null;
  PoseDetectionResult? get detectionResult => data is PoseDetectionResult ? data as PoseDetectionResult : null;
  SelectedFrame? get selectedFrame => data is SelectedFrame ? data as SelectedFrame : null;
  List<SelectedFrame>? get selectedFrames => data is List<SelectedFrame> ? data as List<SelectedFrame> : null;

  @override
  List<Object?> get props => [status, data];
}

enum PoseCaptureStatus {
  readyToCapture,
  detectingPose,
  processingCapture,
  captureSuccess,
  cameraError,
  detectionError,
  captureError,
  allPosesCompleted,
}
