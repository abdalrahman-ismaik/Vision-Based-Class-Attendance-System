# Face Detection Debug Logging Guide

**Date:** October 20, 2025  
**Purpose:** Comprehensive logging to diagnose face detection issues

---

## 🔍 How to Use This Debug Logging

### 1. Hot Restart the App
```
Press: Ctrl+Shift+F5
```

### 2. Open Terminal/Logcat
Make sure you can see the Flutter debug console output

### 3. Navigate to Pose Capture Screen
- Fill student info
- Click "Next"

### 4. Analyze the Logs

---

## 📊 What the Logs Show

### Startup Logs

#### Camera Initialization
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📷 CAMERA INITIALIZED
   Aspect Ratio: 0.75
   Preview Size: Size(480.0, 640.0)
   Sensor Orientation: 270°
   Front Camera: true
   Embedded Mode: false
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**What to Check:**
- ✅ `Sensor Orientation: 270°` - Typical for front camera
- ✅ `Front Camera: true` - Using front camera
- ✅ `Preview Size` - Should be reasonable resolution

#### Image Conversion (First Frame)
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📸 IMAGE CONVERSION (Frame: 2)
   Size: 640x480
   Format: InputImageFormat.nv21 (ImageFormatGroup.nv21)
   Sensor Orientation: 270°
   Required Rotation: InputImageRotation.rotation90deg
   BytesPerRow: 640 (original: 656)
   Front Camera: true
   Total Bytes: 460800
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**What to Check:**
- ✅ `Sensor: 270°` + `Rotation: rotation90deg` = CORRECT!
- ❌ `Sensor: 270°` + `Rotation: rotation270deg` = WRONG!
- ✅ `Format: nv21` - Most common on Android
- ✅ `BytesPerRow: 640` (matching width) - Correct for NV21

---

### Detection Logs

#### Successful Detection
```
✅ Frame 10: 1 face(s) detected (took 142ms)
   Face 1:
      Position: (120, 85)
      Size: 280x320 = 23.4% of frame
      Angles: Yaw=-2.3°, Pitch=5.1°, Roll=-1.2°
      Eyes: Left=95%, Right=92%
      Tracking ID: 123
   🎯 Validating for pose: PoseType.frontal
      Raw angles: Yaw=2.3°, Pitch=5.1°
      Adjusted angles: Yaw=-2.3°, Pitch=5.1°
      Frontal check: true && true = true
      Face size: 23.4% (need ≥15%)
      Eye openness: Left=95%, Right=92%
      ✅ VALID POSE!
      ⏱️  Holding: 1234ms / 2000ms
```

**What This Means:**
- ✅ Face detected successfully
- ✅ Detection took 142ms (good performance)
- ✅ Face is 23.4% of frame (good size)
- ✅ Angles are within frontal range
- ✅ Eyes are open
- ✅ Holding pose, will capture at 2000ms

#### No Face Detected
```
🔍 Frame 15: NO FACES DETECTED (took 98ms)
   ⚠️  State: No face → instruction updated
```

**Possible Reasons:**
1. **Face not in frame** - Move face into view
2. **Face too small** - Move closer to camera
3. **Poor lighting** - Improve lighting conditions
4. **Wrong orientation** - Check rotation logs
5. **Occlusion** - Remove masks, hands from face

#### Face Detected But Invalid Pose
```
✅ Frame 20: 1 face(s) detected (took 135ms)
   Face 1:
      Position: (105, 92)
      Size: 250x285 = 19.8% of frame
      Angles: Yaw=35.7°, Pitch=3.2°, Roll=-2.1°
      Eyes: Left=88%, Right=91%
   🎯 Validating for pose: PoseType.frontal
      Raw angles: Yaw=-35.7°, Pitch=3.2°
      Adjusted angles: Yaw=35.7°, Pitch=3.2°
      Frontal check: false && true = false
      ❌ INVALID: Angles outside range (±15°)
```

**What This Means:**
- ✅ Face detected successfully
- ❌ But Yaw angle (35.7°) is too far (need ±15° for frontal)
- **Action:** Turn face more towards camera

#### Face Lost After Being Valid
```
✅ Frame 25: 1 face(s) detected (took 128ms)
   ...
   🎯 Validating for pose: PoseType.frontal
      ✅ VALID POSE!
      ⏱️  Holding: 850ms / 2000ms

🔍 Frame 30: NO FACES DETECTED (took 95ms)
   ⚠️  State: No face → instruction updated

✅ Frame 35: 1 face(s) detected (took 140ms)
   ...
   ❌ INVALID: Angles outside range (±15°)
   ⚠️  Lost valid pose, resetting timer
```

**What This Means:**
- Face was valid and holding
- Then lost detection (frame 30)
- Found again but no longer valid
- Timer was reset - need to hold again from start

---

## 🐛 Common Issues and What Logs Show

### Issue 1: Rotation Wrong (Images Upside Down)

**Bad Logs:**
```
📸 IMAGE CONVERSION
   Sensor Orientation: 270°
   Required Rotation: InputImageRotation.rotation270deg  ❌ WRONG!
   
🔍 Frame 10: NO FACES DETECTED
🔍 Frame 15: NO FACES DETECTED
🔍 Frame 20: NO FACES DETECTED
```

**Good Logs:**
```
📸 IMAGE CONVERSION
   Sensor Orientation: 270°
   Required Rotation: InputImageRotation.rotation90deg  ✅ CORRECT!
   
✅ Frame 10: 1 face(s) detected
✅ Frame 15: 1 face(s) detected
```

**Fix:** Rotation logic has been corrected in the code

---

### Issue 2: Face Too Small

**Logs:**
```
✅ Frame 10: 1 face(s) detected (took 125ms)
   Face 1:
      Size: 95x110 = 8.2% of frame
      ...
   🎯 Validating for pose: PoseType.frontal
      Face size: 8.2% (need ≥15%)
      ❌ INVALID: Face too small (8.2% < 15%)
```

**Action:** Move closer to camera

---

### Issue 3: Poor Lighting

**Logs:**
```
🔍 Frame 10: NO FACES DETECTED (took 180ms)
🔍 Frame 15: NO FACES DETECTED (took 195ms)
🔍 Frame 20: NO FACES DETECTED (took 210ms)
```

**Signs:**
- Detection times increase (struggling)
- Consistent "NO FACES DETECTED"
- No faces found at all

**Action:** 
- Improve lighting
- Move to brighter area
- Avoid backlighting

---

### Issue 4: Intermittent Detection

**Logs:**
```
✅ Frame 10: 1 face(s) detected
🔍 Frame 15: NO FACES DETECTED
✅ Frame 20: 1 face(s) detected
🔍 Frame 25: NO FACES DETECTED
✅ Frame 30: 1 face(s) detected
```

**Possible Causes:**
1. **Motion blur** - Hold still
2. **Borderline lighting** - Improve lighting
3. **Face partially out of frame** - Center face
4. **Processing lag** - Check detection times

**Check:**
- Are detection times > 200ms? (Too slow)
- Is face size varying a lot? (Movement)
- Are angles changing rapidly? (Not holding still)

---

### Issue 5: Eyes Not Open (Frontal Pose Only)

**Logs:**
```
✅ Frame 10: 1 face(s) detected (took 140ms)
   Face 1:
      Eyes: Left=15%, Right=18%
   🎯 Validating for pose: PoseType.frontal
      Eye openness: Left=15%, Right=18%
      ❌ INVALID: Eyes not open enough (need ≥30%)
```

**Action:** Open eyes wider (only matters for frontal pose)

---

## 📈 Performance Indicators

### Good Performance
```
Detection Times:
✅ Frame 10: (took 95ms)
✅ Frame 15: (took 108ms)
✅ Frame 20: (took 112ms)
✅ Frame 25: (took 98ms)

Average: ~100ms (good!)
```

### Poor Performance
```
Detection Times:
⚠️ Frame 10: (took 245ms)
⚠️ Frame 15: (took 280ms)
⚠️ Frame 20: (took 310ms)
⚠️ Frame 25: (took 295ms)

Average: ~280ms (too slow - may cause lag)
```

**If detection times > 200ms:**
1. Device may be slow
2. Consider reducing frame processing rate
3. Check if other apps are running

---

## 🔧 What to Share for Debugging

If you still have issues, copy these log sections:

### 1. Camera Initialization Logs
```
The full ━━━━ CAMERA INITIALIZED ━━━━ section
```

### 2. Image Conversion Logs
```
The full ━━━━ IMAGE CONVERSION ━━━━ section
```

### 3. Detection Pattern (20-30 consecutive frames)
```
All logs from Frame X to Frame X+30
Including:
- Detection results (✅ or 🔍)
- Detection times
- Face details
- Validation results
```

### 4. Specific Error Messages
```
Any ❌ error messages with stack traces
```

---

## 🎯 Expected Good Logs

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📷 CAMERA INITIALIZED
   Sensor Orientation: 270°
   Front Camera: true
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📸 IMAGE CONVERSION (Frame: 2)
   Sensor Orientation: 270°
   Required Rotation: InputImageRotation.rotation90deg  ✅
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Frame 10: 1 face(s) detected (took 125ms)
   Face 1:
      Size: 280x320 = 23.4% of frame
      Angles: Yaw=-2.3°, Pitch=5.1°, Roll=-1.2°
      ✅ VALID POSE!
      ⏱️  Holding: 0ms / 2000ms

✅ Frame 15: 1 face(s) detected (took 118ms)
   Face 1:
      Size: 282x322 = 23.7% of frame
      Angles: Yaw=-1.8°, Pitch=4.8°, Roll=-0.9°
      ✅ VALID POSE!
      ⏱️  Holding: 512ms / 2000ms

✅ Frame 20: 1 face(s) detected (took 122ms)
   Face 1:
      Size: 281x321 = 23.5% of frame
      Angles: Yaw=-2.1°, Pitch=5.3°, Roll=-1.1°
      ✅ VALID POSE!
      ⏱️  Holding: 1024ms / 2000ms

✅ Frame 25: 1 face(s) detected (took 115ms)
   Face 1:
      Size: 280x320 = 23.4% of frame
      Angles: Yaw=-2.4°, Pitch=5.0°, Roll=-1.0°
      ✅ VALID POSE!
      ⏱️  Holding: 1536ms / 2000ms

✅ Frame 30: 1 face(s) detected (took 128ms)
   Face 1:
      Size: 281x321 = 23.5% of frame
      Angles: Yaw=-2.2°, Pitch=5.2°, Roll=-1.1°
      ✅ VALID POSE!
      ⏱️  Holding: 2048ms / 2000ms
      📸 TRIGGERING AUTO-CAPTURE!
```

---

**Now test with:** `Ctrl+Shift+F5` and watch the logs! 📊
