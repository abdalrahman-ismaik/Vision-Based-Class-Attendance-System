import 'package:flutter/foundation.dart';
import '../../../shared/domain/entities/captured_frame.dart';
import '../../../shared/domain/entities/selected_frame.dart';
import '../../../core/computer_vision/pose_type.dart';
import 'image_quality_analyzer.dart';

/// Result of frame selection for one pose
class PoseFrameSelectionResult {
  const PoseFrameSelectionResult({
    required this.poseType,
    required this.selectedFrames,
    required this.averageQuality,
    required this.totalCaptured,
  });

  final PoseType poseType;
  final List<SelectedFrame> selectedFrames;
  final double averageQuality;
  final int totalCaptured;
}

/// Service for selecting best frames from captured sequences
/// Analyzes quality metrics and selects optimal frames per pose
class FrameSelectionService {
  FrameSelectionService({
    ImageQualityAnalyzer? qualityAnalyzer,
  }) : _qualityAnalyzer = qualityAnalyzer ?? ImageQualityAnalyzer();

  final ImageQualityAnalyzer _qualityAnalyzer;

  /// Select best N frames from a list of captured frames for each pose
  /// Returns map of PoseType -> List<SelectedFrame>
  Future<Map<PoseType, List<SelectedFrame>>> selectBestFrames({
    required List<CapturedFrame> capturedFrames,
    required String sessionId,
    int framesPerPose = 3,
  }) async {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🎯 FRAME SELECTION STARTED');
    debugPrint('   Session ID: $sessionId');
    debugPrint('   Total captured frames: ${capturedFrames.length}');
    debugPrint('   Frames per pose: $framesPerPose');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    final startTime = DateTime.now();
    
    // Group frames by pose type
    final Map<PoseType, List<CapturedFrame>> framesByPose = {};

    for (final frame in capturedFrames) {
      framesByPose.putIfAbsent(frame.poseType, () => []).add(frame);
    }

    debugPrint('📊 Frames grouped by pose:');
    for (final entry in framesByPose.entries) {
      debugPrint('   ${entry.key.name}: ${entry.value.length} frames');
    }
    debugPrint('');

    // Select best frames for each pose
    final Map<PoseType, List<SelectedFrame>> selectedByPose = {};
    int totalSelected = 0;

    for (final entry in framesByPose.entries) {
      final poseType = entry.key;
      final poseFrames = entry.value;

      debugPrint('🔍 Processing ${poseType.name}...');
      final selectedFrames = await _selectBestFramesForPose(
        frames: poseFrames,
        sessionId: sessionId,
        count: framesPerPose,
        poseType: poseType,
      );

      selectedByPose[poseType] = selectedFrames;
      totalSelected += selectedFrames.length;
      debugPrint('   ✓ Selected ${selectedFrames.length} frames');
      debugPrint('');
    }

    final duration = DateTime.now().difference(startTime);
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('✅ FRAME SELECTION COMPLETED');
    debugPrint('   Total selected: $totalSelected frames');
    debugPrint('   Processing time: ${duration.inMilliseconds}ms');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    return selectedByPose;
  }

  /// Select best N frames from a single pose's captured frames
  Future<List<SelectedFrame>> _selectBestFramesForPose({
    required List<CapturedFrame> frames,
    required String sessionId,
    required int count,
    required PoseType poseType,
  }) async {
    if (frames.isEmpty) {
      debugPrint('   ⚠️ No frames to select from');
      return [];
    }
    
    if (frames.length <= count) {
      debugPrint('   ℹ️ Only ${frames.length} frames available (requested $count), returning all');
      return frames.map((cf) => _convertToSelectedFrame(cf, sessionId)).toList();
    }

    debugPrint('   📈 Analyzing quality for ${frames.length} frames...');
    
    // Analyze quality for all frames
    final List<_FrameWithScore> framesWithScores = [];

    for (int i = 0; i < frames.length; i++) {
      final frame = frames[i];
      final quality = await _qualityAnalyzer.analyzeImage(frame.imageFilePath);
      framesWithScores.add(_FrameWithScore(frame: frame, quality: quality.overallScore));
      
      if ((i + 1) % 5 == 0 || i == frames.length - 1) {
        debugPrint('      Analyzed ${i + 1}/${frames.length} frames...');
      }
    }

    // Calculate quality statistics
    final qualities = framesWithScores.map((f) => f.quality).toList();
    final avgQuality = qualities.reduce((a, b) => a + b) / qualities.length;
    final maxQuality = qualities.reduce((a, b) => a > b ? a : b);
    final minQuality = qualities.reduce((a, b) => a < b ? a : b);
    
    debugPrint('   📊 Quality stats:');
    debugPrint('      Min: ${(minQuality * 100).toStringAsFixed(1)}%');
    debugPrint('      Avg: ${(avgQuality * 100).toStringAsFixed(1)}%');
    debugPrint('      Max: ${(maxQuality * 100).toStringAsFixed(1)}%');

    // Sort by quality descending
    framesWithScores.sort((a, b) => b.quality.compareTo(a.quality));

    // Select top N frames with diversity
    final selectedFrames = _selectDiverseFrames(
      framesWithScores,
      count: count,
    );

    debugPrint('   🎯 Selected frames:');
    for (int i = 0; i < selectedFrames.length; i++) {
      final fws = selectedFrames[i];
      debugPrint('      ${i + 1}. Quality: ${(fws.quality * 100).toStringAsFixed(1)}% | Time: ${fws.frame.timestampMs}ms');
    }

    // Convert to SelectedFrame entities
    return selectedFrames.map((fws) => _convertToSelectedFrame(fws.frame, sessionId)).toList();
  }

  /// Select frames ensuring temporal diversity
  /// Avoids selecting frames that are too close together in time
  List<_FrameWithScore> _selectDiverseFrames(
    List<_FrameWithScore> sortedFrames,
    {required int count}
  ) {
    final selected = <_FrameWithScore>[];
    const minTimeDiffMs = 100; // Minimum 100ms between selected frames

    for (final frame in sortedFrames) {
      if (selected.length >= count) break;

      // Check if this frame is temporally diverse from already selected frames
      final isDiverse = selected.every((selectedFrame) {
        final timeDiff = (frame.frame.timestampMs - selectedFrame.frame.timestampMs).abs();
        return timeDiff >= minTimeDiffMs;
      });

      if (isDiverse || selected.isEmpty) {
        selected.add(frame);
      }
    }

    // If we couldn't get enough diverse frames, just take the best ones
    while (selected.length < count && selected.length < sortedFrames.length) {
      final nextBest = sortedFrames.firstWhere(
        (f) => !selected.contains(f),
        orElse: () => sortedFrames.first,
      );
      selected.add(nextBest);
    }

    return selected;
  }

  /// Convert CapturedFrame to SelectedFrame
  SelectedFrame _convertToSelectedFrame(CapturedFrame captured, String sessionId) {
    return SelectedFrame(
      id: captured.id,
      sessionId: sessionId,
      imageFilePath: captured.imageFilePath,
      timestampMs: captured.timestampMs,
      qualityScore: captured.qualityScore,
      poseAngles: captured.poseAngles,
      faceMetrics: captured.faceMetrics,
      extractedAt: DateTime.now(),
      poseType: captured.poseType,
      confidenceScore: captured.confidenceScore,
    );
  }

  /// Get summary of selection results
  List<PoseFrameSelectionResult> getSelectionSummary(
    Map<PoseType, List<SelectedFrame>> selectedByPose,
    Map<PoseType, int> capturedCounts,
  ) {
    return selectedByPose.entries.map((entry) {
      final poseType = entry.key;
      final selectedFrames = entry.value;
      final totalCaptured = capturedCounts[poseType] ?? 0;

      final avgQuality = selectedFrames.isEmpty
          ? 0.0
          : selectedFrames.map((f) => f.qualityScore).reduce((a, b) => a + b) / selectedFrames.length;

      return PoseFrameSelectionResult(
        poseType: poseType,
        selectedFrames: selectedFrames,
        averageQuality: avgQuality,
        totalCaptured: totalCaptured,
      );
    }).toList();
  }
}

/// Internal helper class for pairing frames with quality scores
class _FrameWithScore {
  const _FrameWithScore({
    required this.frame,
    required this.quality,
  });

  final CapturedFrame frame;
  final double quality;
}
