import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';
import '../utils/constants.dart';

// Simple face detection service for MVP
class FaceDetectionService {
  static final FaceDetectionService _instance = FaceDetectionService._internal();
  factory FaceDetectionService() => _instance;
  FaceDetectionService._internal();

  late final FaceDetector _faceDetector;
  bool _isInitialized = false;

  /// Initialize the face detector
  Future<void> initialize() async {
    if (_isInitialized) return;

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: false, // MVP: Skip emotion detection
        enableLandmarks: false,      // MVP: Skip landmark detection
        enableContours: false,       // MVP: Skip contours
        enableTracking: true,        // Enable face tracking for consistency
        minFaceSize: 0.1,           // Minimum face size (10% of image)
        performanceMode: FaceDetectorMode.fast, // Fast mode for real-time
      ),
    );

    _isInitialized = true;
  }

  /// Detect faces in a camera image
  Future<List<Face>> detectFacesFromCameraImage(CameraImage cameraImage) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Convert CameraImage to InputImage
      final inputImage = _convertCameraImageToInputImage(cameraImage);
      if (inputImage == null) return [];

      // Detect faces
      final faces = await _faceDetector.processImage(inputImage);
      return faces;
    } catch (e) {
      print('Face detection error: $e');
      return [];
    }
  }

  /// Check if detected faces meet MVP quality criteria
  bool isQualityAcceptable(List<Face> faces) {
    if (faces.isEmpty) return false;

    for (final face in faces) {
      // MVP criteria: face confidence above threshold
      if (face.headEulerAngleX != null && 
          face.headEulerAngleY != null && 
          face.headEulerAngleZ != null) {
        
        // Simple quality check based on head angles (relaxed for MVP)
        final pitch = face.headEulerAngleX!.abs();
        final yaw = face.headEulerAngleY!.abs();
        final roll = face.headEulerAngleZ!.abs();
        
        // Accept faces with reasonable angles (relaxed thresholds for MVP)
        if (pitch < 30 && yaw < 45 && roll < 30) {
          return true;
        }
      } else {
        // If no angle data, accept if face is detected (very basic for MVP)
        return true;
      }
    }

    return false;
  }

  /// Get simple quality score (0.0 to 1.0)
  double getQualityScore(List<Face> faces) {
    if (faces.isEmpty) return 0.0;

    double totalScore = 0.0;
    int validFaces = 0;

    for (final face in faces) {
      // Basic quality score based on bounding box size and position
      final boundingBox = face.boundingBox;
      final area = boundingBox.width * boundingBox.height;
      
      // Normalize area score (assuming image size ~500x500 for MVP)
      final areaScore = (area / (500 * 500)).clamp(0.0, 1.0);
      
      // Check if face is reasonably centered
      final centerX = boundingBox.left + boundingBox.width / 2;
      final centerY = boundingBox.top + boundingBox.height / 2;
      
      // Simple centering score (assuming 500x500 image)
      final centeringScore = 1.0 - 
          ((centerX - 250).abs() / 250 + (centerY - 250).abs() / 250) / 2;
      
      // Combine scores
      final faceScore = (areaScore * 0.6 + centeringScore * 0.4).clamp(0.0, 1.0);
      
      if (faceScore >= AppConstants.minFaceConfidence) {
        totalScore += faceScore;
        validFaces++;
      }
    }

    return validFaces > 0 ? totalScore / validFaces : 0.0;
  }

  /// Convert CameraImage to InputImage
  InputImage? _convertCameraImageToInputImage(CameraImage cameraImage) {
    try {
      // Get image format
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in cameraImage.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(
        cameraImage.width.toDouble(),
        cameraImage.height.toDouble(),
      );

      // For MVP, assume NV21 format (common on Android)
      const InputImageFormat inputImageFormat = InputImageFormat.nv21;

      final inputImageData = InputImageMetadata(
        size: imageSize,
        rotation: InputImageRotation.rotation0deg,
        format: inputImageFormat,
        bytesPerRow: cameraImage.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageData,
      );
    } catch (e) {
      print('Error converting camera image: $e');
      return null;
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    if (_isInitialized) {
      await _faceDetector.close();
      _isInitialized = false;
    }
  }
}