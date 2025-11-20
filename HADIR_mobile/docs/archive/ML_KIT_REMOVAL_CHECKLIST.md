# ML Kit Code Removal Checklist

## File: guided_pose_capture.dart

### Current Status
- ✅ ML Kit import removed (line 6)
- ⚠️ Has 29 compile errors due to undefined Face/FaceDetector types
- 📝 Need to remove ~1100 lines of ML Kit code

### Systematic Removal Plan

## 1. State Variables to REMOVE (Lines 40-95)

```dart
// ❌ REMOVE - Lines 41-50: FaceDetector
final FaceDetector _faceDetector = FaceDetector(
  options: FaceDetectorOptions(...),
);

// ❌ REMOVE - Line 70: Face list
List<Face> _detectedFaces = [];

// ❌ REMOVE - Line 71: Validation flag
bool _isPoseValid = false;

// ❌ REMOVE - Lines 74-78: Auto-capture timers
DateTime? _poseValidStartTime;
DateTime? _lastValidPoseTime;
Timer? _autoCaptureTimer;
static const _holdDuration = Duration(seconds: 1);
static const _gracePeriod = Duration(milliseconds: 500);

// ❌ REMOVE - Lines 82-85: Temporal smoothing
final List<bool> _validationHistory = [];
final List<int?> _trackingIdHistory = [];
static const _historyWindowSize = 5;
static const _minValidFrames = 3;

// ❌ REMOVE - Lines 90-95: Performance optimization
int _frameCount = 0;
static const _processEveryNthFrame = 2;
bool _isProcessingFrame = false;
DateTime? _lastProcessTime;
int? _sensorOrientation;
```

## 2. Methods to REMOVE

### A. _processCameraImage() - Lines 202-750 (~550 lines)
```dart
// ❌ REMOVE ENTIRE METHOD
void _processCameraImage(CameraImage image) async {
  // All face detection logic
  // Temporal smoothing logic
  // Validation logic
  // Auto-capture timer logic
}
```

### B. _convertCameraImage() - Lines 431-550 (~120 lines)
```dart
// ❌ REMOVE ENTIRE METHOD
InputImage? _convertCameraImage(CameraImage cameraImage) {
  // Camera image conversion for ML Kit
}
```

### C. _validateCurrentPose() - Lines 559-690 (~130 lines)
```dart
// ❌ REMOVE ENTIRE METHOD
bool _validateCurrentPose(List<Face> faces) {
  // Pose angle validation
  // Eye openness checks
  // Profile detection
}
```

### D. _calculateQualityScore() - Lines 691-735 (~45 lines)
```dart
// ❌ REMOVE ENTIRE METHOD
double _calculateQualityScore(Face face) {
  // Quality scoring based on face metrics
}
```

### E. _buildFaceOverlay() - Lines 1429-1445 (~15 lines)
```dart
// ❌ REMOVE ENTIRE METHOD
Widget _buildFaceOverlay() {
  // Face bounding box overlay
}
```

### F. MLKitFaceOverlayPainter class - Lines 1485-1600 (~115 lines)
```dart
// ❌ REMOVE ENTIRE CLASS
class MLKitFaceOverlayPainter extends CustomPainter {
  final List<Face> faces;
  // ... painting logic
}
```

## 3. Code Modifications NEEDED

### A. _initializeCamera() - Lines 141-200
```dart
// ✅ KEEP camera initialization
// ❌ REMOVE line ~200: await _cameraController!.startImageStream(_processCameraImage);
// Manual mode doesn't need image stream
```

### B. _captureFrame() - Lines 751-845
```dart
// ✅ KEEP method signature and structure
// ❌ REMOVE: await _cameraController!.stopImageStream();
// ❌ REMOVE: if (_detectedFaces.isEmpty) check
// ❌ REMOVE: final face = _detectedFaces.first;
// ❌ REMOVE: face detection data usage

// ✅ ADD: Video recording logic
await _cameraController!.startVideoRecording();
await Future.delayed(const Duration(seconds: 1));
final XFile videoFile = await _cameraController!.stopVideoRecording();

// ✅ MODIFY: Create SelectedFrame with placeholder data
// No face angles, no bounding box, use administrator confidence
```

### C. dispose() - Lines 1225-1250
```dart
// ✅ KEEP disposal of animation controllers and camera
// ❌ REMOVE: _faceDetector.close();
// ❌ REMOVE: _autoCaptureTimer?.cancel();
```

### D. _buildCaptureButton() or inline button - Line ~1360
```dart
// ❌ REMOVE: _isPoseValid check from onPressed
onPressed: _isCameraReady && !_isCapturing && _isPoseValid  // OLD
onPressed: _isCameraReady && !_isCapturing  // NEW

// ❌ REMOVE: conditional button color based on _isPoseValid
backgroundColor: _isCapturing
    ? Colors.red
    : _isPoseValid ? Colors.green : Colors.grey,  // OLD

backgroundColor: _isCapturing ? Colors.red : Colors.green,  // NEW
```

### E. build() or view methods - Lines 870-1450
```dart
// ❌ REMOVE: _buildFaceOverlay() call
// ❌ REMOVE: _buildPoseValidationIndicator() call (if exists)
// ✅ ADD: _buildInstructionPanel() with administrator guidance
// ✅ KEEP: _buildPoseGuide() for oval overlay
```

## 4. Search & Replace Operations

Run these searches to find all references that need updating:

### Search for:
- `FaceDetector` (1 result) → Remove entire FaceDetector initialization
- `Face ` (with space) (multiple results) → Remove all Face type usage
- `InputImage` (multiple results) → Remove all InputImage usage
- `_detectedFaces` (multiple results) → Remove all references
- `_isPoseValid` (multiple results) → Remove all references
- `_poseValidStartTime` (multiple results) → Remove all references
- `_autoCaptureTimer` (multiple results) → Remove all references
- `_validationHistory` (multiple results) → Remove all references
- `_trackingIdHistory` (multiple results) → Remove all references
- `_processCameraImage` (multiple results) → Remove method and all calls
- `_convertCameraImage` (multiple results) → Remove method and all calls
- `_validateCurrentPose` (multiple results) → Remove method and all calls
- `_calculateQualityScore` (multiple results) → Remove method and all calls
- `startImageStream` (1-2 results) → Remove (manual mode doesn't need stream)
- `stopImageStream` (1-2 results) → Remove (not using stream)

## 5. Verification Checklist

After removal, verify:
- [ ] No compile errors
- [ ] No `Face` type references
- [ ] No `FaceDetector` references
- [ ] No `InputImage` references
- [ ] No image stream usage
- [ ] Camera initialization works
- [ ] Capture button always enabled when ready
- [ ] Video recording works (startVideoRecording/stopVideoRecording)
- [ ] All 5 poses can be captured
- [ ] No crashes

## Expected Result

**Before**: 1610 lines  
**After**: ~500-600 lines  
**Removed**: ~1000-1100 lines

**Benefits**:
- Simpler, more maintainable code
- No false positives or detection issues
- Faster execution (no frame processing)
- Administrator has full control

## Quick Start Commands

```powershell
# 1. Update dependencies
cd "d:\Education\University\Fall 2025\COSC 330 - Intro to Artificial Intelligence\Project\HADIR\HADIR\hadir_mobile_full"
flutter pub get

# 2. Check errors after ML Kit code removal
flutter analyze lib/features/registration/presentation/widgets/guided_pose_capture.dart

# 3. Test build
flutter build apk --debug

# 4. Run on device/emulator
flutter run
```

## Notes

- Backup already created: `guided_pose_capture_mlkit_backup.dart`
- Can revert if needed: `Copy-Item guided_pose_capture_mlkit_backup.dart guided_pose_capture.dart`
- Focus on completing this TODAY per user requirement
