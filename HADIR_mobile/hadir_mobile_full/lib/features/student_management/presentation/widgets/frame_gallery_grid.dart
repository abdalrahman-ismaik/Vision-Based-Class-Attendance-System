import 'package:flutter/material.dart';
import 'dart:io';
import '../../../../shared/domain/entities/selected_frame.dart';
import 'frame_fullscreen_viewer.dart';

/// Grid view for displaying student frames
class FrameGalleryGrid extends StatelessWidget {
  final String studentId;
  final List<SelectedFrame> frames;

  const FrameGalleryGrid({
    super.key,
    required this.studentId,
    required this.frames,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: frames.length,
      itemBuilder: (context, index) {
        final frame = frames[index];
        return _buildFrameTile(context, frame, index);
      },
    );
  }

  Widget _buildFrameTile(BuildContext context, SelectedFrame frame, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FrameFullscreenViewer(
              frames: frames,
              initialIndex: index,
            ),
          ),
        );
      },
      child: Hero(
        tag: 'frame_${frame.id}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Frame image
              _buildFrameImage(frame),
              
              // Pose type badge
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getPoseLabel(frame.poseType),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              // Quality score badge
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getQualityColor(frame.qualityScore).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 10,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        (frame.qualityScore * 100).toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrameImage(SelectedFrame frame) {
    final file = File(frame.imageFilePath);
    
    if (!file.existsSync()) {
      return Container(
        color: Colors.grey.shade200,
        child: Icon(
          Icons.broken_image,
          color: Colors.grey.shade400,
          size: 32,
        ),
      );
    }

    return RotatedBox(
      quarterTurns: 2, // Fix 180 degree rotation issue
      child: Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade200,
            child: Icon(
              Icons.error_outline,
              color: Colors.grey.shade400,
              size: 32,
            ),
          );
        },
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
