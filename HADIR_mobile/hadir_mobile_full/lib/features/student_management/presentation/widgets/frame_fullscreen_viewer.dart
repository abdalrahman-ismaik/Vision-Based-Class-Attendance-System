import 'package:flutter/material.dart';
import 'dart:io';
import '../../../../shared/domain/entities/selected_frame.dart';

/// Fullscreen viewer for frame gallery
class FrameFullscreenViewer extends StatefulWidget {
  final List<SelectedFrame> frames;
  final int initialIndex;

  const FrameFullscreenViewer({
    super.key,
    required this.frames,
    this.initialIndex = 0,
  });

  @override
  State<FrameFullscreenViewer> createState() => _FrameFullscreenViewerState();
}

class _FrameFullscreenViewerState extends State<FrameFullscreenViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Frame ${_currentIndex + 1} of ${widget.frames.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // Page view for swiping
          PageView.builder(
            controller: _pageController,
            itemCount: widget.frames.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildFramePage(widget.frames[index]);
            },
          ),
          
          // Frame info overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildFrameInfo(widget.frames[_currentIndex]),
          ),
        ],
      ),
    );
  }

  Widget _buildFramePage(SelectedFrame frame) {
    final file = File(frame.imageFilePath);
    
    return Center(
      child: Hero(
        tag: 'frame_${frame.id}',
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: file.existsSync()
              ? Image.file(file)
              : Container(
                  color: Colors.grey.shade900,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 64,
                          color: Colors.white54,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Image not available',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFrameInfo(SelectedFrame frame) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildInfoChip(
                Icons.face,
                'Pose: ${_getPoseLabel(frame.poseType)}',
                Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                Icons.star,
                'Quality: ${(frame.qualityScore * 100).toStringAsFixed(0)}%',
                _getQualityColor(frame.qualityScore),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(
                Icons.photo_camera,
                'Confidence: ${(frame.confidenceScore * 100).toStringAsFixed(0)}%',
                Colors.purple,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                Icons.access_time,
                '${(frame.timestampMs / 1000).toStringAsFixed(1)}s',
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getPoseLabel(dynamic poseType) {
    return poseType.toString().split('.').last.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    ).trim();
  }

  Color _getQualityColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }
}
