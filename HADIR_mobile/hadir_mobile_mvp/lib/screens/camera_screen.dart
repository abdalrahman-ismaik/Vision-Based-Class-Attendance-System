import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../models/student.dart';
import '../utils/constants.dart';
import 'results_screen.dart';

class CameraScreen extends StatefulWidget {
  final Student student;

  const CameraScreen({super.key, required this.student});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  bool _isInitialized = false;
  String? _videoPath;
  int _recordingDuration = 0;
  bool _isProcessing = false;
  bool _cameraInitFailed = false;
  String _currentInstruction = ""; // Current recording instruction

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        // Use front camera if available, otherwise use first camera
        final frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );
        
        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium, // Good balance for MVP
        );

        await _cameraController!.initialize();
        
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraInitFailed = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera initialization failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Demo function to skip camera for browser demonstration
  Future<void> _skipToDemo() async {
    setState(() {
      _isProcessing = true;
    });

    // Simulate demo video path
    final demoVideoPath = '/demo/student_${widget.student.id}_video.mp4';
    
    // Navigate directly to results for demo
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _isProcessing = false;
    });

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            student: widget.student,
            videoPath: demoVideoPath,
          ),
        ),
      );
    }
  }

  Future<void> _startRecording() async {
    if (!_cameraController!.value.isInitialized || _isRecording) {
      return;
    }

    try {
      await _cameraController!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
      });

      // Start recording timer
      _startRecordingTimer();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start recording: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startRecordingTimer() {
    // Set initial instruction
    setState(() {
      _currentInstruction = AppConstants.recordingInstructions[0] ?? "Start recording";
    });
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isRecording) return false;
      
      setState(() {
        _recordingDuration++;
        
        // Update instruction based on current time
        final instruction = AppConstants.recordingInstructions[_recordingDuration];
        if (instruction != null) {
          _currentInstruction = instruction;
        }
      });

      // Auto-stop at max duration
      if (_recordingDuration >= AppConstants.maxRecordingDuration) {
        await _stopRecording();
        return false;
      }
      
      return _isRecording;
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      final video = await _cameraController!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _videoPath = video.path;
        _isProcessing = true;
      });

      // Process video and navigate to results
      await _processVideoAndNavigate();
    } catch (e) {
      setState(() {
        _isRecording = false;
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to stop recording: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processVideoAndNavigate() async {
    // For MVP, we'll simulate processing and go directly to results
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isProcessing = false;
    });

    if (mounted && _videoPath != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            student: widget.student,
            videoPath: _videoPath!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recording: ${widget.student.name}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_isInitialized && !_cameraInitFailed) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing camera...'),
          ],
        ),
      );
    }

    // Show demo option if camera failed (for browser demo)
    if (_cameraInitFailed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'Camera Not Available',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Camera functionality is limited on web browsers.\nOn mobile devices, this screen provides real-time face detection and video recording.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _skipToDemo,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Continue Demo (Skip Camera)'),
              ),
              const SizedBox(height: 16),
              Text(
                'This will simulate the registration process\nand show the results screen.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isProcessing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing video...'),
            SizedBox(height: 8),
            Text('Please wait while we extract the best frames'),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Camera preview
        Expanded(
          flex: 3,
          child: SizedBox(
            width: double.infinity,
            child: CameraPreview(_cameraController!),
          ),
        ),
        
        // Recording status and timer
        if (_isRecording)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.red.shade700,
            child: Column(
              children: [
                // Timer row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.fiber_manual_record, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Recording: $_recordingDuration / ${AppConstants.maxRecordingDuration}s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Current instruction
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _currentInstruction,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

        // Instructions and controls
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(height: 8),
                      Text(
                        _isRecording 
                          ? 'Follow the instructions above\nKeep your face clearly visible'
                          : 'Recording will be 25 seconds:\n• 0-5s: Look straight\n• 5-10s: Turn right\n• 10-15s: Turn left\n• 15-20s: Tilt up\n• 20-25s: Tilt down',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Record button
                GestureDetector(
                  onTap: _isRecording ? _stopRecording : _startRecording,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording ? Colors.red : Colors.blue,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.videocam,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  _isRecording ? 'Tap to Stop Recording' : 'Tap to Start Recording',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                
                if (!_isRecording && _recordingDuration < AppConstants.minRecordingDuration && _videoPath == null)
                  Text(
                    'Minimum ${AppConstants.minRecordingDuration} seconds required',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}