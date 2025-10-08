# MVP Tasks: 2-Week Mobile App Development
**Streamlined for rapid delivery by October 12, 2025**

## CRITICAL PATH: MVP Tasks Only
*Each task should take 0.5-1 day maximum*

---

### WEEK 1: Foundation (Days 1-5)

#### Day 1-2: Project Foundation
- [X] **MVP-T001** Create basic Flutter project structure
  ```bash
  flutter create --org edu.university.hadir hadir_mobile_mvp
  cd hadir_mobile_mvp
  ```
  - Basic `lib/` folder structure: `screens/`, `models/`, `services/`
  - Skip clean architecture complexity for MVP

- [X] **MVP-T002** Add essential dependencies to `pubspec.yaml`
  ```yaml
  dependencies:
    camera: ^0.10.5
    google_ml_kit: ^0.15.0  
    sqflite: ^2.3.0
    path: ^1.8.3
  ```
  - Skip Riverpod, GoRouter for MVP simplicity

- [X] **MVP-T003** Configure Android permissions in `android/app/src/main/AndroidManifest.xml`
  ```xml
  <uses-permission android:name="android.permission.CAMERA" />
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
  ```

#### Day 3: Authentication & Basic Navigation
- [X] **MVP-T004** Create simple login screen `lib/screens/login_screen.dart`
  - Hardcoded admin credentials: username="admin", password="hadir2025"
  - Simple TextFormField widgets with basic validation
  - Navigate to student input on successful login

- [X] **MVP-T005** Create student input screen `lib/screens/student_input_screen.dart`
  - Student ID, Name, Email fields
  - Save button navigates to camera screen
  - Store data in memory (simple Map) for MVP

#### Day 4-5: Camera Integration
- [X] **MVP-T006** Create camera recording screen `lib/screens/camera_screen.dart`
  - Basic CameraController setup
  - Record video button (start/stop)
  - Show camera preview with simple overlay

- [X] **MVP-T007** Implement basic face detection `lib/services/face_detection_service.dart`
  - Use Google ML Kit FaceDetector
  - Process video frames to detect faces
  - Simple boolean: face detected or not

---

### WEEK 2: Core Features (Days 6-12)

#### Day 6-7: Data Models & Storage
- [X] **MVP-T008** Create basic data models `lib/models/`
  - `Student` class: id, name, email
  - `RegistrationSession` class: student, videoPath, selectedFrames
  - Simple JSON serialization (toJson/fromJson)

- [X] **MVP-T009** Implement simple SQLite database `lib/services/database_service.dart`
  - Two tables: students, registration_sessions
  - Basic CRUD operations
  - Initialize database on app start

#### Day 8-9: Frame Processing & Export
- [X] **MVP-T010** Implement basic frame selection `lib/services/frame_selection_service.dart`
  - Extract frames from recorded video
  - Select frames where face is detected
  - Keep 3-5 best frames (based on face confidence)

- [X] **MVP-T011** Create export functionality `lib/services/export_service.dart`
  - Generate JSON file with student data and frame paths
  - Save to device Downloads folder
  - Simple success/error feedback

#### Day 10: Integration & Flow
- [X] **MVP-T012** Connect all screens with navigation
  - Login → Student Input → Camera → Results
  - Pass data between screens using constructor parameters
  - Basic back navigation

- [X] **MVP-T013** Create results screen `lib/screens/results_screen.dart`
  - Show selected frames
  - Export button
  - New registration button (return to student input)

#### Day 11-12: Testing & Polish
- [X] **MVP-T014** Basic error handling
  - Camera permission denied
  - Database errors
  - File system errors
  - Show simple error dialogs

- [X] **MVP-T015** Manual testing & bug fixes
  - Test complete flow on real device
  - Fix critical crashes
  - Ensure data exports correctly

---

## File Structure (Simplified)
```
lib/
├── main.dart                    # App entry point
├── screens/
│   ├── login_screen.dart        # MVP-T004
│   ├── student_input_screen.dart # MVP-T005  
│   ├── camera_screen.dart       # MVP-T006
│   └── results_screen.dart      # MVP-T013
├── services/
│   ├── face_detection_service.dart # MVP-T007
│   ├── database_service.dart       # MVP-T009
│   ├── frame_selection_service.dart # MVP-T010
│   └── export_service.dart         # MVP-T011
├── models/
│   ├── student.dart             # MVP-T008
│   └── registration_session.dart # MVP-T008
└── utils/
    └── constants.dart           # App constants
```

---

## Daily Success Criteria

### Day 1: ✅ Project Launches
- [ ] Flutter project created and runs on device
- [ ] Dependencies added and resolved
- [ ] Basic app structure in place

### Day 2: ✅ Permissions Work  
- [ ] Camera permissions granted
- [ ] App can access camera
- [ ] Basic main screen displays

### Day 3: ✅ User Flow Started
- [ ] Login screen functional
- [ ] Navigation to student input works
- [ ] Form validation working

### Day 4: ✅ Student Data Input
- [ ] Student input form complete
- [ ] Data stored and passed to next screen
- [ ] Navigation to camera works

### Day 5: ✅ Camera Functional
- [ ] Camera preview displays
- [ ] Can start/stop video recording
- [ ] Basic face detection working

### Day 6: ✅ Data Models Ready
- [ ] Student and Session models created
- [ ] JSON serialization working
- [ ] Basic data structure defined

### Day 7: ✅ Database Working
- [ ] SQLite database initialized
- [ ] Can save/retrieve students
- [ ] Basic CRUD operations functional

### Day 8: ✅ Frame Processing
- [ ] Can extract frames from video
- [ ] Face detection on frames working
- [ ] Frame selection algorithm basic version done

### Day 9: ✅ Export System
- [ ] JSON export functional
- [ ] Files saved to device storage
- [ ] Export format verified

### Day 10: ✅ Complete Flow
- [ ] Can complete full registration flow
- [ ] All screens connected properly
- [ ] Data flows through entire process

### Day 11: ✅ Error Handling
- [ ] Basic error dialogs implemented
- [ ] App doesn't crash on common errors
- [ ] User feedback for important actions

### Day 12: ✅ MVP Complete
- [ ] Full registration flow tested on device
- [ ] Exported data verified
- [ ] Ready for demonstration

---

## Technology Simplifications for Speed

### What We're SKIPPING for MVP:
- ❌ Complex state management (Riverpod)
- ❌ Advanced routing (GoRouter)
- ❌ Comprehensive testing suite
- ❌ Advanced pose estimation
- ❌ Real-time quality scoring
- ❌ Complex UI animations
- ❌ Security hardening
- ❌ Performance optimization
- ❌ Clean architecture patterns

### What We're KEEPING Simple:
- ✅ Basic StatefulWidget state management
- ✅ Navigator.push routing
- ✅ Manual testing only
- ✅ Basic face detection (present/not present)
- ✅ Simple quality check (face confidence > 0.5)
- ✅ Basic Material Design UI
- ✅ Hardcoded security (admin credentials)
- ✅ Acceptable performance (no optimization)
- ✅ Direct implementation (no abstraction layers)

---

## Risk Mitigation

### If Behind Schedule:
- **Day 3**: Skip login, go straight to student input
- **Day 5**: Use photo capture instead of video if needed  
- **Day 7**: Use in-memory storage instead of SQLite
- **Day 9**: Manual frame selection if automatic selection fails
- **Day 11**: Skip error handling, focus on happy path

### Emergency Fallbacks:
1. **Camera Issues**: Use gallery picker to select existing videos
2. **Face Detection Problems**: Manual frame selection by admin
3. **Database Issues**: Export to simple text files
4. **Export Problems**: Show data on screen instead of file export

**Success Definition**: Administrator can register a student by recording their face and exporting the data - even if roughly implemented.

---

## Getting Started Command

```bash
# Day 1 commands to begin:
flutter create --org edu.university.hadir hadir_mobile_mvp
cd hadir_mobile_mvp
flutter pub add camera google_ml_kit sqflite path
flutter pub get
```

**Ready to begin MVP development - target completion: October 12, 2025**