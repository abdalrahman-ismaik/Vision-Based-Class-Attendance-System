# Roll Angle Validation Fix

**Date:** October 20, 2025  
**Issue:** Face detection working but losing detection frequently  
**Root Cause:** Missing Roll angle (head tilt) validation

---

## 🔍 Problem Analysis

### What the Logs Showed

When analyzing the detection logs with the user holding the phone **vertically in portrait mode**, we observed:

```
Frame 86:  Roll=24.9° ❌ Eyes not open (but Roll too high!)
Frame 94:  Roll=23.0° ❌ Angles outside range
Frame 104: Roll=27.3° ❌ Angles outside range
Frame 120: Roll=22.0° ❌ Angles outside range
Frame 156: Roll=29.6° ✅ VALID (but Roll almost 30°!)
Frame 172: Roll=19.4° ❌ Pitch too high
Frame 186: Roll=30.5° ❌ Angles outside range
```

### The Critical Issue

**Roll angle represents head tilt (tilting your ear toward your shoulder).**

- When holding phone **vertical** → head should also be **upright** (Roll ≈ 0°)
- User's head was tilted **20-30°** to the side
- Previous validation **completely ignored Roll** - only checked Yaw (left/right) and Pitch (up/down)
- This caused intermittent detection because:
  - Sometimes user's head was tilted less → valid pose detected
  - Then user shifted → head tilted more → pose became invalid
  - User thought they were holding pose correctly, but head tilt was the problem

---

## ✅ The Fix

### 1. Added Roll Angle Validation

**Location:** `guided_pose_capture.dart` → `_validateCurrentPose()`

```dart
// Extract Roll angle from face detection
final rawEulerZ = face.headEulerAngleZ ?? 0; // Roll angle
final eulerZ = rawEulerZ; // Roll doesn't need camera adjustment

debugPrint('   🎯 Validating for pose: $currentPose');
debugPrint('      Raw angles: Yaw=$rawEulerY°, Pitch=$rawEulerX°, Roll=$rawEulerZ°');
debugPrint('      Adjusted angles: Yaw=$eulerY°, Pitch=$eulerX°, Roll=$eulerZ°');

// CRITICAL: Always check Roll angle first (head tilt)
// Roll should be close to 0° for all poses (head upright when phone is vertical)
if (eulerZ.abs() > 20) {
  debugPrint('      ❌ INVALID: Head tilted too much (Roll=${eulerZ.toStringAsFixed(1)}°, need ≤20°)');
  return false; // Early return - no need to check other angles
}
```

**Why 20° threshold?**
- 0° = perfectly upright head
- ±10° = slight natural tilt (acceptable)
- ±20° = maximum acceptable tilt
- >20° = clearly tilted head (needs correction)

### 2. Updated User Instructions

**Short instructions** (shown during capture):
```dart
'Look straight at camera - keep head upright'
'Turn left - keep head upright'
'Turn right - keep head upright'
'Tilt up slightly - keep head upright'
'Tilt down slightly - keep head upright'
```

**Detailed instructions** (shown when pose invalid):
```dart
case PoseType.frontal:
  return 'Keep your head straight and upright. Look directly at the camera. 
          Don\'t tilt your head to either side.';

case PoseType.leftProfile:
  return 'Turn your head to the left (your left) until you show your profile. 
          Keep your head upright - don\'t tilt.';
// ... and so on
```

### 3. Enhanced Logging

Now logs include Roll angle in every detection:
```
✅ Frame 156: 1 face(s) detected (took 48ms)
   Face 1:
      Position: (48, 334)
      Size: 664x663 = 47.8% of frame
      Angles: Yaw=6.9°, Pitch=16.2°, Roll=22.0°  ← NOW SHOWS ROLL!
      Eyes: Left=77%, Right=71%
      Tracking ID: 10
   🎯 Validating for pose: PoseType.frontal
      Raw angles: Yaw=6.9°, Pitch=16.2°, Roll=22.0°  ← RAW ROLL
      Adjusted angles: Yaw=-6.9°, Pitch=16.2°, Roll=22.0°  ← ADJUSTED ROLL
      ❌ INVALID: Head tilted too much (Roll=22.0°, need ≤20°)  ← CLEAR REASON
```

---

## 🎯 Understanding Roll vs Yaw vs Pitch

### Visual Guide (Phone Held Vertically)

```
YAW (Left/Right Turn):
         0°
    -90°  ↕  +90°
   (turn    (turn
    left)   right)

PITCH (Up/Down Tilt):
         -45° (looking up)
           ↕
          0° (straight)
           ↕
         +45° (looking down)

ROLL (Head Tilt):
    -45° (tilt     +45° (tilt
     left ear       right ear
     to shoulder)   to shoulder)
         ↕
        0° (upright)
```

### Why Roll Matters

**Before fix:**
- ✅ Yaw within range
- ✅ Pitch within range
- ❌ **Roll ignored** → head tilted 25° accepted as valid!
- Result: Inconsistent detection, user confused

**After fix:**
- ✅ Yaw within range
- ✅ Pitch within range
- ✅ **Roll checked** → head must be upright
- Result: Only truly correct poses accepted

---

## 📊 Expected Impact

### Before Fix
```
Detection pattern: ✅🔍✅🔍🔍✅🔍🔍✅
(Intermittent - depends on head tilt at that moment)
```

### After Fix
```
Detection pattern: 🔍🔍🔍✅✅✅✅✅✅
(Consistent - once head is upright, stays valid)
```

### User Experience

**Before:**
- "Why does it keep losing my face?"
- "I'm holding still but it says invalid!"
- "What am I doing wrong?"

**After:**
- "Oh, I need to keep my head upright!"
- Clear feedback: "Head tilted too much (Roll=25°, need ≤20°)"
- Consistent validation once head is positioned correctly

---

## 🔧 What Changed

### Files Modified
1. **`guided_pose_capture.dart`**
   - Added Roll angle extraction and validation
   - Updated all pose instructions to mention "keep head upright"
   - Enhanced logging to show Roll angle
   - Added early return if Roll > 20°

### Testing Instructions

1. **Hot restart the app** (Ctrl+Shift+F5 - CRITICAL!)
2. Navigate to pose capture screen
3. Hold phone vertically in portrait mode
4. Try to capture frontal pose

**Test scenarios:**
- ✅ **Head upright (Roll ≈ 0°)**: Should detect and validate ✅
- ❌ **Head tilted right (Roll ≈ 25°)**: Should show "Head tilted too much" ❌
- ❌ **Head tilted left (Roll ≈ -25°)**: Should show "Head tilted too much" ❌
- ✅ **Slight natural tilt (Roll ≈ 10°)**: Should still validate ✅

**What to look for in logs:**
```
✅ Frame X: 1 face(s) detected
   Angles: Yaw=5°, Pitch=3°, Roll=8°  ← Roll should be <20°
   ✅ VALID POSE!

❌ Frame Y: 1 face(s) detected
   Angles: Yaw=3°, Pitch=-2°, Roll=25°  ← Roll too high!
   ❌ INVALID: Head tilted too much (Roll=25.0°, need ≤20°)
```

---

## 📝 Summary

**Root Cause:** Validation logic was incomplete - missing Roll angle check

**Fix Applied:**
1. ✅ Added Roll angle validation (must be ≤20°)
2. ✅ Updated user instructions to emphasize "keep head upright"
3. ✅ Enhanced logging to show Roll angle and specific failure reasons

**Expected Result:**
- More consistent detection once head is positioned correctly
- Clear feedback when head is tilted
- Better user guidance on what "correct pose" means

**Next Steps:**
1. Hot restart app
2. Test with head upright vs tilted
3. Observe logs showing Roll angle validation
4. Confirm detection is now consistent when head is upright

---

## 🔗 Related Documents
- `DEBUG_LOGGING_GUIDE.md` - How to interpret all log messages
- `FACE_DETECTION_DEBUG_REPORT.md` - Previous rotation fix
- `POSE_CAPTURE_COMPLETE_GUIDE.md` - Complete feature documentation
