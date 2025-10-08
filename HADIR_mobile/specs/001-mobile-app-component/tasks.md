# Tasks: Mobile Student Registration App with AI-Enhanced Face Capture

**Input**: Design documents from `d:\Education\University\Fall 2025\COSC 330 - Intro to Artificial Intelligence\Project\HADIR\HADIR\specs\001-mobile-app-component\`  
**Prerequisites**: plan.md (✓), research.md (✓), data-model.md (✓), contracts/ (✓), quickstart.md (✓)

## Execution Flow (main)
```
1. Load plan.md from feature directory ✓
   → Tech stack: Flutter 3.16+ with Dart 3.0+, Riverpod, GoRouter
   → Structure: Clean architecture with feature-driven development
2. Load design documents ✓:
   → data-model.md: 6 entities (Administrator, Student, RegistrationSession, etc.)
   → contracts/: 15 API endpoints across auth, students, registration, export
   → research.md: Technology decisions and architecture patterns
   → quickstart.md: Development setup and integration scenarios
3. Generate tasks by category:
   → Setup: Flutter project, dependencies, permissions, database
   → Tests: Widget tests, unit tests, contract tests, integration tests
   → Core: Models, repositories, providers, services, computer vision
   → UI: Screens, widgets, navigation, camera integration
   → Integration: ML Kit, database, state management
   → Polish: Performance optimization, error handling, documentation
4. Apply Flutter-specific task rules:
   → Different feature modules = mark [P] for parallel
   → Shared files (router, theme) = sequential
   → Test-driven approach for all business logic
5. Number tasks sequentially (T001-T040)
6. Generate dependency graph for Flutter development
7. Create parallel execution examples
8. Validate Flutter app completeness
9. Return: SUCCESS (tasks ready for Flutter implementation)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files/modules, no dependencies)
- Include exact file paths for Flutter project structure

## Path Conventions
Flutter mobile app structure:
- **App core**: `lib/main.dart`, `lib/app/`
- **Features**: `lib/features/{auth,registration,export}/`
- **Shared**: `lib/shared/`, `lib/core/`
- **Tests**: `test/`, `integration_test/`
- **Platform**: `android/`, `assets/`

---

## Phase 3.1: Setup & Project Foundation
- [X] **T001** Create Flutter project structure with clean architecture organization
  - Create `flutter create --org edu.university.hadir mobile_registration_app`
  - Set up directory structure: `lib/features/{auth,registration,export}`, `lib/core/`, `lib/shared/`
  - Initialize `pubspec.yaml` with Flutter 3.16+ dependencies

- [X] **T002** Configure Flutter dependencies and development tools
  - Add Riverpod 2.4+, GoRouter 12.0+, camera, google_ml_kit, sqflite to `pubspec.yaml`
  - Configure `analysis_options.yaml` with Flutter lints
  - Set up build runner and code generation tools

- [ ] **T003** [P] Configure Android permissions and platform setup
  - Update `android/app/src/main/AndroidManifest.xml` with camera, storage permissions
  - Configure camera hardware requirements
  - Set up Android build configuration in `android/app/build.gradle`

- [ ] **T004** [P] Initialize database schema and migration system
  - Create `lib/shared/data/database/database_service.dart` with SQLite setup
  - Implement database schema creation with 7 tables from data model
  - Add database version management and migration support

- [ ] **T005** [P] Set up app-wide configuration and constants
  - Create `lib/app/hadir_app.dart` with MaterialApp.router setup
  - Create `lib/app/theme/app_theme.dart` with Material Design 3 theming
  - Create `lib/shared/utils/constants.dart` with quality thresholds, performance targets

---

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**

### Data Model Tests
- [X] **T006** [P] Unit test Administrator entity model in `test/shared/domain/entities/administrator_test.dart`
- [X] **T007** [P] Unit test Student entity model in `test/shared/domain/entities/student_test.dart`
- [X] **T008** [P] Unit test RegistrationSession entity model in `test/shared/domain/entities/registration_session_test.dart`
- [X] **T009** [P] Unit test SelectedFrame entity model in `test/shared/domain/entities/selected_frame_test.dart`

### Repository Contract Tests
- [X] **T010** [P] Contract test StudentRepository interface in `test/features/registration/data/repositories/student_repository_test.dart`
- [X] **T011** [P] Contract test RegistrationRepository interface in `test/features/registration/data/repositories/registration_repository_test.dart`
- [X] **T012** [P] Contract test ExportRepository interface in `test/features/export/data/repositories/export_repository_test.dart`

### Business Logic Tests
- [ ] **T013** [P] Unit test authentication use cases in `test/features/auth/domain/use_cases/authentication_test.dart`
- [ ] **T014** [P] Unit test registration use cases in `test/features/registration/domain/use_cases/registration_test.dart`
- [ ] **T015** [P] Unit test YOLOv7-Pose pipeline in `test/core/computer_vision/yolov7_pose_detection_test.dart`

### Widget Tests
- [ ] **T016** [P] Widget test LoginScreen in `test/features/auth/presentation/screens/login_screen_test.dart`
- [ ] **T017** [P] Widget test RegistrationScreen in `test/features/registration/presentation/screens/registration_screen_test.dart`
- [ ] **T018** [P] Widget test guided pose capture components in `test/features/registration/presentation/widgets/guided_pose_capture_test.dart`

### Integration Tests
- [ ] **T019** [P] Integration test complete multi-pose registration flow in `integration_test/multi_pose_registration_flow_test.dart`
- [ ] **T020** [P] Integration test authentication flow in `integration_test/auth_flow_test.dart`
- [ ] **T021** [P] Integration test database operations in `integration_test/database_integration_test.dart`

---

## Phase 3.3: Core Implementation (ONLY after tests are failing)

### Domain Layer - Entities and Business Logic
- [ ] **T022** [P] Administrator entity model in `lib/shared/domain/entities/administrator.dart`
- [ ] **T023** [P] Student entity model in `lib/shared/domain/entities/student.dart`
- [ ] **T024** [P] RegistrationSession entity model in `lib/shared/domain/entities/registration_session.dart`
- [ ] **T025** [P] SelectedFrame and related entities in `lib/shared/domain/entities/selected_frame.dart`

### Data Layer - Repositories and Data Sources
- [ ] **T026** [P] StudentRepository interface in `lib/features/registration/domain/repositories/student_repository.dart`
- [ ] **T027** [P] RegistrationRepository interface in `lib/features/registration/domain/repositories/registration_repository.dart`
- [ ] **T028** [P] ExportRepository interface in `lib/features/export/domain/repositories/export_repository.dart`

- [ ] **T029** [P] Local database data source in `lib/shared/data/data_sources/local_database_data_source.dart`
- [ ] **T030** SQLite repository implementations
  - Implement `LocalStudentRepository` in `lib/features/registration/data/repositories/local_student_repository.dart`
  - Implement `LocalRegistrationRepository` in `lib/features/registration/data/repositories/local_registration_repository.dart`
  - Connect to shared database service

### Business Logic - Use Cases
- [ ] **T031** [P] Authentication use cases in `lib/features/auth/domain/use_cases/`
  - Create `login_administrator.dart`, `logout_administrator.dart`, `validate_session.dart`
- [ ] **T032** [P] Registration use cases in `lib/features/registration/domain/use_cases/`
  - Create `create_registration_session.dart`, `process_video_frames.dart`, `select_optimal_frames.dart`

### Computer Vision Core with YOLOv7-Pose Integration
- [ ] **T033** YOLOv7-Pose detection service in `lib/core/computer_vision/yolov7_pose_service.dart`
  - Integrate YOLOv7-Pose model with PyTorch backend
  - Implement real-time pose detection with keypoint extraction (17 COCO keypoints)
  - Add GPU inference with CPU fallback for mobile optimization
- [ ] **T034** Guided pose estimation service in `lib/core/pose_estimation/guided_pose_service.dart`
  - Implement 5-pose detection: straight, right profile, left profile, head up, head down
  - Calculate pose angles from YOLOv7-Pose keypoints (yaw, pitch, roll)
  - Add confidence thresholds and pose validation logic
- [ ] **T035** Multi-pose capture controller in `lib/core/capture_control/multi_pose_capture_controller.dart`
  - Implement finite state machine for pose guidance workflow
  - Control 1-second frame capture per validated pose (24-30 FPS)
  - Add pose-specific frame buffering and confirmation logic
- [ ] **T036** Enhanced frame selection service in `lib/core/frame_selection/enhanced_frame_selection_service.dart`
  - Select best 3 frames per pose using quality and diversity metrics
  - Implement pose-specific quality scoring algorithms
  - Add frame metadata extraction and pose angle validation

### YOLOv7-Pose Integration Service (Updated Architecture)
- [ ] **T036A** YOLOv7-Pose model integration in `frame_selection_service/`
  - Create FastAPI application with PyTorch >= 2.0, OpenCV, YOLOv7-Pose model weights
  - Set up requirements.txt with: fastapi, uvicorn, torch, torchvision, opencv-python, numpy, pydantic
  - Load YOLOv7-Pose model weights (yolov7-w6-pose.pth) with GPU/CPU detection
- [ ] **T036B** YOLOv7-Pose processing pipeline in `frame_selection_service/services/`
  - Implement `yolov7_pose_detector.py` with letterboxing and normalization preprocessing
  - Create `pose_analyzer.py` for keypoint extraction and pose angle classification
  - Build `guided_capture_controller.py` for 5-pose validation and frame buffering
- [ ] **T036C** Multi-pose frame selection system
  - Implement `pose_frame_selector.py` for selecting best 3 frames per pose (15 total)
  - Create quality scoring specific to each pose type (frontal, profile, tilted)
  - Add pose-specific diversity analysis and frame validation
- [ ] **T036D** Guided capture API endpoints
  - Create POST `/start-guided-capture` endpoint for pose sequence initialization
  - Implement `/validate-pose` endpoint for real-time pose confirmation
  - Add `/capture-pose-frames` endpoint for 1-second frame capture per pose
- [ ] **T036E** Performance optimization and pose testing
  - Add unit tests for YOLOv7-Pose detection accuracy across 5 pose types
  - Implement GPU memory optimization and inference batching
  - Add pose detection confidence thresholds and error handling

---

## Phase 3.4: Presentation Layer - UI and State Management

### State Management - Riverpod Providers
- [ ] **T037** [P] Authentication providers in `lib/features/auth/presentation/providers/auth_providers.dart`
- [ ] **T038** [P] Registration state providers in `lib/features/registration/presentation/providers/registration_providers.dart`
- [ ] **T039** [P] Camera and computer vision providers in `lib/features/registration/presentation/providers/camera_providers.dart`

### Screen Implementations
- [ ] **T040** Authentication screens
  - Implement `LoginScreen` in `lib/features/auth/presentation/screens/login_screen.dart`
  - Add administrator credential input, validation, and session management
- [ ] **T041** Registration screens and navigation
  - Implement `RegistrationScreen` in `lib/features/registration/presentation/screens/registration_screen.dart`
  - Add student information input and camera preparation
- [ ] **T042** Guided multi-pose capture screen
  - Implement `GuidedMultiPoseCaptureScreen` in `lib/features/registration/presentation/screens/guided_multi_pose_capture_screen.dart`
  - Integrate camera preview with YOLOv7-Pose detection (no continuous recording)
  - Add pose-by-pose guidance workflow and 1-second frame capture per validated pose

### Guided Multi-Pose Camera Integration
- [ ] **T043** Guided pose capture overlay system
  - Implement `GuidedPoseCameraOverlay` in `lib/features/registration/presentation/widgets/guided_pose_camera_overlay.dart`
  - Add 5-pose guidance animations: straight, right profile, left profile, head up, head down
  - Integrate real-time YOLOv7-Pose feedback and pose validation indicators
- [ ] **T044** Pose guidance animation widgets
  - Implement `PoseGuidanceAnimator` in `lib/features/registration/presentation/widgets/pose_guidance_animator.dart`
  - Create `PoseConfirmationWidget` for "pose detected" and "capturing frames" feedback
  - Add `PoseProgressTracker` showing completion status for all 5 poses
- [ ] **T045** Multi-pose state management
  - Implement `MultiPoseCaptureState` in `lib/features/registration/presentation/providers/multi_pose_capture_provider.dart`
  - Add finite state machine for pose sequence: guidance → validation → capture → confirmation → next pose
  - Integrate pose retry logic and individual pose validation controls

### Navigation and Asset Management
- [ ] **T046** App router configuration with guided capture routes
  - Implement `AppRouter` in `lib/app/router/app_router.dart` with GoRouter
  - Add guided multi-pose capture routes and pose retry navigation
  - Connect authentication state to route protection
- [ ] **T047** Pose guidance assets and animations
  - Create pose guidance animations/GIFs in `assets/animations/pose_guidance/`
  - Add pose instruction assets: straight.gif, right_profile.gif, left_profile.gif, head_up.gif, head_down.gif
  - Implement pose confirmation animations and progress indicators

---

## Phase 3.5: Integration and Multi-Pose Export

### YOLOv7-Pose Pipeline Integration
- [ ] **T048** YOLOv7-Pose service integration with Flutter
  - Create HTTP client service in `lib/core/services/yolov7_pose_client.dart`
  - Implement real-time pose validation and guided capture communication
  - Add error handling and retry logic for pose detection failures
- [ ] **T049** Multi-pose frame processing optimization
  - Integrate background pose detection using Dart isolates for non-blocking UI
  - Add pose-specific progress tracking and real-time feedback
  - Implement local caching of captured frames per pose (15 total frames)

### Multi-Pose Data Export System
- [ ] **T050** [P] Multi-pose export package creation in `lib/features/export/data/services/multi_pose_export_service.dart`
- [ ] **T051** [P] Pose-aware JSON serialization in `lib/features/export/data/models/multi_pose_export_package.dart`
- [ ] **T052** Multi-pose export UI with pose coverage summary in `lib/features/export/presentation/screens/multi_pose_export_screen.dart`

---

## Phase 3.6: Polish and Optimization

### Performance and Error Handling
- [ ] **T053** [P] YOLOv7-Pose performance optimization and memory management
  - Optimize pose detection inference for mobile devices with GPU/CPU fallback
  - Implement memory management for 1-second frame buffers per pose
  - Add pose detection confidence thresholds and false positive prevention
- [ ] **T054** [P] Multi-pose error handling in `lib/shared/utils/multi_pose_error_handler.dart`
- [ ] **T055** [P] Pose capture logging and analytics in `lib/shared/utils/pose_capture_logger.dart`

### Security and Validation
- [ ] **T056** [P] Multi-pose input validation and sanitization
- [ ] **T057** [P] Enhanced biometric data encryption for 15-frame pose sequences using AES-256
- [ ] **T058** [P] Administrator session management with pose capture audit logging

### Documentation and Testing Completion
- [ ] **T059** [P] YOLOv7-Pose API documentation update in `docs/yolov7-pose-integration.md`
- [ ] **T060** [P] Multi-pose capture user manual in `docs/guided-pose-capture-guide.md`
- [ ] **T061** Run complete multi-pose integration test suite from `integration_test/multi_pose_app_test.dart`
- [ ] **T062** YOLOv7-Pose performance benchmarking and pose detection accuracy validation

---

## Dependencies

### Sequential Dependencies
- **Setup Phase**: T001 → T002 → T004 (project setup before database)
- **Database**: T004 → T029 → T030 (schema before data sources before repositories)
- **Core Logic**: T022-T025 → T026-T028 → T031-T032 (entities before repositories before use cases)
- **Computer Vision**: T033 → T034 → T035 → T036 (face detection before pose before quality before selection)
- **UI Flow**: T037-T039 → T040-T042 → T043-T045 (providers before screens before widgets/routing)
- **Integration**: T046 → T047 (basic pipeline before optimization)
- **Testing**: All implementation tasks → T059 (implementation before final integration tests)

### Parallel Execution Blocks
- **Foundation [P]**: T003, T005 (platform config, constants)
- **Entity Tests [P]**: T006, T007, T008, T009
- **Repository Tests [P]**: T010, T011, T012
- **Business Logic Tests [P]**: T013, T014, T015
- **Widget Tests [P]**: T016, T017, T018
- **Integration Tests [P]**: T019, T020, T021
- **Domain Entities [P]**: T022, T023, T024, T025
- **Repository Interfaces [P]**: T026, T027, T028
- **Use Cases [P]**: T031, T032
- **State Providers [P]**: T037, T038, T039
- **Export System [P]**: T048, T049
- **Polish Phase [P]**: T051, T052, T053, T054, T055, T056, T057, T058

---

## Parallel Execution Examples

### Phase 1: Entity Models (after tests fail)
```bash
# Launch T022-T025 together:
Task: "Administrator entity model in lib/shared/domain/entities/administrator.dart"
Task: "Student entity model in lib/shared/domain/entities/student.dart"
Task: "RegistrationSession entity model in lib/shared/domain/entities/registration_session.dart"
Task: "SelectedFrame and related entities in lib/shared/domain/entities/selected_frame.dart"
```

### Phase 2: Repository Interfaces
```bash
# Launch T026-T028 together:
Task: "StudentRepository interface in lib/features/registration/domain/repositories/student_repository.dart"
Task: "RegistrationRepository interface in lib/features/registration/domain/repositories/registration_repository.dart"
Task: "ExportRepository interface in lib/features/export/domain/repositories/export_repository.dart"
```

### Phase 3: State Management Providers
```bash
# Launch T037-T039 together:
Task: "Authentication providers in lib/features/auth/presentation/providers/auth_providers.dart"
Task: "Registration state providers in lib/features/registration/presentation/providers/registration_providers.dart"
Task: "Camera and computer vision providers in lib/features/registration/presentation/providers/camera_providers.dart"
```

---

## Quality Gates and Validation

### Constitutional Compliance Checkpoints (Updated for YOLOv7-Pose)
- **T015**: Verify YOLOv7-Pose detection accuracy across 5 pose types with ≥90% confidence
- **T035**: Validate multi-pose capture controller 1-second frame buffering at 24-30 FPS
- **T048**: Confirm real-time pose validation with <200ms detection latency
- **T053**: Validate <200MB memory usage during 5-pose sequence capture
- **T057**: Verify AES-256 encryption for 15-frame pose sequence data

### Testing Requirements
- **Minimum 90% code coverage** for business logic (T013-T015, T031-T032)
- **Widget test coverage** for all custom UI components (T016-T018)
- **Integration test coverage** for complete user flows (T019-T021)
- **Performance benchmarks** meeting constitutional standards (T059-T060)

---

## Task Generation Rules Applied

✅ **From Contracts**: 15 API endpoints → Contract tests (integrated into T010-T012, T019-T021)  
✅ **From Data Model**: 6 entities → Model creation tasks [P] (T022-T025)  
✅ **From User Stories**: Registration flow → Integration tests [P] (T019-T021)  
✅ **Ordering**: Setup → Tests → Models → Services → UI → Integration → Polish  
✅ **Flutter-specific**: Clean architecture, Riverpod providers, camera integration  
✅ **Parallel tasks**: Different feature modules and independent components marked [P]

---

## Validation Checklist
*GATE: Checked before task execution*

- [x] All entities have corresponding model and test tasks
- [x] All business logic has unit tests before implementation
- [x] All UI components have widget tests
- [x] Integration tests cover complete user flows
- [x] Computer vision pipeline properly decomposed into services
- [x] Flutter architecture follows clean architecture principles
- [x] Camera integration properly handles permissions and lifecycle
- [x] Performance requirements addressed in optimization tasks
- [x] Security requirements (encryption, validation) included
- [x] Each task specifies exact file path in Flutter project structure
- [x] No task modifies same file as another [P] task
- [x] All constitutional requirements mapped to specific tasks

**Total Tasks**: 62 tasks covering complete Flutter mobile app with YOLOv7-Pose guided multi-angle capture
**Estimated Duration**: 8-10 weeks with proper parallel execution
**Ready for Execution**: ✅ All tasks are specific, actionable, and properly ordered