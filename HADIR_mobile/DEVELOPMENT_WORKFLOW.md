# HADIR Development Workflow

This document outlines the development workflow, best practices, and guidelines for contributing to the HADIR project. It ensures consistency, quality, and maintainability across all development activities.

## Table of Contents
1. [Development Environment Setup](#development-environment-setup)
2. [Git Workflow](#git-workflow)
3. [Test-Driven Development (TDD)](#test-driven-development-tdd)
4. [Code Standards](#code-standards)
5. [Review Process](#review-process)
6. [Release Management](#release-management)
7. [Maintenance Procedures](#maintenance-procedures)

## Development Environment Setup

### Prerequisites

#### Required Software
```bash
# Flutter SDK (version 3.16+)
flutter --version

# Dart SDK (version 3.0+)
dart --version

# Android Studio or VS Code
# Git (version 2.30+)
git --version

# Optional but recommended
# Android SDK (for Android development)
# Xcode (for iOS development on macOS)
```

#### Recommended VS Code Extensions
```json
{
  "recommendations": [
    "dart-code.flutter",
    "dart-code.dart-code",
    "ms-vscode.vscode-json",
    "bradlc.vscode-tailwindcss",
    "github.copilot",
    "ms-vscode.test-adapter-converter"
  ]
}
```

### Project Setup

#### 1. Clone and Initial Setup
```bash
# Clone the repository
git clone <repository-url>
cd HADIR

# Navigate to mobile app
cd hadir_mobile_full

# Install dependencies
flutter pub get

# Generate code (mocks, JSON serialization, etc.)
dart pub run build_runner build --delete-conflicting-outputs

# Verify setup
flutter doctor
flutter test
```

#### 2. IDE Configuration

**VS Code Settings (`.vscode/settings.json`)**
```json
{
  "dart.flutterSdkPath": "path/to/flutter",
  "dart.analysisExcludedFolders": [
    "build/**",
    ".dart_tool/**"
  ],
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true,
    "source.organizeImports": true
  },
  "dart.lineLength": 100,
  "dart.insertArgumentPlaceholders": false
}
```

**Launch Configuration (`.vscode/launch.json`)**
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter (Debug)",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "args": ["--flavor", "development"]
    },
    {
      "name": "Flutter (Release)",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "args": ["--release"]
    }
  ]
}
```

## Git Workflow

### Branch Strategy

We use **Git Flow** with the following branch types:

#### Main Branches
- **`main`**: Production-ready code, always deployable
- **`develop`**: Integration branch for features, latest development state

#### Supporting Branches
- **`feature/`**: New features and enhancements
- **`bugfix/`**: Bug fixes for current release
- **`hotfix/`**: Critical fixes for production issues
- **`release/`**: Prepare releases, final testing and bug fixes

### Branch Naming Conventions

```bash
# Feature branches
feature/authentication-system
feature/pose-detection-improvement
feature/user-profile-management

# Bug fix branches
bugfix/camera-permission-handling
bugfix/database-migration-error
bugfix/ui-layout-issues

# Hotfix branches
hotfix/security-vulnerability-fix
hotfix/critical-crash-fix

# Release branches
release/v1.0.0
release/v1.1.0-beta
```

### Commit Message Format

Use **Conventional Commits** format:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

#### Types
- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, etc.)
- **refactor**: Code refactoring
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **chore**: Maintenance tasks

#### Examples
```bash
feat(auth): implement biometric authentication
fix(camera): resolve permission handling on Android
docs(api): update authentication endpoint documentation
refactor(pose): improve YOLOv7-Pose detection accuracy
test(registration): add comprehensive integration tests
chore(deps): update flutter dependencies to latest versions
```

### Development Workflow Steps

#### 1. Starting New Work
```bash
# Update your main branch
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b bugfix/issue-description
```

#### 2. Development Process
```bash
# Make changes following TDD approach
# 1. Write tests first
# 2. Implement code to pass tests
# 3. Refactor as needed

# Stage and commit changes
git add .
git commit -m "feat(feature): implement specific functionality"

# Push branch regularly
git push origin feature/your-feature-name
```

#### 3. Integration Process
```bash
# Update from develop branch
git checkout develop
git pull origin develop

# Rebase your feature branch
git checkout feature/your-feature-name
git rebase develop

# Resolve any conflicts and test
flutter test
flutter analyze

# Push updated branch
git push origin feature/your-feature-name --force-with-lease
```

#### 4. Pull Request Process
1. Create pull request from feature branch to `develop`
2. Fill out PR template with description, testing notes, and checklist
3. Request review from team members
4. Address review feedback
5. Merge after approval and CI checks pass

## Test-Driven Development (TDD)

### TDD Cycle

#### Red-Green-Refactor Process
1. **Red**: Write a failing test
2. **Green**: Write minimal code to pass the test
3. **Refactor**: Improve code quality while keeping tests green

### Test Categories

#### 1. Unit Tests
```dart
// Test individual functions, methods, and classes
// Location: test/unit/
// Example: Entity validation, use case logic

group('Student Entity Tests', () {
  test('should create student with valid data', () {
    // Arrange
    const studentData = StudentTestData.validStudent;
    
    // Act
    final student = Student.fromJson(studentData);
    
    // Assert
    expect(student.studentId, equals('STU20240001'));
    expect(student.firstName, equals('Ahmed'));
    expect(student.isValid, isTrue);
  });
  
  test('should throw validation exception for invalid email', () {
    // Arrange
    const invalidData = StudentTestData.invalidEmail;
    
    // Act & Assert
    expect(
      () => Student.fromJson(invalidData),
      throwsA(isA<ValidationException>()),
    );
  });
});
```

#### 2. Integration Tests
```dart
// Test interaction between components
// Location: test/integration/
// Example: Repository with database, API with services

group('StudentRepository Integration Tests', () {
  late StudentRepository repository;
  late DatabaseService database;
  
  setUp(() async {
    database = await DatabaseService.createInMemory();
    repository = StudentRepositoryImpl(database);
  });
  
  tearDown(() async {
    await database.close();
  });
  
  test('should save and retrieve student', () async {
    // Arrange
    const student = StudentTestData.validStudent;
    
    // Act
    final savedStudent = await repository.create(student);
    final retrievedStudent = await repository.getById(savedStudent.id);
    
    // Assert
    expect(retrievedStudent, equals(savedStudent));
  });
});
```

#### 3. Widget Tests
```dart
// Test UI components and user interactions
// Location: test/widget/
// Example: Screen rendering, form validation, navigation

group('LoginScreen Widget Tests', () {
  testWidgets('should display login form', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );
    
    // Act
    await tester.pumpAndSettle();
    
    // Assert
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
  
  testWidgets('should show error for invalid credentials', 
    (WidgetTester tester) async {
    // Test error handling and validation
  });
});
```

### Test Organization

#### Test File Structure
```
test/
├── unit/
│   ├── domain/
│   │   ├── entities/
│   │   └── use_cases/
│   └── core/
│       └── utils/
├── integration/
│   ├── repositories/
│   └── services/
├── widget/
│   ├── screens/
│   └── widgets/
└── helpers/
    ├── test_data.dart      # Test data builders
    ├── mock_helpers.dart   # Mock object helpers
    └── test_utils.dart     # Test utility functions
```

#### Test Data Management
```dart
// helpers/test_data.dart
class StudentTestData {
  static const validStudent = {
    'id': 'uuid-123',
    'studentId': 'STU20240001',
    'firstName': 'Ahmed',
    'lastName': 'Hassan',
    'email': 'ahmed.hassan@university.edu',
    // ... other valid data
  };
  
  static const invalidEmail = {
    // Copy of validStudent with invalid email
    ...validStudent,
    'email': 'invalid-email',
  };
  
  static Student createValidStudent({
    String? studentId,
    String? firstName,
    String? lastName,
  }) {
    return Student.fromJson({
      ...validStudent,
      if (studentId != null) 'studentId': studentId,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
    });
  }
}
```

### Testing Commands

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/domain/entities/student_test.dart

# Run tests with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Run tests in watch mode (with entr or similar tool)
find test -name "*.dart" | entr -r flutter test
```

## Code Standards

### Dart/Flutter Code Style

#### 1. Follow Official Style Guide
```dart
// Use official Dart style guide
// https://dart.dev/guides/language/effective-dart

// Good: Use lowerCamelCase for variables, functions, and parameters
final String userName = 'ahmed.hassan';
void updateUserProfile() { }

// Good: Use UpperCamelCase for classes, enums, and typedefs
class UserProfile { }
enum UserStatus { active, inactive }

// Good: Use lowercase_with_underscores for libraries and directories
// lib/features/user_management/
```

#### 2. Code Organization
```dart
// Import order: Dart SDK, Flutter, Third-party, Local
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:riverpod/riverpod.dart';
import 'package:dartz/dartz.dart';

import '../domain/entities/student.dart';
import '../repositories/student_repository.dart';

// Class member order: Static, Fields, Constructors, Methods
class StudentService {
  // Static members first
  static const String defaultStatus = 'active';
  
  // Instance fields
  final StudentRepository _repository;
  final Logger _logger;
  
  // Constructor
  StudentService(this._repository, this._logger);
  
  // Public methods
  Future<Student> createStudent(Student student) async { }
  
  // Private methods
  void _logStudentCreation(Student student) { }
}
```

#### 3. Documentation Standards
```dart
/// Service for managing student data and operations.
/// 
/// This service provides CRUD operations for students and handles
/// validation, business rules, and data persistence.
/// 
/// Example usage:
/// ```dart
/// final service = StudentService(repository, logger);
/// final student = await service.createStudent(newStudent);
/// ```
class StudentService {
  /// Creates a new student with validation.
  /// 
  /// Throws [ValidationException] if student data is invalid.
  /// Throws [DuplicateStudentException] if student ID already exists.
  /// 
  /// Returns the created [Student] with assigned ID.
  Future<Student> createStudent(Student student) async {
    // Implementation
  }
  
  /// Private helper method for validation.
  bool _isValidStudent(Student student) {
    // Implementation
  }
}
```

### Error Handling Standards

#### 1. Exception Hierarchy Usage
```dart
// Use specific exception types from the hierarchy
throw ValidationException('Invalid email format: ${student.email}');
throw DuplicateStudentException('Student ID already exists: ${student.studentId}');
throw PoseDetectionException('YOLOv7-Pose model initialization failed');

// Avoid generic exceptions
// Bad: throw Exception('Something went wrong');
// Good: throw SpecificHadirException('Detailed error message');
```

#### 2. Error Handling Patterns
```dart
// Use Either pattern for use cases
Future<Either<HadirException, Student>> createStudent(Student student) async {
  try {
    // Validation
    if (!_isValidStudent(student)) {
      return Left(ValidationException('Invalid student data'));
    }
    
    // Business logic
    final createdStudent = await _repository.create(student);
    return Right(createdStudent);
    
  } on DuplicateStudentException catch (e) {
    return Left(e);
  } on DatabaseException catch (e) {
    return Left(RepositoryException('Failed to save student: ${e.message}'));
  } catch (e) {
    return Left(UnknownException('Unexpected error: $e'));
  }
}

// Handle Either results consistently
final result = await studentUseCase.createStudent(student);
result.fold(
  (error) => _handleError(error),
  (student) => _handleSuccess(student),
);
```

### State Management Standards

#### 1. Provider Organization
```dart
// Define providers in separate files
// File: lib/features/auth/presentation/providers/auth_provider.dart

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() => const AuthState.initial();
  
  Future<void> login(String username, String password) async {
    state = const AuthState.loading();
    
    final result = await ref.read(authUseCasesProvider).login(username, password);
    
    result.fold(
      (error) => state = AuthState.error(error),
      (user) => state = AuthState.authenticated(user),
    );
  }
  
  Future<void> logout() async {
    await ref.read(authUseCasesProvider).logout();
    state = const AuthState.initial();
  }
}

// Use providers consistently in widgets
class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    
    return authState.when(
      initial: () => _buildLoginForm(ref),
      loading: () => const CircularProgressIndicator(),
      authenticated: (user) => _buildWelcomeScreen(user),
      error: (error) => _buildErrorState(error),
    );
  }
}
```

## Review Process

### Code Review Checklist

#### Before Submitting PR
- [ ] All tests pass (`flutter test`)
- [ ] Code analysis passes (`flutter analyze`)
- [ ] Code follows style guidelines
- [ ] Documentation is updated
- [ ] CHANGELOG.md is updated (if applicable)
- [ ] No debug prints or commented code
- [ ] Proper error handling implemented
- [ ] State management follows patterns

#### PR Template
```markdown
## Description
Brief description of changes and motivation.

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Widget tests added/updated
- [ ] Manual testing completed

## Screenshots (if applicable)
Add screenshots to help explain your changes.

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Code is properly documented
- [ ] Tests pass locally
- [ ] No merge conflicts
```

#### Review Criteria
1. **Functionality**: Does the code do what it's supposed to do?
2. **Testing**: Are there adequate tests covering the changes?
3. **Design**: Is the code well-designed and fitting with architecture?
4. **Performance**: Are there any performance implications?
5. **Security**: Are there any security concerns?
6. **Documentation**: Is the code properly documented?
7. **Maintainability**: Is the code easy to understand and maintain?

### Review Process Steps
1. **Author** creates PR with proper description and checklist
2. **Reviewers** are assigned (minimum 1, preferably 2)
3. **Automated checks** run (tests, analysis, build)
4. **Manual review** by assigned reviewers
5. **Feedback addressed** by author if necessary
6. **Approval** from required reviewers
7. **Merge** to target branch

## Release Management

### Release Process

#### 1. Version Numbering (Semantic Versioning)
```
MAJOR.MINOR.PATCH[-PRERELEASE]

Examples:
1.0.0       - Initial release
1.1.0       - New features added
1.1.1       - Bug fixes
2.0.0       - Breaking changes
1.2.0-beta  - Pre-release version
```

#### 2. Release Branch Workflow
```bash
# Create release branch from develop
git checkout develop
git pull origin develop
git checkout -b release/v1.1.0

# Update version in pubspec.yaml
# version: 1.1.0+1

# Update CHANGELOG.md
# Add release notes and breaking changes

# Final testing and bug fixes only
flutter test
flutter analyze
flutter build apk --release

# Merge to main
git checkout main
git merge release/v1.1.0
git tag v1.1.0

# Merge back to develop
git checkout develop
git merge release/v1.1.0

# Clean up
git branch -d release/v1.1.0
```

#### 3. Release Checklist
- [ ] Version updated in `pubspec.yaml`
- [ ] CHANGELOG.md updated with release notes
- [ ] All tests pass
- [ ] Code analysis passes
- [ ] Release builds successfully
- [ ] Documentation updated
- [ ] Security review completed (if applicable)
- [ ] Performance testing completed
- [ ] Backward compatibility verified

### Hotfix Process
```bash
# Create hotfix branch from main
git checkout main
git checkout -b hotfix/critical-fix

# Make minimal fix
# Update patch version (e.g., 1.1.0 -> 1.1.1)
# Test thoroughly

# Merge to main and develop
git checkout main
git merge hotfix/critical-fix
git tag v1.1.1

git checkout develop
git merge hotfix/critical-fix
```

## Maintenance Procedures

### Regular Maintenance Tasks

#### Weekly Tasks
- [ ] Update dependencies to latest compatible versions
- [ ] Review and address any new analyzer warnings
- [ ] Check test coverage and improve if below 80%
- [ ] Review performance metrics and address bottlenecks
- [ ] Update documentation for any API changes

#### Monthly Tasks
- [ ] Security audit of dependencies
- [ ] Performance profiling and optimization
- [ ] Database cleanup and optimization
- [ ] Update Flutter/Dart versions if stable releases available
- [ ] Review and update CI/CD pipelines

#### Quarterly Tasks
- [ ] Architecture review and refactoring opportunities
- [ ] Comprehensive security audit
- [ ] User feedback analysis and feature planning
- [ ] Technology stack evaluation and upgrade planning
- [ ] Documentation review and updates

### Dependency Management

#### Updating Dependencies
```bash
# Check for outdated packages
flutter pub outdated

# Update to latest compatible versions
flutter pub upgrade

# Update to latest versions (may require code changes)
flutter pub upgrade --major-versions

# Verify after updates
flutter test
flutter analyze
flutter build apk --debug
```

#### Dependency Security
```bash
# Audit dependencies for security vulnerabilities
dart pub audit

# Check for deprecated packages
flutter pub deps --style=compact | grep -E '\(discontinued\)|\(unmaintained\)'
```

### Performance Monitoring

#### Key Metrics to Monitor
1. **App Startup Time**: Time from launch to first screen
2. **Pose Detection Latency**: YOLOv7-Pose processing time
3. **Database Query Performance**: Complex query execution times
4. **Memory Usage**: Peak memory during heavy operations
5. **Battery Usage**: Impact on device battery life

#### Performance Testing
```dart
// Example performance test
testWidgets('pose detection performance test', (WidgetTester tester) async {
  final stopwatch = Stopwatch()..start();
  
  final detector = YOLOv7PoseDetector.instance;
  await detector.initialize();
  
  final testImage = await loadTestImage();
  final result = await detector.detectPose(testImage);
  
  stopwatch.stop();
  
  expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // Max 2 seconds
  expect(result.confidence, greaterThan(0.9)); // Min 90% confidence
});
```

### Monitoring and Logging

#### Production Monitoring
```dart
// Use structured logging
class Logger {
  static void info(String message, {Map<String, dynamic>? extra}) {
    final logEntry = {
      'level': 'INFO',
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      if (extra != null) ...extra,
    };
    
    // Send to monitoring service
    MonitoringService.log(logEntry);
  }
  
  static void error(String message, Object error, StackTrace stackTrace) {
    final logEntry = {
      'level': 'ERROR',
      'message': message,
      'error': error.toString(),
      'stackTrace': stackTrace.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    MonitoringService.log(logEntry);
  }
}
```

#### Error Tracking
```dart
// Integrate with crash reporting service
void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FirebaseCrashlytics.instance.recordFlutterError(details);
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack);
    return true;
  };
  
  runApp(MyApp());
}
```

---

*Last Updated: October 8, 2025*
*Workflow Version: 1.0.0*
*For questions about the development process, refer to the team lead or check the TROUBLESHOOTING.md guide.*