# Research Report: Mobile Student Registration App Technical Stack

**Research Date**: September 28, 2025  
**Scope**: Flutter/Dart mobile app for face registration with computer vision

---

## Technology Stack Research

### 1. Flutter Framework & Dart Language

**Decision**: Flutter 3.16+ with Dart 3.0+

**Rationale**:
- **Cross-platform efficiency**: Single codebase for Android and iOS with native performance
- **Real-time processing capability**: Direct access to camera APIs and ML processing
- **UI performance**: Flutter's rendering engine provides 60+ FPS smooth animations
- **Computer vision support**: Excellent ML Kit and OpenCV integration
- **State management ecosystem**: Mature Riverpod and GoRouter libraries

**Alternatives considered**:
- React Native: Less efficient for computer vision tasks, weaker ML Kit integration
- Native Android (Kotlin): Platform-specific, doubles development effort
- Xamarin: Microsoft ecosystem dependency, less ML/CV library support

### 2. Navigation Architecture

**Decision**: GoRouter 12.0+

**Rationale**:
- **Declarative routing**: Type-safe route definitions matching clean architecture
- **Deep linking support**: URL-based navigation for future web deployment
- **Nested navigation**: Supports complex registration flow with sub-routes
- **State restoration**: Maintains navigation state during app lifecycle
- **Integration**: Seamless Riverpod integration for route guards

**Alternatives considered**:
- Navigator 2.0 directly: Too low-level, complex implementation
- AutoRoute: Code generation overhead, less flexible
- Beamer: Smaller community, less documentation

### 3. State Management

**Decision**: Riverpod 2.4+ (with Hooks for UI)

**Rationale**:
- **Compile-time safety**: Eliminates runtime state management errors
- **Testability**: Easy mocking and testing of providers
- **Performance**: Automatic dependency tracking and rebuilds
- **Computer vision integration**: Excellent for managing camera streams and ML processing
- **Clean architecture fit**: Natural separation of data/domain/presentation layers

**Alternatives considered**:
- BLoC: More boilerplate, complex for simple state
- Provider: Legacy, less type-safe than Riverpod
- GetX: Service locator pattern, testing difficulties

### 4. Computer Vision & ML (Updated to YOLOv7-Pose)

**Decision**: YOLOv7-Pose with PyTorch Mobile + Guided Multi-Pose Capture

**Rationale**:
- **Advanced pose detection**: YOLOv7-Pose provides 17 COCO keypoints for precise pose angle classification
- **Multi-pose guidance**: Supports 5 specific poses (straight, right profile, left profile, head up, head down)
- **On-device processing**: PyTorch Mobile enables local inference with GPU/CPU fallback
- **Real-time validation**: Confidence-based pose validation before frame capture
- **Quality optimization**: Pose-specific frame selection (best 3 per pose)

**YOLOv7-Pose Pipeline Components**:
- **Pose detection**: YOLOv7-Pose model with letterboxing and normalization preprocessing
- **Pose classification**: Keypoint geometry analysis for 5-pose validation
- **Guided capture**: 1-second frame capture per validated pose (24-30 FPS)
- **Frame selection**: Pose-aware quality scoring and diversity analysis

**Alternatives considered**:
- Google ML Kit: Less precise pose angle detection, limited to basic face tracking
- MediaPipe: Python 3.13 compatibility issues, complex mobile integration
- OpenPose: Heavier computational requirements, not optimized for mobile

### 5. Local Database & Storage

**Decision**: SQLite (sqflite 2.3+) + Hive for key-value storage

**Rationale**:
- **SQLite for relational data**: Student profiles, registration sessions, metadata
- **Hive for configuration**: App settings, temporary data, cache
- **Offline-first**: No network dependency for core functionality
- **Performance**: Fast queries for thousands of student records
- **Encryption**: Built-in AES-256 encryption support

**Schema Design**:
```sql
-- Student profiles
CREATE TABLE students (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    student_id TEXT UNIQUE NOT NULL,
    registration_date DATETIME,
    status TEXT DEFAULT 'pending'
);

-- Registration sessions
CREATE TABLE registration_sessions (
    id TEXT PRIMARY KEY,
    student_id TEXT NOT NULL,
    administrator_id TEXT NOT NULL,
    video_path TEXT,
    frame_count INTEGER,
    quality_score REAL,
    pose_coverage REAL,
    created_at DATETIME,
    status TEXT DEFAULT 'in_progress',
    FOREIGN KEY (student_id) REFERENCES students (id)
);

-- Selected frames
CREATE TABLE selected_frames (
    id TEXT PRIMARY KEY,
    session_id TEXT NOT NULL,
    frame_path TEXT NOT NULL,
    quality_score REAL,
    pose_angles TEXT, -- JSON: {yaw, pitch, roll}
    timestamp_ms INTEGER,
    FOREIGN KEY (session_id) REFERENCES registration_sessions (id)
);
```

**Alternatives considered**:
- Firebase Firestore: Requires network, overkill for offline-first
- Isar: Newer, less proven in production environments
- ObjectBox: Commercial licensing concerns

### 6. Camera & Media Handling (Updated for Guided Multi-Pose)

**Decision**: camera 0.10.5+ plugin with guided pose capture (no continuous recording)

**Rationale**:
- **Live preview**: Continuous camera preview for real-time YOLOv7-Pose feedback
- **Pose-triggered capture**: 1-second frame capture only when pose is validated
- **Cross-platform**: Consistent API across Android and iOS with YOLOv7-Pose integration
- **Performance**: No continuous video recording reduces battery usage and storage

**Guided Multi-Pose Pipeline**:
1. **Camera preview**: Continuous preview for pose guidance and detection feedback
2. **YOLOv7-Pose detection**: Real-time pose validation with confidence thresholds
3. **Pose-triggered capture**: 1-second burst capture (24-30 frames) per validated pose
4. **Frame buffering**: Temporary storage during pose-specific capture windows
5. **Quality selection**: Best 3 frames per pose using pose-aware quality metrics

**Alternatives considered**:
- Continuous video recording: Wasteful battery usage, unnecessary storage overhead
- camera_awesome: Heavier dependency, not optimized for guided capture workflow
- Custom platform channels: Complex implementation for pose-triggered capture timing

### 7. UI/UX Design System

**Decision**: Material Design 3 with custom computer vision overlay

**Rationale**:
- **Modern aesthetic**: Material You theming with dynamic colors
- **Accessibility**: Built-in accessibility features and screen reader support
- **Administrator-friendly**: Clear, professional interface for institutional use
- **Real-time feedback**: Custom overlay widgets for pose guidance
- **Performance**: Flutter's widget system optimized for 60+ FPS

**Key UI Components**:
- `CameraOverlay`: Real-time pose guidance and quality feedback
- `RegistrationProgress`: Visual pose coverage tracking
- `QualityIndicator`: Live image quality meter
- `AdminDashboard`: Registration management interface

**Alternatives considered**:
- Cupertino (iOS style): Android-primary deployment
- Custom design system: Increased development time
- Third-party UI kits: Additional dependencies, licensing

### 8. Testing Strategy (Updated for YOLOv7-Pose)

**Decision**: Multi-layered testing with YOLOv7-Pose mocks and pose-specific validation

**Testing Framework**:
- **Unit tests**: flutter_test for guided pose capture business logic
- **Widget tests**: flutter_test for pose guidance animation components
- **Integration tests**: integration_test for complete 5-pose capture flows
- **Golden tests**: For pose guidance UI consistency across devices

**YOLOv7-Pose Testing**:
- **Mock YOLOv7-Pose**: Deterministic pose detection for 5-pose sequence testing
- **Pose-specific data**: Test images with known keypoints for each pose type
- **Confidence validation**: Test pose detection confidence thresholds
- **Performance benchmarks**: YOLOv7-Pose inference speed and memory usage tests

**Alternatives considered**:
- Real YOLOv7-Pose in tests: Too slow and resource-intensive for CI/CD
- Static image testing only: Insufficient for real-time pose guidance validation

### 9. Performance Optimization (Updated for YOLOv7-Pose)

**Research Findings**:
- **YOLOv7-Pose inference**: GPU acceleration essential, CPU fallback required
- **Pose detection latency**: Target <200ms inference time for real-time feedback
- **Memory management**: Critical for 1-second frame buffers per pose
- **Battery efficiency**: Guided capture reduces battery usage vs continuous recording

**YOLOv7-Pose Optimization Strategies**:
1. **Model optimization**: Use quantized YOLOv7-Pose models for mobile inference
2. **GPU/CPU fallback**: Automatic detection and graceful degradation
3. **Frame buffer management**: Efficient 1-second capture buffers per pose
4. **Pose-triggered processing**: Only process frames when pose guidance active
5. **Memory pools**: Reuse YOLOv7-Pose input/output tensors to reduce allocation overhead

---

## Architecture Patterns

### Clean Architecture Implementation

**Layers**:
1. **Presentation**: UI widgets, state management (Riverpod providers)
2. **Domain**: Business logic, use cases, entities
3. **Data**: Repositories, data sources (database, camera, ML Kit)

**Dependency Flow**: Presentation → Domain ← Data

**Benefits**:
- **Testability**: Easy to mock and test each layer
- **Maintainability**: Clear separation of concerns
- **Scalability**: Easy to add new features and data sources

### Repository Pattern

**Implementation**:
```dart
abstract class RegistrationRepository {
  Future<RegistrationSession> createSession(String studentId, String adminId);
  Stream<QualityMetrics> processVideoStream();
  Future<List<SelectedFrame>> selectOptimalFrames(String sessionId);
}

class LocalRegistrationRepository implements RegistrationRepository {
  final DatabaseService database;
  final ComputerVisionService cvService;
  
  // Implementation with local SQLite and ML Kit
}
```

### State Management Pattern

**Riverpod Providers Structure**:
```dart
// Data layer providers
final databaseProvider = Provider<DatabaseService>((ref) => DatabaseService());
final cameraProvider = Provider<CameraService>((ref) => CameraService());

// Repository providers
final registrationRepoProvider = Provider<RegistrationRepository>((ref) {
  return LocalRegistrationRepository(
    database: ref.read(databaseProvider),
    cvService: ref.read(computerVisionProvider),
  );
});

// Use case providers
final createRegistrationProvider = Provider<CreateRegistrationUseCase>((ref) {
  return CreateRegistrationUseCase(ref.read(registrationRepoProvider));
});

// UI state providers
final registrationStateProvider = StateNotifierProvider<RegistrationNotifier, RegistrationState>((ref) {
  return RegistrationNotifier(ref.read(createRegistrationProvider));
});
```

---

## Security & Privacy Research

### Data Encryption

**Implementation**: AES-256 encryption for all biometric data
- **At rest**: SQLCipher for database encryption
- **In transit**: TLS 1.3 for future API communication
- **Key management**: Android Keystore / iOS Keychain

### Privacy by Design

**Strategies**:
1. **Local processing**: All CV operations on-device
2. **Minimal data**: Only store necessary biometric features
3. **Data retention**: Configurable retention policies
4. **Consent management**: Clear privacy notices and consent flows

### Authentication & Authorization

**Administrator Security**:
- **Multi-factor authentication**: PIN + biometric (if available)
- **Session management**: Secure token-based sessions
- **Audit logging**: Comprehensive activity logs
- **Role-based access**: Different permission levels

---

## Integration Requirements

### AI System Integration

**Data Export Format**:
```json
{
  "registration_id": "uuid",
  "student_profile": {
    "id": "student_123",
    "name": "John Doe",
    "metadata": {}
  },
  "session_data": {
    "video_metadata": {},
    "quality_metrics": {},
    "administrator_id": "admin_456"
  },
  "selected_frames": [
    {
      "frame_id": "uuid",
      "image_data": "base64_encoded",
      "quality_score": 0.85,
      "pose_angles": {"yaw": -15, "pitch": 5, "roll": 2},
      "timestamp_ms": 1500
    }
  ]
}
```

### Future API Integration

**RESTful Endpoints Design**:
- `POST /api/v1/registrations` - Submit registration data
- `GET /api/v1/students/{id}` - Retrieve student status
- `POST /api/v1/sync` - Bulk data synchronization

---

## Performance Benchmarks

### Target Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Face Detection FPS | ≥20 FPS | Real-time camera stream |
| Frame Processing Latency | <150ms | ML Kit + custom pipeline |
| UI Response Time | <100ms | Touch to visual feedback |
| Memory Usage | <200MB | Peak during video processing |
| App Launch Time | <2s | Cold start to camera ready |
| Frame Selection Time | <5s | Post-recording processing |

### Testing Approach

1. **Synthetic benchmarks**: Known test images and videos
2. **Real-world testing**: Various lighting conditions and devices
3. **Stress testing**: Memory pressure and long recording sessions
4. **Cross-device validation**: Different Android devices and versions

---

## Conclusions

The research validates Flutter with Riverpod and GoRouter as the optimal technology stack for this computer vision mobile application. The combination provides:

1. **Technical feasibility**: All requirements can be implemented with chosen technologies
2. **Performance capability**: Real-time processing targets are achievable
3. **Scalability**: Architecture supports university-scale deployment
4. **Maintainability**: Clean architecture ensures long-term maintainability
5. **Security**: Privacy-by-design with comprehensive encryption

The architecture is ready for Phase 1 design and contract generation.