# HADIR Project Structure Guide

This document provides a comprehensive overview of the HADIR project structure, file organization, and dependencies to help developers navigate and understand the codebase efficiently.

## Project Overview

```
HADIR/
├── CHANGELOG.md                     # Detailed change history
├── ARCHITECTURE.md                  # Architecture documentation
├── TROUBLESHOOTING.md              # Common issues and solutions
├── PROJECT_STRUCTURE.md            # This file
├── DEVELOPMENT_WORKFLOW.md         # Development guidelines (coming soon)
├── project_plan.md                 # Original project planning
├── srs_document.md                 # Software requirements specification
└── system_design.md                # System design document
```

## Mobile Application Structure

### Main Application (`hadir_mobile_full/`)

```
hadir_mobile_full/
├── lib/                            # Main source code
│   ├── app/                        # Application-level configuration
│   ├── core/                       # Shared services and utilities
│   ├── features/                   # Feature-based modules
│   └── shared/                     # Shared domain objects
├── test/                           # Test files mirror lib/ structure
├── assets/                         # Static assets (images, fonts, etc.)
├── android/                        # Android-specific configuration
├── ios/                           # iOS-specific configuration
├── pubspec.yaml                   # Dart package dependencies
└── README.md                      # Setup and usage instructions
```

## Detailed Directory Structure

### 1. Application Layer (`lib/app/`)

```
app/
├── router/
│   └── app_router.dart            # GoRouter configuration and route definitions
└── providers/
    └── app_providers.dart         # Global application providers
```

**Purpose**: Application-wide configuration and routing
**Dependencies**: GoRouter, Riverpod providers
**Key Files**:
- `app_router.dart`: Defines all application routes and navigation guards

### 2. Core Layer (`lib/core/`)

```
core/
├── computer_vision/
│   ├── yolov7_pose_detector.dart  # YOLOv7-Pose integration
│   ├── pose_angles.dart           # Pose angle calculations
│   ├── face_metrics.dart          # Face detection metrics
│   └── bounding_box.dart          # Bounding box utilities
├── utils/
│   ├── app_config.dart            # Application configuration
│   ├── constants.dart             # Application constants
│   └── validators.dart            # Input validation utilities
└── exceptions/
    └── core_exceptions.dart       # Core-level exceptions
```

**Purpose**: Shared services, utilities, and computer vision processing
**Dependencies**: ML Kit, Camera plugins, native platform code
**Key Components**:
- **YOLOv7PoseDetector**: Singleton service for pose detection
- **Face Recognition**: Embedding generation and quality assessment
- **Validation**: Reusable validation logic

### 3. Features Layer (`lib/features/`)

The features layer is organized by business domain, each containing its own clean architecture layers:

#### Authentication Feature (`features/auth/`)

```
auth/
├── domain/
│   ├── entities/
│   │   └── admin_user.dart        # Administrator entity (if separate from shared)
│   ├── repositories/
│   │   └── auth_repository.dart   # Authentication repository interface
│   └── use_cases/
│       └── authentication_use_cases.dart # Business logic for auth operations
├── data/
│   ├── repositories/
│   │   └── auth_repository_impl.dart # Repository implementation
│   ├── models/
│   │   ├── login_request.dart     # API request models
│   │   └── auth_response.dart     # API response models
│   └── services/
│       └── auth_api_service.dart  # External API communication
└── presentation/
    ├── screens/
    │   └── login_screen.dart      # Login UI screen
    ├── widgets/
    │   ├── login_form.dart        # Reusable login form widget
    │   └── auth_error_widget.dart # Error display widget
    └── providers/
        └── auth_provider.dart     # Riverpod state management
```

#### Registration Feature (`features/registration/`)

```
registration/
├── domain/
│   ├── entities/
│   │   └── registration_entities.dart # Registration-specific entities
│   ├── repositories/
│   │   ├── registration_repository.dart # Session management interface
│   │   └── student_repository.dart    # Student data interface
│   └── use_cases/
│       └── registration_use_cases.dart # Registration business logic
├── data/
│   ├── repositories/
│   │   ├── registration_repository_impl.dart # Session management implementation
│   │   └── student_repository_impl.dart      # Student data implementation
│   ├── models/
│   │   ├── registration_requests.dart  # API request DTOs
│   │   └── registration_responses.dart # API response DTOs
│   └── services/
│       ├── registration_api_service.dart # Registration API client
│       └── camera_service.dart          # Camera hardware interface
└── presentation/
    ├── screens/
    │   └── registration_screen.dart     # Multi-step registration wizard
    ├── widgets/
    │   ├── guided_pose_capture.dart     # Pose guidance widget
    │   ├── student_form.dart            # Student information form
    │   ├── pose_progress_indicator.dart # Visual progress tracking
    │   └── quality_feedback_widget.dart # Real-time quality feedback
    └── providers/
        ├── registration_provider.dart   # Registration state management
        └── pose_capture_provider.dart   # Camera and pose detection state
```

#### Export Feature (`features/export/`)

```
export/
├── domain/
│   ├── repositories/
│   │   └── export_repository.dart     # Data export interface
│   └── use_cases/
│       └── export_use_cases.dart      # Export business logic
├── data/
│   ├── repositories/
│   │   └── export_repository_impl.dart # Export implementation
│   ├── models/
│   │   └── export_models.dart         # Export format models
│   └── services/
│       └── export_service.dart        # File generation service
└── presentation/
    ├── screens/
    │   └── export_screen.dart         # Export configuration UI
    ├── widgets/
    │   └── export_options_widget.dart # Export format selection
    └── providers/
        └── export_provider.dart      # Export state management
```

### 4. Shared Layer (`lib/shared/`)

```
shared/
├── domain/
│   ├── entities/
│   │   ├── student.dart               # Core student entity
│   │   ├── registration_session.dart # Registration workflow entity
│   │   ├── selected_frame.dart        # Captured frame entity
│   │   └── administrator.dart         # Admin user entity
│   └── exceptions/
│       └── hadir_exceptions.dart      # Comprehensive exception hierarchy
├── data/
│   ├── repositories/
│   │   └── base_repository.dart       # Common repository functionality
│   ├── services/
│   │   ├── database_service.dart      # SQLite database service
│   │   ├── file_service.dart          # File system operations
│   │   └── frame_selection_api_service.dart # Frame quality API
│   └── models/
│       └── common_models.dart         # Shared data models
└── exceptions/
    └── registration_exceptions.dart   # Registration-specific exceptions
```

**Purpose**: Shared business objects and cross-cutting concerns
**Key Components**:
- **Entities**: Core business objects used across features
- **Exceptions**: Comprehensive error handling hierarchy
- **Services**: Shared infrastructure services

## Test Structure (`test/`)

The test directory mirrors the lib/ structure to maintain consistency:

```
test/
├── core/
│   └── computer_vision/
│       └── yolov7_pose_detection_test.dart # Computer vision tests
├── features/
│   ├── auth/
│   │   ├── domain/use_cases/
│   │   │   └── authentication_test.dart    # Authentication use case tests
│   │   └── presentation/screens/
│   │       └── login_screen_test.dart      # UI widget tests
│   ├── registration/
│   │   ├── domain/use_cases/
│   │   │   └── registration_test.dart      # Registration use case tests
│   │   ├── data/repositories/
│   │   │   ├── registration_repository_test.dart # Repository tests
│   │   │   └── student_repository_test.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── registration_screen_test.dart
│   │       └── widgets/
│   │           └── guided_pose_capture_test.dart
│   └── export/
│       └── data/repositories/
│           └── export_repository_test.dart
├── shared/
│   └── domain/entities/
│       ├── student_test.dart          # Entity validation tests
│       ├── registration_session_test.dart
│       ├── selected_frame_test.dart
│       └── administrator_test.dart
└── widget_test.dart                   # Basic widget tests
```

**Test Categories**:
- **Unit Tests**: Domain entities, use cases, utilities
- **Integration Tests**: Repository implementations, API services
- **Widget Tests**: UI components and user interactions
- **Mock Files**: Generated mock classes for testing

## Configuration Files

### Package Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  flutter: ^3.16.0
  
  # State Management
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0
  
  # Navigation
  go_router: ^12.0.0
  
  # Computer Vision
  camera: ^0.10.5
  google_ml_kit: ^0.16.0
  
  # Data Persistence
  sqflite: ^2.3.0
  shared_preferences: ^2.2.0
  
  # Functional Programming
  dartz: ^0.10.1
  
  # Utilities
  equatable: ^2.0.5
  json_annotation: ^4.8.1

dev_dependencies:
  # Testing
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0
  build_runner: ^2.4.0
  
  # Code Generation
  riverpod_generator: ^2.3.0
  json_serializable: ^6.7.0
```

### Android Configuration (`android/`)

```
android/
├── app/
│   ├── build.gradle              # App-level build configuration
│   ├── src/main/
│   │   ├── AndroidManifest.xml   # App permissions and configuration
│   │   └── kotlin/               # Native Android code (if needed)
│   └── proguard-rules.pro        # Code obfuscation rules
├── build.gradle                  # Project-level build configuration
└── gradle.properties             # Gradle configuration properties
```

**Key Configurations**:
- **Permissions**: Camera, file system access
- **Min SDK**: Android 21+ for ML Kit compatibility
- **Proguard**: Code obfuscation for release builds

### iOS Configuration (`ios/`)

```
ios/
├── Runner/
│   ├── Info.plist                # iOS app configuration and permissions
│   ├── AppDelegate.swift         # iOS app lifecycle
│   └── Assets.xcassets/          # iOS app icons and launch images
└── Podfile                       # iOS dependency management
```

**Key Configurations**:
- **Permissions**: Camera usage descriptions
- **Min iOS**: 11.0+ for ML Kit compatibility
- **CocoaPods**: Native iOS dependencies

## Dependencies and Relationships

### Layer Dependencies (Clean Architecture)

```
Presentation Layer (UI/Providers)
        ↓
    Use Cases (Business Logic)
        ↓
    Domain Entities (Core Models)
        ↑
    Repository Interfaces
        ↑
Data Layer (Repository Implementations)
        ↓
External Services (API/Database/ML)
```

**Dependency Rules**:
- Inner layers cannot depend on outer layers
- Dependencies point inward toward the domain
- Interfaces are defined in inner layers, implemented in outer layers

### Feature Dependencies

```
Authentication ←→ Shared Domain Entities
        ↓
Registration → Computer Vision Services
        ↓
Export ← Registration Data
```

### Service Dependencies

```
UI Components → Riverpod Providers → Use Cases → Repositories → External Services
                     ↓
Computer Vision ← Camera Service ← Hardware Permissions
                     ↓
Database Service ← SQLite ← File System
```

## Key File Relationships

### Critical Path Files

1. **Application Entry Point**
   - `lib/main.dart` → `lib/app/hadir_app.dart` → Router Configuration

2. **Authentication Flow**
   - `LoginScreen` → `AuthProvider` → `AuthenticationUseCases` → `AuthRepository`

3. **Registration Workflow**
   - `RegistrationScreen` → `RegistrationProvider` → `RegistrationUseCases` → `RegistrationRepository`
   - `GuidedPoseCapture` → `PoseCaptureProvider` → `YOLOv7PoseDetector` → ML Processing

4. **Data Flow**
   - `Domain Entities` → `Repository Interfaces` → `Repository Implementations` → `Database/API`

### State Management Flow

```
UI Widget
    ↓ (watches)
Riverpod Provider
    ↓ (calls)
Use Case
    ↓ (uses)
Repository Interface
    ↓ (implemented by)
Repository Implementation
    ↓ (calls)
External Service
```

## Build and Generated Files

### Generated Files (Do Not Edit)

```
lib/
├── **/*.g.dart                   # JSON serialization code
├── **/*.freezed.dart             # Immutable class generation
└── **/*.riverpod.dart            # Riverpod provider generation

test/
└── **/*.mocks.dart               # Mockito mock class generation
```

### Build Artifacts

```
build/                            # Flutter build outputs
.dart_tool/                       # Dart tooling cache
android/app/build/                # Android build artifacts
ios/build/                        # iOS build artifacts
```

## Development Workflow Files

### Version Control

```
.gitignore                        # Git ignore patterns
.github/
├── workflows/                    # GitHub Actions CI/CD
└── copilot-instructions.md       # GitHub Copilot configuration
```

### IDE Configuration

```
.vscode/
├── settings.json                 # VSCode workspace settings
├── launch.json                   # Debug configurations
└── extensions.json               # Recommended extensions

.idea/                           # IntelliJ/Android Studio settings
```

## Quick Navigation Guide

### Finding Specific Functionality

| What you need | Where to look |
|---------------|---------------|
| **Business Rules** | `lib/features/*/domain/entities/` and `lib/features/*/domain/use_cases/` |
| **UI Components** | `lib/features/*/presentation/screens/` and `lib/features/*/presentation/widgets/` |
| **State Management** | `lib/features/*/presentation/providers/` |
| **Data Access** | `lib/features/*/data/repositories/` |
| **API Integration** | `lib/features/*/data/services/` |
| **Computer Vision** | `lib/core/computer_vision/` |
| **Database Schema** | `lib/shared/data/services/database_service.dart` |
| **Error Handling** | `lib/shared/domain/exceptions/` |
| **Configuration** | `lib/core/utils/app_config.dart` |
| **Tests** | `test/` (mirrors lib/ structure) |

### Common Tasks

| Task | Primary Files |
|------|---------------|
| **Add new screen** | Create in `features/*/presentation/screens/`, add route to `app/router/` |
| **Add business logic** | Create use case in `features/*/domain/use_cases/` |
| **Add data source** | Implement repository in `features/*/data/repositories/` |
| **Add state management** | Create provider in `features/*/presentation/providers/` |
| **Add validation** | Update entity in `shared/domain/entities/` or `core/utils/validators.dart` |
| **Add exception type** | Update `shared/domain/exceptions/hadir_exceptions.dart` |
| **Configure navigation** | Update `app/router/app_router.dart` |
| **Add dependencies** | Update `pubspec.yaml` |

## File Naming Conventions

### Dart Files
- **Snake case**: `registration_screen.dart`, `auth_provider.dart`
- **Descriptive names**: Include purpose and type (screen, provider, service, etc.)
- **Consistent suffixes**: `_screen.dart`, `_provider.dart`, `_service.dart`, `_test.dart`

### Test Files
- **Mirror structure**: Same path as source file in test/ directory
- **Test suffix**: `_test.dart` for all test files
- **Mock suffix**: `.mocks.dart` for generated mock files

### Asset Files
- **Organized by type**: `assets/images/`, `assets/fonts/`, `assets/icons/`
- **Descriptive names**: Include purpose and size when relevant
- **Supported formats**: PNG, JPEG for images; TTF, OTF for fonts

## Performance Considerations

### Large Files to Monitor
- **YOLOv7 Model**: Monitor model file size and loading performance
- **Database**: Watch for database growth and query performance
- **Images**: Implement image compression and caching strategies
- **State Objects**: Monitor memory usage of large state objects

### Critical Performance Paths
1. **Camera Preview**: Real-time camera display and capture
2. **Pose Detection**: YOLOv7-Pose processing pipeline
3. **Database Queries**: Student search and registration retrieval
4. **State Updates**: Frequent provider state changes
5. **Navigation**: Screen transitions and route changes

---

*Last Updated: October 8, 2025*
*Project Structure Version: 1.0.0*
*For questions about specific files or structures, refer to the TROUBLESHOOTING.md guide.*