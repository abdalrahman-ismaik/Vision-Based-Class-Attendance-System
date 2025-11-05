import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hadir_mobile_full/shared/domain/entities/selected_frame.dart';
import 'package:hadir_mobile_full/core/computer_vision/pose_type.dart';
import 'package:hadir_mobile_full/app/theme/app_colors.dart';
import 'package:hadir_mobile_full/app/theme/app_spacing.dart';
import 'package:hadir_mobile_full/app/theme/app_text_styles.dart';

/// Screen showing selected frames organized by pose type
/// Displays the best 3 frames selected for each pose with quality scores
class SelectedFramesPreviewScreen extends StatelessWidget {
  const SelectedFramesPreviewScreen({
    super.key,
    required this.selectedFramesByPose,
    required this.onConfirm,
    required this.onRetake,
  });

  final Map<PoseType, List<SelectedFrame>> selectedFramesByPose;
  final VoidCallback onConfirm;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    // Calculate total selected frames
    final totalFrames = selectedFramesByPose.values
        .fold<int>(0, (sum, frames) => sum + frames.length);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Selected Frames',
          style: AppTextStyles.headingMedium.copyWith(color: AppColors.textDark),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Modern summary header with gradient
          Container(
            padding: AppSpacing.paddingLG,
            decoration: BoxDecoration(
              gradient: AppColors.successGradient,
              boxShadow: AppElevation.shadowSM,
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: AppRadius.circularMD,
                    ),
                    child: const Icon(Icons.check_circle, color: Colors.white, size: 32),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Frame Selection Complete',
                          style: AppTextStyles.headingMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          '$totalFrames frames selected from ${selectedFramesByPose.length} poses',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Frames grid with modern design
          Expanded(
            child: ListView.builder(
              padding: AppSpacing.paddingMD,
              itemCount: selectedFramesByPose.length,
              itemBuilder: (context, index) {
                final entry = selectedFramesByPose.entries.elementAt(index);
                final poseType = entry.key;
                final frames = entry.value;

                return _buildPoseSection(poseType, frames);
              },
            ),
          ),

          // Modern action buttons
          Container(
            padding: AppSpacing.paddingLG,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: AppElevation.shadowMD,
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onRetake,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retake All'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        side: BorderSide(color: AppColors.warningAmber, width: 1.5),
                        foregroundColor: AppColors.warningAmber,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.circularMD,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.successGradient,
                        borderRadius: AppRadius.circularMD,
                        boxShadow: AppElevation.coloredShadow(AppColors.successGreen),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: onConfirm,
                        icon: const Icon(Icons.check),
                        label: Text(
                          'Confirm & Save',
                          style: AppTextStyles.button.copyWith(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.circularMD,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoseSection(PoseType poseType, List<SelectedFrame> frames) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern pose header
          Container(
            padding: AppSpacing.paddingMD,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryIndigo.withOpacity(0.1),
                  AppColors.primaryPurple.withOpacity(0.1),
                ],
              ),
              borderRadius: AppRadius.circularMD,
              border: Border.all(
                color: AppColors.primaryIndigo.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: AppRadius.circularSM,
                  ),
                  child: Icon(_getPoseIcon(poseType), color: Colors.white, size: 20),
                ),
                SizedBox(width: AppSpacing.md),
                Text(
                  _getPoseName(poseType),
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.primaryIndigo,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs / 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryIndigo.withOpacity(0.2),
                    borderRadius: AppRadius.circularSM,
                  ),
                  child: Text(
                    '${frames.length} selected',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primaryIndigo,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),

          // Modern frames grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.75,
            ),
            itemCount: frames.length,
            itemBuilder: (context, index) {
              return _buildFrameCard(frames[index], index + 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFrameCard(SelectedFrame frame, int frameNumber) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.circularMD,
        boxShadow: AppElevation.shadowMD,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.circularMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image with modern overlay
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Display captured image
                  Image.file(
                    File(frame.imageFilePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.backgroundGray,
                        child: Icon(Icons.error, color: AppColors.warningRed),
                      );
                    },
                  ),

                  // Modern frame number badge
                  Positioned(
                    top: AppSpacing.xs,
                    left: AppSpacing.xs,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs / 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: AppRadius.circularSM,
                        boxShadow: AppElevation.shadowSM,
                      ),
                      child: Text(
                        '#$frameNumber',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Modern quality score
            Container(
              padding: EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                gradient: _getQualityGradient(frame.qualityScore),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.white),
                  SizedBox(width: AppSpacing.xs / 2),
                  Text(
                    '${(frame.qualityScore * 100).toStringAsFixed(0)}%',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
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

  IconData _getPoseIcon(PoseType poseType) {
    switch (poseType) {
      case PoseType.frontal:
        return Icons.face;
      case PoseType.leftProfile:
        return Icons.keyboard_arrow_left;
      case PoseType.rightProfile:
        return Icons.keyboard_arrow_right;
      case PoseType.lookingUp:
        return Icons.keyboard_arrow_up;
      case PoseType.lookingDown:
        return Icons.keyboard_arrow_down;
    }
  }

  String _getPoseName(PoseType poseType) {
    switch (poseType) {
      case PoseType.frontal:
        return 'Frontal';
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

  LinearGradient _getQualityGradient(double quality) {
    if (quality >= 0.8) {
      return AppColors.successGradient;
    } else if (quality >= 0.6) {
      return AppColors.warningGradient;
    }
    return LinearGradient(
      colors: [AppColors.warningRed, AppColors.warningRed.withOpacity(0.8)],
    );
  }
}
