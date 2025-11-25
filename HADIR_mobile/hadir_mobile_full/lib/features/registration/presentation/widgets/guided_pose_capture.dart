import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:hadir_mobile_full/shared/domain/entities/selected_frame.dart';
import 'package:hadir_mobile_full/shared/domain/entities/captured_frame.dart';
import 'package:hadir_mobile_full/core/computer_vision/pose_type.dart';
import 'package:hadir_mobile_full/core/computer_vision/pose_angles.dart';
import 'package:hadir_mobile_full/core/computer_vision/face_metrics.dart';
import 'package:hadir_mobile_full/core/computer_vision/bounding_box.dart';
import 'package:hadir_mobile_full/app/theme/app_colors.dart';
import 'package:hadir_mobile_full/app/theme/app_spacing.dart';
import 'package:hadir_mobile_full/app/theme/app_text_styles.dart';

/// Guided pose capture widget with MANUAL administrator validation
/// No ML Kit - administrator validates pose visually and triggers capture
/// Now captures individual images instead of video for better quality selection
class GuidedPoseCapture extends ConsumerStatefulWidget {
  const GuidedPoseCapture({
    super.key,
    required this.sessionId,
    required this.onFrameCaptured,
    required this.onComplete,
    required this.onError,
    this.onAllFramesCaptured,
    this.onPoseChanged,
    this.embedded = false,
  });

  final String sessionId;
  final Function(SelectedFrame frame) onFrameCaptured;  // Legacy - for backward compatibility
  final Function() onComplete;
  final Function(String error) onError;
  final Function(List<CapturedFrame> frames)? onAllFramesCaptured;  // NEW - returns all captured frames
  final Function(int poseIndex, PoseType poseType, String instruction)? onPoseChanged;  // NEW - notifies pose changes
  final bool embedded;

  @override
  ConsumerState<GuidedPoseCapture> createState() => _GuidedPoseCaptureState();
}

class _GuidedPoseCaptureState extends ConsumerState<GuidedPoseCapture>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  // Camera controller
  CameraController? _cameraController;
  
  // Current pose being captured
  int _currentPoseIndex = 0;
  final List<PoseType> _requiredPoses = [
    PoseType.frontal,
    PoseType.leftProfile,
    PoseType.rightProfile,
    PoseType.lookingUp,
    PoseType.lookingDown,
  ];
  
  // Store captured frames for each pose (will be used for selection)
  final List<CapturedFrame> _allCapturedFrames = [];
  
  // Image stream capture state
  bool _isStreamCapturing = false;
  List<CameraImage> _capturedImages = [];
  Timer? _streamCaptureTimer;
  
  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // State
  bool _isCapturing = false;
  bool _isCameraReady = false;
  String? _currentInstruction;
  bool _isFrontCamera = true;
  int _captureProgress = 0; // 0-15 for capturing 15 frames
  bool _allPosesComplete = false; // Track when all 5 poses are captured
  bool _isProcessingFrames = false; // Track when frame selection is processing
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _updateInstruction(useSetState: false); // Don't use setState during init
    _initializeCamera();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _pulseController.repeat(reverse: true);
  }

  void _updateInstruction({bool useSetState = true}) {
    if (_currentPoseIndex < _requiredPoses.length) {
      final poseType = _requiredPoses[_currentPoseIndex];
      final instruction = _getPoseInstruction(poseType);
      
      if (useSetState && mounted) {
        setState(() {
          _currentInstruction = instruction;
        });
      } else {
        _currentInstruction = instruction;
      }
      
      // Notify parent about pose change
      widget.onPoseChanged?.call(_currentPoseIndex, poseType, instruction);
    }
  }
  
  String _getPoseInstruction(PoseType poseType) {
    switch (poseType) {
      case PoseType.frontal:
        return 'Look straight at camera - keep head upright';
      case PoseType.leftProfile:
        return 'Turn left - keep head upright';
      case PoseType.rightProfile:
        return 'Turn right - keep head upright';
      case PoseType.lookingUp:
        return 'Tilt up slightly - keep head upright';
      case PoseType.lookingDown:
        return 'Tilt down slightly - keep head upright';
    }
  }

  /// Initialize camera using official Flutter camera package guidelines
  /// Reference: https://pub.dev/packages/camera
  Future<void> _initializeCamera() async {
    try {
      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        widget.onError('No cameras found');
        return;
      }
      
      // Select front camera for face detection (or first available camera)
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      
      _isFrontCamera = camera.lensDirection == CameraLensDirection.front;
      
      // Cache sensor orientation for image conversion
      
      // Initialize camera controller with high resolution for better face detection
      // Following official camera package documentation
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      
      // Wait for camera to initialize before using
      await _cameraController!.initialize();
      
      // Debug: Log camera information
      // Note: previewSize is in landscape orientation (width > height)
      final cameraAspectRatio = _cameraController!.value.aspectRatio;
      final previewSize = _cameraController!.value.previewSize;
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📷 CAMERA INITIALIZED');
      debugPrint('   Aspect Ratio: $cameraAspectRatio');
      debugPrint('   Preview Size: $previewSize');
      debugPrint('   Front Camera: $_isFrontCamera');
      debugPrint('   Embedded Mode: ${widget.embedded}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      // Manual mode: No image stream needed
      
      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });
      }
    } catch (e) {
      if (mounted) {
        widget.onError('Failed to initialize camera: $e');
      }
    }
  }

  /// Manual capture - administrator clicks button after validating pose
  /// Uses image stream for true 30 FPS capture without autofocus delays
  Future<void> _captureFrame() async {
    if (_isCapturing || !_isCameraReady || _cameraController == null) return;
    
    setState(() {
      _isCapturing = true;
      _isStreamCapturing = true;
      _captureProgress = 0;
      _capturedImages = [];
    });

    try {
      const framesPerPose = 15; // Capture 15 frames at true 30 FPS = 0.5 seconds
      final captureStartTime = DateTime.now();
      
      debugPrint('🎬 Starting image stream capture for ${_getPoseDisplayName(_requiredPoses[_currentPoseIndex])}');
      
      // Start image stream
      await _cameraController!.startImageStream((CameraImage image) {
        if (!_isStreamCapturing) return;
        
        // Capture every frame (30 FPS)
        if (_capturedImages.length < framesPerPose) {
          _capturedImages.add(image);
          
          if (mounted) {
            setState(() {
              _captureProgress = _capturedImages.length;
            });
          }
          
          debugPrint('📸 Frame ${_capturedImages.length}/$framesPerPose captured');
          
          // Stop when we have enough frames
          if (_capturedImages.length >= framesPerPose) {
            _isStreamCapturing = false;
          }
        }
      });
      
      // Wait for all frames to be captured (should take ~1 second at 30 FPS)
      while (_capturedImages.length < framesPerPose && mounted) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      // Stop image stream
      try {
        await _cameraController!.stopImageStream();
      } catch (e) {
        debugPrint('⚠️ Error stopping image stream: $e');
      }
      
      final totalCaptureTime = DateTime.now().difference(captureStartTime).inMilliseconds;
      debugPrint('⏱️ Captured ${_capturedImages.length} frames in ${totalCaptureTime}ms');
      debugPrint('� Average: ${(totalCaptureTime / _capturedImages.length).toStringAsFixed(1)}ms per frame');
      debugPrint('🎯 Actual FPS: ${(_capturedImages.length / (totalCaptureTime / 1000)).toStringAsFixed(1)}');
      
      // Convert CameraImage to files and create CapturedFrame objects
      final List<CapturedFrame> poseFrames = [];
      debugPrint('🔄 Converting ${_capturedImages.length} images to files...');
      
      for (int i = 0; i < _capturedImages.length; i++) {
        final cameraImage = _capturedImages[i];
        
        try {
          // Convert YUV to RGB
          var rgbImage = _convertYUV420ToImage(cameraImage);

          // Rotate image to match portrait orientation
          // Android camera streams are landscape (sensor orientation)
          // We need to rotate to get portrait. 
          // For front camera (270 deg sensor), -90 (270) usually corrects it.
          rgbImage = img.copyRotate(rgbImage, angle: -90);
          
          // Save to temporary file
          final directory = await getTemporaryDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final filePath = '${directory.path}/captured_${timestamp}_$i.jpg';
          final file = File(filePath);
          
          // Encode and save as JPEG
          final jpegBytes = img.encodeJpg(rgbImage, quality: 85);
          await file.writeAsBytes(jpegBytes);
          
          // Create captured frame
          final capturedFrame = CapturedFrame(
            id: 'captured_${timestamp}_$i',
            sessionId: widget.sessionId,
            imageFilePath: filePath,
            timestampMs: timestamp + i, // Add index to ensure unique timestamps
            qualityScore: 0.0, // Will be calculated during selection
            poseAngles: PoseAngles(
              yaw: 0.0,
              pitch: 0.0,
              roll: 0.0,
              confidence: 1.0,
            ),
            faceMetrics: FaceMetrics(
              boundingBox: BoundingBox(x: 0, y: 0, width: 0, height: 0),
              faceSize: 0.5,
              sharpnessScore: 0.0,
              lightingScore: 0.0,
              symmetryScore: 0.9,
              hasGlasses: false,
              hasHat: false,
              isSmiling: false,
            ),
            capturedAt: DateTime.now(),
            poseType: _requiredPoses[_currentPoseIndex],
            confidenceScore: 1.0,
          );
          
          poseFrames.add(capturedFrame);
          
          // Quality analysis will happen AFTER all frames captured (deferred to background)
          
        } catch (e) {
          debugPrint('⚠️ Error converting frame $i: $e');
        }
      }
      
      debugPrint('✅ Converted ${poseFrames.length} frames to files');
      
      // Store all captured frames
      _allCapturedFrames.addAll(poseFrames);
      
      debugPrint('✅ Captured $framesPerPose frames for ${_getPoseDisplayName(_requiredPoses[_currentPoseIndex])}');
      debugPrint('   Total frames captured: ${_allCapturedFrames.length}');
      
      // Move to next pose
      _currentPoseIndex++;
      
      if (_currentPoseIndex >= _requiredPoses.length) {
        // All poses captured - trigger selection phase
        _handleAllPosesCaptured();
      } else {
        // Update instruction for next pose
        _updateInstruction();
        _showCaptureSuccess();
      }
      
    } catch (e) {
      widget.onError('Failed to capture images: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _isStreamCapturing = false;
          _captureProgress = 0;
          _capturedImages = [];
        });
      }
    }
  }
  
  /// Convert YUV420 CameraImage to RGB Image
  img.Image _convertYUV420ToImage(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;
    
    final img.Image image = img.Image(width: width, height: height);
    
    final Plane yPlane = cameraImage.planes[0];
    final Plane uPlane = cameraImage.planes[1];
    final Plane vPlane = cameraImage.planes[2];
    
    final int uvRowStride = uPlane.bytesPerRow;
    final int uvPixelStride = uPlane.bytesPerPixel ?? 1;
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * yPlane.bytesPerRow + x;
        final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;
        
        final int yValue = yPlane.bytes[yIndex];
        final int uValue = uPlane.bytes[uvIndex];
        final int vValue = vPlane.bytes[uvIndex];
        
        // YUV to RGB conversion
        int r = (yValue + 1.370705 * (vValue - 128)).round().clamp(0, 255);
        int g = (yValue - 0.337633 * (uValue - 128) - 0.698001 * (vValue - 128)).round().clamp(0, 255);
        int b = (yValue + 1.732446 * (uValue - 128)).round().clamp(0, 255);
        
        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    
    return image;
  }
  
  /// Handle all poses captured - notify parent with all captured frames
  void _handleAllPosesCaptured() async {
    debugPrint('🎉 All poses captured! Total frames: ${_allCapturedFrames.length}');
    
    setState(() {
      _allPosesComplete = true; // Disable capture button
      _isProcessingFrames = true; // Show loading overlay
    });
    
    // Notify parent with all captured frames if callback is provided
    if (widget.onAllFramesCaptured != null) {
      // Await the callback if it's async (which it should be for frame selection)
      await widget.onAllFramesCaptured!(_allCapturedFrames);
    }
    
    // Hide processing overlay after callback completes
    if (mounted) {
      setState(() {
        _isProcessingFrames = false;
      });
    }
    
    // Also call completion callback
    widget.onComplete();
  }

  void _showCaptureSuccess() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Captured ${_getPoseDisplayName(_requiredPoses[_currentPoseIndex - 1])} successfully!',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildEmbeddedView() {
    return Stack(
      children: [
        // Main camera view - full width, no borders
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Camera preview - full width
                  if (_isCameraReady)
                    SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: _buildCameraPreview(),
                    )
                  else
                  _buildCameraLoadingView(),
                  
                  // Capture button - centered
                  if (_isCameraReady && !_isCapturing)
                    Positioned(
                      bottom: constraints.maxHeight * 0.15,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _buildCaptureButton(),
                      ),
                    ),
                    
                  // Capture progress indicator
                  if (_isCapturing)
                    Positioned(
                      bottom: constraints.maxHeight * 0.15,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _buildCaptureProgress(),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        
        // Processing overlay - shown when frame selection is running
        if (_isProcessingFrames)
          _buildProcessingOverlay(),
      ],
    );
  }

  Widget _buildCameraLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryIndigo),
            strokeWidth: 3,
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            'Initializing Camera',
            style: AppTextStyles.headingMedium.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _captureFrame,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryIndigo.withOpacity(0.4),
              blurRadius: 24,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Icon(
          Icons.camera_alt,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }

  Widget _buildCaptureProgress() {
    return Container(
      padding: AppSpacing.paddingLG,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: AppRadius.circularXL,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _captureProgress / 15.0,
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryIndigo),
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
                Text(
                  '$_captureProgress',
                  style: AppTextStyles.headingLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Capturing...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.95),
            Colors.black.withOpacity(0.98),
          ],
        ),
        borderRadius: AppRadius.circularXL,
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated processing indicator with gradient
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: AppElevation.coloredShadow(AppColors.primaryIndigo),
                ),
                padding: EdgeInsets.all(AppSpacing.md),
                child: CircularProgressIndicator(
                  strokeWidth: 6,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              
              // Processing title
              Text(
                '🎯 Processing Frames',
                style: AppTextStyles.displaySmall.copyWith(
                  color: Colors.white,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              
              // Processing description
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Text(
                  'Analyzing ${_allCapturedFrames.length} captured frames to select the best ones for registration...',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              
              // Processing steps indicator with modern design
              Container(
                margin: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                padding: AppSpacing.paddingLG,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryIndigo.withOpacity(0.2),
                      AppColors.primaryPurple.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: AppRadius.circularXL,
                  border: Border.all(
                    color: AppColors.primaryIndigo.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildProcessingStep(Icons.image_search, 'Analyzing image quality', true),
                    SizedBox(height: AppSpacing.md),
                    _buildProcessingStep(Icons.face, 'Detecting face poses', true),
                    SizedBox(height: AppSpacing.md),
                    _buildProcessingStep(Icons.stars, 'Selecting best frames', true),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              
              // Estimated time with modern styling
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: AppRadius.circularMD,
                ),
                child: Text(
                  'This usually takes 20-30 seconds',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingStep(IconData icon, String label, bool isActive) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            gradient: isActive ? AppColors.successGradient : null,
            color: isActive ? null : Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        if (isActive)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.successGreen),
            ),
          ),
      ],
    );
  }

  String _getPoseDisplayName(PoseType poseType) {
    switch (poseType) {
      case PoseType.frontal:
        return 'Front Face';
      case PoseType.leftProfile:
        return 'Left Profile';
      case PoseType.rightProfile:
        return 'Right Profile';
      case PoseType.lookingUp:
        return 'Looking Up';
      case PoseType.lookingDown:
        return 'Looking Down';
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // Stop processing when app goes to background
      // Auto-capture timer removed
      // Processing frame flag removed
    } else if (state == AppLifecycleState.resumed && _cameraController != null) {
      // Manual mode: No image stream needed
    }
  }

  @override
  void dispose() {
    // Remove observer first
    WidgetsBinding.instance.removeObserver(this);
    
    // Cancel stream capture timer
    _streamCaptureTimer?.cancel();
    _isStreamCapturing = false;
    
    // Dispose animations
    _pulseController.dispose();
    
    // Stop camera processing safely (fire and forget - can't await in dispose)
    _cameraController?.stopImageStream().catchError((e) {
      debugPrint('Error stopping image stream: $e');
    });
    
    _cameraController?.dispose().catchError((e) {
      debugPrint('Error disposing camera: $e');
    });
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildEmbeddedView();
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Pose Capture ${_currentPoseIndex + 1}/${_requiredPoses.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: _currentPoseIndex / _requiredPoses.length,
            backgroundColor: Colors.grey[800],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          
          // Camera preview area
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isCapturing ? Colors.blue : Colors.green[700]!,
                  width: 3,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Center(
                      child: _isCameraReady
                          ? _buildCameraPreview()
                          : const CircularProgressIndicator(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Instructions
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    _isCapturing 
                      ? 'Capturing...'
                      : _currentInstruction ?? 'Preparing camera...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  if (_currentPoseIndex < _requiredPoses.length)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getPoseDisplayName(_requiredPoses[_currentPoseIndex]),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  
                  const Spacer(),
                  
                  // Capture button with progress indicator
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isCapturing ? 1.0 : _pulseAnimation.value,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Progress ring during capture
                            if (_isCapturing)
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: CircularProgressIndicator(
                                  value: _captureProgress / 15.0, // Updated to 15 frames
                                  strokeWidth: 4,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                  backgroundColor: Colors.white.withAlpha(77),
                                ),
                              ),
                            
                            // Capture button
                            FloatingActionButton.large(
                              onPressed: _isCameraReady && !_isCapturing && !_allPosesComplete
                                  ? _captureFrame
                                  : null,
                              backgroundColor: _allPosesComplete
                                  ? Colors.grey
                                  : _isCapturing
                                      ? Colors.orange
                                      : Colors.green,
                              child: _allPosesComplete
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 32,
                                    )
                                  : _isCapturing
                                      ? Text(
                                          '$_captureProgress',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build camera preview with correct aspect ratio
  /// Following official Flutter camera package guidelines
  /// Reference: https://pub.dev/packages/camera
  Widget _buildCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final camera = _cameraController!;
    
    // Get the camera preview size and aspect ratio
    // Important: previewSize is always in landscape orientation (width > height)
    // For example: Size(1920, 1080) even when phone is in portrait
    final size = camera.value.previewSize!;
    
    // Calculate the correct aspect ratio for portrait display
    // Since camera preview is landscape but we display in portrait,
    // we need to swap width and height to get the correct ratio
    // Example: 1920x1080 landscape -> 1080/1920 = 0.5625 for portrait
    final aspectRatio = size.height / size.width;
    
    // Wrap CameraPreview in AspectRatio widget to maintain correct proportions
    // This prevents stretching or distortion of the camera feed
    return Center(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: CameraPreview(camera),
      ),
    );
  }
}
