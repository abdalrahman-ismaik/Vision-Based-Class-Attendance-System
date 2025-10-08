Here is a detailed update prompt/document for Claude Sonnet 4 AI code agent to implement the described video capture and frame selection feature update efficiently and without errors:

***

# Update Task: Video Capture & Frame Selection with YOLOv7-Pose and Guided Pose Capture

## Overview  
Upgrade the existing video capture and frame selection feature to support multi-angle face pose capture using YOLOv7-Pose for real-time pose detection, replacing any previous pose detection method. The goal is to guide the user through capturing 5 specific face poses (straight, right, left, up, down) with visual instructions before capturing frames.

## Functional Requirements

1. **Pose Angles to Capture**  
   - Straight (frontal face)  
   - Right profile  
   - Left profile  
   - Head tilted up  
   - Head tilted down

2. **Pose Detection using YOLOv7-Pose**  
   - Integrate YOLOv7-Pose pose detection model.  
   - Detect current user's face pose continuously in real-time while camera runs but does **not** record video continuously.  
   - Confirm when user holds target pose within defined confidence thresholds.

3. **Guided User Experience**  
   - Display animated guiding GIFs or animations prompting the user which pose to hold next.  
   - Start by showing animation/text asking user to face straight at camera.  
   - After pose is detected and validated, show a confirmation animation or text ("Front pose recorded"). Then proceed to next pose with instruction animation.

4. **Frame Capture Per Pose**  
   - For each validated pose, record frames for exactly 1 second at 24 or 30 fps (configurable).  
   - After recording, select the best 3 frames per pose using existing or enhanced frame quality/density metrics.

5. **Architecture & Flow**  
   - Camera preview runs continuously for live feedback.  
   - Detection pipeline operates frame-by-frame asynchronously to avoid blocking UI or capture.  
   - Pose guidance animation syncs state with detection result to control capture timing.  
   - Maintain clean separation between pose detection, capture controller, frame selection, and UI components.

6. **Performance & Reliability**  
   - Optimize for GPU inference. Fall back gracefully to CPU if GPU unavailable.  
   - Use pose detection confidence thresholds to avoid false triggers.  
   - Provide error handling and retry logic for pose detection failure or insufficient frame quality.  
   - Implement progress feedback and allow retrying individual poses without entire restart.  

## Implementation Details

- Remove all previous MediaPipe pose detection related code and dependencies.  
- Add and configure YOLOv7-Pose model, including loading model weights (`yolov7-w6-pose.pth` or similar).  
- Implement image pre-processing: letterboxing, normalization per YOLOv7-Pose specs.  
- Implement post-processing: keypoint extraction, confidence filtering, pose angle classification based on keypoint geometry.  
- Design finite state machine to transition through pose capture states (initial animation → pose validation → capture frames → pose completion animation → next pose).  
- Implement a buffer to store frames during the 1 second capture window per pose.  
- Implement frame quality scoring and diversity analysis for selecting 3 best frames per pose.  
- Ensure all UI text and animations are configurable via resource files or constants for localization and modification.  

## Testing & Validation

- Unit tests for each module: pose detection, capture buffer, frame scoring, UI state transitions.  
- Integration testing with camera emulator/device to confirm smooth user flow through all 5 poses.  
- Performance profiling on target mobile devices for capture FPS and inference latency.  
- Validation of correctness and quality of selected frames by manual review and automated metrics.

## Dependencies & Environment

- PyTorch >= 2.0 for YOLOv7 inference.  
- OpenCV or platform native camera API for preview and frame capture.  
- Flutter/Dart UI updates for animations and state management.  
- Possible use of Flutter isolates or background threads for offloading pose detection.

## Deliverables

- Updated pose detection and capture modules integrated into the app codebase.  
- UI animations/GIF resources added and hooked to pose states.  
- Documentation of new architecture, usage instructions, and configuration.  
- Test cases and performance reports.

***

This prompt ensures Claude Sonnet 4 AI agent covers every aspect—from technical integration, user interaction, quality assurance, to performance optimization—minimizing errors and incomplete implementation risks.


Here is a realistic use case scenario / user registration flow example for your updated app with YOLOv7-Pose guided multi-angle face capture:

***

## Use Case Scenario: Student Face Registration with Guided Multi-Angle Capture  

### Actors  
- **Administrator:** Staff member facilitating the face registration process  
- **Student:** The registration subject whose face data is being captured  

### Preconditions  
- Student is physically present and properly positioned in front of device camera  
- The app is launched, and administrator has authenticated  

### Registration Flow  

1. **Start Registration Session**  
   Administrator inputs student info and initiates registration. The camera preview starts with no video recording yet.

2. **Pose Guidance: Front Pose**  
   - Animation plays instructing the student: "Please face the camera straight ahead."  
   - YOLOv7-Pose runs continuously in background detecting user’s current head pose.  
   - Once pose meets confidence threshold for "straight" position, animation changes to "Front pose detected! Capturing photos..."  

3. **Capture Frames for Front Pose**  
   - App records frames at 24 or 30 FPS for 1 second (24-30 frames).  
   - Frames buffered and passed to frame quality and diversity module to select top 3 for this pose.  
   - Confirmation animation/display shows: "Front pose captured successfully."

4. **Pose Guidance: Right Side Pose**  
   - Animation instructs: "Please turn your face to the right side."  
   - YOLOv7-Pose detects head turned right, confirming when confidence threshold met.  
   - Frames captured for 1 second, then best 3 selected. Confirmation shown.

5. **Pose Guidance: Left Side Pose**  
   Similar to the right side pose guidance, detection, capture, selection, and confirmation.

6. **Pose Guidance: Looking Up**  
   Animation asks to tilt head upward. Detection and capture process repeated.

7. **Pose Guidance: Looking Down**  
   Animation asks to tilt head downward. Detection and capture repeated.

8. **Completion**  
   - After all five poses captured with their respective best frames, app compiles selected frames and metadata.  
   - The administrator is shown a summary screen with pose coverage stats and option to retry any pose if needed.  
   - Upon confirmation, data is saved and uploaded as per system workflow.

9. **End of Session**  
   - Registration session is logged with timestamps, selected frames, and pose data.  
   - Administrator can start new registration or exit.

### Postconditions  
- High-quality face images with diverse pose angles are saved.  
- The AI system receives standardized, rich training data with pose diversity.  
- The user experience ensures understanding and cooperation from the student, minimizing errors or repeated attempts.

***

This scenario exemplifies the seamless interplay of guided instructions, real-time pose detection by YOLOv7-Pose, timely frame capturing, and user feedback. It ensures comprehensive pose coverage and data quality for accurate student face registration.

[1](https://ieeexplore.ieee.org/document/10486760/)
[2](https://doiserbia.nb.rs/Article.aspx?ID=1820-02142400038B)
[3](https://www.granthaalayahpublication.org/Arts-Journal/ShodhKosh/article/view/3183)
[4](https://ieeexplore.ieee.org/document/10716379/)
[5](https://ieeexplore.ieee.org/document/10763516/)
[6](https://ieeexplore.ieee.org/document/10657959/)
[7](https://ijcsm.researchcommons.org/ijcsm/vol4/iss3/12)
[8](https://ieeexplore.ieee.org/document/10306966/)
[9](https://ieeexplore.ieee.org/document/10404290/)
[10](https://dl.acm.org/doi/10.1145/3600160.3600179)
[11](https://www.jointcommission.org/assets/1/6/NPSG_Chapter_HAP_Jan2018.pdf)
[12](https://www.mdpi.com/2078-2489/12/12/532/pdf)
[13](https://sciresol.s3.us-east-2.amazonaws.com/IJST/Articles/2018/Issue-26/Article17.pdf)
[14](https://peerj.com/articles/444)
[15](https://peerj.com/articles/cs-1468)
[16](https://ijaers.com/uploads/issue_files/48-IJAERS-APR-2019-46-FacialRecognition.pdf)
[17](https://arxiv.org/pdf/2403.16202.pdf)
[18](https://arxiv.org/pdf/2308.06944.pdf)
[19](http://arxiv.org/pdf/2502.20803.pdf)
[20](https://crinn.conferencehunter.com/index.php/jcrinn/article/download/273/199)