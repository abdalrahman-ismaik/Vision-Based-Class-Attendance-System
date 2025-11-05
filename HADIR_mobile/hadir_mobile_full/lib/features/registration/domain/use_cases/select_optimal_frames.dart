import 'package:dartz/dartz.dart';
import 'package:hadir_mobile_full/shared/domain/entities/selected_frame.dart';
import 'package:hadir_mobile_full/shared/domain/exceptions/hadir_exceptions.dart';
import 'package:hadir_mobile_full/features/registration/domain/repositories/registration_repository.dart';
import 'package:hadir_mobile_full/core/computer_vision/pose_type.dart';

/// Result type for use case operations
typedef UseCaseResult<T> = Either<HadirException, T>;

/// Parameters for selecting optimal frames
class SelectOptimalFramesParams {
  const SelectOptimalFramesParams({
    required this.sessionId,
    required this.requiredPoses,
    this.framesPerPose = 3,
    this.qualityThreshold = 0.7,
  });

  final String sessionId;
  final List<PoseType> requiredPoses;
  final int framesPerPose;
  final double qualityThreshold;
}

/// Result of optimal frame selection operation
class SelectOptimalFramesResult {
  const SelectOptimalFramesResult({
    required this.selectedFrames,
    required this.posesCovered,
    required this.totalFramesSelected,
    required this.averageQuality,
    required this.selectionMetrics,
  });

  final List<SelectedFrame> selectedFrames;
  final Map<PoseType, List<SelectedFrame>> posesCovered;
  final int totalFramesSelected;
  final double averageQuality;
  final FrameSelectionMetrics selectionMetrics;
}

/// Metrics for frame selection operation
class FrameSelectionMetrics {
  const FrameSelectionMetrics({
    required this.totalCandidates,
    required this.qualityDistribution,
    required this.diversityScore,
    required this.coverageScore,
  });

  final int totalCandidates;
  final Map<String, int> qualityDistribution;
  final double diversityScore;
  final double coverageScore;
}

/// Use case for selecting optimal frames from captured candidates
class SelectOptimalFramesUseCase {
  const SelectOptimalFramesUseCase({
    required this.registrationRepository,
  });

  final RegistrationRepository registrationRepository;

  /// Execute the optimal frame selection operation
  Future<UseCaseResult<SelectOptimalFramesResult>> call(SelectOptimalFramesParams params) async {
    try {
      // Validate parameters
      if (params.sessionId.trim().isEmpty) {
        return Left(const FieldRequiredException('sessionId'));
      }
      
      if (params.requiredPoses.isEmpty) {
        return Left(const FieldRequiredException('requiredPoses'));
      }
      
      if (params.framesPerPose <= 0) {
        return Left(const InvalidFormatException('framesPerPose must be greater than 0'));
      }
      
      if (params.qualityThreshold < 0.0 || params.qualityThreshold > 1.0) {
        return Left(const InvalidFormatException('qualityThreshold must be between 0.0 and 1.0'));
      }

      // Get registration session
      final session = await registrationRepository.getSessionById(params.sessionId);
      if (session == null) {
        return Left(const RegistrationSessionNotFoundException());
      }

      // Get all captured frames for this session
      final allFrames = await registrationRepository.getSessionFrames(params.sessionId);
      if (allFrames.isEmpty) {
        return Left(const RegistrationSessionFailedException('No frames available for selection'));
      }

      // Filter frames by quality threshold
      final qualityFrames = allFrames
          .where((frame) => frame.qualityScore >= params.qualityThreshold)
          .toList();

      if (qualityFrames.isEmpty) {
        return Left(const InsufficientFaceQualityException('No frames meet the quality threshold'));
      }

      // Group frames by pose type
      final framesByPose = <PoseType, List<SelectedFrame>>{};
      for (final frame in qualityFrames) {
        framesByPose.putIfAbsent(frame.poseType, () => []).add(frame);
      }

      // Select optimal frames for each required pose
      final selectedFrames = <SelectedFrame>[];
      final posesCovered = <PoseType, List<SelectedFrame>>{};
      
      for (final requiredPose in params.requiredPoses) {
        final candidatesForPose = framesByPose[requiredPose] ?? [];
        
        if (candidatesForPose.isEmpty) {
          return Left(IncorrectPoseException('No frames available for required pose: ${requiredPose.nameLabel}'));
        }

        // Select best frames for this pose
        final bestFramesForPose = _selectBestFramesForPose(
          candidatesForPose, 
          params.framesPerPose,
        );
        
        selectedFrames.addAll(bestFramesForPose);
        posesCovered[requiredPose] = bestFramesForPose;
      }

      // Calculate metrics
      final averageQuality = selectedFrames.isEmpty 
          ? 0.0 
          : selectedFrames.map((f) => f.qualityScore).reduce((a, b) => a + b) / selectedFrames.length;

      final qualityDistribution = _calculateQualityDistribution(selectedFrames);
      final diversityScore = _calculateDiversityScore(selectedFrames);
      final coverageScore = posesCovered.length / params.requiredPoses.length;

      final selectionMetrics = FrameSelectionMetrics(
        totalCandidates: allFrames.length,
        qualityDistribution: qualityDistribution,
        diversityScore: diversityScore,
        coverageScore: coverageScore,
      );

      // Update session with selected frames
      await _updateSessionWithOptimalFrames(params.sessionId, selectedFrames);

      final result = SelectOptimalFramesResult(
        selectedFrames: selectedFrames,
        posesCovered: posesCovered,
        totalFramesSelected: selectedFrames.length,
        averageQuality: averageQuality,
        selectionMetrics: selectionMetrics,
      );

      return Right(result);
    } on RegistrationException catch (e) {
      return Left(e);
    } on ValidationException catch (e) {
      return Left(e);
    } on Exception catch (e) {
      return Left(GenericHadirException('Failed to select optimal frames: ${e.toString()}'));
    }
  }

  /// Select the best frames for a specific pose type
  List<SelectedFrame> _selectBestFramesForPose(List<SelectedFrame> candidates, int maxFrames) {
    // Sort candidates by multiple criteria:
    // 1. Quality score (highest first)
    // 2. Confidence score (highest first)
    // 3. Face size (largest first, from face metrics)
    candidates.sort((a, b) {
      // Primary: Quality score
      int qualityComparison = b.qualityScore.compareTo(a.qualityScore);
      if (qualityComparison != 0) return qualityComparison;
      
      // Secondary: Confidence score
      int confidenceComparison = b.confidenceScore.compareTo(a.confidenceScore);
      if (confidenceComparison != 0) return confidenceComparison;
      
      // Tertiary: Face size (larger is better)
      double aFaceSize = a.faceMetrics.faceSize;
      double bFaceSize = b.faceMetrics.faceSize;
      return bFaceSize.compareTo(aFaceSize);
    });

    // Apply diversity filter to avoid selecting very similar frames
    final selectedFrames = <SelectedFrame>[];
    
    for (final candidate in candidates) {
      if (selectedFrames.length >= maxFrames) break;
      
      // Check if this frame is sufficiently different from already selected frames
      if (_isFrameDiverseEnough(candidate, selectedFrames)) {
        selectedFrames.add(candidate);
      }
    }

    // If we don't have enough diverse frames, fill with best remaining frames
    if (selectedFrames.length < maxFrames) {
      for (final candidate in candidates) {
        if (selectedFrames.length >= maxFrames) break;
        if (!selectedFrames.contains(candidate)) {
          selectedFrames.add(candidate);
        }
      }
    }

    return selectedFrames;
  }

  /// Check if a frame is diverse enough from already selected frames
  bool _isFrameDiverseEnough(SelectedFrame candidate, List<SelectedFrame> selectedFrames) {
    if (selectedFrames.isEmpty) return true;
    
    const double diversityThreshold = 0.1; // 10% difference threshold
    
    for (final selected in selectedFrames) {
      // Check quality score difference
      double qualityDiff = (candidate.qualityScore - selected.qualityScore).abs();
      
      // Check pose angle differences
      double yawDiff = (candidate.poseAngles.yaw - selected.poseAngles.yaw).abs();
      double pitchDiff = (candidate.poseAngles.pitch - selected.poseAngles.pitch).abs();
      double rollDiff = (candidate.poseAngles.roll - selected.poseAngles.roll).abs();
      
      // Check face size difference
      double sizeDiff = (candidate.faceMetrics.faceSize - selected.faceMetrics.faceSize).abs() / 
                       ((candidate.faceMetrics.faceSize + selected.faceMetrics.faceSize) / 2);
      
      // Frame is diverse if it differs significantly in any dimension
      if (qualityDiff > diversityThreshold ||
          yawDiff > 10.0 || // 10 degrees difference
          pitchDiff > 10.0 ||
          rollDiff > 10.0 ||
          sizeDiff > diversityThreshold) {
        return true;
      }
    }
    
    return false;
  }

  /// Calculate quality distribution of selected frames
  Map<String, int> _calculateQualityDistribution(List<SelectedFrame> frames) {
    final distribution = <String, int>{
      'excellent': 0,
      'good': 0,
      'fair': 0,
      'poor': 0,
    };

    for (final frame in frames) {
      if (frame.qualityScore >= 0.9) {
        distribution['excellent'] = (distribution['excellent'] ?? 0) + 1;
      } else if (frame.qualityScore >= 0.7) {
        distribution['good'] = (distribution['good'] ?? 0) + 1;
      } else if (frame.qualityScore >= 0.5) {
        distribution['fair'] = (distribution['fair'] ?? 0) + 1;
      } else {
        distribution['poor'] = (distribution['poor'] ?? 0) + 1;
      }
    }

    return distribution;
  }

  /// Calculate diversity score based on frame variations
  double _calculateDiversityScore(List<SelectedFrame> frames) {
    if (frames.length <= 1) return 1.0;
    
    double totalVariation = 0.0;
    int comparisons = 0;
    
    for (int i = 0; i < frames.length; i++) {
      for (int j = i + 1; j < frames.length; j++) {
        final frameA = frames[i];
        final frameB = frames[j];
        
        // Calculate variation in multiple dimensions
        double qualityVariation = (frameA.qualityScore - frameB.qualityScore).abs();
        double yawVariation = (frameA.poseAngles.yaw - frameB.poseAngles.yaw).abs() / 180.0;
        double pitchVariation = (frameA.poseAngles.pitch - frameB.poseAngles.pitch).abs() / 180.0;
        double rollVariation = (frameA.poseAngles.roll - frameB.poseAngles.roll).abs() / 180.0;
        
        double frameVariation = (qualityVariation + yawVariation + pitchVariation + rollVariation) / 4.0;
        totalVariation += frameVariation;
        comparisons++;
      }
    }
    
    return comparisons > 0 ? (totalVariation / comparisons).clamp(0.0, 1.0) : 0.0;
  }

  /// Update session with the final selected optimal frames
  Future<void> _updateSessionWithOptimalFrames(String sessionId, List<SelectedFrame> optimalFrames) async {
    // This would typically mark the session as ready for final processing
    // and update metadata about the selected frames
    // Note: We'd need to add this method to the repository interface
    // For now, this is a placeholder for the intended behavior
  }
}