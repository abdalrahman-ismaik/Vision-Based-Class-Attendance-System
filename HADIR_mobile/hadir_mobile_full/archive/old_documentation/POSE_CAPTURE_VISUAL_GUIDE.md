# 5-Pose Guided Capture - Visual User Flow

**Quick visual guide showing how the pose capture works in HADIR Mobile**

---

## 📱 User Flow Overview

```
Start Registration
      ↓
Fill Student Info
      ↓
Click "Next"
      ↓
[Pose Capture Screen]
      ↓
Capture 5 Poses
      ↓
Complete!
```

---

## 🎬 Pose Capture Screen States

### State 1: Initializing Camera
```
┌─────────────────────────────────────────┐
│                                         │
│                                         │
│         ⏳ Initializing Camera...       │
│                                         │
│     Setting up face detection system   │
│                                         │
│                                         │
└─────────────────────────────────────────┘
```

### State 2: Pose 1 - Frontal Face
```
┌─────────────────────────────────────────┐
│ 🎯 Pose 1 of 5 | Frontal Face           │
│ Quality: -- | Confidence: --            │
├─────────────────────────────────────────┤
│                                         │
│              📷 Camera View             │
│           ┌─────────────────┐           │
│           │                 │           │
│           │    😊 Face      │           │
│           │   Detected      │           │
│           │                 │           │
│           └─────────────────┘           │
│                                         │
│          ⚪ Hold Still...               │
│                                         │
├─────────────────────────────────────────┤
│  📝 Look straight at the camera         │
│                                         │
│  Tips:                                  │
│  • Keep your face centered              │
│  • Ensure good lighting                 │
│  • Hold pose for 1.5 seconds            │
│                                         │
│          [🟢 Capture Button]            │
└─────────────────────────────────────────┘
```

### State 3: Detecting Pose (Wrong Angle)
```
┌─────────────────────────────────────────┐
│ 🎯 Pose 1 of 5 | Frontal Face           │
│ Quality: 72% | Confidence: 85%          │
├─────────────────────────────────────────┤
│              📷 Camera View             │
│           ┌─────────────────┐           │
│           │    🔄 Face      │           │
│           │   Turn Right    │           │
│           │                 │           │
│           └─────────────────┘           │
│                                         │
│          🟡 Adjust Position             │
│                                         │
├─────────────────────────────────────────┤
│  📝 Turn your head slightly to the left │
│                                         │
│  Current Status: Angle too far right   │
│                                         │
│          [⚪ Capture Button]            │
└─────────────────────────────────────────┘
```

### State 4: Pose Valid - Auto-capturing
```
┌─────────────────────────────────────────┐
│ 🎯 Pose 1 of 5 | Frontal Face           │
│ Quality: 94% | Confidence: 96%          │
├─────────────────────────────────────────┤
│              📷 Camera View             │
│           ┌─────────────────┐           │
│           │    ✅ Perfect!  │           │
│           │    😊 Face      │           │
│           │   Hold Still    │           │
│           └─────────────────┘           │
│                                         │
│     🟢 Hold Still... (1.2s/1.5s)       │
│          ████████░░░░                   │
│                                         │
├─────────────────────────────────────────┤
│  📝 Perfect! Capturing in a moment...   │
│                                         │
│          [🟢 Capture Button]            │
│           (Auto-capturing)              │
└─────────────────────────────────────────┘
```

### State 5: Capturing
```
┌─────────────────────────────────────────┐
│ 🎯 Pose 1 of 5 | Frontal Face           │
│ Quality: 94% | Confidence: 96%          │
├─────────────────────────────────────────┤
│              📷 Camera View             │
│           ┌─────────────────┐           │
│           │    📸 Flash!    │           │
│           │   Capturing...  │           │
│           │                 │           │
│           └─────────────────┘           │
│                                         │
│          🔵 Capturing...                │
│                                         │
├─────────────────────────────────────────┤
│  📝 Processing capture...               │
│                                         │
│     ⏳ Please wait...                   │
│                                         │
└─────────────────────────────────────────┘
```

### State 6: Capture Success
```
┌─────────────────────────────────────────┐
│ 🎯 Pose 1 of 5 | Frontal Face           │
│ Quality: 94% | Confidence: 96%          │
├─────────────────────────────────────────┤
│              📷 Camera View             │
│           ┌─────────────────┐           │
│           │    🎉 Success!  │           │
│           │   😊 Face       │           │
│           │   Captured!     │           │
│           └─────────────────┘           │
│                                         │
│          ✅ Pose Captured!              │
│                                         │
├─────────────────────────────────────────┤
│  📝 Great! Moving to next pose...       │
│                                         │
│  ✅ Frontal Face - Complete             │
│  ⏭️  Next: Left Profile                 │
│                                         │
└─────────────────────────────────────────┘
```

### State 7: Pose 2 - Left Profile
```
┌─────────────────────────────────────────┐
│ 🎯 Pose 2 of 5 | Left Profile           │
│ Quality: -- | Confidence: --            │
├─────────────────────────────────────────┤
│              📷 Camera View             │
│           ┌─────────────────┐           │
│           │    👈 Face      │           │
│           │   Turn Left     │           │
│           │                 │           │
│           └─────────────────┘           │
│                                         │
│          ⚪ Position Your Face          │
│                                         │
├─────────────────────────────────────────┤
│  📝 Turn your head to the left          │
│                                         │
│  Tips:                                  │
│  • Show your left side profile          │
│  • Keep your left eye visible           │
│  • Turn about 30-45 degrees             │
│                                         │
│          [⚪ Capture Button]            │
└─────────────────────────────────────────┘
```

---

## 🎯 Complete 5-Pose Sequence

### Pose Progress Visualization

```
Pose 1: Frontal Face
┌─────┐
│ 😊  │  ✅ Captured (Quality: 94%)
└─────┘

Pose 2: Left Profile  
┌─────┐
│ 😊👈│  ✅ Captured (Quality: 91%)
└─────┘

Pose 3: Right Profile
┌─────┐
│👉😊 │  ✅ Captured (Quality: 92%)
└─────┘

Pose 4: Looking Up
┌─────┐
│ 😊  │  ✅ Captured (Quality: 89%)
│  ⬆  │
└─────┘

Pose 5: Looking Down
┌─────┐
│  ⬇  │  ✅ Captured (Quality: 90%)
│ 😊  │
└─────┘
```

---

## 🎨 Visual Indicators

### Face Detection Overlays

#### No Face Detected
```
┌─────────────────┐
│                 │
│                 │
│    ❌ No Face   │
│    Detected     │
│                 │
│                 │
└─────────────────┘
```

#### Face Detected - Wrong Pose
```
┌─────────────────┐
│    🟡 Yaw: 45°  │
│  ┌──────────┐   │
│  │   🔄     │   │
│  │  Face    │   │
│  │  Found   │   │
│  └──────────┘   │
│  Adjust Position│
└─────────────────┘
```

#### Face Detected - Correct Pose
```
┌─────────────────┐
│    🟢 Yaw: 2°   │
│  ┌──────────┐   │
│  │   ✅     │   │
│  │  Perfect │   │
│  │  Pose!   │   │
│  └──────────┘   │
│  Hold Still 1.2s│
└─────────────────┘
```

---

## 🎬 Animation States

### Pulse Animation (When Ready to Capture)
```
Frame 1:        Frame 2:        Frame 3:        Frame 4:
   [🟢]            [🟢]            [🟢]            [🟢]
   Small          Medium           Large          Medium
```

### Progress Bar (During Hold)
```
0.0s:  ░░░░░░░░░░░░  (0%)
0.5s:  ████░░░░░░░░  (33%)
1.0s:  ████████░░░░  (67%)
1.5s:  ████████████  (100%) → Capture!
```

### Capture Flash Animation
```
Frame 1:  Normal Brightness
Frame 2:  ⚡ Full White Flash
Frame 3:  Fade to Normal
Frame 4:  Normal
```

---

## 📊 Quality Indicators

### Quality Score Display

```
Excellent (>0.8):  🟢 ████████░░  94%
Good (0.6-0.8):    🟡 ██████░░░░  72%
Poor (<0.6):       🔴 ███░░░░░░░  45%
```

### Confidence Level Display

```
High (>0.9):       🟢 Confidence: 96%
Medium (0.7-0.9):  🟡 Confidence: 85%
Low (<0.7):        🔴 Confidence: 62%
```

---

## ⚠️ Error States

### No Camera Permission
```
┌─────────────────────────────────────────┐
│                                         │
│           📷 Camera Access              │
│                                         │
│    HADIR needs camera access to         │
│    capture your face for registration   │
│                                         │
│   [Grant Camera Permission Button]     │
│                                         │
└─────────────────────────────────────────┘
```

### Camera Error
```
┌─────────────────────────────────────────┐
│                                         │
│              ⚠️ Camera Error            │
│                                         │
│    Failed to initialize camera          │
│                                         │
│    Please check:                        │
│    • Camera is not being used           │
│    • Camera permissions are granted     │
│                                         │
│         [Retry Button]                  │
│                                         │
└─────────────────────────────────────────┘
```

### Multiple Faces Detected
```
┌─────────────────────────────────────────┐
│              📷 Camera View             │
│           ┌─────────────────┐           │
│           │  ⚠️ Multiple    │           │
│           │     Faces       │           │
│           │    Detected     │           │
│           └─────────────────┘           │
│                                         │
│  Please ensure only ONE person is       │
│  visible in the camera frame            │
│                                         │
└─────────────────────────────────────────┘
```

---

## 🎯 Completion Screen

### All Poses Captured
```
┌─────────────────────────────────────────┐
│                                         │
│              🎉 Success!                │
│                                         │
│        All 5 Poses Captured!            │
│                                         │
│  ┌───────┐ ┌───────┐ ┌───────┐        │
│  │ 😊    │ │ 😊👈  │ │👉😊   │        │
│  │ 94%   │ │ 91%   │ │ 92%   │        │
│  └───────┘ └───────┘ └───────┘        │
│                                         │
│  ┌───────┐ ┌───────┐                   │
│  │ 😊    │ │ 😊    │                   │
│  │ ⬆ 89% │ │ ⬇ 90% │                   │
│  └───────┘ └───────┘                   │
│                                         │
│  Average Quality: 91%                   │
│                                         │
│      [Continue to Next Step]            │
│                                         │
└─────────────────────────────────────────┘
```

---

## 💡 Tips for Best Results

### Lighting Conditions
```
✅ GOOD                    ❌ BAD
┌─────────────┐          ┌─────────────┐
│   ☀️ Bright  │          │  🌙 Too Dark │
│   lighting   │          │              │
│             │          │              │
│    😊       │          │    👤?       │
│             │          │              │
└─────────────┘          └─────────────┘

✅ Even light             ❌ Backlit
┌─────────────┐          ┌─────────────┐
│   💡→😊      │          │   😊←💡☀️   │
│   Front lit  │          │   Silhouette│
└─────────────┘          └─────────────┘
```

### Face Position
```
✅ GOOD                    ❌ BAD
┌─────────────┐          ┌─────────────┐
│             │          │             │
│    😊       │          │             │
│  Centered   │          │😊           │
│             │          │ Off-center  │
└─────────────┘          └─────────────┘

✅ Right size             ❌ Too far
┌─────────────┐          ┌─────────────┐
│   😊        │          │             │
│   Good      │          │    😊       │
│   size      │          │   Too small │
└─────────────┘          └─────────────┘
```

---

## 🎓 Development Mode

### Quick Test with Mock Data

```
┌─────────────────────────────────────────┐
│  🚀 Development Mode Active             │
│                                         │
│  Student ID: 1000 | 12345               │
│  Email: 100012345@ku.ac.ae              │
│                                         │
│  [Skip to Pose Capture] ⏭️              │
│                                         │
└─────────────────────────────────────────┘
```

**Enable with:**
```dart
// lib/main.dart
const bool kDevelopmentMode = true;
```

**Remember:** Use Hot Restart (Ctrl+Shift+F5) after enabling!

---

## 📚 Related Documentation

- [POSE_CAPTURE_COMPLETE_GUIDE.md](POSE_CAPTURE_COMPLETE_GUIDE.md) - Technical implementation details
- [DEV_MODE_QUICK_REFERENCE.md](DEV_MODE_QUICK_REFERENCE.md) - Development mode guide
- [CAMERA_PREVIEW_IMPLEMENTATION.md](CAMERA_PREVIEW_IMPLEMENTATION.md) - Camera setup details
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions

---

**Last Updated:** October 20, 2025  
**Version:** 1.0.0
