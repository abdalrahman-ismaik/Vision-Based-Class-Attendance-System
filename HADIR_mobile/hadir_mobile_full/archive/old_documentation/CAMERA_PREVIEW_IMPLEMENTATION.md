# Camera Preview Implementation - Official Flutter Camera Package

## Overview
This document explains the camera preview implementation in the pose registration screen, following the official Flutter camera package documentation.

## Reference
- Official Package: https://pub.dev/packages/camera
- Version: ^0.10.5

## Key Changes Made

### 1. Camera Initialization (`_initializeCamera`)
Following the official camera package guidelines:
- Use `availableCameras()` to get available cameras
- Create `CameraController` with appropriate settings
- Wait for `initialize()` to complete before using
- Start image stream for real-time processing

```dart
final cameras = await availableCameras();
_cameraController = CameraController(
  camera,
  ResolutionPreset.high,
  enableAudio: false,
  imageFormatGroup: ImageFormatGroup.yuv420,
);
await _cameraController!.initialize();
```

### 2. Camera Preview Display (`_buildCameraPreview`)

#### Understanding Camera Preview Size
- **Important**: `previewSize` is ALWAYS in landscape orientation
- Example: `Size(1920, 1080)` even when phone is in portrait mode
- This means width > height in the previewSize

#### Aspect Ratio Calculation
For portrait display, we need to invert the aspect ratio:
```dart
final size = camera.value.previewSize!; // e.g., Size(1920, 1080)
final aspectRatio = size.height / size.width; // 1080/1920 = 0.5625
```

#### Proper Display Widget
```dart
Center(
  child: AspectRatio(
    aspectRatio: aspectRatio,
    child: CameraPreview(camera),
  ),
)
```

This ensures:
- ✅ No stretching or distortion
- ✅ Maintains camera's native aspect ratio
- ✅ Properly centered in the container
- ✅ Works in both embedded and fullscreen modes

### 3. Face Overlay Alignment (`MLKitFaceOverlayPainter`)

#### Coordinate System Conversion
Since the camera preview is landscape but display is portrait:
1. Swap X and Y coordinates from face detection
2. Adjust scaling factors accordingly

```dart
// Camera preview size is in landscape (width > height)
// But display is in portrait, so we swap dimensions
final double imageWidth = imageSize.height;
final double imageHeight = imageSize.width;

// Convert bounding box coordinates
double left = boundingBox.top * scaleX;    // Swap X and Y
double top = boundingBox.left * scaleY;
double right = boundingBox.bottom * scaleX;
double bottom = boundingBox.right * scaleY;
```

#### Front Camera Mirroring
For front-facing cameras, mirror the X coordinates:
```dart
if (isFrontCamera) {
  final temp = left;
  left = size.width - right;
  right = size.width - temp;
}
```

### 4. Layout Improvements

#### Embedded View
- Added `LayoutBuilder` to properly constrain camera preview
- Centered preview within container
- Applied `ClipRRect` for rounded corners
- Maintains aspect ratio regardless of container size

```dart
LayoutBuilder(
  builder: (context, constraints) {
    return Stack(
      children: [
        Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth,
              maxHeight: constraints.maxHeight,
            ),
            child: _buildCameraPreview(),
          ),
        ),
        // ... overlays
      ],
    );
  },
)
```

#### Fullscreen View
- Added `ClipRRect` for rounded corners on camera container
- Maintains proper aspect ratio within the border
- Face overlay uses `LayoutBuilder` for accurate positioning

## Benefits of This Implementation

1. **Correct Aspect Ratio**: Camera preview maintains its native aspect ratio without distortion
2. **Proper Alignment**: Face detection overlays align perfectly with detected faces
3. **Official Guidelines**: Follows Flutter camera package best practices
4. **Cross-Mode Support**: Works in both embedded and fullscreen modes
5. **Responsive Design**: Adapts to different screen sizes and orientations

## Testing Recommendations

1. **Test on Multiple Devices**: Different phones have different camera aspect ratios
2. **Portrait and Landscape**: Verify in both orientations
3. **Face Detection Alignment**: Check that bounding boxes align with actual faces
4. **Embedded vs Fullscreen**: Ensure consistent behavior in both modes

## Common Issues Resolved

### ❌ Before (Incorrect)
- Camera preview was stretched or compressed
- Face detection boxes didn't align with faces
- Different behavior in embedded vs fullscreen modes
- Aspect ratio not maintained

### ✅ After (Correct)
- Camera preview maintains native aspect ratio
- Face detection overlays perfectly aligned
- Consistent behavior across all modes
- Proper display on all screen sizes

## Code Structure

```
guided_pose_capture.dart
├── _initializeCamera()          # Camera setup following official docs
├── _buildCameraPreview()        # Proper aspect ratio handling
├── _buildEmbeddedView()         # Layout with LayoutBuilder
├── _buildFaceOverlay()          # Overlay with proper sizing
└── MLKitFaceOverlayPainter      # Coordinate conversion for overlay
    └── paint()                  # Handles landscape->portrait conversion
```

## References

- [Flutter Camera Package](https://pub.dev/packages/camera)
- [Camera Package Example](https://github.com/flutter/packages/tree/main/packages/camera/camera/example)
- [CameraController Documentation](https://pub.dev/documentation/camera/latest/camera/CameraController-class.html)
- [CameraPreview Widget](https://pub.dev/documentation/camera/latest/camera/CameraPreview-class.html)

## Notes

- Always check `isInitialized` before using camera controller
- Handle lifecycle events properly (dispose on pause, reinitialize on resume)
- Use appropriate resolution preset based on needs (we use `high` for face detection)
- Consider performance when processing frames (we throttle to every 8th frame)
