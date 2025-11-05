import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Quality assessment results for a captured frame
class ImageQualityMetrics {
  const ImageQualityMetrics({
    required this.sharpness,
    required this.brightness,
    required this.contrast,
    required this.overallScore,
  });

  /// Sharpness score (0.0 to 1.0) - higher is sharper
  /// Based on Laplacian variance
  final double sharpness;

  /// Brightness score (0.0 to 1.0) - optimal range is 0.4-0.7
  final double brightness;

  /// Contrast score (0.0 to 1.0) - higher is better
  final double contrast;

  /// Overall quality score (0.0 to 1.0)
  /// Weighted combination of all metrics
  final double overallScore;

  @override
  String toString() => 'Quality(overall: ${overallScore.toStringAsFixed(2)}, '
      'sharpness: ${sharpness.toStringAsFixed(2)}, '
      'brightness: ${brightness.toStringAsFixed(2)}, '
      'contrast: ${contrast.toStringAsFixed(2)})';
}

/// Service for analyzing image quality metrics
/// Used to select best frames from captured sequences
class ImageQualityAnalyzer {
  /// Analyze quality of an image file
  Future<ImageQualityMetrics> analyzeImage(String imagePath) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    return analyzeImageBytes(bytes);
  }

  /// Analyze quality of image bytes
  ImageQualityMetrics analyzeImageBytes(Uint8List bytes) {
    // Decode image
    final image = img.decodeImage(bytes);
    if (image == null) {
      return const ImageQualityMetrics(
        sharpness: 0.0,
        brightness: 0.0,
        contrast: 0.0,
        overallScore: 0.0,
      );
    }

    // Calculate individual metrics
    final sharpness = _calculateSharpness(image);
    final brightness = _calculateBrightness(image);
    final contrast = _calculateContrast(image);

    // Calculate weighted overall score
    // Sharpness is most important (50%), then contrast (30%), then brightness (20%)
    final overallScore = (sharpness * 0.5) + (contrast * 0.3) + (brightness * 0.2);

    return ImageQualityMetrics(
      sharpness: sharpness,
      brightness: brightness,
      contrast: contrast,
      overallScore: overallScore,
    );
  }

  /// Calculate sharpness using Laplacian variance
  /// Higher variance = sharper image
  double _calculateSharpness(img.Image image) {
    // Convert to grayscale for edge detection
    final grayscale = img.grayscale(image);

    // Apply Laplacian operator to detect edges
    // Laplacian kernel:
    // [ 0  1  0 ]
    // [ 1 -4  1 ]
    // [ 0  1  0 ]
    
    double sumOfSquares = 0.0;
    double sum = 0.0;
    int count = 0;

    for (int y = 1; y < grayscale.height - 1; y++) {
      for (int x = 1; x < grayscale.width - 1; x++) {
        final center = grayscale.getPixel(x, y).r.toInt();
        final top = grayscale.getPixel(x, y - 1).r.toInt();
        final bottom = grayscale.getPixel(x, y + 1).r.toInt();
        final left = grayscale.getPixel(x - 1, y).r.toInt();
        final right = grayscale.getPixel(x + 1, y).r.toInt();

        // Laplacian value (signed for true variance calculation)
        final laplacian = (top + bottom + left + right - 4 * center).toDouble();
        sum += laplacian;
        sumOfSquares += laplacian * laplacian;
        count++;
      }
    }
    
    // Calculate true variance: Var(X) = E[X²] - E[X]²
    final mean = count > 0 ? sum / count : 0.0;
    final variance = count > 0 ? (sumOfSquares / count) - (mean * mean) : 0.0;

    // Normalize to 0-1 range using sigmoid normalization
    final normalized = variance / (variance + 5000);

    return normalized.clamp(0.0, 1.0);
  }

  /// Calculate brightness score
  /// Optimal brightness is in the middle range (0.4-0.7)
  double _calculateBrightness(img.Image image) {
    double totalBrightness = 0.0;
    int pixelCount = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        // Average of RGB channels
        final brightness = (pixel.r + pixel.g + pixel.b) / 3;
        totalBrightness += brightness;
        pixelCount++;
      }
    }

    // Average brightness (0-255)
    final avgBrightness = pixelCount > 0 ? totalBrightness / pixelCount : 0.0;

    // Normalize to 0-1
    final normalized = avgBrightness / 255.0;

    // Score based on distance from optimal range (0.4-0.7)
    // Perfect score at 0.55 (middle of range)
    const optimalBrightness = 0.55;
    final distance = (normalized - optimalBrightness).abs();

    // Score decreases as distance from optimal increases
    final score = 1.0 - (distance * 2.5).clamp(0.0, 1.0);

    return score.clamp(0.0, 1.0);
  }

  /// Calculate contrast score using standard deviation
  /// Higher standard deviation = better contrast
  double _calculateContrast(img.Image image) {
    // First pass: calculate mean
    double totalBrightness = 0.0;
    int pixelCount = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final brightness = (pixel.r + pixel.g + pixel.b) / 3;
        totalBrightness += brightness;
        pixelCount++;
      }
    }

    final mean = pixelCount > 0 ? totalBrightness / pixelCount : 0.0;

    // Second pass: calculate variance
    double sumOfSquaredDiffs = 0.0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final brightness = (pixel.r + pixel.g + pixel.b) / 3;
        final diff = brightness - mean;
        sumOfSquaredDiffs += diff * diff;
      }
    }

    final variance = pixelCount > 0 ? sumOfSquaredDiffs / pixelCount : 0.0;
    final stdDev = math.sqrt(variance);

    // Normalize to 0-1 range
    // Typical standard deviation ranges from 0 to ~80 for mobile images
    final normalized = stdDev / (stdDev + 40);

    return normalized.clamp(0.0, 1.0);
  }
}
