# Camera Preview - Visual Guide

## Understanding Camera Preview Orientation

### The Problem
Camera sensors capture in **landscape orientation** by default, even when the phone is in portrait mode.

```
Camera Sensor Output (Landscape):
┌────────────────────────────┐
│                            │
│        1920 x 1080         │
│                            │
└────────────────────────────┘
   Width: 1920, Height: 1080
```

But we want to display in **portrait mode**:

```
Phone Display (Portrait):
┌──────────────┐
│              │
│              │
│              │
│   1080 x     │
│   1920       │
│              │
│              │
│              │
└──────────────┘
Width: 1080, Height: 1920
```

## The Solution

### Step 1: Get Preview Size
```dart
final size = camera.value.previewSize!;
// Returns: Size(1920, 1080) - ALWAYS in landscape
```

### Step 2: Calculate Portrait Aspect Ratio
```dart
final aspectRatio = size.height / size.width;
// 1080 / 1920 = 0.5625
```

### Step 3: Apply to CameraPreview
```dart
AspectRatio(
  aspectRatio: aspectRatio,  // 0.5625
  child: CameraPreview(camera),
)
```

## Before vs After

### ❌ Before (Incorrect Implementation)
```
Container with CameraPreview (stretched):
┌──────────────┐
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓│ ← Stretched vertically
│▓▓▓ FACE ▓▓▓▓▓│ ← Face looks elongated
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓│ ← Not natural
└──────────────┘

Issues:
- Preview fills container by stretching
- Face appears elongated/compressed
- Face detection boxes misaligned
- Unnatural appearance
```

### ✅ After (Correct Implementation)
```
Container with proper AspectRatio:
┌──────────────┐
│              │ ← Empty space (black bars)
├──────────────┤
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓│ ← Correct aspect ratio
│▓▓  FACE  ▓▓▓│ ← Face looks natural
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓│ ← Proper proportions
├──────────────┤
│              │ ← Empty space (black bars)
└──────────────┘

Benefits:
- Preview maintains native aspect ratio
- Face appears natural and proportional
- Face detection boxes align perfectly
- Professional appearance
```

## Face Detection Overlay Alignment

### Coordinate Conversion

#### Camera Image Coordinates (Landscape)
```
     0                1920
  0  ┌────────────────────┐
     │                    │
     │      FACE          │
     │    (x, y, w, h)    │
     │                    │
1080 └────────────────────┘
```

#### Display Coordinates (Portrait)
We need to swap X ↔ Y coordinates:

```dart
// Original face bounding box from ML Kit
boundingBox.left   // X in landscape
boundingBox.top    // Y in landscape

// Convert to portrait coordinates
left = boundingBox.top * scaleX      // Swap!
top = boundingBox.left * scaleY      // Swap!
```

#### With Front Camera Mirroring
```
Portrait Display:        After Mirroring:
┌────────┐              ┌────────┐
│   ○    │              │    ○   │
│  /|\   │     →        │   /|\  │
│  / \   │   Mirror     │  / \   │
└────────┘              └────────┘
  (Original)           (Mirrored for natural view)
```

## Layout Structure

### Embedded Mode
```
Container (rounded corners)
└─ ClipRRect
   └─ LayoutBuilder
      └─ Stack
         ├─ Center
         │  └─ Container (constrained)
         │     └─ CameraPreview (correct aspect ratio)
         │
         ├─ Face Overlay (aligned)
         ├─ Status Bar (top)
         ├─ Validation Indicator (center)
         ├─ Instructions (bottom)
         └─ Capture Button (bottom center)
```

### Fullscreen Mode
```
Scaffold
└─ Column
   ├─ Progress Bar
   ├─ Expanded (Camera Area)
   │  └─ Container (bordered)
   │     └─ ClipRRect
   │        └─ Stack
   │           ├─ Center
   │           │  └─ CameraPreview (correct aspect ratio)
   │           ├─ Face Overlay
   │           └─ Pose Guide
   └─ Expanded (Instructions & Button)
```

## Key Principles

### 1. Never Stretch the Preview
```dart
// ❌ Wrong - Stretches the preview
Container(
  width: double.infinity,
  height: double.infinity,
  child: CameraPreview(camera),  // Will stretch!
)

// ✅ Correct - Maintains aspect ratio
Center(
  child: AspectRatio(
    aspectRatio: size.height / size.width,
    child: CameraPreview(camera),
  ),
)
```

### 2. Always Check isInitialized
```dart
// ❌ Wrong - Might crash
CameraPreview(_cameraController!)

// ✅ Correct - Safe
if (_cameraController?.value.isInitialized ?? false) {
  CameraPreview(_cameraController!)
} else {
  CircularProgressIndicator()
}
```

### 3. Handle Coordinate Systems
```dart
// ❌ Wrong - Direct mapping doesn't work
left = boundingBox.left * scaleX  // Incorrect for portrait

// ✅ Correct - Swap for portrait display
left = boundingBox.top * scaleX   // Swap X ↔ Y
top = boundingBox.left * scaleY
```

## Testing Checklist

- [ ] Camera preview maintains aspect ratio
- [ ] No stretching or compression
- [ ] Face detection boxes align with faces
- [ ] Front camera shows mirrored view (natural)
- [ ] Works in embedded mode
- [ ] Works in fullscreen mode
- [ ] Handles different screen sizes
- [ ] Black bars appear if needed (expected behavior)
- [ ] Camera initializes properly
- [ ] Face overlay updates in real-time

## Common Mistakes to Avoid

1. **Using full container size**: Causes stretching
2. **Not swapping coordinates**: Misaligned overlays
3. **Forgetting to mirror**: Unnatural front camera view
4. **Not using AspectRatio widget**: Distorted preview
5. **Ignoring previewSize orientation**: Wrong calculations

## Result

With these changes, the camera preview will:
- Display at the correct aspect ratio
- Show faces naturally without distortion
- Align face detection overlays perfectly
- Work consistently across all modes and devices
- Follow Flutter camera package best practices
