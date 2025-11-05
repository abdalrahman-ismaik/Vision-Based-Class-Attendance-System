import 'package:flutter/material.dart';
import 'dart:io';
import '../../../../shared/shared.dart';

/// Camera page for capturing and processing student photos
/// 
/// This page demonstrates the integration with ML Kit Face Detection
/// frame selection service for AI-powered photo selection.
class CameraPage extends StatefulWidget {
  final String? studentId;
  
  const CameraPage({super.key, this.studentId});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final FrameSelectionRepository _frameSelectionRepository = FrameSelectionRepositoryImpl();
  
  bool _isProcessing = false;
  ServiceHealthResult? _serviceHealth;
  FrameSelectionResult? _lastResult;
  final List<File> _capturedImages = [];

  @override
  void initState() {
    super.initState();
    _checkServiceHealth();
  }

  Future<void> _checkServiceHealth() async {
    try {
      final health = await _frameSelectionRepository.checkServiceHealth();
      setState(() {
        _serviceHealth = health;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to check service health: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera - ${widget.studentId ?? 'New Student'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showServiceInfo,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Service Status Card
            _buildServiceStatusCard(),
            
            const SizedBox(height: 16),
            
            // Camera Preview Placeholder
            Expanded(
              flex: 2,
              child: _buildCameraPreview(),
            ),
            
            const SizedBox(height: 16),
            
            // Controls
            _buildControlsSection(),
            
            const SizedBox(height: 16),
            
            // Results Section
            if (_lastResult != null) 
              Expanded(
                flex: 1,
                child: _buildResultsSection(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(
              _serviceHealth?.isHealthy == true 
                  ? Icons.check_circle 
                  : Icons.error,
              color: _serviceHealth?.isHealthy == true 
                  ? Colors.green 
                  : Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ML Kit Face Detection',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _serviceHealth?.isHealthy == true 
                        ? 'Online - v${_serviceHealth?.version ?? 'Unknown'}'
                        : _serviceHealth?.error ?? 'Offline',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _serviceHealth?.isHealthy == true 
                          ? Colors.green[700] 
                          : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _checkServiceHealth,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          
          Text(
            'Camera Preview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            'Camera integration will be implemented here\nwith live face detection overlay',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Mock capture info
          if (_capturedImages.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                '${_capturedImages.length} images captured',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlsSection() {
    return Column(
      children: [
        // Capture Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _simulateCapture,
            icon: Icon(_isProcessing ? Icons.hourglass_empty : Icons.camera_alt),
            label: Text(_isProcessing ? 'Processing...' : 'Capture Photo'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            // Process Frames Button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _capturedImages.isEmpty || _isProcessing 
                    ? null 
                    : _processFrames,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('AI Select'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Clear Button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _capturedImages.isEmpty ? null : _clearImages,
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultsSection() {
    final result = _lastResult!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'AI Selection Results',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Summary Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Selected',
                  '${result.selectedFrames.length}',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatItem(
                  'Processed',
                  '${result.totalFramesProcessed}',
                  Icons.image,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Time',
                  '${result.processingTimeSeconds.toStringAsFixed(1)}s',
                  Icons.timer,
                  Colors.orange,
                ),
                _buildStatItem(
                  'Quality',
                  '${(result.averageQualityScore * 100).toInt()}%',
                  Icons.star,
                  Colors.purple,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Best Frame Info
            if (result.bestFrame != null) 
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.green[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Best Frame: Quality ${(result.bestFrame!.qualityScore * 100).toInt()}% '
                        '(${result.bestFrame!.qualityAssessment.description})',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Future<void> _simulateCapture() async {
    // Simulate capturing an image
    // In real implementation, this would use the camera plugin
    setState(() {
      _capturedImages.add(File('/mock/path/image_${_capturedImages.length}.jpg'));
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Photo captured! Total: ${_capturedImages.length}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _processFrames() async {
    if (_capturedImages.isEmpty) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final result = await _frameSelectionRepository.selectBestFrames(
        imageFiles: _capturedImages,
        maxFrames: 3,
        options: FrameSelectionOptions(
          minQualityScore: 0.6,
          requireFrontalFace: true,
          enableDiversityScoring: true,
        ),
      );
      
      setState(() {
        _lastResult = result;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'AI processing complete! Selected ${result.selectedFrames.length} best frames',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Processing failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _clearImages() {
    setState(() {
      _capturedImages.clear();
      _lastResult = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Images cleared'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _showServiceInfo() async {
    try {
      final serviceInfo = await _frameSelectionRepository.getServiceInfo();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Service Information'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Name: ${serviceInfo.serviceName}'),
                  Text('Version: ${serviceInfo.version}'),
                  const SizedBox(height: 8),
                  Text('Description: ${serviceInfo.description}'),
                  const SizedBox(height: 12),
                  const Text('Capabilities:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...serviceInfo.capabilities.keys.map((capability) => 
                    Text('• $capability')),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get service info: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}