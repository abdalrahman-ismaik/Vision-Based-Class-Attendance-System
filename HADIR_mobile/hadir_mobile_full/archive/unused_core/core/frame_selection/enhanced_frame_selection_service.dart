import 'dart:async';
import 'dart:math';
import 'package:hadir_mobile_full/core/capture_control/multi_pose_capture_controller.dart';
import 'package:hadir_mobile_full/core/computer_vision/pose_type.dart';
import 'package:hadir_mobile_full/shared/domain/exceptions/hadir_exceptions.dart';

/// Enhanced frame selection service for optimal frame selection
/// Selects best 3 frames per pose using quality and diversity metrics
class EnhancedFrameSelectionService {
  EnhancedFrameSelectionService._();
  
  static EnhancedFrameSelectionService? _instance;
  static EnhancedFrameSelectionService get instance {
    _instance ??= EnhancedFrameSelectionService._();
    return _instance!;
  }

  /// Selection configuration
  static const int framesPerPose = 3;
  static const double qualityWeight = 0.4;
  static const double diversityWeight = 0.3;
  static const double confidenceWeight = 0.2;
  static const double stabilityWeight = 0.1;
  
  /// Select optimal frames from captured frames
  Future<FrameSelectionResult> selectOptimalFrames(
    Map<PoseType, List<CapturedFrame>> capturedFrames, {
    int framesPerPose = EnhancedFrameSelectionService.framesPerPose,
    FrameSelectionCriteria? criteria,
  }) async {
    if (capturedFrames.isEmpty) {
      throw ArgumentError('No captured frames provided for selection');
    }

    final selectionCriteria = criteria ?? FrameSelectionCriteria.defaultCriteria();
    final selectedFrames = <PoseType, List<SelectedFrameCandidate>>{};
    final selectionMetrics = <PoseType, PoseSelectionMetrics>{};
    
    final stopwatch = Stopwatch()..start();

    try {
      // Process each pose type
      for (final entry in capturedFrames.entries) {
        final poseType = entry.key;
        final frames = entry.value;
        
        if (frames.isEmpty) {
          continue;
        }

        // Select best frames for this pose
        final poseSelection = await _selectFramesForPose(
          poseType,
          frames,
          framesPerPose,
          selectionCriteria,
        );
        
        selectedFrames[poseType] = poseSelection.selectedFrames;
        selectionMetrics[poseType] = poseSelection.metrics;
      }

      stopwatch.stop();

      // Calculate overall metrics
      final overallMetrics = _calculateOverallMetrics(selectionMetrics);
      
      return FrameSelectionResult(
        success: true,
        selectedFrames: selectedFrames,
        poseMetrics: selectionMetrics,
        overallMetrics: overallMetrics,
        processingTimeMs: stopwatch.elapsedMilliseconds,
        totalFramesProcessed: capturedFrames.values.fold(0, (sum, frames) => sum! + frames.length),
        totalFramesSelected: selectedFrames.values.fold(0, (sum, frames) => sum! + frames.length),
      );
    } catch (e) {
      stopwatch.stop();
      return FrameSelectionResult(
        success: false,
        error: GenericHadirException('Frame selection failed: ${e.toString()}'),
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// Select frames for a specific pose
  Future<PoseFrameSelection> _selectFramesForPose(
    PoseType poseType,
    List<CapturedFrame> frames,
    int targetCount,
    FrameSelectionCriteria criteria,
  ) async {
    // Calculate quality scores for all frames
    final candidates = <FrameCandidate>[];
    
    for (int i = 0; i < frames.length; i++) {
      final frame = frames[i];
      final quality = await _calculateFrameQuality(frame, poseType);
      final diversity = _calculateDiversityScore(frame, frames, i);
      
      candidates.add(FrameCandidate(
        frame: frame,
        index: i,
        qualityScore: quality.overallScore,
        diversityScore: diversity,
        confidenceScore: frame.confidence,
        stabilityScore: _calculateStabilityScore(frame, frames, i),
        compositeScore: _calculateCompositeScore(
          quality.overallScore,
          diversity,
          frame.confidence,
          _calculateStabilityScore(frame, frames, i),
          criteria,
        ),
        qualityMetrics: quality,
      ));
    }

    // Sort by composite score (descending)
    candidates.sort((a, b) => b.compositeScore.compareTo(a.compositeScore));

    // Apply diversity filtering to avoid selecting very similar frames
    final selectedCandidates = _applyDiversityFiltering(candidates, targetCount, poseType);

    // Convert to SelectedFrameCandidate
    final selectedFrames = selectedCandidates.map((candidate) => 
      SelectedFrameCandidate(
        frame: candidate.frame,
        qualityScore: candidate.qualityScore,
        diversityScore: candidate.diversityScore,
        confidenceScore: candidate.confidenceScore,
        compositeScore: candidate.compositeScore,
        selectionRank: selectedCandidates.indexOf(candidate) + 1,
        metadata: _extractFrameMetadata(candidate, poseType),
      )
    ).toList();

    // Calculate metrics for this pose
    final metrics = PoseSelectionMetrics(
      poseType: poseType,
      totalCandidates: frames.length,
      selectedCount: selectedFrames.length,
      averageQuality: selectedFrames.map((f) => f.qualityScore).reduce((a, b) => a + b) / selectedFrames.length,
      averageConfidence: selectedFrames.map((f) => f.confidenceScore).reduce((a, b) => a + b) / selectedFrames.length,
      diversityScore: _calculatePoseDiversityScore(selectedFrames),
      qualityDistribution: _calculateQualityDistribution(candidates),
    );

    return PoseFrameSelection(
      selectedFrames: selectedFrames,
      metrics: metrics,
    );
  }

  /// Calculate comprehensive frame quality score
  Future<FrameQualityMetrics> _calculateFrameQuality(CapturedFrame frame, PoseType poseType) async {
    // Simulate quality analysis (in real implementation, this would analyze the actual image)
    await Future.delayed(const Duration(milliseconds: 1));

    // Base quality on confidence and pose-specific factors
    double baseQuality = frame.confidence;
    
    // Pose-specific quality adjustments
    double poseSpecificScore = _calculatePoseSpecificQuality(frame, poseType);
    
    // Simulated image quality metrics
    double sharpness = 0.7 + (Random().nextDouble() * 0.3);
    double lighting = 0.6 + (Random().nextDouble() * 0.4);
    double contrast = 0.65 + (Random().nextDouble() * 0.35);
    double exposure = 0.7 + (Random().nextDouble() * 0.3);
    
    // Calculate overall score
    double overallScore = (
      baseQuality * 0.3 +
      poseSpecificScore * 0.25 +
      sharpness * 0.2 +
      lighting * 0.15 +
      contrast * 0.05 +
      exposure * 0.05
    ).clamp(0.0, 1.0);

    return FrameQualityMetrics(
      overallScore: overallScore,
      sharpness: sharpness,
      lighting: lighting,
      contrast: contrast,
      exposure: exposure,
      poseSpecificScore: poseSpecificScore,
    );
  }

  /// Calculate pose-specific quality score
  double _calculatePoseSpecificQuality(CapturedFrame frame, PoseType poseType) {
    // In a real implementation, this would analyze pose angles and positioning
    // For simulation, we add some variation based on pose type
    
    switch (poseType) {
      case PoseType.frontal:
        // Frontal poses benefit from centered positioning
        return 0.85 + (Random().nextDouble() * 0.15);
      case PoseType.leftProfile:
      case PoseType.rightProfile:
        // Profile poses need good angle definition
        return 0.8 + (Random().nextDouble() * 0.2);
      case PoseType.lookingUp:
      case PoseType.lookingDown:
        // Up/down poses can be more challenging
        return 0.75 + (Random().nextDouble() * 0.25);
    }
  }

  /// Calculate diversity score relative to other frames
  double _calculateDiversityScore(CapturedFrame frame, List<CapturedFrame> allFrames, int currentIndex) {
    if (allFrames.length <= 1) return 1.0;
    
    double totalDifference = 0.0;
    int comparisons = 0;
    
    for (int i = 0; i < allFrames.length; i++) {
      if (i == currentIndex) continue;
      
      final otherFrame = allFrames[i];
      
      // Calculate difference based on timestamp and confidence
      double timeDiff = (frame.timestamp.difference(otherFrame.timestamp).inMilliseconds.abs() / 1000.0).clamp(0.0, 1.0);
      double confidenceDiff = (frame.confidence - otherFrame.confidence).abs();
      
      double frameDifference = (timeDiff + confidenceDiff) / 2.0;
      totalDifference += frameDifference;
      comparisons++;
    }
    
    return comparisons > 0 ? (totalDifference / comparisons).clamp(0.0, 1.0) : 1.0;
  }

  /// Calculate stability score based on neighboring frames
  double _calculateStabilityScore(CapturedFrame frame, List<CapturedFrame> allFrames, int currentIndex) {
    const neighborhoodSize = 2; // Check 2 frames before and after
    
    double stabilitySum = 0.0;
    int validNeighbors = 0;
    
    for (int offset = -neighborhoodSize; offset <= neighborhoodSize; offset++) {
      if (offset == 0) continue;
      
      int neighborIndex = currentIndex + offset;
      if (neighborIndex >= 0 && neighborIndex < allFrames.length) {
        final neighbor = allFrames[neighborIndex];
        
        // Calculate stability based on confidence similarity
        double confidenceSimilarity = 1.0 - (frame.confidence - neighbor.confidence).abs();
        stabilitySum += confidenceSimilarity;
        validNeighbors++;
      }
    }
    
    return validNeighbors > 0 ? (stabilitySum / validNeighbors).clamp(0.0, 1.0) : 0.5;
  }

  /// Calculate composite score combining all factors
  double _calculateCompositeScore(
    double quality,
    double diversity,
    double confidence,
    double stability,
    FrameSelectionCriteria criteria,
  ) {
    return (
      quality * criteria.qualityWeight +
      diversity * criteria.diversityWeight +
      confidence * criteria.confidenceWeight +
      stability * criteria.stabilityWeight
    ).clamp(0.0, 1.0);
  }

  /// Apply diversity filtering to avoid selecting similar frames
  List<FrameCandidate> _applyDiversityFiltering(
    List<FrameCandidate> candidates,
    int targetCount,
    PoseType poseType,
  ) {
    if (candidates.length <= targetCount) {
      return candidates;
    }

    final selected = <FrameCandidate>[];
    final remaining = List<FrameCandidate>.from(candidates);
    
    // Always select the highest scoring frame first
    selected.add(remaining.removeAt(0));
    
    // Select remaining frames based on diversity
    while (selected.length < targetCount && remaining.isNotEmpty) {
      FrameCandidate? bestCandidate;
      double bestDiversityScore = -1.0;
      
      for (final candidate in remaining) {
        // Calculate minimum diversity to already selected frames
        double minDiversity = selected.map((selected) =>
          _calculateFrameDiversity(candidate, selected)
        ).reduce(min);
        
        // Combine with original score
        double adjustedScore = candidate.compositeScore * 0.7 + minDiversity * 0.3;
        
        if (adjustedScore > bestDiversityScore) {
          bestDiversityScore = adjustedScore;
          bestCandidate = candidate;
        }
      }
      
      if (bestCandidate != null) {
        selected.add(bestCandidate);
        remaining.remove(bestCandidate);
      } else {
        break;
      }
    }
    
    return selected;
  }

  /// Calculate diversity between two frame candidates
  double _calculateFrameDiversity(FrameCandidate a, FrameCandidate b) {
    // Calculate diversity based on multiple factors
    double timeDiff = (a.frame.timestamp.difference(b.frame.timestamp).inMilliseconds.abs() / 1000.0).clamp(0.0, 1.0);
    double confidenceDiff = (a.frame.confidence - b.frame.confidence).abs();
    double qualityDiff = (a.qualityScore - b.qualityScore).abs();
    
    return (timeDiff + confidenceDiff + qualityDiff) / 3.0;
  }

  /// Extract frame metadata for selected frame
  Map<String, dynamic> _extractFrameMetadata(FrameCandidate candidate, PoseType poseType) {
    return {
      'poseType': poseType.nameLabel,
      'timestamp': candidate.frame.timestamp.toIso8601String(),
      'confidence': candidate.frame.confidence,
      'qualityScore': candidate.qualityScore,
      'diversityScore': candidate.diversityScore,
      'compositeScore': candidate.compositeScore,
      'index': candidate.index,
      'qualityMetrics': candidate.qualityMetrics?.toJson(),
    };
  }

  /// Calculate pose-level diversity score
  double _calculatePoseDiversityScore(List<SelectedFrameCandidate> frames) {
    if (frames.length <= 1) return 1.0;
    
    double totalDiversity = 0.0;
    int comparisons = 0;
    
    for (int i = 0; i < frames.length; i++) {
      for (int j = i + 1; j < frames.length; j++) {
        double timeDiff = (frames[i].frame.timestamp.difference(frames[j].frame.timestamp).inMilliseconds.abs() / 1000.0).clamp(0.0, 1.0);
        double qualityDiff = (frames[i].qualityScore - frames[j].qualityScore).abs();
        
        totalDiversity += (timeDiff + qualityDiff) / 2.0;
        comparisons++;
      }
    }
    
    return comparisons > 0 ? (totalDiversity / comparisons).clamp(0.0, 1.0) : 1.0;
  }

  /// Calculate quality distribution among candidates
  Map<String, int> _calculateQualityDistribution(List<FrameCandidate> candidates) {
    final distribution = {'excellent': 0, 'good': 0, 'fair': 0, 'poor': 0};
    
    for (final candidate in candidates) {
      if (candidate.qualityScore >= 0.9) {
        distribution['excellent'] = distribution['excellent']! + 1;
      } else if (candidate.qualityScore >= 0.7) {
        distribution['good'] = distribution['good']! + 1;
      } else if (candidate.qualityScore >= 0.5) {
        distribution['fair'] = distribution['fair']! + 1;
      } else {
        distribution['poor'] = distribution['poor']! + 1;
      }
    }
    
    return distribution;
  }

  /// Calculate overall metrics across all poses
  OverallSelectionMetrics _calculateOverallMetrics(Map<PoseType, PoseSelectionMetrics> poseMetrics) {
    if (poseMetrics.isEmpty) {
      return OverallSelectionMetrics(
        totalPoses: 0,
        totalFramesSelected: 0,
        averageQuality: 0.0,
        averageConfidence: 0.0,
        overallDiversityScore: 0.0,
      );
    }
    
    final totalFrames = poseMetrics.values.fold(0, (sum, metrics) => sum + metrics.selectedCount);
    final avgQuality = poseMetrics.values.map((m) => m.averageQuality).reduce((a, b) => a + b) / poseMetrics.length;
    final avgConfidence = poseMetrics.values.map((m) => m.averageConfidence).reduce((a, b) => a + b) / poseMetrics.length;
    final avgDiversity = poseMetrics.values.map((m) => m.diversityScore).reduce((a, b) => a + b) / poseMetrics.length;
    
    return OverallSelectionMetrics(
      totalPoses: poseMetrics.length,
      totalFramesSelected: totalFrames,
      averageQuality: avgQuality,
      averageConfidence: avgConfidence,
      overallDiversityScore: avgDiversity,
    );
  }
}

/// Frame selection criteria configuration
class FrameSelectionCriteria {
  const FrameSelectionCriteria({
    required this.qualityWeight,
    required this.diversityWeight,
    required this.confidenceWeight,
    required this.stabilityWeight,
  });

  final double qualityWeight;
  final double diversityWeight;
  final double confidenceWeight;
  final double stabilityWeight;

  factory FrameSelectionCriteria.defaultCriteria() {
    return const FrameSelectionCriteria(
      qualityWeight: EnhancedFrameSelectionService.qualityWeight,
      diversityWeight: EnhancedFrameSelectionService.diversityWeight,
      confidenceWeight: EnhancedFrameSelectionService.confidenceWeight,
      stabilityWeight: EnhancedFrameSelectionService.stabilityWeight,
    );
  }
}

/// Frame candidate for selection
class FrameCandidate {
  const FrameCandidate({
    required this.frame,
    required this.index,
    required this.qualityScore,
    required this.diversityScore,
    required this.confidenceScore,
    required this.stabilityScore,
    required this.compositeScore,
    this.qualityMetrics,
  });

  final CapturedFrame frame;
  final int index;
  final double qualityScore;
  final double diversityScore;
  final double confidenceScore;
  final double stabilityScore;
  final double compositeScore;
  final FrameQualityMetrics? qualityMetrics;
}

/// Selected frame candidate
class SelectedFrameCandidate {
  const SelectedFrameCandidate({
    required this.frame,
    required this.qualityScore,
    required this.diversityScore,
    required this.confidenceScore,
    required this.compositeScore,
    required this.selectionRank,
    required this.metadata,
  });

  final CapturedFrame frame;
  final double qualityScore;
  final double diversityScore;
  final double confidenceScore;
  final double compositeScore;
  final int selectionRank;
  final Map<String, dynamic> metadata;
}

/// Frame quality metrics
class FrameQualityMetrics {
  const FrameQualityMetrics({
    required this.overallScore,
    required this.sharpness,
    required this.lighting,
    required this.contrast,
    required this.exposure,
    required this.poseSpecificScore,
  });

  final double overallScore;
  final double sharpness;
  final double lighting;
  final double contrast;
  final double exposure;
  final double poseSpecificScore;

  Map<String, dynamic> toJson() {
    return {
      'overallScore': overallScore,
      'sharpness': sharpness,
      'lighting': lighting,
      'contrast': contrast,
      'exposure': exposure,
      'poseSpecificScore': poseSpecificScore,
    };
  }
}

/// Selection result for a specific pose
class PoseFrameSelection {
  const PoseFrameSelection({
    required this.selectedFrames,
    required this.metrics,
  });

  final List<SelectedFrameCandidate> selectedFrames;
  final PoseSelectionMetrics metrics;
}

/// Metrics for pose selection
class PoseSelectionMetrics {
  const PoseSelectionMetrics({
    required this.poseType,
    required this.totalCandidates,
    required this.selectedCount,
    required this.averageQuality,
    required this.averageConfidence,
    required this.diversityScore,
    required this.qualityDistribution,
  });

  final PoseType poseType;
  final int totalCandidates;
  final int selectedCount;
  final double averageQuality;
  final double averageConfidence;
  final double diversityScore;
  final Map<String, int> qualityDistribution;
}

/// Overall selection metrics
class OverallSelectionMetrics {
  const OverallSelectionMetrics({
    required this.totalPoses,
    required this.totalFramesSelected,
    required this.averageQuality,
    required this.averageConfidence,
    required this.overallDiversityScore,
  });

  final int totalPoses;
  final int totalFramesSelected;
  final double averageQuality;
  final double averageConfidence;
  final double overallDiversityScore;
}

/// Frame selection result
class FrameSelectionResult {
  const FrameSelectionResult({
    required this.success,
    this.selectedFrames,
    this.poseMetrics,
    this.overallMetrics,
    this.processingTimeMs,
    this.totalFramesProcessed,
    this.totalFramesSelected,
    this.error,
  });

  final bool success;
  final Map<PoseType, List<SelectedFrameCandidate>>? selectedFrames;
  final Map<PoseType, PoseSelectionMetrics>? poseMetrics;
  final OverallSelectionMetrics? overallMetrics;
  final int? processingTimeMs;
  final int? totalFramesProcessed;
  final int? totalFramesSelected;
  final Exception? error;
}