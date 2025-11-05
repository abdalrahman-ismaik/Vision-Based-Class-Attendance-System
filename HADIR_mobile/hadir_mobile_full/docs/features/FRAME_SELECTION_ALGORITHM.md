# Frame Selection Algorithm - Technical Specification

**Status**: Proposed implementation for T036D (Fix Sharpness Calculation)  
**Created**: October 25, 2025  
**Purpose**: Replace current low-performing sharpness algorithm

---

## 🎯 Algorithm Overview

```
Input: 150 captured frames (30 frames × 5 poses)
Output: 5 selected frames (1 best frame per pose)
Time Budget: <2 seconds total on mid-range mobile device
```

---

## 🔬 Current Implementation Status

### What's Working ✅
- Brightness calculation (0.42-0.47 range observed)
- Contrast calculation (basic implementation)
- Frame grouping by pose type
- Selection logic with temporal diversity

### What's Broken 🔴
- **Sharpness scores**: Showing 0.00-0.01 (should be 0.3-0.8)
- **Root cause**: Likely YUV→RGB conversion quality or Laplacian parameters

---

## 📐 Proposed Algorithm Architecture

### Three-Stage Pipeline

```
Stage 1: Quick Pre-Filter (100ms)
├─ 150 frames → brightness check → 50-60 candidates
└─ Eliminates obviously bad frames fast

Stage 2: Detailed Scoring (800ms)
├─ 50 candidates → full quality analysis → 30 scored frames
└─ Sharpness, brightness, contrast, face area

Stage 3: Final Selection (100ms)
├─ 30 scored frames → best per pose → 5 selected frames
└─ Ensures temporal diversity (≥100ms apart)

Total: ~1 second
```

---

## 🧪 Quality Metrics Explained

### 1. Sharpness (Laplacian Variance) - Weight: 50%

**Theory**: Sharp images have high variance in pixel gradients (edges are well-defined)

```dart
double _calculateSharpness(img.Image image) {
  final gray = img.grayscale(image);
  
  double sum = 0;
  double sumSq = 0;
  int count = 0;
  
  // Sample every 4th pixel for speed
  for (int y = 1; y < gray.height - 1; y += 4) {
    for (int x = 1; x < gray.width - 1; x += 4) {
      // Laplacian kernel: 4*center - (top + bottom + left + right)
      final center = gray.getPixel(x, y).r;
      final top = gray.getPixel(x, y - 1).r;
      final bottom = gray.getPixel(x, y + 1).r;
      final left = gray.getPixel(x - 1, y).r;
      final right = gray.getPixel(x + 1, y).r;
      
      final laplacian = (4 * center - top - bottom - left - right).toDouble();
      
      sum += laplacian;
      sumSq += laplacian * laplacian;
      count++;
    }
  }
  
  // Variance = measure of sharpness
  final mean = sum / count;
  final variance = (sumSq / count) - (mean * mean);
  
  // Normalize to 0-1 (empirical max variance ~10000)
  return math.min(1.0, variance / 10000.0);
}
```

**Expected Results**:
- Sharp image: Variance = 8500 → Score = 0.85
- Blurry image: Variance = 1200 → Score = 0.12

**Current Issue**: All frames showing 0.00-0.01 variance

**Debugging Steps**:
1. Print raw variance values (before normalization)
2. Test on known sharp/blurry test images
3. Verify grayscale conversion working correctly
4. Check if RGB image quality sufficient after YUV conversion

---

### 2. Brightness (Optimal Range) - Weight: 25%

**Theory**: Optimal face images have average brightness in 100-200 range (out of 255)

```dart
double _calculateBrightness(img.Image image) {
  int sum = 0;
  int count = 0;
  
  // Sample every 4th pixel for speed
  for (int y = 0; y < image.height; y += 4) {
    for (int x = 0; x < image.width; x += 4) {
      final pixel = image.getPixel(x, y);
      sum += (pixel.r + pixel.g + pixel.b) ~/ 3;
      count++;
    }
  }
  
  final avgBrightness = sum / count;
  
  // Optimal brightness is 100-200
  // Score = 1.0 at 150, decreases toward extremes
  if (avgBrightness < 100) {
    return avgBrightness / 100.0;
  } else if (avgBrightness > 200) {
    return math.max(0.0, 1.0 - ((avgBrightness - 200) / 55.0));
  } else {
    // In optimal range
    return 1.0 - (avgBrightness - 150).abs() / 50.0;
  }
}
```

**Expected Results**:
- Dark room: Avg = 60 → Score = 0.60
- Good lighting: Avg = 150 → Score = 1.0
- Overexposed: Avg = 230 → Score = 0.45

**Current Status**: ✅ Working (scores 0.42-0.47 observed)

---

### 3. Contrast (Standard Deviation) - Weight: 15%

**Theory**: High contrast images have clear feature separation

```dart
double _calculateContrast(img.Image image) {
  int sum = 0;
  int sumSq = 0;
  int count = 0;
  
  // Sample every 4th pixel
  for (int y = 0; y < image.height; y += 4) {
    for (int x = 0; x < image.width; x += 4) {
      final pixel = image.getPixel(x, y);
      final intensity = (pixel.r + pixel.g + pixel.b) ~/ 3;
      sum += intensity;
      sumSq += intensity * intensity;
      count++;
    }
  }
  
  final mean = sum / count;
  final variance = (sumSq / count) - (mean * mean);
  final stdDev = math.sqrt(variance);
  
  // Normalize to 0-1 (good contrast ~50-70 std dev)
  return math.min(1.0, stdDev / 70.0);
}
```

**Expected Results**:
- Good contrast: StdDev = 60 → Score = 0.86
- Low contrast: StdDev = 20 → Score = 0.29

---

### 4. Face Area (Center Weighting) - Weight: 10%

**Theory**: Faces are typically centered in frame

```dart
double _estimateFaceArea(img.Image image) {
  final centerX = image.width ~/ 2;
  final centerY = image.height ~/ 2;
  final regionWidth = image.width ~/ 4;
  final regionHeight = image.height ~/ 4;
  
  int centerSum = 0;
  int edgeSum = 0;
  int centerCount = 0;
  int edgeCount = 0;
  
  // Compare center brightness vs edge brightness
  for (int y = 0; y < image.height; y += 8) {
    for (int x = 0; x < image.width; x += 8) {
      final pixel = image.getPixel(x, y);
      final intensity = (pixel.r + pixel.g + pixel.b) ~/ 3;
      
      if ((x - centerX).abs() < regionWidth && 
          (y - centerY).abs() < regionHeight) {
        centerSum += intensity;
        centerCount++;
      } else {
        edgeSum += intensity;
        edgeCount++;
      }
    }
  }
  
  final centerAvg = centerSum / centerCount;
  final edgeAvg = edgeSum / edgeCount;
  
  // Higher center/edge ratio suggests face presence
  final ratio = centerAvg / (edgeAvg + 1);
  return math.min(1.0, ratio / 2.0);
}
```

**Expected Results**:
- Face centered: Ratio = 1.8 → Score = 0.90
- Face off-center: Ratio = 0.9 → Score = 0.45

---

## ⚡ Performance Optimization Strategies

### 1. Multi-Stage Filtering Pipeline
```
150 frames → Quick Brightness Filter → 50-60 frames (100ms)
           → Detailed Scoring        → 30 frames    (800ms)
           → Final Selection         → 5 frames     (100ms)
Total: ~1 second
```

### 2. Pixel Sampling Strategy
- ✅ Every 4th pixel for sharpness (94% reduction)
- ✅ Every 4th pixel for brightness
- ✅ Every 8th pixel for face area
- Result: 16x faster with minimal accuracy loss

### 3. Parallel Processing (Optional)
```dart
Future<List<SelectedFrame>> selectOptimalFramesParallel(
  Map<String, List<CapturedFrame>> framesByPose,
) async {
  // Process all 5 poses simultaneously
  final futures = framesByPose.entries.map((entry) {
    return compute(_selectBestFrameIsolate, {
      'pose': entry.key,
      'frames': entry.value,
    });
  });
  
  return await Future.wait(futures);
}
```

---

## 🔧 Implementation Checklist

### Phase 1: Debug Current Implementation
- [ ] Read `lib/core/services/image_quality_analyzer.dart`
- [ ] Add logging for raw variance values (before normalization)
- [ ] Create test with known sharp/blurry images
- [ ] Validate grayscale conversion
- [ ] Check RGB image quality after YUV→RGB conversion

### Phase 2: Fix Sharpness Algorithm
- [ ] Identify root cause of low variance
- [ ] Adjust normalization factor (currently /10000.0)
- [ ] Consider alternative methods:
  - [ ] Gradient magnitude
  - [ ] FFT-based frequency analysis
  - [ ] OpenCV's Laplacian implementation
- [ ] Test on real captured frames
- [ ] Validate scores in expected 0.3-0.8 range

### Phase 3: Optimize Performance
- [ ] Profile current implementation
- [ ] Implement pixel sampling (every 4th pixel)
- [ ] Add quick pre-filter stage
- [ ] Test on low-end device (target <2s total)

### Phase 4: Integration
- [ ] Wire into frame selection service
- [ ] Add logging for selection decisions
- [ ] Create debug visualization showing quality scores
- [ ] Test end-to-end with preview screen

---

## 📊 Testing Strategy

### Unit Tests
```dart
// test/core/services/image_quality_analyzer_test.dart

test('Sharp image should score > 0.7', () {
  final sharpImage = _loadTestImage('sharp_face.jpg');
  final analyzer = ImageQualityAnalyzer();
  final metrics = analyzer.analyzeImage(sharpImage);
  
  expect(metrics.sharpness, greaterThan(0.7));
});

test('Blurry image should score < 0.3', () {
  final blurryImage = _loadTestImage('blurry_face.jpg');
  final analyzer = ImageQualityAnalyzer();
  final metrics = analyzer.analyzeImage(blurryImage);
  
  expect(metrics.sharpness, lessThan(0.3));
});
```

### Integration Tests
```dart
// integration_test/frame_selection_test.dart

testWidgets('Frame selection picks sharp over blurry', (tester) async {
  // Create test frames with known quality
  final frames = [
    CapturedFrame(imageData: sharpImage, ...),
    CapturedFrame(imageData: blurryImage, ...),
  ];
  
  final service = FrameSelectionService();
  final selected = await service.selectBestFrames(frames);
  
  // Should select sharp frame
  expect(selected.first.qualityScore, greaterThan(0.7));
});
```

---

## 🚨 Known Issues & Solutions

### Issue: Low Sharpness Scores (0.00-0.01)

**Hypothesis 1: YUV→RGB Conversion Quality**
```dart
// Test: Save RGB image to file and inspect manually
final rgbImage = _convertYUV420ToImage(cameraImage);
final file = File('/storage/debug_rgb_output.jpg');
await file.writeAsBytes(img.encodeJpg(rgbImage, quality: 95));
// Check image quality visually
```

**Hypothesis 2: Normalization Factor Too Large**
```dart
// Current: variance / 10000.0
// Try: variance / 1000.0 or variance / 500.0
return math.min(1.0, variance / 500.0); // Test different values
```

**Hypothesis 3: JPEG Compression Artifacts**
```dart
// Current: quality: 85
// Try: quality: 95 or save as PNG
final jpegBytes = img.encodeJpg(rgbImage, quality: 95);
```

**Hypothesis 4: Image Resolution Too Low**
```dart
// Check captured image dimensions
print('Image size: ${rgbImage.width}x${rgbImage.height}');
// If < 640x480, may need higher resolution capture
```

---

## 📈 Success Metrics

After implementing fixes, verify:

- ✅ Sharp frames score: 0.6-0.9 range
- ✅ Blurry frames score: 0.1-0.4 range
- ✅ Clear differentiation between quality levels
- ✅ Total processing time: <2 seconds for 150 frames
- ✅ Selected frames visually sharper than non-selected

---

## 🔗 References

- Laplacian Variance: Pech-Pacheco et al. (2000) - "Diatom autofocusing in brightfield microscopy"
- Image Quality Metrics: Wang & Bovik (2006) - "Modern Image Quality Assessment"
- Flutter Image Processing: `package:image` documentation
- YUV Color Space: ITU-R BT.601 standard

---

## 📝 Developer Notes

**Created by**: AI Assistant  
**Date**: October 25, 2025  
**Context**: Debugging low sharpness scores in HADIR mobile app frame selection  
**Next Steps**: Implement debugging phase, fix algorithm, integrate and test
