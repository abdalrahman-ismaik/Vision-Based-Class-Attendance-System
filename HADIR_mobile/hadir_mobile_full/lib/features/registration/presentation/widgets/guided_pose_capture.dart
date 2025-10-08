import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hadir_mobile_full/shared/domain/entities/selected_frame.dart';

/// Guided pose capture widget for YOLOv7-Pose based face registration
class GuidedPoseCapture extends ConsumerStatefulWidget {
  const GuidedPoseCapture({
    super.key,
    required this.sessionId,
    required this.onFrameCaptured,
    required this.onComplete,
    required this.onError,
  });

  final String sessionId;
  final Function(SelectedFrame frame) onFrameCaptured;
  final Function() onComplete;
  final Function(String error) onError;

  @override
  ConsumerState<GuidedPoseCapture> createState() => _GuidedPoseCaptureState();
}

class _GuidedPoseCaptureState extends ConsumerState<GuidedPoseCapture>
    with TickerProviderStateMixin {
  
  // Current pose being captured
  int _currentPoseIndex = 0;
  final List<PoseType> _requiredPoses = PoseType.values;
  
  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // State
  bool _isCapturing = false;
  bool _isCameraReady = false;
  String? _currentInstruction;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _updateInstruction();
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

  void _updateInstruction() {
    if (_currentPoseIndex < _requiredPoses.length) {
      setState(() {
        _currentInstruction = _requiredPoses[_currentPoseIndex].instruction;
      });
    }
  }

  Future<void> _initializeCamera() async {
    // Simulate camera initialization
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() {
        _isCameraReady = true;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  color: _isCapturing ? Colors.green : Colors.grey[700]!,
                  width: 3,
                ),
              ),
              child: Stack(
                children: [
                  // Camera preview placeholder
                  Center(
                    child: _isCameraReady
                        ? _buildCameraPreview()
                        : const CircularProgressIndicator(),
                  ),
                  
                  // Face detection overlay
                  if (_isCameraReady) _buildFaceOverlay(),
                  
                  // Pose guide overlay
                  if (_isCameraReady) _buildPoseGuide(),
                ],
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
                  // Current instruction
                  Text(
                    _currentInstruction ?? 'Preparing camera...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Pose type indicator
                  if (_currentPoseIndex < _requiredPoses.length)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[900],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _requiredPoses[_currentPoseIndex].toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  
                  const Spacer(),
                  
                  // Capture button
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isCapturing ? 1.0 : _pulseAnimation.value,
                        child: FloatingActionButton.large(
                          onPressed: _isCameraReady && !_isCapturing
                              ? _captureFrame
                              : null,
                          backgroundColor: _isCapturing
                              ? Colors.red
                              : Colors.white,
                          child: Icon(
                            _isCapturing ? Icons.stop : Icons.camera_alt,
                            color: _isCapturing ? Colors.white : Colors.black,
                            size: 32,
                          ),
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

  Widget _buildCameraPreview() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[800]!,
            Colors.grey[900]!,
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam,
              size: 64,
              color: Colors.white54,
            ),
            SizedBox(height: 8),
            Text(
              'Camera Preview',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceOverlay() {
    return CustomPaint(
      size: Size.infinite,
      painter: FaceDetectionOverlayPainter(),
    );
  }

  Widget _buildPoseGuide() {
    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getPoseIcon(_requiredPoses[_currentPoseIndex]),
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  IconData _getPoseIcon(PoseType poseType) {
    switch (poseType) {
      case PoseType.frontal:
        return Icons.face;
      case PoseType.leftProfile:
        return Icons.face_3;
      case PoseType.rightProfile:
        return Icons.face_4;
      case PoseType.lookingUp:
        return Icons.keyboard_arrow_up;
      case PoseType.lookingDown:
        return Icons.keyboard_arrow_down;
    }
  }

  Future<void> _captureFrame() async {
    if (_isCapturing || !_isCameraReady) return;
    
    setState(() {
      _isCapturing = true;
    });

    try {
      // Simulate frame capture and processing
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate successful capture
      final now = DateTime.now();
      final mockFrame = SelectedFrame(
        id: 'FRM${now.millisecondsSinceEpoch.toString().padLeft(8, '0')}',
        registrationSessionId: widget.sessionId,
        imagePath: 'frames/mock_frame_${now.millisecondsSinceEpoch}.jpg',
        poseType: _requiredPoses[_currentPoseIndex],
        confidenceScore: 0.95,
        quality: FrameQuality.excellent,
        faceEmbedding: List.generate(512, (i) => (i * 0.001) - 0.256),
        faceBoundingBox: [100.0, 150.0, 200.0, 250.0],
        keyPoints: List.generate(68, (i) => [100.0 + i * 2.0, 200.0 + i * 1.5]),
        capturedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      // Notify parent of successful capture
      widget.onFrameCaptured(mockFrame);
      
      // Move to next pose or complete
      _currentPoseIndex++;
      
      if (_currentPoseIndex >= _requiredPoses.length) {
        // All poses captured
        widget.onComplete();
      } else {
        // Update instruction for next pose
        _updateInstruction();
        
        // Show success feedback
        _showCaptureSuccess();
      }
      
    } catch (e) {
      widget.onError('Failed to capture frame: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  void _showCaptureSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Captured ${_requiredPoses[_currentPoseIndex - 1]} pose successfully!',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

/// Custom painter for face detection overlay
class FaceDetectionOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw face detection rectangle (simulated)
    final center = Offset(size.width / 2, size.height / 2);
    final faceRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.6,
      height: size.height * 0.6,
    );

    // Draw rounded rectangle for face area
    final rrect = RRect.fromRectAndRadius(
      faceRect,
      const Radius.circular(8),
    );
    
    canvas.drawRRect(rrect, paint);

    // Draw corner indicators
    final cornerLength = 20.0;
    final cornerPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Top-left corner
    canvas.drawLine(
      Offset(faceRect.left, faceRect.top + cornerLength),
      Offset(faceRect.left, faceRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(faceRect.left, faceRect.top),
      Offset(faceRect.left + cornerLength, faceRect.top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(faceRect.right - cornerLength, faceRect.top),
      Offset(faceRect.right, faceRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(faceRect.right, faceRect.top),
      Offset(faceRect.right, faceRect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(faceRect.left, faceRect.bottom - cornerLength),
      Offset(faceRect.left, faceRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(faceRect.left, faceRect.bottom),
      Offset(faceRect.left + cornerLength, faceRect.bottom),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(faceRect.right - cornerLength, faceRect.bottom),
      Offset(faceRect.right, faceRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(faceRect.right, faceRect.bottom),
      Offset(faceRect.right, faceRect.bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}