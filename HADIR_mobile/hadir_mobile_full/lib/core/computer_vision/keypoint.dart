import 'package:equatable/equatable.dart';

class Keypoint extends Equatable {
  final int id;
  final double x;
  final double y;
  final double confidence;

  const Keypoint({required this.id, required this.x, required this.y, required this.confidence});

  @override
  List<Object?> get props => [id, x, y, confidence];

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': x,
        'y': y,
        'confidence': confidence,
      };

  factory Keypoint.fromJson(Map<String, dynamic> json) => Keypoint(
        id: json['id'] as int,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        confidence: (json['confidence'] as num).toDouble(),
      );
}
