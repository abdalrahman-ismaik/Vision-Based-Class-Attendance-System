// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:camera/camera.dart';
// import 'package:hadir_mobile_full/shared/domain/entities/selected_frame.dart';
// import 'package:hadir_mobile_full/core/computer_vision/pose_type.dart';
// import 'package:hadir_mobile_full/core/computer_vision/pose_angles.dart';
// import 'package:hadir_mobile_full/core/computer_vision/face_metrics.dart';
// import 'package:hadir_mobile_full/core/computer_vision/bounding_box.dart';

// /// Guided pose capture widget for ML Kit based face detection and pose estimation
// class GuidedPoseCapture extends ConsumerStatefulWidget {
//   const GuidedPoseCapture({
//     super.key,
//     required this.sessionId,
//     required this.onFrameCaptured,
//     required this.onComplete,
//     required this.onError,
//     this.embedded = false,
//   });

//   final String sessionId;
//   final Function(SelectedFrame frame) onFrameCaptured;
//   final Function() onComplete;
//   final Function(String error) onError;
//   final bool embedded;

//   @override
//   ConsumerState<GuidedPoseCapture> createState() => _GuidedPoseCaptureState();
// }

// class _GuidedPoseCaptureState extends ConsumerState<GuidedPoseCapture>
//     with TickerProviderStateMixin, WidgetsBindingObserver {
  
//   // Camera controller
//   CameraController? _cameraController;
  
//   // Face detection with balanced settings for accuracy and performance
//   final FaceDetector _faceDetector = FaceDetector(
//     options: FaceDetectorOptions(
//       enableContours: false,      // Disable contours to reduce processing
//       enableLandmarks: false,     // Disable landmarks for speed
//       enableClassification: true,  // Enable for eye openness detection
//       enableTracking: true,       // Enable tracking for better continuity
//       performanceMode: FaceDetectorMode.accurate, // Use accurate mode for better detection
//       minFaceSize: 0.15,          // Minimum face size (15% of image)
//     ),
//   );
  
//   // Current pose being captured
//   int _currentPoseIndex = 0;
//   final List<PoseType> _requiredPoses = [
//     PoseType.frontal,
//     PoseType.leftProfile,
//     PoseType.rightProfile,
//     PoseType.lookingUp,
//     PoseType.lookingDown,
//   ];
  
//   // Animation controllers
//   late AnimationController _pulseController;
//   late Animation<double> _pulseAnimation;
  
//   // State
//   bool _isCapturing = false;
//   bool _isCameraReady = false;
//   String? _currentInstruction;
//   List<Face> _detectedFaces = [];
//   bool _isPoseValid = false;
//   bool _isFrontCamera = true;
  
//   // Auto-capture state
//   DateTime? _poseValidStartTime;
//   DateTime? _lastValidPoseTime; // Track last time pose was valid (for grace period)
//   Timer? _autoCaptureTimer;
//   static const _holdDuration = Duration(seconds: 1); // REDUCED: 1 second with temporal smoothing
//   static const _gracePeriod = Duration(milliseconds: 500); // Grace period for brief detection losses
  
//   // Temporal smoothing - rolling window of validation results
//   final List<bool> _validationHistory = []; // Last N frames validation results
//   final List<int?> _trackingIdHistory = []; // Last N frames tracking IDs
//   static const _historyWindowSize = 5; // Look at last 5 frames
//   static const _minValidFrames = 3; // Need 3 out of 5 valid frames
  
//   // Performance optimization - balanced frame processing
//   int _frameCount = 0;
//   static const _processEveryNthFrame = 2; // Process every 2nd frame (better balance)
//   bool _isProcessingFrame = false;
//   DateTime? _lastProcessTime;
//   int? _sensorOrientation; // Cache sensor orientation
  
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _initializeAnimations();
//     _updateInstruction();
//     _initializeCamera();
//   }

//   void _initializeAnimations() {
//     _pulseController = AnimationController(
//       duration: const Duration(seconds: 1),
//       vsync: this,
//     );
    
//     _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
//       CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
//     );
    
//     _pulseController.repeat(reverse: true);
//   }

//   void _updateInstruction() {
//     if (_currentPoseIndex < _requiredPoses.length) {
//       setState(() {
//         _currentInstruction = _getPoseInstruction(_requiredPoses[_currentPoseIndex]);
//       });
//     }
//   }
  
//   String _getPoseInstruction(PoseType poseType) {
//     switch (poseType) {
//       case PoseType.frontal:
//         return 'Look straight at camera - keep head upright';
//       case PoseType.leftProfile:
//         return 'Turn left - keep head upright';
//       case PoseType.rightProfile:
//         return 'Turn right - keep head upright';
//       case PoseType.lookingUp:
//         return 'Tilt up slightly - keep head upright';
//       case PoseType.lookingDown:
//         return 'Tilt down slightly - keep head upright';
//     }
//   }

//   /// Initialize camera using official Flutter camera package guidelines
//   /// Reference: https://pub.dev/packages/camera
//   Future<void> _initializeCamera() async {
//     try {
//       // Get available cameras
//       final cameras = await availableCameras();
//       if (cameras.isEmpty) {
//         widget.onError('No cameras found');
//         return;
//       }
      
//       // Select front camera for face detection (or first available camera)
//       final camera = cameras.firstWhere(
//         (camera) => camera.lensDirection == CameraLensDirection.front,
//         orElse: () => cameras.first,
//       );
      
//       _isFrontCamera = camera.lensDirection == CameraLensDirection.front;
      
//       // Cache sensor orientation for image conversion
//       _sensorOrientation = camera.sensorOrientation;
      
//       // Initialize camera controller with high resolution for better face detection
//       // Following official camera package documentation
//       _cameraController = CameraController(
//         camera,
//         ResolutionPreset.high,
//         enableAudio: false,
//         imageFormatGroup: ImageFormatGroup.yuv420,
//       );
      
//       // Wait for camera to initialize before using
//       await _cameraController!.initialize();
      
//       // Debug: Log camera information
//       // Note: previewSize is in landscape orientation (width > height)
//       final cameraAspectRatio = _cameraController!.value.aspectRatio;
//       final previewSize = _cameraController!.value.previewSize;
//       debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
//       debugPrint('📷 CAMERA INITIALIZED');
//       debugPrint('   Aspect Ratio: $cameraAspectRatio');
//       debugPrint('   Preview Size: $previewSize');
//       debugPrint('   Sensor Orientation: $_sensorOrientation°');
//       debugPrint('   Front Camera: $_isFrontCamera');
//       debugPrint('   Embedded Mode: ${widget.embedded}');
//       debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
//       // Start image stream for real-time face detection
//       await _cameraController!.startImageStream(_processCameraImage);
      
//       if (mounted) {
//         setState(() {
//           _isCameraReady = true;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         widget.onError('Failed to initialize camera: $e');
//       }
//     }
//   }
  
//   /// Process camera image for face detection with balanced throttling
//   void _processCameraImage(CameraImage image) async {
//     // Skip if already processing or capturing
//     if (_isProcessingFrame || _isCapturing) {
//       if (_frameCount % 50 == 0) {
//         debugPrint('⏸️  Skipping frame: isProcessing=$_isProcessingFrame, isCapturing=$_isCapturing');
//       }
//       return;
//     }
    
//     // Time-based throttling: process at most once every 100ms (10 FPS - better responsiveness)
//     final now = DateTime.now();
//     if (_lastProcessTime != null && 
//         now.difference(_lastProcessTime!).inMilliseconds < 100) {
//       return;
//     }
    
//     // Skip frames for additional performance (every 2nd frame = 15-20 FPS effective)
//     _frameCount++;
//     if (_frameCount % _processEveryNthFrame != 0) {
//       return;
//     }
    
//     _isProcessingFrame = true;
//     _lastProcessTime = now;
    
//     final inputImage = _convertCameraImage(image);
//     if (inputImage == null) {
//       debugPrint('❌ Failed to convert camera image (Frame: $_frameCount)');
//       _isProcessingFrame = false;
//       return;
//     }
    
//     try {
//       final detectionStartTime = DateTime.now();
//       final faces = await _faceDetector.processImage(inputImage);
//       final detectionDuration = DateTime.now().difference(detectionStartTime);
      
//       // ALWAYS log detection results for debugging
//       if (faces.isEmpty) {
//         debugPrint('🔍 Frame $_frameCount: NO FACES DETECTED (took ${detectionDuration.inMilliseconds}ms)');
//       } else {
//         debugPrint('✅ Frame $_frameCount: ${faces.length} face(s) detected (took ${detectionDuration.inMilliseconds}ms)');
        
//         // Log detailed info for each face
//         for (int i = 0; i < faces.length; i++) {
//           final face = faces[i];
//           final yaw = face.headEulerAngleY?.toStringAsFixed(1) ?? 'N/A';
//           final pitch = face.headEulerAngleX?.toStringAsFixed(1) ?? 'N/A';
//           final roll = face.headEulerAngleZ?.toStringAsFixed(1) ?? 'N/A';
//           final box = face.boundingBox;
//           final faceSize = _calculateFaceSize(box);
          
//           debugPrint('   Face ${i + 1}:');
//           debugPrint('      Position: (${box.left.toInt()}, ${box.top.toInt()})');
//           debugPrint('      Size: ${box.width.toInt()}x${box.height.toInt()} = ${(faceSize * 100).toStringAsFixed(1)}% of frame');
          
//           // Flag tiny phantom faces
//           if (faceSize < 0.05) {
//             debugPrint('      ⚠️  PHANTOM FACE - too small (${(faceSize * 100).toStringAsFixed(1)}% < 5%) - will be filtered out');
//           }
          
//           debugPrint('      Angles: Yaw=$yaw°, Pitch=$pitch°, Roll=$roll°');
          
//           if (face.leftEyeOpenProbability != null && face.rightEyeOpenProbability != null) {
//             debugPrint('      Eyes: Left=${(face.leftEyeOpenProbability! * 100).toStringAsFixed(0)}%, Right=${(face.rightEyeOpenProbability! * 100).toStringAsFixed(0)}%');
//           }
          
//           if (face.trackingId != null) {
//             debugPrint('      Tracking ID: ${face.trackingId}');
//           }
//         }
//       }
      
//       // CRITICAL: Filter out phantom faces (ML Kit false positives)
//       // Real faces should be:
//       // 1. At least 5% of frame (typically 15-60%)
//       // 2. Fully on-screen (no negative positions)
//       // 3. At least 70% visible within frame boundaries
//       final validFaces = faces.where((face) {
//         final faceSize = _calculateFaceSize(face.boundingBox);
//         final box = face.boundingBox;
        
//         // Filter 1: Size check (minimum 5%)
//         if (faceSize < 0.05) {
//           debugPrint('      🚫 REJECTED: Face too small (${(faceSize * 100).toStringAsFixed(1)}%)');
//           return false;
//         }
        
//         // Filter 2: Position check - reject faces with ANY negative coordinates
//         // Negative positions = off-screen phantoms (reflections, shadows, edge artifacts)
//         if (box.top < 0 || box.left < 0) {
//           debugPrint('      🚫 REJECTED: Face off-screen (X=${box.left.toInt()}, Y=${box.top.toInt()})');
//           return false;
//         }
        
//         // Filter 3: Reject faces mostly off-screen (require 70% visible)
//         // Image size is 720x1280 (width x height after rotation)
//         final imageWidth = 720.0;
//         final imageHeight = 1280.0;
//         final visibleWidth = (box.right.clamp(0, imageWidth) - box.left.clamp(0, imageWidth)).abs();
//         final visibleHeight = (box.bottom.clamp(0, imageHeight) - box.top.clamp(0, imageHeight)).abs();
//         final visibleArea = visibleWidth * visibleHeight;
//         final totalArea = box.width * box.height;
//         final visiblePercentage = totalArea > 0 ? (visibleArea / totalArea) : 0;
        
//         if (visiblePercentage < 0.7) {
//           debugPrint('      🚫 REJECTED: Face mostly off-screen (${(visiblePercentage * 100).toStringAsFixed(0)}% visible)');
//           return false;
//         }
        
//         return true; // Face passes all filters
//       }).toList();
      
//       if (mounted) {
//         setState(() {
//           _detectedFaces = validFaces; // Use filtered faces
          
//           if (validFaces.isEmpty) {
//             // TEMPORAL SMOOTHING: Add "no face" to history
//             _validationHistory.add(false);
//             _trackingIdHistory.add(null);
            
//             // Keep only last N frames
//             if (_validationHistory.length > _historyWindowSize) {
//               _validationHistory.removeAt(0);
//               _trackingIdHistory.removeAt(0);
//             }
            
//             // Count valid frames in recent history
//             final validCount = _validationHistory.where((v) => v).length;
            
//             // Only reset if we have NO valid frames in recent history
//             if (validCount == 0) {
//               _currentInstruction = 'No face detected - position your face in the frame';
//               _isPoseValid = false;
//               _poseValidStartTime = null;
//               _autoCaptureTimer?.cancel();
//               debugPrint('   !  State: No face detected (0/${_validationHistory.length} recent frames valid)');
//             } else {
//               // Keep timer running - we have valid frames in recent history
//               debugPrint('   ⏸️  Temporal smoothing: No face this frame but $validCount/${_validationHistory.length} recent frames valid - keeping timer');
//             }
//           } else if (validFaces.length > 1) {
//             // TEMPORAL SMOOTHING: Multiple faces - add as invalid
//             _validationHistory.add(false);
//             _trackingIdHistory.add(null);
            
//             // Keep only last N frames
//             if (_validationHistory.length > _historyWindowSize) {
//               _validationHistory.removeAt(0);
//               _trackingIdHistory.removeAt(0);
//             }
            
//             // Count valid frames
//             final validCount = _validationHistory.where((v) => v).length;
            
//             // Only show error if consistently multiple faces
//             if (validCount < _minValidFrames) {
//               _currentInstruction = 'Multiple faces detected - ensure only one person is in frame';
//               _isPoseValid = false;
//               _poseValidStartTime = null;
//               _autoCaptureTimer?.cancel();
//               debugPrint('   !  State: Multiple faces (${validFaces.length}), only $validCount/${_validationHistory.length} recent frames valid');
//             } else {
//               debugPrint('   ⏸️  Multiple faces this frame but $validCount/${_validationHistory.length} recent frames valid - keeping timer');
//             }
//           } else {
//             // TEMPORAL SMOOTHING: Validate current frame
//             final currentFrameValid = _validateCurrentPose(validFaces);
//             final currentTrackingId = validFaces.first.trackingId;
            
//             // Add to history
//             _validationHistory.add(currentFrameValid);
//             _trackingIdHistory.add(currentTrackingId);
            
//             // Keep only last N frames
//             if (_validationHistory.length > _historyWindowSize) {
//               _validationHistory.removeAt(0);
//               _trackingIdHistory.removeAt(0);
//             }
            
//             // Check tracking continuity: if tracking ID changes dramatically, reset
//             final trackingIds = _trackingIdHistory.whereType<int>().toList();
//             if (trackingIds.length >= 2) {
//               final idVariance = trackingIds.map((id) => (id - trackingIds.first).abs()).reduce((a, b) => a > b ? a : b);
//               if (idVariance > 5) {
//                 debugPrint('   ⚠️  Tracking ID jumped (${trackingIds.first} → ${trackingIds.last}), resetting history');
//                 _validationHistory.clear();
//                 _trackingIdHistory.clear();
//                 _poseValidStartTime = null;
//                 _isPoseValid = false;
//                 _updateInstruction();
//                 return;
//               }
//             }
            
//             // Count valid frames in history
//             final validCount = _validationHistory.where((v) => v).length;
//             final wasValid = _isPoseValid;
//             _isPoseValid = validCount >= _minValidFrames; // 3 out of 5 frames valid
            
//             if (_isPoseValid) {
//               final holdTime = _poseValidStartTime != null 
//                   ? DateTime.now().difference(_poseValidStartTime!).inMilliseconds 
//                   : 0;
//               debugPrint('   ✅ State: Valid pose! ($validCount/${_validationHistory.length} frames) Holding: ${holdTime}ms/${_holdDuration.inMilliseconds}ms');
//             } else {
//               if (wasValid) {
//                 debugPrint('   ⚠️  State: Lost stability (only $validCount/${_validationHistory.length} valid frames)');
//               }
//               // Don't update instruction immediately - give time for smoothing
//               if (validCount == 0) {
//                 _updateInstruction();
//               }
//             }
//           }
//         });
//       }
//     } catch (e, stackTrace) {
//       // Log error with details
//       debugPrint('❌ Face detection error on Frame $_frameCount: $e');
//       debugPrint('   Stack trace: $stackTrace');
//     } finally {
//       _isProcessingFrame = false;
//     }
//   }
  
//   /// Convert CameraImage to InputImage with CORRECT rotation handling
//   /// This is critical for face detection to work properly!
//   InputImage? _convertCameraImage(CameraImage cameraImage) {
//     try {
//       if (_cameraController == null || _sensorOrientation == null) return null;
      
//       // Get image format
//       InputImageFormat? format;
//       switch (cameraImage.format.group) {
//         case ImageFormatGroup.yuv420:
//           format = InputImageFormat.yuv420;
//           break;
//         case ImageFormatGroup.bgra8888:
//           format = InputImageFormat.bgra8888;
//           break;
//         case ImageFormatGroup.nv21:
//           format = InputImageFormat.nv21;
//           break;
//         default:
//           debugPrint('❌ Unsupported image format: ${cameraImage.format.group}');
//           return null;
//       }

//       // CRITICAL: Calculate CORRECT rotation for ML Kit
//       // ML Kit needs to know how to rotate the image to make it upright
//       //
//       // Sensor orientation values:
//       // - Front camera: typically 270° (facing user)
//       // - Back camera: typically 90° (facing away)
//       //
//       // For portrait mode (device held upright):
//       // - Image from camera is in landscape
//       // - We need to tell ML Kit how many degrees to rotate to make it portrait
//       //
//       // Front camera (270° sensor):
//       //   Camera image is rotated 270° clockwise from natural orientation
//       //   To make upright: need 90° rotation (270 + 90 = 360 = 0°)
//       //
//       // Back camera (90° sensor):
//       //   Camera image is rotated 90° clockwise from natural orientation
//       //   To make upright: need 270° rotation (90 + 270 = 360 = 0°)
      
//       InputImageRotation rotation;
      
//       if (_isFrontCamera) {
//         // Front camera: sensor orientation 270° → needs 90° rotation to be upright
//         switch (_sensorOrientation!) {
//           case 0:
//             rotation = InputImageRotation.rotation0deg;
//             break;
//           case 90:
//             rotation = InputImageRotation.rotation90deg;
//             break;
//           case 180:
//             rotation = InputImageRotation.rotation180deg;
//             break;
//           case 270:
//             rotation = InputImageRotation.rotation90deg; // ✅ CORRECT: 270° sensor needs 90° rotation
//             break;
//           default:
//             rotation = InputImageRotation.rotation0deg;
//         }
//       } else {
//         // Back camera: sensor orientation 90° → needs 270° rotation to be upright
//         switch (_sensorOrientation!) {
//           case 0:
//             rotation = InputImageRotation.rotation0deg;
//             break;
//           case 90:
//             rotation = InputImageRotation.rotation270deg; // ✅ CORRECT: 90° sensor needs 270° rotation
//             break;
//           case 180:
//             rotation = InputImageRotation.rotation180deg;
//             break;
//           case 270:
//             rotation = InputImageRotation.rotation270deg;
//             break;
//           default:
//             rotation = InputImageRotation.rotation0deg;
//         }
//       }

//       // Concatenate plane bytes
//       final WriteBuffer allBytes = WriteBuffer();
//       for (final Plane plane in cameraImage.planes) {
//         allBytes.putUint8List(plane.bytes);
//       }
//       final bytes = allBytes.done().buffer.asUint8List();

//       // Special handling for NV21 format (most common on Android)
//       int bytesPerRow = cameraImage.planes[0].bytesPerRow;
      
//       if (format == InputImageFormat.nv21) {
//         // NV21 format has padding, need to use actual width for bytesPerRow
//         bytesPerRow = cameraImage.width;
//       }

//       final inputImage = InputImage.fromBytes(
//         bytes: bytes,
//         metadata: InputImageMetadata(
//           size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
//           rotation: rotation,
//           format: format,
//           bytesPerRow: bytesPerRow,
//         ),
//       );
      
//       // Log image details on first conversion and periodically
//       if (_frameCount == _processEveryNthFrame || _frameCount % 30 == 0) {
//         debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
//         debugPrint('📸 IMAGE CONVERSION (Frame: $_frameCount)');
//         debugPrint('   Size: ${cameraImage.width}x${cameraImage.height}');
//         debugPrint('   Format: $format (${cameraImage.format.group})');
//         debugPrint('   Sensor Orientation: $_sensorOrientation°');
//         debugPrint('   Required Rotation: $rotation');
//         debugPrint('   BytesPerRow: $bytesPerRow (original: ${cameraImage.planes[0].bytesPerRow})');
//         debugPrint('   Front Camera: $_isFrontCamera');
//         debugPrint('   Total Bytes: ${bytes.length}');
//         debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
//       }
      
//       return inputImage;
      
//     } catch (e) {
//       debugPrint('❌ Error converting camera image: $e');
//       return null;
//     }
//   }
  
//   /// Validate if current pose matches required pose with auto-capture
//   bool _validateCurrentPose(List<Face> faces) {
//     if (faces.isEmpty) {
//       debugPrint('   🔍 Validation: No faces to validate');
//       _poseValidStartTime = null;
//       _autoCaptureTimer?.cancel();
//       return false;
//     }
    
//     final face = faces.first;
//     final currentPose = _requiredPoses[_currentPoseIndex];
    
//     final rawEulerY = face.headEulerAngleY ?? 0;
//     final rawEulerX = face.headEulerAngleX ?? 0;
//     final rawEulerZ = face.headEulerAngleZ ?? 0; // Roll angle
//     final eulerY = _isFrontCamera ? -rawEulerY : rawEulerY;
//     final eulerX = rawEulerX;
//     final eulerZ = rawEulerZ; // Roll doesn't need camera adjustment
    
//     debugPrint('   🎯 Validating for pose: $currentPose');
//     debugPrint('      Raw angles: Yaw=$rawEulerY°, Pitch=$rawEulerX°, Roll=$rawEulerZ°');
//     debugPrint('      Adjusted angles: Yaw=$eulerY°, Pitch=$eulerX°, Roll=$eulerZ°');
    
//     // Validate pose with relaxed criteria for better user experience
//     bool isValid = false;
//     String failReason = '';
    
//     // CRITICAL: Check Roll angle first (head tilt)
//     // Relaxed to 35° to accommodate natural head position variations
//     if (eulerZ.abs() > 35) {
//       debugPrint('      ❌ INVALID: Head tilted too much (Roll=${eulerZ.toStringAsFixed(1)}°, need ≤35°)');
//       return false; // Early return - no need to check other angles
//     }
    
//     switch (currentPose) {
//       case PoseType.frontal:
//         // Relaxed from ±15° → ±20° → ±30° for natural phone-holding positions
//         // Yaw: ±20° (left/right head turn)
//         // Pitch: ±30° (up/down head tilt - more lenient for natural viewing angle)
//         isValid = eulerY.abs() < 20 && eulerX.abs() < 30;
//         if (!isValid) failReason = 'Angles outside range (Yaw ±20°, Pitch ±30°)';
//         debugPrint('      Frontal check: ${eulerY.abs() < 20} && ${eulerX.abs() < 30} = $isValid');
//         break;
//       case PoseType.leftProfile:
//         isValid = eulerY > 25 && eulerY < 50;
//         if (!isValid) failReason = 'Yaw not in range (25-50°)';
//         debugPrint('      Left profile check: $eulerY > 25 && $eulerY < 50 = $isValid');
//         break;
//       case PoseType.rightProfile:
//         isValid = eulerY < -25 && eulerY > -50;
//         if (!isValid) failReason = 'Yaw not in range (-50 to -25°)';
//         debugPrint('      Right profile check: $eulerY < -25 && $eulerY > -50 = $isValid');
//         break;
//       case PoseType.lookingUp:
//         isValid = eulerX < -10 && eulerX > -35;
//         if (!isValid) failReason = 'Pitch not in range (-35 to -10°)';
//         debugPrint('      Looking up check: $eulerX < -10 && $eulerX > -35 = $isValid');
//         break;
//       case PoseType.lookingDown:
//         isValid = eulerX > 10 && eulerX < 35;
//         if (!isValid) failReason = 'Pitch not in range (10-35°)';
//         debugPrint('      Looking down check: $eulerX > 10 && $eulerX < 35 = $isValid');
//         break;
//     }
    
//     // Additional quality checks
//     if (isValid) {
//       // Check face size (should be at least 15% of frame)
//       final faceSize = _calculateFaceSize(face.boundingBox);
//       debugPrint('      Face size: ${(faceSize * 100).toStringAsFixed(1)}% (need ≥15%)');
      
//       if (faceSize < 0.15) {
//         isValid = false;
//         failReason = 'Face too small (${(faceSize * 100).toStringAsFixed(1)}% < 15%)';
//       }
      
//       // Check eye openness (relaxed from 30% → 20% → 15% for natural expressions)
//       // Allow one eye to be partially closed (common when smiling or in bright light)
//       final leftEyeOpen = face.leftEyeOpenProbability ?? 0;
//       final rightEyeOpen = face.rightEyeOpenProbability ?? 0;
//       debugPrint('      Eye openness: Left=${(leftEyeOpen * 100).toStringAsFixed(0)}%, Right=${(rightEyeOpen * 100).toStringAsFixed(0)}%');
      
//       // Only check eye openness for frontal pose, be very lenient
//       // Require at least one eye open ≥15% (very permissive for natural expressions)
//       if (currentPose == PoseType.frontal && (leftEyeOpen < 0.15 && rightEyeOpen < 0.15)) {
//         isValid = false;
//         failReason = 'Eyes not open enough (need at least one eye ≥15%)';
//       }
//     }
    
//     if (isValid) {
//       debugPrint('      ✅ VALID POSE!');
//       _lastValidPoseTime = DateTime.now(); // Update last valid time
//     } else {
//       debugPrint('      ❌ INVALID: $failReason');
//     }
    
//     // Handle auto-capture with grace period for brief detection losses
//     if (isValid) {
//       _poseValidStartTime ??= DateTime.now();
      
//       final holdTime = DateTime.now().difference(_poseValidStartTime!);
//       debugPrint('      ⏱️  Holding: ${holdTime.inMilliseconds}ms / ${_holdDuration.inMilliseconds}ms');
      
//       if (holdTime >= _holdDuration && !_isCapturing) {
//         debugPrint('      📸 TRIGGERING AUTO-CAPTURE!');
//         _autoCaptureTimer?.cancel();
//         _autoCaptureTimer = Timer(const Duration(milliseconds: 100), () {
//           _captureFrame();
//         });
//       }
//     } else {
//       // Grace period: Don't reset timer if we had a valid pose very recently
//       // This prevents timer resets from brief detection losses (e.g., blinking, momentary focus loss)
//       final timeSinceLastValid = _lastValidPoseTime != null 
//         ? DateTime.now().difference(_lastValidPoseTime!) 
//         : Duration.zero;
      
//       if (_poseValidStartTime != null) {
//         if (timeSinceLastValid > _gracePeriod) {
//           debugPrint('      ⚠️  Lost valid pose (grace period expired), resetting timer');
//           _poseValidStartTime = null;
//           _autoCaptureTimer?.cancel();
//         } else {
//           debugPrint('      ⏸️  Invalid pose but within grace period (${timeSinceLastValid.inMilliseconds}ms/${_gracePeriod.inMilliseconds}ms) - keeping timer');
//         }
//       }
//     }
    
//     return isValid;
//   }

//   /// Calculate quality score for captured frame
//   double _calculateQualityScore(Face face) {
//     double score = 0.0;
    
//     // Face size (30% weight)
//     final faceSize = _calculateFaceSize(face.boundingBox);
//     if (faceSize > 0.2) {
//       score += 0.3;
//     } else if (faceSize > 0.15) {
//       score += 0.2;
//     }
    
//     // Head angles (30% weight)
//     final eulerY = (face.headEulerAngleY ?? 0).abs();
//     final eulerX = (face.headEulerAngleX ?? 0).abs();
//     final currentPose = _requiredPoses[_currentPoseIndex];
    
//     bool angleMatch = false;
//     switch (currentPose) {
//       case PoseType.frontal:
//         angleMatch = eulerY < 15 && eulerX < 15;
//         break;
//       case PoseType.leftProfile:
//         angleMatch = eulerY > 25;
//         break;
//       case PoseType.rightProfile:
//         angleMatch = eulerY > 25;
//         break;
//       case PoseType.lookingUp:
//         angleMatch = eulerX > 10;
//         break;
//       case PoseType.lookingDown:
//         angleMatch = eulerX > 10;
//         break;
//     }
//     if (angleMatch) score += 0.3;
    
//     // Eye openness (40% weight)
//     final leftEyeOpen = face.leftEyeOpenProbability ?? 0;
//     final rightEyeOpen = face.rightEyeOpenProbability ?? 0;
//     if (leftEyeOpen > 0.5 && rightEyeOpen > 0.5) {
//       score += 0.4;
//     } else if (leftEyeOpen > 0.3 && rightEyeOpen > 0.3) {
//       score += 0.2;
//     }
    
//     return score;
//   }

//   /// Calculate face size ratio
//   double _calculateFaceSize(Rect boundingBox) {
//     final cameraSize = _cameraController?.value.previewSize;
//     if (cameraSize == null) return 0.0;
    
//     final faceArea = boundingBox.width * boundingBox.height;
//     final frameArea = cameraSize.width * cameraSize.height;
    
//     return faceArea / frameArea;
//   }

//   /// Capture current frame with actual image data
//   Future<void> _captureFrame() async {
//     if (_isCapturing || !_isCameraReady || _cameraController == null) return;
    
//     setState(() {
//       _isCapturing = true;
//     });

//     try {
//       // Stop image stream during capture
//       await _cameraController!.stopImageStream();
      
//       // Small delay to ensure stream is stopped
//       await Future.delayed(const Duration(milliseconds: 100));
      
//       // Capture the image
//       final XFile imageFile = await _cameraController!.takePicture();
      
//       // Get the latest detected face data
//       if (_detectedFaces.isEmpty) {
//         throw Exception('No face detected during capture');
//       }
      
//       final face = _detectedFaces.first;
//       final now = DateTime.now();
      
//       // Create frame with real data
//       final capturedFrame = SelectedFrame(
//         id: 'frame_${now.millisecondsSinceEpoch}',
//         sessionId: widget.sessionId,
//         imageFilePath: imageFile.path,
//         timestampMs: now.millisecondsSinceEpoch,
//         qualityScore: _calculateQualityScore(face),
//         poseAngles: PoseAngles(
//           yaw: _isFrontCamera ? -(face.headEulerAngleY ?? 0) : (face.headEulerAngleY ?? 0),
//           pitch: face.headEulerAngleX ?? 0,
//           roll: face.headEulerAngleZ ?? 0,
//           confidence: 0.95,
//         ),
//         faceMetrics: FaceMetrics(
//           boundingBox: BoundingBox(
//             x: face.boundingBox.left,
//             y: face.boundingBox.top,
//             width: face.boundingBox.width,
//             height: face.boundingBox.height,
//           ),
//           faceSize: _calculateFaceSize(face.boundingBox),
//           sharpnessScore: 0.9,
//           lightingScore: 0.8,
//           symmetryScore: 0.95,
//           hasGlasses: false,
//           hasHat: false,
//           isSmiling: (face.smilingProbability ?? 0) > 0.5,
//         ),
//         extractedAt: now,
//         poseType: _requiredPoses[_currentPoseIndex],
//         confidenceScore: 0.95,
//       );

//       // Notify parent of successful capture
//       widget.onFrameCaptured(capturedFrame);
      
//       // Move to next pose
//       _currentPoseIndex++;
      
//       if (_currentPoseIndex >= _requiredPoses.length) {
//         // All poses captured - don't restart stream
//         widget.onComplete();
//       } else {
//         // Update instruction for next pose
//         _updateInstruction();
//         _showCaptureSuccess();
        
//         // Resume image stream for next pose
//         await _cameraController!.startImageStream(_processCameraImage);
//       }
      
//     } catch (e) {
//       widget.onError('Failed to capture frame: ${e.toString()}');
      
//       // Try to resume stream on error
//       try {
//         await _cameraController?.startImageStream(_processCameraImage);
//       } catch (resumeError) {
//         debugPrint('Failed to resume stream: $resumeError');
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isCapturing = false;
//           _poseValidStartTime = null;
//           _autoCaptureTimer?.cancel();
//         });
//       }
//     }
//   }

//   void _showCaptureSuccess() {
//     if (!mounted) return;
    
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.check_circle, color: Colors.white),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Text(
//                 'Captured ${_getPoseDisplayName(_requiredPoses[_currentPoseIndex - 1])} successfully!',
//               ),
//             ),
//           ],
//         ),
//         backgroundColor: Colors.green,
//         duration: const Duration(seconds: 2),
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   Widget _buildEmbeddedView() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.black,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(12),
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             return Stack(
//               children: [
//                 // Camera preview with proper aspect ratio handling
//                 // Centered and scaled to fit the container
//                 if (_isCameraReady)
//                   Center(
//                     child: Container(
//                       constraints: BoxConstraints(
//                         maxWidth: constraints.maxWidth,
//                         maxHeight: constraints.maxHeight,
//                       ),
//                       child: _buildCameraPreview(),
//                     ),
//                   )
//                 else
//                   _buildCameraLoadingView(),
              
//                 // ML Kit face detection overlay
//                 if (_isCameraReady) _buildFaceOverlay(),
                
//                 // Top status bar with progress and current pose
//                 Positioned(
//                   top: 16,
//                   left: 16,
//                   right: 16,
//                   child: _buildStatusBar(),
//                 ),
                
//                 // Pose validation indicator (center)
//                 if (_isCameraReady)
//                   Positioned(
//                     top: 0,
//                     left: 0,
//                     right: 0,
//                     bottom: 80,
//                     child: Center(
//                       child: _buildPoseValidationIndicator(),
//                     ),
//                   ),
                
//                 // Bottom instruction panel
//                 Positioned(
//                   bottom: 16,
//                   left: 16,
//                   right: 16,
//                   child: _buildInstructionPanel(),
//                 ),
                
//                 // Manual capture button (show even when auto-capturing)
//                 if (_isCameraReady && !_isCapturing)
//                   Positioned(
//                     bottom: 100,
//                     left: 0,
//                     right: 0,
//                     child: Center(
//                       child: _buildCaptureButton(),
//                     ),
//                   ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildCameraLoadingView() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const CircularProgressIndicator(color: Colors.green),
//           const SizedBox(height: 16),
//           Text(
//             'Initializing Camera...',
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.8),
//               fontSize: 16,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Please wait while we set up pose detection',
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.6),
//               fontSize: 12,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusBar() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.black.withOpacity(0.8),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           // Progress indicator
//           Row(
//             children: [
//               const Icon(
//                 Icons.face,
//                 color: Colors.green,
//                 size: 20,
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 '${_currentPoseIndex + 1}/${_requiredPoses.length}',
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
          
//           // Current pose type
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//             decoration: BoxDecoration(
//               color: _isPoseValid ? Colors.green : Colors.orange,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Text(
//               _getPoseDisplayName(_requiredPoses[_currentPoseIndex]),
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPoseValidationIndicator() {
//     double progress = 0.0;
//     if (_poseValidStartTime != null && _isPoseValid) {
//       final elapsed = DateTime.now().difference(_poseValidStartTime!);
//       progress = (elapsed.inMilliseconds / _holdDuration.inMilliseconds).clamp(0.0, 1.0);
//     }
    
//     return Stack(
//       alignment: Alignment.center,
//       children: [
//         // Progress ring
//         if (_isPoseValid && progress > 0)
//           SizedBox(
//             width: 90,
//             height: 90,
//             child: CircularProgressIndicator(
//               value: progress,
//               strokeWidth: 6,
//               backgroundColor: Colors.green.withOpacity(0.2),
//               valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
//             ),
//           ),
        
//         // Center indicator
//         AnimatedContainer(
//           duration: const Duration(milliseconds: 300),
//           width: 80,
//           height: 80,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: _isPoseValid 
//               ? Colors.green.withOpacity(0.2)
//               : Colors.orange.withOpacity(0.2),
//             border: Border.all(
//               color: _isPoseValid ? Colors.green : Colors.orange,
//               width: 3,
//             ),
//           ),
//           child: Icon(
//             _isPoseValid ? Icons.check : Icons.face,
//             color: _isPoseValid ? Colors.green : Colors.orange,
//             size: 40,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildInstructionPanel() {
//     String countdownText = '';
//     if (_poseValidStartTime != null && _isPoseValid && !_isCapturing) {
//       final remaining = _holdDuration - DateTime.now().difference(_poseValidStartTime!);
//       if (remaining.inSeconds >= 0) {
//         countdownText = ' (${remaining.inSeconds + 1}s)';
//       }
//     }
    
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.black.withOpacity(0.8),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: _isPoseValid ? Colors.green : Colors.orange,
//           width: 2,
//         ),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 _isCapturing 
//                   ? Icons.camera 
//                   : _isPoseValid 
//                     ? Icons.check_circle 
//                     : Icons.warning,
//                 color: _isCapturing 
//                   ? Colors.blue 
//                   : _isPoseValid 
//                     ? Colors.green 
//                     : Colors.orange,
//                 size: 24,
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   _isCapturing 
//                     ? 'Capturing...'
//                     : (_currentInstruction ?? 'Preparing camera...') + countdownText,
//                   style: TextStyle(
//                     color: _isPoseValid ? Colors.green : Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           if (!_isPoseValid && !_isCapturing) ...[
//             const SizedBox(height: 8),
//             Text(
//               _getDetailedInstruction(_requiredPoses[_currentPoseIndex]),
//               style: TextStyle(
//                 color: Colors.white.withOpacity(0.8),
//                 fontSize: 14,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildCaptureButton() {
//     return AnimatedBuilder(
//       animation: _pulseAnimation,
//       builder: (context, child) {
//         return Transform.scale(
//           scale: _isPoseValid ? _pulseAnimation.value : 1.0,
//           child: Container(
//             width: 60,
//             height: 60,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: _isPoseValid ? Colors.green : Colors.grey,
//               boxShadow: _isPoseValid ? [
//                 BoxShadow(
//                   color: Colors.green.withOpacity(0.4),
//                   blurRadius: 15,
//                   spreadRadius: 5,
//                 ),
//               ] : null,
//             ),
//             child: Material(
//               color: Colors.transparent,
//               child: InkWell(
//                 borderRadius: BorderRadius.circular(30),
//                 onTap: _isPoseValid ? _captureFrame : null,
//                 child: Icon(
//                   Icons.camera,
//                   color: _isPoseValid ? Colors.white : Colors.grey[400],
//                   size: 28,
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   String _getPoseDisplayName(PoseType poseType) {
//     switch (poseType) {
//       case PoseType.frontal:
//         return 'Front Face';
//       case PoseType.leftProfile:
//         return 'Left Profile';
//       case PoseType.rightProfile:
//         return 'Right Profile';
//       case PoseType.lookingUp:
//         return 'Looking Up';
//       case PoseType.lookingDown:
//         return 'Looking Down';
//     }
//   }

//   String _getDetailedInstruction(PoseType poseType) {
//     switch (poseType) {
//       case PoseType.frontal:
//         return 'Keep your head straight and upright. Look directly at the camera. Don\'t tilt your head to either side.';
//       case PoseType.leftProfile:
//         return 'Turn your head to the left (your left) until you show your profile. Keep your head upright - don\'t tilt.';
//       case PoseType.rightProfile:
//         return 'Turn your head to the right (your right) until you show your profile. Keep your head upright - don\'t tilt.';
//       case PoseType.lookingUp:
//         return 'Tilt your head slightly upward while keeping your face visible. Keep your head upright (no side tilt).';
//       case PoseType.lookingDown:
//         return 'Tilt your head slightly downward while keeping your eyes visible. Keep your head upright (no side tilt).';
//     }
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
//     if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
//       // Stop processing when app goes to background
//       _autoCaptureTimer?.cancel();
//       _isProcessingFrame = false;
//     } else if (state == AppLifecycleState.resumed && _cameraController != null) {
//       // Resume processing when app comes back to foreground
//       if (_cameraController!.value.isInitialized && !_cameraController!.value.isStreamingImages) {
//         _cameraController!.startImageStream(_processCameraImage);
//       }
//     }
//   }

//   @override
//   void dispose() {
//     // Remove observer first
//     WidgetsBinding.instance.removeObserver(this);
    
//     // Cancel timers first
//     _autoCaptureTimer?.cancel();
    
//     // Dispose animations
//     _pulseController.dispose();
    
//     // Stop camera processing safely (fire and forget - can't await in dispose)
//     _cameraController?.stopImageStream().catchError((e) {
//       debugPrint('Error stopping image stream: $e');
//     });
    
//     _cameraController?.dispose().catchError((e) {
//       debugPrint('Error disposing camera: $e');
//     });
    
//     // Close face detector (fire and forget - can't await in dispose)
//     _faceDetector.close().catchError((e) {
//       debugPrint('Error closing face detector: $e');
//     });
    
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (widget.embedded) {
//       return _buildEmbeddedView();
//     }
    
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.close, color: Colors.white),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         title: Text(
//           'Pose Capture ${_currentPoseIndex + 1}/${_requiredPoses.length}',
//           style: const TextStyle(color: Colors.white),
//         ),
//       ),
//       body: Column(
//         children: [
//           // Progress indicator
//           LinearProgressIndicator(
//             value: _currentPoseIndex / _requiredPoses.length,
//             backgroundColor: Colors.grey[800],
//             valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
//           ),
          
//           // Camera preview area
//           Expanded(
//             flex: 3,
//             child: Container(
//               width: double.infinity,
//               margin: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.grey[900],
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(
//                   color: _isCapturing ? Colors.blue : _isPoseValid ? Colors.green : Colors.grey[700]!,
//                   width: 3,
//                 ),
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(16),
//                 child: Stack(
//                   children: [
//                     Center(
//                       child: _isCameraReady
//                           ? _buildCameraPreview()
//                           : const CircularProgressIndicator(),
//                     ),
                    
//                     if (_isCameraReady) _buildFaceOverlay(),
//                     if (_isCameraReady) _buildPoseGuide(),
//                   ],
//                 ),
//               ),
//             ),
//           ),
          
//           // Instructions
//           Expanded(
//             flex: 1,
//             child: Container(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   Text(
//                     _isCapturing 
//                       ? 'Capturing...'
//                       : _currentInstruction ?? 'Preparing camera...',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 16),
                  
//                   if (_currentPoseIndex < _requiredPoses.length)
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 8,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.blue[900],
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Text(
//                         _getPoseDisplayName(_requiredPoses[_currentPoseIndex]),
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
                  
//                   const Spacer(),
                  
//                   // Capture button
//                   AnimatedBuilder(
//                     animation: _pulseAnimation,
//                     builder: (context, child) {
//                       return Transform.scale(
//                         scale: _isCapturing ? 1.0 : _pulseAnimation.value,
//                         child: FloatingActionButton.large(
//                           onPressed: _isCameraReady && !_isCapturing && _isPoseValid
//                               ? _captureFrame
//                               : null,
//                           backgroundColor: _isCapturing
//                               ? Colors.red
//                               : _isPoseValid 
//                                   ? Colors.green
//                                   : Colors.grey,
//                           child: Icon(
//                             _isCapturing ? Icons.stop : Icons.camera_alt,
//                             color: _isCapturing 
//                                 ? Colors.white 
//                                 : _isPoseValid
//                                     ? Colors.white
//                                     : Colors.grey[300],
//                             size: 32,
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Build camera preview with correct aspect ratio
//   /// Following official Flutter camera package guidelines
//   /// Reference: https://pub.dev/packages/camera
//   Widget _buildCameraPreview() {
//     if (_cameraController == null || !_cameraController!.value.isInitialized) {
//       return Container(
//         width: double.infinity,
//         height: double.infinity,
//         color: Colors.black,
//         child: const Center(
//           child: CircularProgressIndicator(),
//         ),
//       );
//     }

//     final camera = _cameraController!;
    
//     // Get the camera preview size and aspect ratio
//     // Important: previewSize is always in landscape orientation (width > height)
//     // For example: Size(1920, 1080) even when phone is in portrait
//     final size = camera.value.previewSize!;
    
//     // Calculate the correct aspect ratio for portrait display
//     // Since camera preview is landscape but we display in portrait,
//     // we need to swap width and height to get the correct ratio
//     // Example: 1920x1080 landscape -> 1080/1920 = 0.5625 for portrait
//     final aspectRatio = size.height / size.width;
    
//     // Wrap CameraPreview in AspectRatio widget to maintain correct proportions
//     // This prevents stretching or distortion of the camera feed
//     return Center(
//       child: AspectRatio(
//         aspectRatio: aspectRatio,
//         child: CameraPreview(camera),
//       ),
//     );
//   }

//   Widget _buildFaceOverlay() {
//     if (_detectedFaces.isEmpty || _cameraController == null) {
//       return const SizedBox.shrink();
//     }

//     return LayoutBuilder(
//       builder: (context, constraints) {
//         return CustomPaint(
//           size: Size(constraints.maxWidth, constraints.maxHeight),
//           painter: MLKitFaceOverlayPainter(
//             faces: _detectedFaces,
//             imageSize: _cameraController!.value.previewSize!,
//             isFrontCamera: _isFrontCamera,
//             isPoseValid: _isPoseValid,
//             currentPose: _requiredPoses[_currentPoseIndex],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildPoseGuide() {
//     return Positioned(
//       top: 16,
//       right: 16,
//       child: Container(
//         padding: const EdgeInsets.all(8),
//         decoration: BoxDecoration(
//           color: Colors.black.withOpacity(0.7),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               _isPoseValid ? Icons.check_circle : Icons.face,
//               color: _isPoseValid ? Colors.green : Colors.orange,
//               size: 24,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               _isPoseValid ? 'Valid' : 'Position',
//               style: TextStyle(
//                 color: _isPoseValid ? Colors.green : Colors.orange,
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// Custom painter for ML Kit face detection overlay
// class MLKitFaceOverlayPainter extends CustomPainter {
//   final List<Face> faces;
//   final Size imageSize;
//   final bool isFrontCamera;
//   final bool isPoseValid;
//   final PoseType currentPose;

//   MLKitFaceOverlayPainter({
//     required this.faces,
//     required this.imageSize,
//     required this.isFrontCamera,
//     required this.isPoseValid,
//     required this.currentPose,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     if (faces.isEmpty) return;

//     final paint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 3.0;

//     // Camera preview size is in landscape (width > height)
//     // But display is in portrait, so we need to swap width/height
//     // and adjust the scaling accordingly
//     final double imageWidth = imageSize.height;
//     final double imageHeight = imageSize.width;
    
//     // Scale factors to convert from image coordinates to canvas coordinates
//     final scaleX = size.width / imageWidth;
//     final scaleY = size.height / imageHeight;

//     for (final face in faces) {
//       final boundingBox = face.boundingBox;
      
//       // Convert bounding box to canvas coordinates
//       // Swap X and Y because camera is landscape but display is portrait
//       double left = boundingBox.top * scaleX;
//       double top = boundingBox.left * scaleY;
//       double right = boundingBox.bottom * scaleX;
//       double bottom = boundingBox.right * scaleY;
      
//       // Mirror coordinates for front camera
//       if (isFrontCamera) {
//         final temp = left;
//         left = size.width - right;
//         right = size.width - temp;
//       }

//       // Draw face bounding box
//       paint.color = isPoseValid ? Colors.green : Colors.orange;
//       final rect = Rect.fromLTRB(left, top, right, bottom);
//       canvas.drawRect(rect, paint);

//       // Draw face landmarks if available
//       _drawFaceLandmarks(canvas, face, scaleX, scaleY, size, paint);
      
//       // Draw pose angles indicator
//       _drawPoseAngles(canvas, face, rect, paint);
//     }
//   }

//   void _drawFaceLandmarks(Canvas canvas, Face face, double scaleX, double scaleY, Size size, Paint paint) {
//     // Skip landmark drawing since we disabled landmarks in detector options
//     // This prevents the "Unknown landmark type" warnings
//     // We'll focus on bounding box and pose angles instead
//     return;
//   }

//   void _drawPoseAngles(Canvas canvas, Face face, Rect boundingBox, Paint paint) {
//     final centerX = boundingBox.center.dx;
//     final centerY = boundingBox.center.dy;
    
//     // Get pose angles
//     final yaw = isFrontCamera ? -(face.headEulerAngleY ?? 0) : (face.headEulerAngleY ?? 0);
//     final pitch = face.headEulerAngleX ?? 0;
//     final roll = face.headEulerAngleZ ?? 0;

//     // Draw angle indicators
//     paint.style = PaintingStyle.stroke;
//     paint.strokeWidth = 2.0;
//     paint.color = isPoseValid ? Colors.green : Colors.orange;

//     // Draw angle text
//     final textPainter = TextPainter(
//       textDirection: TextDirection.ltr,
//     );

//     textPainter.text = TextSpan(
//       text: 'Y: ${yaw.toStringAsFixed(1)}°',
//       style: TextStyle(
//         color: isPoseValid ? Colors.green : Colors.orange,
//         fontSize: 12,
//         backgroundColor: Colors.black.withOpacity(0.7),
//       ),
//     );
//     textPainter.layout();
//     textPainter.paint(canvas, Offset(centerX - 30, centerY - 40));

//     textPainter.text = TextSpan(
//       text: 'P: ${pitch.toStringAsFixed(1)}°',
//       style: TextStyle(
//         color: isPoseValid ? Colors.green : Colors.orange,
//         fontSize: 12,
//         backgroundColor: Colors.black.withOpacity(0.7),
//       ),
//     );
//     textPainter.layout();
//     textPainter.paint(canvas, Offset(centerX - 30, centerY - 25));

//     textPainter.text = TextSpan(
//       text: 'R: ${roll.toStringAsFixed(1)}°',
//       style: TextStyle(
//         color: isPoseValid ? Colors.green : Colors.orange,
//         fontSize: 12,
//         backgroundColor: Colors.black.withOpacity(0.7),
//       ),
//     );
//     textPainter.layout();
//     textPainter.paint(canvas, Offset(centerX - 30, centerY - 10));
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }