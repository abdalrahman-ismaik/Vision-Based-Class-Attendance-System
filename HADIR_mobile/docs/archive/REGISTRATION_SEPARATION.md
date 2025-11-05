# Registration Session and Frame Selection Separation

## Overview
This document describes the separation of functionalities between image capture and frame selection in the HADIR registration system.

## Changes Made

### 1. New Entity: CapturedFrame
**Location**: `lib/shared/domain/entities/captured_frame.dart`

A new entity representing raw captured images before selection:
- Represents frames captured during the registration session
- Contains quality metrics, pose information, and face metrics
- Can be converted to `SelectedFrame` after selection process
- Separate from `SelectedFrame` which represents final chosen frames

**Key Properties:**
- `id`: Unique identifier
- `sessionId`: Registration session reference
- `imageFilePath`: Path to captured image
- `poseType`: Detected pose type
- `qualityScore`: Frame quality (0.0-1.0)
- `confidenceScore`: Detection confidence (0.0-1.0)
- `poseAngles`, `faceMetrics`, `boundingBox`: Computer vision data

**Key Methods:**
- `toSelectedFrame()`: Convert to SelectedFrame after selection

### 2. Updated Entity: RegistrationSession
**Location**: `lib/shared/domain/entities/registration_session.dart`

**New Properties:**
- `capturedFrames`: List of CapturedFrame (raw captures)
- `capturedFramesCount`: Count of captured frames
- `selectedFrames`: List of SelectedFrame (final selections)
- Both lists maintained separately

**Updated Status Flow:**
```
capturingInProgress → captureCompleted → selectionInProgress → completed
```

**New Methods:**
- `addCapturedFrame()`: Add a frame during capture phase
- `addSelectedFrames()`: Add selected frames after selection
- `markCaptureComplete()`: Mark capture phase as done
- `startFrameSelection()`: Begin selection process
- `captureProgress`: Progress of capture (0.0-1.0)
- `selectionProgress`: Progress of selection (0.0-1.0)
- `progress`: Overall progress combining both phases

**Updated Helper Properties:**
- `isAllPosesCaptured`: Check if all poses captured (uses capturedFrames)
- `isFrameSelectionComplete`: Check if selection is done (uses selectedFrames)

### 3. Updated Enum: SessionStatus
**Location**: `lib/shared/domain/entities/registration_session.dart`

**New Status Values:**
- `capturingInProgress`: Initial state - capturing images
- `captureCompleted`: Image capture completed successfully
- `selectionInProgress`: Frame selection in progress
- `completed`: Frame selection completed - registration finished
- `failed`: Session failed during capture or selection
- `expired`: Session expired (took too long)
- `cancelled`: Session was cancelled by user

**New Helper Methods:**
- `isCapturing`: Check if in capture phase
- `isCaptureComplete`: Check if capture is done
- `isSelecting`: Check if in selection phase
- `isFinalized`: Check if session is finished

### 4. New Entity: FrameSelectionSession
**Location**: `lib/shared/domain/entities/frame_selection_session.dart`

A dedicated entity for the frame selection process:
- Manages the selection of optimal frames from captured candidates
- Tracks selection progress and metrics
- Independent from capture process

**Key Properties:**
- `id`: Unique selection session identifier
- `registrationSessionId`: Reference to parent registration session
- `status`: Selection status (inProgress, completed, failed, cancelled)
- `candidateFrames`: List of CapturedFrame to select from
- `selectedFrames`: List of SelectedFrame after selection
- `requiredPoses`: Pose types that must be covered
- `qualityThreshold`: Minimum quality score (default 0.7)
- `framesPerPose`: Number of frames per pose type (default 3)
- `selectionMetrics`: Metrics about selection process

**Key Methods:**
- `markComplete()`: Mark selection as complete with selected frames
- `markFailed()`: Mark selection as failed with reason
- `markCancelled()`: Cancel the selection
- `progress`: Get selection progress (0.0-1.0)
- `poseCoverage`: Get pose coverage percentage
- `averageQuality`: Get average quality of selected frames

## Workflow

### Previous Flow (Mixed)
```
Start Session → Capture & Select → Complete Session
```

### New Flow (Separated)
```
1. Start Registration Session (status: capturingInProgress)
   ↓
2. Capture Images (add CapturedFrame instances)
   ↓
3. Mark Capture Complete (status: captureCompleted)
   ↓
4. Start Frame Selection (status: selectionInProgress)
   - Create FrameSelectionSession
   - Process candidateFrames
   - Select optimal frames
   ↓
5. Add Selected Frames (status: completed)
   - Update RegistrationSession with selectedFrames
```

## Benefits

1. **Separation of Concerns**: Capture and selection are now distinct phases
2. **Better Tracking**: Can track progress of each phase independently
3. **Flexibility**: Can re-run selection without re-capturing
4. **Clearer State Management**: Status values clearly indicate current phase
5. **Independent Entities**: CapturedFrame and SelectedFrame serve different purposes
6. **Auditing**: FrameSelectionSession provides detailed selection audit trail

## Migration Notes

### For Existing Code:

1. **Status Updates**: Replace `SessionStatus.inProgress` with `SessionStatus.capturingInProgress`

2. **Frame Addition**: 
   - During capture: Use `addCapturedFrame()` instead of `addFrame()`
   - After selection: Use `addSelectedFrames()`

3. **Progress Tracking**:
   - Use `captureProgress` for capture phase
   - Use `selectionProgress` for selection phase
   - Use `progress` for overall progress (weighted 50/50)

4. **Completion Check**:
   - Use `isAllPosesCaptured` to check if capture is done
   - Use `isFrameSelectionComplete` to check if selection is done

5. **Session Flow**:
```dart
// Start capture
session = session.copyWith(status: SessionStatus.capturingInProgress);

// Capture frames
for (var frame in captures) {
  session = session.addCapturedFrame(frame);
}

// Mark capture complete
session = session.markCaptureComplete();

// Start selection
session = session.startFrameSelection();

// Run selection algorithm
var selectionSession = FrameSelectionSession(...);
var selectedFrames = await selectOptimalFrames(session.capturedFrames);

// Add selected frames
session = session.addSelectedFrames(selectedFrames);
```

## Next Steps

1. Update use cases:
   - `CreateRegistrationSessionUseCase`: Use new status
   - `ProcessVideoFramesUseCase`: Work with CapturedFrame
   - `SelectOptimalFramesUseCase`: Create FrameSelectionSession
   
2. Update repositories to handle:
   - CapturedFrame storage and retrieval
   - FrameSelectionSession CRUD operations
   
3. Update UI/presentation layer:
   - Show capture progress separately from selection
   - Update status displays
   - Handle new workflow states

## API Changes

### RegistrationSession

**Added:**
- `List<CapturedFrame> capturedFrames`
- `int capturedFramesCount`
- `addCapturedFrame(CapturedFrame)` 
- `addSelectedFrames(List<SelectedFrame>)`
- `markCaptureComplete()`
- `startFrameSelection()`
- `captureProgress` getter
- `selectionProgress` getter
- `isFrameSelectionComplete` getter

**Changed:**
- `progress` now returns weighted progress (capture 50%, selection 50%)
- `isAllPosesCaptured` now uses `capturedFrames` instead of `selectedFrames`

**Status Values Changed:**
- `inProgress` → `capturingInProgress`
- Added: `captureCompleted`, `selectionInProgress`

### New Classes
- `CapturedFrame`: Raw captured frame entity
- `FrameSelectionSession`: Frame selection session entity
- `SelectionStatus`: Enum for selection session status
