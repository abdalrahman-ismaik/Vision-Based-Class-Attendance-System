# Phantom Face Filter Fix

**Date:** October 20, 2025  
**Issue:** Green boxes appearing in weird locations outside the camera view  
**Root Cause:** ML Kit detecting tiny phantom faces (0.0-0.1% of frame) - false positives  
**Solution:** Filter out faces smaller than 5% of frame

---

## 🔴 The Problem

### What the Logs Showed

```
Frame 276: Size: 17x17 = 0.0% of frame
           Position: (30, 497) ← Edge of frame!
           
Frame 306: Size: 19x19 = 0.0% of frame  
           Position: (37, 502) ← Edge of frame!
           
Frame 354: Size: 33x34 = 0.1% of frame
           Position: (29, 475) ← Edge of frame!
```

**These are NOT real faces!** ML Kit is detecting:
- Background patterns
- Reflections
- Image noise/artifacts
- Tiny specks at edges of frame

**Size comparison:**
- **Real face:** 25-60% of frame (typical)
- **Phantom face:** 0.0-0.1% of frame (noise)

**This is why you see:**
- Green boxes in weird locations
- Boxes outside camera view
- Erratic box movement
- "Multiple faces" when you're alone

---

## ✅ The Fix

### Added Phantom Face Filter

**Location:** `guided_pose_capture.dart` → `_processCameraImage()`

```dart
// CRITICAL: Filter out tiny phantom faces (ML Kit false positives)
// Real faces should be at least 5% of frame (typically 15-60%)
// Tiny detections (0.0-0.1%) are background noise, reflections, or artifacts
final validFaces = faces.where((face) {
  final faceSize = _calculateFaceSize(face.boundingBox);
  return faceSize >= 0.05; // Minimum 5% of frame to be considered real
}).toList();

// Use validFaces instead of all detected faces
_detectedFaces = validFaces;
```

### Added Phantom Detection Logging

```dart
// Flag tiny phantom faces in logs
if (faceSize < 0.05) {
  debugPrint('   ⚠️  PHANTOM FACE - too small (0.1% < 5%) - will be filtered out');
}
```

---

## 📊 Face Size Thresholds

| Face Type | Size % | Status |
|-----------|--------|--------|
| **Real Face (close)** | 40-60% | ✅ Valid |
| **Real Face (normal)** | 20-40% | ✅ Valid |
| **Real Face (far)** | 15-20% | ✅ Valid (minimum) |
| **Too Far** | 5-15% | ❌ Too small |
| **Phantom/Noise** | 0-5% | ❌ **Filtered out** |

**The 5% threshold:**
- Above 5%: Likely a real face (or very close)
- Below 5%: Almost certainly noise/artifact
- 0.0-0.1%: Definitely phantom detection

---

## 🎯 Expected Behavior

### Before Fix

```
ML Kit detects: [RealFace 25%, PhantomFace 0.1%, PhantomFace 0.0%]
                     ↓
Overlay draws: 3 green boxes
                     ↓
User sees: Boxes in weird places, "Multiple faces" error
```

### After Fix

```
ML Kit detects: [RealFace 25%, PhantomFace 0.1%, PhantomFace 0.0%]
                     ↓
Filter: Keep faces ≥5% only
                     ↓
Result: [RealFace 25%]
                     ↓
Overlay draws: 1 green box on your face ✅
```

---

## 📝 What You'll See in Logs

### Phantom Detection (Filtered)

```
✅ Frame 276: 1 face(s) detected (took 44ms)
   Face 1:
      Position: (30, 497)
      Size: 17x17 = 0.0% of frame
      ⚠️  PHANTOM FACE - too small (0.0% < 5%) - will be filtered out
      
🔍 After filter: NO FACES (phantom filtered out)
   ⚠️  State: No face → instruction updated
```

### Real Face (Kept)

```
✅ Frame 142: 1 face(s) detected (took 34ms)
   Face 1:
      Position: (92, 449)
      Size: 595x595 = 38.4% of frame  ← Above 5% threshold
      Angles: Yaw=3.3°, Pitch=-3.7°, Roll=19.3°
      
✅ After filter: 1 valid face
   🎯 Validating for pose: PoseType.frontal
```

---

## 🧪 Testing

1. **Hot Restart** (Ctrl+Shift+F5) ⚠️ **CRITICAL!**
2. Navigate to pose capture screen
3. Position your face normally

**Expected:**
- ✅ Green box should now frame YOUR face correctly
- ✅ No more phantom boxes in weird locations
- ✅ No more "Multiple faces" when you're alone
- ✅ Stable, consistent face framing

**What logs should show:**
- Your real face: **25-40% of frame** ✅
- Phantom detections: **Flagged and filtered** ⚠️
- Result: **Only real face used** ✅

---

## 🔍 Why This Happened

### ML Kit's Behavior

ML Kit Face Detection is **very sensitive** by design:
- Detects faces at multiple scales
- Can detect partial faces
- Can detect face-like patterns (false positives)
- Optimized for recall (find all possible faces) over precision

**Common false positives:**
- Reflections in glasses/mirrors
- Background patterns (wallpaper, posters)
- Shadows or lighting artifacts
- Image compression artifacts
- Edge noise in low light

### Why Phantom Faces Are Tiny

ML Kit detected these at the **smallest scale** - barely a few pixels. Real faces, even far away, are much larger (15%+ of frame). Anything below 5% is almost certainly noise.

---

## ✅ Summary

**Problem:**
- ML Kit detecting tiny phantom faces (0.0-0.1% of frame)
- Overlay drawing green boxes for phantoms
- Boxes appearing in weird locations
- "Multiple faces" errors when alone

**Solution:**
- Filter faces: Keep only if ≥5% of frame
- Real faces are 15-60% (well above threshold)
- Phantom faces are 0.0-0.1% (well below threshold)
- Overlay now only draws real faces

**Impact:**
- ✅ Green box frames YOUR face correctly
- ✅ No more phantom boxes
- ✅ No more false "Multiple faces"
- ✅ Stable, predictable behavior

**Files Changed:**
- `guided_pose_capture.dart` - Added 5% size filter

**Next Step:**
- Hot restart and test - green box should work correctly now! 🚀
