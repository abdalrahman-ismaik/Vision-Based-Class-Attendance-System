# Data Model: Mobile Student Registration App

**Version**: 1.0  
**Date**: September 28, 2025  
**Dependencies**: research.md, spec.md

---

## Domain Entities

### 1. Administrator Entity

**Purpose**: Represents system administrators who operate the mobile app

```dart
class Administrator {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final AdministratorRole role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  
  // Authentication data (stored separately for security)
  // - Password hash
  // - Salt
  // - MFA settings
}

enum AdministratorRole {
  operator,     // Can register students
  supervisor,   // Can register + manage other operators
  admin         // Full system access
}
```

**Validation Rules**:
- `id`: UUID format, not null, unique
- `username`: Alphanumeric, 3-20 characters, unique
- `fullName`: 2-100 characters, not null
- `email`: Valid email format, unique
- `role`: Must be one of defined enum values

**State Transitions**:
- `pending` → `active` (account activation)
- `active` → `suspended` (temporary deactivation)
- `suspended` → `active` (reactivation)
- `active` → `deleted` (permanent removal)

### 2. Student Entity

**Purpose**: Represents students who are being registered in the system

```dart
class Student {
  final String id;
  final String studentId;     // University student ID
  final String fullName;
  final String? email;
  final DateTime? dateOfBirth;
  final String? department;
  final String? program;
  final StudentStatus status;
  final DateTime createdAt;
  final DateTime? lastUpdatedAt;
}

enum StudentStatus {
  pending,      // Registration in progress
  registered,   // Successfully registered
  incomplete,   // Registration failed/incomplete
  archived      // No longer active
}
```

**Validation Rules**:
- `id`: UUID format, not null, unique
- `studentId`: University format, 5-20 characters, unique
- `fullName`: 2-100 characters, not null
- `email`: Valid email format if provided
- `dateOfBirth`: Valid date, not future
- `status`: Must be one of defined enum values

**State Transitions**:
- `pending` → `registered` (successful registration)
- `pending` → `incomplete` (registration failed)
- `incomplete` → `pending` (retry registration)
- `registered` → `archived` (student no longer active)

### 3. Registration Session Entity

**Purpose**: Represents a single face registration session conducted by an administrator

```dart
class RegistrationSession {
  final String id;
  final String studentId;
  final String administratorId;
  final String videoFilePath;
  final SessionStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int videoDurationMs;
  final int totalFramesProcessed;
  final int selectedFramesCount;
  final double overallQualityScore;
  final double poseCoveragePercentage;
  final Map<String, dynamic> metadata;
}

enum SessionStatus {
  inProgress,   // Currently recording/processing
  completed,    // Successfully completed
  failed,       // Failed due to quality/errors
  cancelled,    // Manually cancelled
  expired       // Timed out
}
```

**Validation Rules**:
- `id`: UUID format, not null, unique
- `studentId`: Must reference existing Student
- `administratorId`: Must reference existing Administrator
- `videoFilePath`: Valid file path, not null
- `videoDurationMs`: Positive integer, 8000-25000 range
- `selectedFramesCount`: 15-25 range
- `overallQualityScore`: 0.0-1.0 range
- `poseCoveragePercentage`: 0.0-100.0 range

**State Transitions**:
- `inProgress` → `completed` (successful processing)
- `inProgress` → `failed` (quality threshold not met)
- `inProgress` → `cancelled` (administrator cancellation)
- `inProgress` → `expired` (timeout occurred)
- `failed` → `inProgress` (retry attempt)

### 4. Selected Frame Entity

**Purpose**: Represents individual frames selected from registration video

```dart
class SelectedFrame {
  final String id;
  final String sessionId;
  final String imageFilePath;
  final int timestampMs;        // Position in video
  final double qualityScore;
  final PoseAngles poseAngles;
  final FaceMetrics faceMetrics;
  final DateTime extractedAt;
}

class PoseAngles {
  final double yaw;     // Head rotation left/right (-90 to +90)
  final double pitch;   // Head tilt up/down (-90 to +90)
  final double roll;    // Head roll left/right (-180 to +180)
  final double confidence; // ML confidence score (0.0-1.0)
}

class FaceMetrics {
  final BoundingBox boundingBox;
  final double faceSize;           // Relative to frame size
  final double sharpnessScore;     // Image sharpness metric
  final double lightingScore;      // Lighting quality metric
  final double symmetryScore;      // Face symmetry metric
  final bool hasGlasses;
  final bool hasHat;
  final bool isSmiling;
}

class BoundingBox {
  final double x;      // Top-left x coordinate (0.0-1.0)
  final double y;      // Top-left y coordinate (0.0-1.0)
  final double width;  // Box width (0.0-1.0)
  final double height; // Box height (0.0-1.0)
}
```

**Validation Rules**:
- `sessionId`: Must reference existing RegistrationSession
- `qualityScore`: 0.8-1.0 range (minimum quality threshold)
- `yaw`: -90.0 to +90.0 degrees
- `pitch`: -90.0 to +90.0 degrees  
- `roll`: -180.0 to +180.0 degrees
- `faceSize`: 0.1-1.0 (minimum 10% of frame)
- All score metrics: 0.0-1.0 range

### 5. Quality Metrics Entity

**Purpose**: Aggregated quality metrics for registration sessions

```dart
class QualityMetrics {
  final String sessionId;
  final double overallQuality;
  final CoverageMetrics poseMetrics;
  final QualityDistribution qualityDistribution;
  final EnvironmentalFactors environmental;
  final ProcessingStats processingStats;
}

class CoverageMetrics {
  final double frontalCoverage;    // -15° to +15° yaw
  final double leftProfileCoverage; // 15° to 60° yaw
  final double rightProfileCoverage; // -60° to -15° yaw
  final double uptiltCoverage;     // -20° to -5° pitch
  final double downtiltCoverage;   // 5° to 20° pitch
  final double overallCoverage;    // Combined percentage
}

class QualityDistribution {
  final int highQuality;    // Frames with score >0.9
  final int mediumQuality;  // Frames with score 0.8-0.9
  final int lowQuality;     // Frames with score <0.8
  final double averageScore;
  final double standardDeviation;
}

class EnvironmentalFactors {
  final LightingCondition lighting;
  final BackgroundType background;
  final double noiseLevel;
  final List<String> detectedIssues;
}

enum LightingCondition {
  excellent,  // Well-lit, even lighting
  good,       // Adequate lighting
  poor,       // Too dark or too bright
  uneven      // Harsh shadows or mixed lighting
}

enum BackgroundType {
  plain,      // Solid color or minimal patterns
  complex,    // Busy background
  outdoor,    // Natural outdoor setting
  indoor      // Indoor environment
}
```

### 6. Export Package Entity

**Purpose**: Standardized data package for AI system integration

```dart
class ExportPackage {
  final String id;
  final String sessionId;
  final PackageMetadata metadata;
  final List<ExportFrame> frames;
  final PackageStatus status;
  final DateTime createdAt;
  final DateTime? exportedAt;
  final String? exportFilePath;
}

class PackageMetadata {
  final String studentId;
  final String studentName;
  final String administratorId;
  final String appVersion;
  final String deviceInfo;
  final DateTime sessionDate;
  final QualityMetrics qualityMetrics;
  final Map<String, dynamic> customFields;
}

class ExportFrame {
  final String frameId;
  final String base64ImageData;
  final FrameMetadata metadata;
}

class FrameMetadata {
  final int timestampMs;
  final double qualityScore;
  final PoseAngles pose;
  final FaceMetrics faceMetrics;
  final Map<String, double> additionalScores;
}

enum PackageStatus {
  preparing,   // Being generated
  ready,       // Available for export
  exported,    // Successfully sent
  failed,      // Export failed
  expired      // Export window expired
}
```

---

## Database Schema (SQLite)

### Tables Structure

```sql
-- Administrators table
CREATE TABLE administrators (
    id TEXT PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('operator', 'supervisor', 'admin')),
    created_at DATETIME NOT NULL,
    last_login_at DATETIME,
    is_active BOOLEAN NOT NULL DEFAULT 1
);

-- Students table
CREATE TABLE students (
    id TEXT PRIMARY KEY,
    student_id TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    email TEXT,
    date_of_birth DATE,
    department TEXT,
    program TEXT,
    status TEXT NOT NULL CHECK (status IN ('pending', 'registered', 'incomplete', 'archived')),
    created_at DATETIME NOT NULL,
    last_updated_at DATETIME
);

-- Registration sessions table
CREATE TABLE registration_sessions (
    id TEXT PRIMARY KEY,
    student_id TEXT NOT NULL,
    administrator_id TEXT NOT NULL,
    video_file_path TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('inProgress', 'completed', 'failed', 'cancelled', 'expired')),
    started_at DATETIME NOT NULL,
    completed_at DATETIME,
    video_duration_ms INTEGER,
    total_frames_processed INTEGER,
    selected_frames_count INTEGER,
    overall_quality_score REAL,
    pose_coverage_percentage REAL,
    metadata TEXT, -- JSON
    FOREIGN KEY (student_id) REFERENCES students (id),
    FOREIGN KEY (administrator_id) REFERENCES administrators (id)
);

-- Selected frames table
CREATE TABLE selected_frames (
    id TEXT PRIMARY KEY,
    session_id TEXT NOT NULL,
    image_file_path TEXT NOT NULL,
    timestamp_ms INTEGER NOT NULL,
    quality_score REAL NOT NULL CHECK (quality_score >= 0.8),
    pose_yaw REAL NOT NULL,
    pose_pitch REAL NOT NULL,
    pose_roll REAL NOT NULL,
    pose_confidence REAL NOT NULL,
    face_bounding_box TEXT NOT NULL, -- JSON
    face_size REAL NOT NULL,
    sharpness_score REAL NOT NULL,
    lighting_score REAL NOT NULL,
    symmetry_score REAL NOT NULL,
    has_glasses BOOLEAN NOT NULL DEFAULT 0,
    has_hat BOOLEAN NOT NULL DEFAULT 0,
    is_smiling BOOLEAN NOT NULL DEFAULT 0,
    extracted_at DATETIME NOT NULL,
    FOREIGN KEY (session_id) REFERENCES registration_sessions (id)
);

-- Quality metrics table
CREATE TABLE quality_metrics (
    session_id TEXT PRIMARY KEY,
    overall_quality REAL NOT NULL,
    frontal_coverage REAL NOT NULL,
    left_profile_coverage REAL NOT NULL,
    right_profile_coverage REAL NOT NULL,
    uptilt_coverage REAL NOT NULL,
    downtilt_coverage REAL NOT NULL,
    overall_coverage REAL NOT NULL,
    high_quality_count INTEGER NOT NULL,
    medium_quality_count INTEGER NOT NULL,
    low_quality_count INTEGER NOT NULL,
    average_score REAL NOT NULL,
    standard_deviation REAL NOT NULL,
    lighting_condition TEXT NOT NULL,
    background_type TEXT NOT NULL,
    noise_level REAL NOT NULL,
    detected_issues TEXT, -- JSON array
    FOREIGN KEY (session_id) REFERENCES registration_sessions (id)
);

-- Export packages table
CREATE TABLE export_packages (
    id TEXT PRIMARY KEY,
    session_id TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('preparing', 'ready', 'exported', 'failed', 'expired')),
    created_at DATETIME NOT NULL,
    exported_at DATETIME,
    export_file_path TEXT,
    metadata TEXT NOT NULL, -- JSON
    FOREIGN KEY (session_id) REFERENCES registration_sessions (id)
);

-- Authentication table (separate for security)
CREATE TABLE auth_credentials (
    administrator_id TEXT PRIMARY KEY,
    password_hash TEXT NOT NULL,
    salt TEXT NOT NULL,
    mfa_enabled BOOLEAN NOT NULL DEFAULT 0,
    mfa_secret TEXT,
    failed_attempts INTEGER NOT NULL DEFAULT 0,
    locked_until DATETIME,
    last_password_change DATETIME NOT NULL,
    FOREIGN KEY (administrator_id) REFERENCES administrators (id)
);

-- Audit log table
CREATE TABLE audit_logs (
    id TEXT PRIMARY KEY,
    administrator_id TEXT NOT NULL,
    action TEXT NOT NULL,
    resource_type TEXT NOT NULL,
    resource_id TEXT,
    details TEXT, -- JSON
    ip_address TEXT,
    user_agent TEXT,
    timestamp DATETIME NOT NULL,
    FOREIGN KEY (administrator_id) REFERENCES administrators (id)
);
```

### Indexes for Performance

```sql
-- Performance indexes
CREATE INDEX idx_students_student_id ON students (student_id);
CREATE INDEX idx_students_status ON students (status);
CREATE INDEX idx_sessions_student ON registration_sessions (student_id);
CREATE INDEX idx_sessions_admin ON registration_sessions (administrator_id);
CREATE INDEX idx_sessions_status ON registration_sessions (status);
CREATE INDEX idx_sessions_date ON registration_sessions (started_at);
CREATE INDEX idx_frames_session ON selected_frames (session_id);
CREATE INDEX idx_frames_quality ON selected_frames (quality_score);
CREATE INDEX idx_audit_admin ON audit_logs (administrator_id);
CREATE INDEX idx_audit_timestamp ON audit_logs (timestamp);
```

---

## Repository Interfaces

### Student Repository
```dart
abstract class StudentRepository {
  Future<Student> createStudent(CreateStudentRequest request);
  Future<Student?> getStudentById(String id);
  Future<Student?> getStudentByStudentId(String studentId);
  Future<List<Student>> getAllStudents({StudentStatus? status});
  Future<Student> updateStudent(String id, UpdateStudentRequest request);
  Future<void> deleteStudent(String id);
  Future<bool> existsByStudentId(String studentId);
}
```

### Registration Repository
```dart
abstract class RegistrationRepository {
  Future<RegistrationSession> createSession(CreateSessionRequest request);
  Future<RegistrationSession?> getSessionById(String id);
  Future<List<RegistrationSession>> getSessionsByStudent(String studentId);
  Future<RegistrationSession> updateSession(String id, UpdateSessionRequest request);
  Stream<RegistrationSession> watchSession(String id);
  
  Future<List<SelectedFrame>> saveSelectedFrames(String sessionId, List<SelectedFrame> frames);
  Future<List<SelectedFrame>> getSelectedFrames(String sessionId);
  
  Future<QualityMetrics> saveQualityMetrics(String sessionId, QualityMetrics metrics);
  Future<QualityMetrics?> getQualityMetrics(String sessionId);
}
```

### Export Repository
```dart
abstract class ExportRepository {
  Future<ExportPackage> createPackage(String sessionId);
  Future<ExportPackage?> getPackageById(String id);
  Future<List<ExportPackage>> getPackagesByStatus(PackageStatus status);
  Future<ExportPackage> updatePackageStatus(String id, PackageStatus status);
  Future<String> exportPackageToJson(String packageId);
  Future<void> deleteExpiredPackages();
}
```

---

## Validation Rules Summary

### Data Integrity Rules
1. **Foreign Key Constraints**: All relationships must be valid
2. **Status Transitions**: Only valid state transitions allowed
3. **Quality Thresholds**: Minimum quality scores enforced
4. **Temporal Constraints**: Dates must be logical (e.g., completion after start)

### Business Rules
1. **Session Timeout**: Sessions expire after 10 minutes of inactivity
2. **Retry Limits**: Maximum 3 retry attempts per student per day
3. **Data Retention**: Registration data retained for 2 years by default
4. **Administrator Permissions**: Role-based access control enforced

### Performance Rules
1. **Batch Operations**: Large operations must be batched
2. **Index Usage**: All queries must use appropriate indexes
3. **Transaction Boundaries**: Long operations must be transactional
4. **Memory Management**: Large objects must be properly disposed

This data model provides a comprehensive foundation for the mobile registration app with proper validation, relationships, and performance considerations.