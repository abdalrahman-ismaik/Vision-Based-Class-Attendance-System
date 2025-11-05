import 'package:equatable/equatable.dart';

/// Class representing a bounding box for face detection
class BoundingBox extends Equatable {
  const BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// X coordinate of the top-left corner (normalized 0.0 to 1.0)
  final double x;

  /// Y coordinate of the top-left corner (normalized 0.0 to 1.0)
  final double y;

  /// Width of the bounding box (normalized 0.0 to 1.0)
  final double width;

  /// Height of the bounding box (normalized 0.0 to 1.0)
  final double height;

  @override
  List<Object?> get props => [x, y, width, height];

  /// Create a copy with updated values
  BoundingBox copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return BoundingBox(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }

  /// Create from JSON
  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  /// Get the area of the bounding box
  double get area => width * height;

  /// Get the center point of the bounding box
  ({double x, double y}) get center => (
    x: x + width / 2,
    y: y + height / 2,
  );

  @override
  String toString() {
    return 'BoundingBox(x: $x, y: $y, width: $width, height: $height)';
  }
}