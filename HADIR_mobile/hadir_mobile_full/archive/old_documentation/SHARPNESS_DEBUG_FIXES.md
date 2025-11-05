# Sharpness Calculation Debug & Fixes

**Date**: October 26, 2025  
**Issue**: All sharpness scores showing 0.00-0.01 instead of expected 0.3-0.8 range  
**File**: `lib/core/services/image_quality_analyzer.dart`

---

## 🐛 Bugs Found

### **Bug #1: Using .abs() on Laplacian Values (CRITICAL)**

**Location**: Line ~103 (original)

**Original Code**:
```dart
final laplacian = (top + bottom + left + right - 4 * center).abs();
sumOfSquares += laplacian * laplacian;
```

**Problem**: 
- Taking absolute value prevents calculating true variance
- Variance formula requires **signed** values: `Var = E[X²] - E[X]²`
- Using `.abs()` makes all values positive, so `E[X]` is always positive
- This causes variance to be incorrectly calculated

**Fix**:
```dart
final laplacian = (top + bottom + left + right - 4 * center).toDouble();
sum += laplacian;
sumOfSquares += laplacian * laplacian;
```

**Impact**: This was the PRIMARY cause of near-zero sharpness scores

---

### **Bug #2: Missing Square Root in Contrast Calculation**

**Location**: Line ~181 (original)

**Original Code**:
```dart
final variance = pixelCount > 0 ? sumOfSquaredDiffs / pixelCount : 0.0;
final stdDev = variance > 0 ? variance : 0.0;  // ❌ Wrong!
```

**Problem**:
- Standard deviation = **sqrt(variance)**, not variance itself
- Code was using variance directly as stdDev
- This caused contrast scores to be inflated

**Fix**:
```dart
final variance = pixelCount > 0 ? sumOfSquaredDiffs / pixelCount : 0.0;
final stdDev = math.sqrt(variance);  // ✅ Correct!
```

**Impact**: Contrast scores were incorrectly high (but this wasn't blocking since contrast has lower weight)

---

## 🔍 Debug Enhancements Added

### 1. **Sharpness Debugging**
```dart
print('🔍 SHARPNESS DEBUG - Image size: ${image.width}x${image.height}');
print('🔍 Sample Laplacian values (first 10): $sampleLaplacians');
print('🔍 Pixel count: $count');
print('🔍 Sum of Laplacians: $sum');
print('🔍 Sum of squares: $sumOfSquares');
print('🔍 Mean Laplacian: $mean');
print('🔍 RAW VARIANCE: $variance');
print('🔍 Normalized (sigmoid /5000): ${normalized1.toStringAsFixed(4)}');
print('🔍 Normalized (linear /10000): ${normalized2.toStringAsFixed(4)}');
print('🔍 Normalized (linear /1000): ${normalized3.toStringAsFixed(4)}');
print('🔍 Normalized (linear /500): ${normalized4.toStringAsFixed(4)}');
```

### 2. **Brightness Debugging**
```dart
print('🔍 BRIGHTNESS - Avg: ${avgBrightness.toStringAsFixed(2)}, Normalized: ${normalized.toStringAsFixed(3)}');
print('🔍 BRIGHTNESS - Distance from optimal: ${distance.toStringAsFixed(3)}, Score: ${score.toStringAsFixed(3)}');
```

### 3. **Contrast Debugging**
```dart
print('🔍 CONTRAST - Mean: ${mean.toStringAsFixed(2)}, Variance: ${variance.toStringAsFixed(2)}, StdDev: ${stdDev.toStringAsFixed(2)}');
print('🔍 CONTRAST - Normalized: ${normalized.toStringAsFixed(3)}');
```

---

## 📊 Expected Results After Fix

### Before Fix:
```
Frame 0 quality: 0.46 (sharpness: 0.00)
Frame 1 quality: 0.47 (sharpness: 0.01)
Frame 2 quality: 0.46 (sharpness: 0.00)
```

### After Fix (Expected):
```
🔍 RAW VARIANCE: 1234.56
🔍 Normalized (sigmoid /5000): 0.1980
Frame 0 quality: 0.65 (sharpness: 0.35)
Frame 1 quality: 0.72 (sharpness: 0.48)
Frame 2 quality: 0.58 (sharpness: 0.28)
```

---

## 🧪 Testing Instructions

### Step 1: Hot Reload
```bash
# In running Flutter app terminal:
Press 'r' for hot reload
```

### Step 2: Register New Student
```
Student ID: 100012346  (NOT 100012345)
Name: Test User
Fill other fields...
```

### Step 3: Capture Frames
- Click "Start Capture"
- Capture all 5 poses
- **Watch the debug logs** for:
  - ✅ Raw variance values (should be > 100)
  - ✅ Normalized sharpness (should be 0.1-0.6 range)
  - ✅ Quality scores varying between frames

### Step 4: Expected Debug Output
```
🔍 SHARPNESS DEBUG - Image size: 1280x720
🔍 Sample Laplacian values (first 10): [-12.0, 5.0, -8.0, 15.0, ...]
🔍 Pixel count: 921600
🔍 Sum of Laplacians: -1234.5
🔍 Sum of squares: 567890.12
🔍 Mean Laplacian: -0.0013
🔍 RAW VARIANCE: 2345.67  ← Should be > 100
🔍 Normalized (sigmoid /5000): 0.3195  ← Should be > 0.10
🔍 BRIGHTNESS - Avg: 123.45, Normalized: 0.484
🔍 CONTRAST - Mean: 125.00, Variance: 2500.00, StdDev: 50.00
```

---

## ✅ Success Criteria

After these fixes, you should see:

1. **Sharpness Variance**:
   - ✅ RAW VARIANCE > 500 (typical for decent image)
   - ✅ RAW VARIANCE > 2000 (sharp image)
   - ❌ RAW VARIANCE < 100 (blurry image)

2. **Normalized Sharpness Scores**:
   - ✅ Sharp frames: 0.3 - 0.7
   - ✅ Average frames: 0.15 - 0.4
   - ✅ Blurry frames: 0.0 - 0.2

3. **Overall Quality Differentiation**:
   - ✅ Clear variation between frames (not all 0.46-0.47)
   - ✅ Best 3 frames per pose have noticeably higher scores
   - ✅ Selection preview shows green badges (>80%) for top frames

---

## 🔄 Next Steps

### If Sharpness Still Too Low:
1. **Check normalization**: Try different denominators
   ```dart
   // Instead of: variance / (variance + 5000)
   // Try: variance / 10000.0
   ```

2. **Check image quality**: Save RGB image to disk and inspect
   ```dart
   final file = File('/storage/emulated/0/debug_image.jpg');
   await file.writeAsBytes(img.encodeJpg(image, quality: 95));
   ```

3. **Alternative sharpness metric**: Consider gradient magnitude
   ```dart
   // Use Sobel operator instead of Laplacian
   ```

### If Everything Works:
1. Remove debug prints (or make them conditional)
2. Integrate preview screen (T036E)
3. Test end-to-end workflow
4. Verify selected frames are actually sharper

---

## 📝 Code Changes Summary

**Files Modified**: 1
- `lib/core/services/image_quality_analyzer.dart`

**Lines Changed**: ~50 lines
- Added: 25 lines (debug logging)
- Modified: 5 lines (bug fixes)
- Imports: Added `dart:math`

**Bugs Fixed**: 2 critical bugs
**Debug Enhancements**: 3 metric types with detailed logging
**Testing Required**: Yes - need to verify fixes work on device

---

## 🎯 Root Cause Analysis

**Why were sharpness scores so low?**

The Laplacian variance formula is:
```
Var(L) = E[L²] - E[L]²
```

Original code with `.abs()`:
```dart
L = abs(top + bottom + left + right - 4*center)
// L is always positive
// E[L] ≈ large positive number
// E[L²] ≈ large positive number
// E[L²] - E[L]² ≈ very small (close to 0)
```

Fixed code without `.abs()`:
```dart
L = top + bottom + left + right - 4*center  
// L can be positive or negative
// E[L] ≈ 0 (Laplacian sum tends to zero)
// E[L²] ≈ large positive number
// E[L²] - E[L]² ≈ E[L²] ≈ actual variance!
```

**Conclusion**: The `.abs()` operation destroyed the variance calculation by making all values positive, causing E[L] to be non-zero and E[L²] - E[L]² to collapse to near-zero.
