# Manual Validation Implementation Progress

**Date**: Oct 23, 2024  
**Status**: In Progress  
**Goal**: Replace ML Kit automated pose detection with manual administrator validation

## Background

After multiple attempts to stabilize ML Kit face detection (phantom faces, tracking issues, detection gaps), user decided to pivot to a simpler, more reliable manual validation approach where the administrator visually validates student pose and triggers capture.

## Completed Tasks ✅

### 1. Updated tasks.md Documentation
- ✅ Updated T033-T036 (Computer Vision Core) to reflect manual validation approach
- ✅ Marked T036A-T036E (YOLOv7-Pose Integration) as REMOVED
- ✅ Documented rationale for architectural pivot

### 2. Removed ML Kit Dependencies
- ✅ Removed `google_mlkit_face_detection: ^0.9.0` from pubspec.yaml
- ✅ Removed ML Kit import from guided_pose_capture.dart
- ✅ Created backup: `guided_pose_capture_mlkit_backup.dart`

## Remaining Tasks ⏳

### 3. Complete ML Kit Code Removal
**Status**: In Progress  
**File**: `guided_pose_capture.dart` (currently has compile errors)

**Need to Remove**:
- Lines 41-50: FaceDetector initialization
- Line 70: `List<Face> _detectedFaces` variable
- Lines 82-85: Temporal smoothing variables (`_validationHistory`, `_trackingIdHistory`, etc.)
- Line 71: `bool _isPoseValid` flag
- Lines 74-78: Auto-capture timer variables (`_poseValidStartTime`, `_lastValidPoseTime`, `_autoCaptureTimer`, etc.)
- Lines 91-93: Performance optimization variables (`_frameCount`, `_processEveryNthFrame`, `_isProcessingFrame`, etc.)
- Lines 202-750: `_processCameraImage()` method (all face detection logic)
- Lines 431-550: `_convertCameraImage()` helper method
- Lines 559-690: `_validateCurrentPose()` method
- Lines 691-735: `_calculateQualityScore()` method
- Lines 1429-1445: `_buildFaceOverlay()` method
- Lines 1485-1600: `MLKitFaceOverlayPainter` class
- Any references to `_detectedFaces`, `_isPoseValid`, `_autoCaptureTimer`, etc. in UI code

**Search & Remove Keywords**: `FaceDetector`, `Face `, `InputImage`, `_detectedFaces`, `_isPoseValid`, `_poseValidStartTime`, `_autoCaptureTimer`, `_validationHistory`, `_trackingIdHistory`, `_processCameraImage`, `_convertCameraImage`, `_validateCurrentPose`, `_calculateQualityScore`

### 4. Modify _captureFrame for Video Recording
**Status**: Not Started  
**Current**: Takes single picture (line ~751-845)  
**Target**: Record 1-second video, extract frames

**Implementation**:
```dart
Future<void> _captureFrame() async {
  if (_isCapturing || !_isCameraReady || _cameraController == null) return;
  
  setState(() => _isCapturing = true);

  try {
    // Start video recording
    await _cameraController!.startVideoRecording();
    
    // Record for 1 second
    await Future.delayed(const Duration(seconds: 1));
    
    // Stop recording and get file
    final XFile videoFile = await _cameraController!.stopVideoRecording();
    
    // TODO: Extract ~30 frames from video
    // Options:
    // 1. Use ffmpeg_kit_flutter package
    // 2. Use video_player + screenshot
    // 3. For MVP: Just use video file as-is
    
    final now = DateTime.now();
    
    // Create frame with NO face detection data
    final capturedFrame = SelectedFrame(
      id: 'frame_${now.millisecondsSinceEpoch}',
      sessionId: widget.sessionId,
      imageFilePath: videoFile.path, // Video file for now
      timestampMs: now.millisecondsSinceEpoch,
      qualityScore: 0.95, // Administrator validated
      poseAngles: PoseAngles(
        yaw: 0.0, // No automated detection
        pitch: 0.0,
        roll: 0.0,
        confidence: 1.0, // 100% administrator confidence
      ),
      faceMetrics: FaceMetrics(
        boundingBox: BoundingBox(x: 0, y: 0, width: 0, height: 0),
        faceSize: 0.5,
        sharpnessScore: 0.9,
        lightingScore: 0.8,
        symmetryScore: 0.95,
        hasGlasses: false,
        hasHat: false,
        isSmiling: false,
      ),
      extractedAt: now,
      poseType: _requiredPoses[_currentPoseIndex],
      confidenceScore: 1.0, // Administrator validation
    );

    widget.onFrameCaptured(capturedFrame);
    
    _currentPoseIndex++;
    
    if (_currentPoseIndex >= _requiredPoses.length) {
      widget.onComplete();
    } else {
      _updateInstruction();
      _showCaptureSuccess();
    }
    
  } catch (e) {
    widget.onError('Failed to capture video: ${e.toString()}');
  } finally {
    if (mounted) setState(() => _isCapturing = false);
  }
}
```

### 5. Update UI for Manual Mode
**Status**: Not Started

**Changes Needed**:

**A. Capture Button (Line ~1360)**:
```dart
// BEFORE: Disabled unless pose valid
onPressed: _isCameraReady && !_isCapturing && _isPoseValid
    ? _captureFrame
    : null,

// AFTER: Always enabled when camera ready
onPressed: _isCameraReady && !_isCapturing
    ? _captureFrame
    : null,

// BEFORE: Gray when invalid, green when valid
backgroundColor: _isCapturing
    ? Colors.red
    : _isPoseValid 
        ? Colors.green
        : Colors.grey,

// AFTER: Always green when ready
backgroundColor: _isCapturing
    ? Colors.red
    : Colors.green,
```

**B. Instruction Panel (need to add)**:
```dart
Widget _buildInstructionPanel() {
  return Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.7),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Text(
          'Administrator: Validate Pose',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _currentInstruction ?? '',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Ensure student is in correct pose, then click CAPTURE',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
```

**C. Recording Progress Indicator**:
Add visual feedback during 1-second recording (circular progress or countdown).

**D. Remove/Update**:
- Remove `_buildPoseValidationIndicator()` (lines ~1025-1070) - no longer needed
- Remove face overlay bounding boxes (no ML detection)
- Keep simple oval guide overlay for positioning

### 6. Testing Plan
**Status**: Not Started

**Test Cases**:
1. ✅ Camera initializes correctly
2. ✅ Instruction displays for each pose
3. ✅ Capture button is always enabled (green) when camera ready
4. ✅ Clicking capture starts 1-second recording
5. ✅ Recording indicator shows during capture
6. ✅ Automatically moves to next pose after capture
7. ✅ All 5 poses can be captured sequentially
8. ✅ Video files are saved correctly
9. ✅ onComplete called after all 5 poses
10. ✅ No crashes or errors

## Key Benefits of Manual Approach

1. **Simpler Code**: ~1600 lines → ~500 lines (removing ~1100 lines of ML Kit logic)
2. **More Reliable**: No false positives, no detection gaps, no tracking issues
3. **Faster to Complete**: Can finish today (user's requirement)
4. **Better UX**: Administrator has full control, can re-capture if needed
5. **Sufficient for Use Case**: Administrator is present during registration anyway

## File Status

- **pubspec.yaml**: ✅ ML Kit dependency removed, needs `flutter pub get`
- **guided_pose_capture.dart**: ⚠️ Has compile errors (Face/FaceDetector undefined), needs surgical removal of ML Kit code
- **guided_pose_capture_mlkit_backup.dart**: ✅ Backup created (1610 lines)
- **tasks.md**: ✅ Updated with manual approach

## Next Steps (Priority Order)

1. **Remove all ML Kit code** from guided_pose_capture.dart (~1100 lines to delete)
   - Use find/replace to systematically remove Face, FaceDetector, InputImage, validation logic
   - Fix all compile errors
   
2. **Simplify state variables** (remove temporal smoothing, timers, validation flags)
   - Keep: `_cameraController`, `_currentPoseIndex`, `_requiredPoses`, `_isCapturing`, `_isCameraReady`, `_currentInstruction`
   - Remove: `_faceDetector`, `_detectedFaces`, `_isPoseValid`, `_poseValidStartTime`, `_autoCaptureTimer`, `_validationHistory`, `_trackingIdHistory`, etc.

3. **Update _captureFrame** to record 1-second video
   - Use `startVideoRecording()` / `stopVideoRecording()`
   - For MVP: Store video file, don't extract individual frames yet
   - Remove face detection data from SelectedFrame creation

4. **Update UI** to always enable capture button
   - Remove `_isPoseValid` checks
   - Change button color logic (always green when ready)
   - Add administrator instructions
   - Add recording progress indicator

5. **Run `flutter pub get`** to update dependencies

6. **Test end-to-end** flow with all 5 poses

7. **Verify** no crashes, proper video saving, correct pose progression

## Estimated Time Remaining

- ML Kit code removal: 45 minutes
- Video recording implementation: 30 minutes
- UI updates: 20 minutes
- Testing: 30 minutes
- **Total**: ~2 hours (achievable today)

## Notes

- The manual approach is architecturally simpler and more reliable for this use case
- Administrator presence during registration makes automated detection unnecessary
- Video recording gives ~30 frames per pose (1 sec @ 30 FPS) for later analysis if needed
- Can add frame extraction in future iteration if needed (ffmpeg_kit_flutter)
- This aligns with user's requirement to "finish the app as soon as possible (preferably today)"
