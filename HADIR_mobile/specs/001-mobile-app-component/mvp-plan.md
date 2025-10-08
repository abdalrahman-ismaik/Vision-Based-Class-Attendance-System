# 2-Week MVP Development Plan
**Target: Complete functional mobile app by October 12, 2025**  
**Priority: MVP with core functionality first, then iterative improvements**

## MVP Scope Definition
**Core Features Only:**
- Administrator login (simple credential check)
- Student information input
- Video recording with basic face detection
- Frame selection and export
- Local data storage

**Deferred to Post-MVP:**
- Advanced pose estimation
- Real-time quality scoring
- Complex overlay UI
- Advanced security features
- Performance optimizations
- Comprehensive testing

---

## Week 1: Foundation & Core (Oct 1-5)

### Day 1-2: Project Setup & Basic Structure
**Sprint: Foundation** 
- **T001**: Flutter project creation with basic structure
- **T002**: Essential dependencies only (camera, basic ML Kit, sqflite)
- **T003**: Android permissions setup
- **T004**: Simple database schema (students, sessions tables only)
- **T005**: Basic app configuration

**Deliverable**: Working Flutter app that launches

### Day 3-4: Authentication & Navigation  
**Sprint: User Flow**
- **T040**: Simple login screen (hardcoded admin credentials for MVP)
- **T041**: Student input screen with basic form
- **T045**: Basic navigation between screens (no GoRouter, use Navigator.push)

**Deliverable**: Administrator can log in and navigate to student registration

### Day 5: Basic Camera Integration
**Sprint: Camera Foundation**
- **T042**: Basic camera screen with recording capability
- **T033** (Simplified): Basic face detection using ML Kit (no advanced features)

**Deliverable**: Camera can record video and detect faces

---

## Week 2: Core Functionality & MVP Release (Oct 6-12)

### Day 6-7: Frame Processing & Selection
**Sprint: Core Logic**
- **T036** (Simplified): Basic frame selection (select frames where face is detected)
- **T022-T025** (Essential only): Basic entity models for Student and RegistrationSession
- **T029-T030** (Simplified): Basic database operations

**Deliverable**: App can select frames from video recording

### Day 8-9: Data Export & Integration
**Sprint: Data Handling**
- **T048-T049** (Simplified): Basic JSON export functionality
- **T037-T039** (Minimal): Simple state management (no Riverpod, use StatefulWidget)
- Basic error handling for critical paths

**Deliverable**: App can export student registration data as JSON

### Day 10-12: Testing & Polish
**Sprint: MVP Completion**
- **T019** (Essential): Basic integration test for registration flow
- **T051** (Critical): Basic performance optimization
- **T052** (Essential): Basic error handling
- Manual testing and bug fixes

**Deliverable**: Working MVP ready for demonstration

---

## MVP Task Prioritization

### CRITICAL (Must Have - Week 1)
```
T001, T002, T003, T004, T005: Project setup
T040, T041, T045: Basic user flow
T042, T033: Camera and face detection
```

### HIGH (Core Features - Week 2, Days 1-2)  
```
T036, T022, T023, T029: Frame selection and data models
T048, T049: Export functionality
```

### MEDIUM (Polish - Week 2, Days 3-4)
```
T037, T019, T051, T052: State management, testing, optimization
```

### DEFERRED (Post-MVP)
```
All advanced computer vision (T034, T035)
Advanced UI components (T043, T044)
Comprehensive testing (T006-T021)
Security features (T054-T056)
Performance optimization (remaining tasks)
```

---

## Daily Development Schedule

### Week 1 Schedule
- **Monday (Day 1)**: T001-T002 → Working Flutter project with dependencies
- **Tuesday (Day 2)**: T003-T005 → Complete project foundation
- **Wednesday (Day 3)**: T040-T041 → Authentication and student input
- **Thursday (Day 4)**: T045 + navigation testing → Complete user flow
- **Friday (Day 5)**: T042, T033 → Basic camera and face detection

### Week 2 Schedule  
- **Monday (Day 6)**: T036, T022-T023 → Frame selection and models
- **Tuesday (Day 7)**: T024-T025, T029-T030 → Complete data handling
- **Wednesday (Day 8)**: T048-T049 → Export functionality
- **Thursday (Day 9)**: T037-T039 → Basic state management
- **Friday (Day 10)**: T019, T051-T052 → Testing and optimization
- **Weekend (Days 11-12)**: Bug fixes, manual testing, MVP finalization

---

## MVP Success Criteria

### Functional Requirements
✅ Administrator can log in with credentials  
✅ Administrator can input student information  
✅ Administrator can record video of student face  
✅ App detects faces in video frames  
✅ App selects best frames automatically  
✅ App exports registration data as JSON  
✅ App stores data locally in SQLite  

### Technical Requirements
✅ App launches without crashes  
✅ Camera permissions work correctly  
✅ Face detection runs at acceptable speed (≥10 FPS for MVP)  
✅ Basic error handling prevents data loss  
✅ Export format is valid JSON  

### Performance Targets (Relaxed for MVP)
- Face detection: ≥10 FPS (vs 20+ FPS in full version)
- Frame processing: <300ms (vs <150ms in full version)  
- Memory usage: <300MB (vs <200MB in full version)
- Basic quality threshold: >0.5 (vs >0.8 in full version)

---

## Risk Mitigation

### High-Risk Items (Address First)
1. **ML Kit Integration**: Start with basic face detection, defer advanced features
2. **Camera Permissions**: Test on real Android device early
3. **Frame Selection Logic**: Keep algorithm simple, focus on face presence over quality
4. **Database Operations**: Use simple schema, defer complex relationships

### Fallback Options
- **Face Detection Issues**: Fallback to manual frame selection by administrator  
- **Camera Problems**: Use device gallery to select existing videos
- **Export Problems**: Simple file save to downloads directory
- **Database Issues**: Use temporary in-memory storage for demonstration

---

## Post-MVP Roadmap (Weeks 3-4)

### Phase 2: Enhancement (Week 3)
- Advanced pose estimation (T034)
- Quality scoring system (T035)
- Real-time overlay UI (T043-T044)
- Comprehensive error handling (T052-T053)

### Phase 3: Polish (Week 4)  
- Full test suite (T006-T021)
- Performance optimization (T051)
- Security hardening (T054-T056)
- Documentation completion (T057-T058)

---

## Development Environment Requirements

### Immediate Setup Needed
- Flutter SDK 3.16+ installed
- Android Studio with Android SDK
- Physical Android device for testing (camera required)
- VS Code with Flutter/Dart extensions

### Dependencies (Minimal Set)
```yaml
dependencies:
  flutter_sdk: flutter
  camera: ^0.10.5
  google_ml_kit: ^0.15.0
  sqflite: ^2.3.0
  path: ^1.8.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
```

---

## Quality Gates

### Week 1 Gate (Friday Check)
- [ ] App launches successfully
- [ ] Camera permissions granted
- [ ] Basic navigation works
- [ ] Face detection shows results

### MVP Gate (End of Week 2)
- [ ] Complete registration flow functional
- [ ] Data exports successfully
- [ ] No critical crashes
- [ ] Ready for demonstration

**Estimated MVP Delivery**: October 12, 2025 (Day 12)  
**Buffer Time**: Built into schedule with simpler implementations  
**Risk Level**: MEDIUM (achievable with focused scope)