import 'package:equatable/equatable.dart';
import 'bounding_box.dart';

/// Class representing face quality metrics
class FaceMetrics extends Equatable {
  const FaceMetrics({
    required this.boundingBox,
    required this.faceSize,
    required this.sharpnessScore,
    required this.lightingScore,
    required this.symmetryScore,
    required this.hasGlasses,
    required this.hasHat,
    required this.isSmiling,
    this.blurScore,
    this.brightnessScore,
    this.contrastScore,
    this.overallQuality,
    this.isBlurred,
    this.isOverexposed,
    this.isUnderexposed,
    this.isFrontal,
  });

  /// Face bounding box
  final BoundingBox boundingBox;

  /// Face size relative to frame (0.0 to 1.0)
  final double faceSize;

  /// Sharpness score (0.0 to 1.0, higher is sharper)
  final double sharpnessScore;

  /// Lighting quality score (0.0 to 1.0, higher is better)
  final double lightingScore;

  /// Facial symmetry score (0.0 to 1.0, higher is more symmetrical)
  final double symmetryScore;

  /// Whether the person is wearing glasses
  final bool hasGlasses;

  /// Whether the person is wearing a hat
  final bool hasHat;

  /// Whether the person is smiling
  final bool isSmiling;

  /// Optional blur score (0.0 to 1.0, higher is less blurred)
  final double? blurScore;

  /// Optional brightness score (0.0 to 1.0, 0.5 is optimal)
  final double? brightnessScore;

  /// Optional contrast score (0.0 to 1.0, higher is better)
  final double? contrastScore;

  /// Optional overall quality score combining all metrics (0.0 to 1.0)
  final double? overallQuality;

  /// Optional: whether the face is considered blurred
  final bool? isBlurred;

  /// Optional: whether the face is overexposed
  final bool? isOverexposed;

  /// Optional: whether the face is underexposed
  final bool? isUnderexposed;

  /// Optional: whether the face is in frontal pose
  final bool? isFrontal;

  @override
  List<Object?> get props => [
    boundingBox,
    faceSize,
    sharpnessScore,
    lightingScore,
    symmetryScore,
    hasGlasses,
    hasHat,
    isSmiling,
    blurScore,
    brightnessScore,
    contrastScore,
    overallQuality,
    isBlurred,
    isOverexposed,
    isUnderexposed,
    isFrontal,
  ];

  /// Create a copy with updated values
  FaceMetrics copyWith({
    BoundingBox? boundingBox,
    double? faceSize,
    double? sharpnessScore,
    double? lightingScore,
    double? symmetryScore,
    bool? hasGlasses,
    bool? hasHat,
    bool? isSmiling,
    double? blurScore,
    double? brightnessScore,
    double? contrastScore,
    double? overallQuality,
    bool? isBlurred,
    bool? isOverexposed,
    bool? isUnderexposed,
    bool? isFrontal,
  }) {
    return FaceMetrics(
      boundingBox: boundingBox ?? this.boundingBox,
      faceSize: faceSize ?? this.faceSize,
      sharpnessScore: sharpnessScore ?? this.sharpnessScore,
      lightingScore: lightingScore ?? this.lightingScore,
      symmetryScore: symmetryScore ?? this.symmetryScore,
      hasGlasses: hasGlasses ?? this.hasGlasses,
      hasHat: hasHat ?? this.hasHat,
      isSmiling: isSmiling ?? this.isSmiling,
      blurScore: blurScore ?? this.blurScore,
      brightnessScore: brightnessScore ?? this.brightnessScore,
      contrastScore: contrastScore ?? this.contrastScore,
      overallQuality: overallQuality ?? this.overallQuality,
      isBlurred: isBlurred ?? this.isBlurred,
      isOverexposed: isOverexposed ?? this.isOverexposed,
      isUnderexposed: isUnderexposed ?? this.isUnderexposed,
      isFrontal: isFrontal ?? this.isFrontal,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'boundingBox': boundingBox.toJson(),
      'faceSize': faceSize,
      'sharpnessScore': sharpnessScore,
      'lightingScore': lightingScore,
      'symmetryScore': symmetryScore,
      'hasGlasses': hasGlasses,
      'hasHat': hasHat,
      'isSmiling': isSmiling,
      'blurScore': blurScore,
      'brightnessScore': brightnessScore,
      'contrastScore': contrastScore,
      'overallQuality': overallQuality,
      'isBlurred': isBlurred,
      'isOverexposed': isOverexposed,
      'isUnderexposed': isUnderexposed,
      'isFrontal': isFrontal,
    };
  }

  /// Create from JSON
  factory FaceMetrics.fromJson(Map<String, dynamic> json) {
    return FaceMetrics(
      boundingBox: BoundingBox.fromJson(json['boundingBox'] as Map<String, dynamic>),
      faceSize: (json['faceSize'] as num).toDouble(),
      sharpnessScore: (json['sharpnessScore'] as num).toDouble(),
      lightingScore: (json['lightingScore'] as num).toDouble(),
      symmetryScore: (json['symmetryScore'] as num).toDouble(),
      hasGlasses: json['hasGlasses'] as bool,
      hasHat: json['hasHat'] as bool,
      isSmiling: json['isSmiling'] as bool,
      blurScore: json['blurScore'] != null ? (json['blurScore'] as num).toDouble() : null,
      brightnessScore: json['brightnessScore'] != null ? (json['brightnessScore'] as num).toDouble() : null,
      contrastScore: json['contrastScore'] != null ? (json['contrastScore'] as num).toDouble() : null,
      overallQuality: json['overallQuality'] != null ? (json['overallQuality'] as num).toDouble() : null,
      isBlurred: json['isBlurred'] as bool?,
      isOverexposed: json['isOverexposed'] as bool?,
      isUnderexposed: json['isUnderexposed'] as bool?,
      isFrontal: json['isFrontal'] as bool?,
    );
  }

  @override
  String toString() {
    return 'FaceMetrics(boundingBox: $boundingBox, faceSize: $faceSize, '
           'sharpnessScore: $sharpnessScore, lightingScore: $lightingScore, '
           'symmetryScore: $symmetryScore, hasGlasses: $hasGlasses, '
           'hasHat: $hasHat, isSmiling: $isSmiling, blurScore: $blurScore, '
           'brightnessScore: $brightnessScore, contrastScore: $contrastScore, '
           'overallQuality: $overallQuality, isBlurred: $isBlurred, '
           'isOverexposed: $isOverexposed, isUnderexposed: $isUnderexposed, '
           'isFrontal: $isFrontal)';
  }
}