# HADIR Troubleshooting Guide

This guide provides solutions to common issues encountered during HADIR development, testing, and deployment.

## Table of Contents
1. [Compilation Errors](#compilation-errors)
2. [Test Issues](#test-issues)
3. [State Management Issues](#state-management-issues)
4. [Computer Vision Problems](#computer-vision-problems)
5. [Camera Integration Issues](#camera-integration-issues)
6. [Database Problems](#database-problems)
7. [Build and Deployment Issues](#build-and-deployment-issues)
8. [Performance Issues](#performance-issues)

## Compilation Errors

### 1. Undefined Class Errors

**Problem**: `Undefined class 'ClassName'` or `The name 'ClassName' isn't a type`

**Common Causes**:
- Missing imports
- Incorrect class names
- File not created yet

**Solutions**:
```dart
// 1. Add proper import
import 'package:hadir_mobile_full/path/to/your/class.dart';

// 2. Check class name spelling and capitalization
// Correct: ValidationException
// Incorrect: validationException

// 3. Ensure the file exists and contains the class definition
```

**Example Fix**:
```dart
// Before (Error)
expect(result.error, isA<ValidationException>());

// After (Fixed) - Add import
import 'package:hadir_mobile_full/shared/domain/exceptions/hadir_exceptions.dart';
expect(result.error, isA<ValidationException>());
```

### 2. Named Parameter Errors

**Problem**: `The named parameter 'parameterName' isn't defined`

**Common Causes**:
- Constructor signature mismatch
- Using old API after refactoring
- Missing required parameters

**Solutions**:
```dart
// 1. Check constructor definition
class Student {
  const Student({
    required this.id,
    required this.studentId,
    required this.firstName, // Make sure parameter exists
    required this.lastName,
    // ... other parameters
  });
}

// 2. Update usage to match constructor
const student = Student(
  id: 'uuid-123',
  studentId: 'STU20240001',
  firstName: 'Ahmed',  // Use correct parameter name
  lastName: 'Hassan',
  // ... other required parameters
);
```

### 3. Type Assignment Errors

**Problem**: `The argument type 'TypeA' can't be assigned to the parameter type 'TypeB'`

**Common Causes**:
- Type mismatch between expected and actual types
- Enum vs String confusion
- Generic type issues

**Solutions**:
```dart
// 1. Use correct enum values
// Before (Error)
status: SessionStatus.inProgress  // Custom enum
// After (Fixed)
status: RegistrationSessionStatus.inProgress  // Correct enum

// 2. Check generic types
// Before (Error)
Future<Either<Exception, Student>> getStudent()
// After (Fixed)  
Future<Either<HadirException, Student>> getStudent()
```

### 4. Method Override Errors

**Problem**: `'MockClass.method' isn't a valid override of 'Interface.method'`

**Common Causes**:
- Repository interface changes after mock generation
- Return type mismatches
- Parameter type differences

**Solutions**:
```dart
// 1. Update mock to match interface
// Interface
abstract class StudentRepository {
  Future<Student?> getById(String id);
}

// Mock (should match exactly)
class MockStudentRepository extends Mock implements StudentRepository {
  @override
  Future<Student?> getById(String id) => super.noSuchMethod(
    Invocation.method(#getById, [id]),
    returnValue: Future<Student?>.value(null),
  );
}

// 2. Regenerate mocks if needed
// Run: dart pub run build_runner build --delete-conflicting-outputs
```

## Test Issues

### 1. Mock Generation Problems

**Problem**: `Invalid @GenerateMocks annotation` or mock files not generated

**Solutions**:
```dart
// 1. Ensure proper imports in test file
import 'package:mockito/annotations.dart';
import 'package:hadir_mobile_full/features/registration/domain/repositories/student_repository.dart';

// 2. Add GenerateMocks annotation correctly
@GenerateMocks([
  StudentRepository,
  RegistrationRepository,
  YOLOv7PoseDetector,
])
void main() {
  // Test code
}

// 3. Run build runner to generate mocks
// Command: dart pub run build_runner build --delete-conflicting-outputs

// 4. Import generated mocks
import 'test_file.mocks.dart';
```

### 2. Test Result Access Errors

**Problem**: `The getter 'isSuccess' isn't defined for the type 'UseCaseResult<T>'`

**Common Causes**:
- Using wrong result type pattern
- API changes in use case results

**Solutions**:
```dart
// 1. Use Either pattern correctly
final Either<HadirException, Student> result = await useCase.execute();

result.fold(
  (error) => expect(true, isFalse, reason: 'Should not have error: ${error.message}'),
  (data) => {
    expect(data, isNotNull),
    expect(data.studentId, equals('STU20240001')),
  },
);

// 2. Or use isLeft/isRight checks
expect(result.isRight(), isTrue);
expect(result.getOrElse(() => throw Exception()), isA<Student>());
```

### 3. Widget Test Failures

**Problem**: Widget tests failing due to missing providers or context

**Solutions**:
```dart
testWidgets('LoginScreen should display correctly', (WidgetTester tester) async {
  // 1. Wrap with ProviderScope for Riverpod
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // Override providers with mocks
        authProviderProvider.overrideWith((ref) => MockAuthProvider()),
      ],
      child: MaterialApp(
        home: LoginScreen(),
      ),
    ),
  );

  // 2. Pump and settle for async operations
  await tester.pumpAndSettle();

  // 3. Your test assertions
  expect(find.byType(TextFormField), findsNWidgets(2));
});
```

## State Management Issues

### 1. Provider Disposal Errors

**Problem**: `StateNotifier<T> was disposed` or state access after disposal

**Solutions**:
```dart
class MyProvider extends StateNotifier<MyState> {
  MyProvider() : super(MyState.initial());

  @override
  void dispose() {
    // 1. Cancel any subscriptions or timers
    _subscription?.cancel();
    _timer?.cancel();
    
    // 2. Call super.dispose() last
    super.dispose();
  }

  // 3. Check if disposed before state updates
  void updateState(MyState newState) {
    if (mounted) {  // Check if still mounted
      state = newState;
    }
  }
}
```

### 2. Provider Dependency Issues

**Problem**: Circular dependencies or provider not found

**Solutions**:
```dart
// 1. Avoid circular dependencies
// Bad: Provider A depends on B, B depends on A
// Good: Both depend on shared service provider

// 2. Use proper provider hierarchy
final sharedServiceProvider = Provider<SharedService>((ref) => SharedService());

final providerAProvider = StateNotifierProvider<ProviderA, StateA>((ref) {
  final sharedService = ref.watch(sharedServiceProvider);
  return ProviderA(sharedService);
});

final providerBProvider = StateNotifierProvider<ProviderB, StateB>((ref) {
  final sharedService = ref.watch(sharedServiceProvider);
  return ProviderB(sharedService);
});
```

## Computer Vision Problems

### 1. YOLOv7-Pose Initialization Failures

**Problem**: Model fails to initialize or crashes on first use

**Common Causes**:
- Missing model files
- Insufficient memory
- Incompatible device architecture

**Solutions**:
```dart
class YOLOv7PoseDetector {
  static YOLOv7PoseDetector? _instance;
  
  static YOLOv7PoseDetector get instance {
    _instance ??= YOLOv7PoseDetector._internal();
    return _instance!;
  }

  Future<bool> initialize() async {
    try {
      // 1. Check if model files exist
      final modelFile = await _getModelFile();
      if (!await modelFile.exists()) {
        throw PoseDetectorException('Model file not found');
      }

      // 2. Initialize with error handling
      await _initializeModel(modelFile.path);
      
      // 3. Test with dummy data
      final testResult = await _testModel();
      if (!testResult) {
        throw PoseDetectorException('Model test failed');
      }

      return true;
    } catch (e) {
      debugPrint('YOLOv7-Pose initialization failed: $e');
      return false;
    }
  }

  // 4. Add memory management
  Future<void> dispose() async {
    try {
      await _cleanupModel();
      _instance = null;
    } catch (e) {
      debugPrint('YOLOv7-Pose disposal error: $e');
    }
  }
}
```

### 2. Face Detection Accuracy Issues

**Problem**: Low confidence scores or incorrect pose classification

**Solutions**:
```dart
class PoseQualityValidator {
  static const double MIN_CONFIDENCE = 0.9;
  static const double MIN_FACE_SIZE = 0.1; // 10% of image
  
  bool validatePoseQuality({
    required PoseAngles angles,
    required double confidence,
    required FaceMetrics faceMetrics,
  }) {
    // 1. Check confidence threshold
    if (confidence < MIN_CONFIDENCE) {
      return false;
    }

    // 2. Validate face size
    if (faceMetrics.relativeFaceSize < MIN_FACE_SIZE) {
      return false;
    }

    // 3. Check pose angle ranges
    if (!_isValidPoseAngle(angles)) {
      return false;
    }

    // 4. Validate face landmarks
    if (!_hasValidLandmarks(faceMetrics)) {
      return false;
    }

    return true;
  }

  bool _isValidPoseAngle(PoseAngles angles) {
    // Define acceptable ranges for each pose type
    const double tolerance = 15.0; // degrees
    
    switch (angles.poseType) {
      case PoseType.frontal:
        return angles.yaw.abs() < tolerance && angles.pitch.abs() < tolerance;
      case PoseType.leftProfile:
        return angles.yaw > (90 - tolerance) && angles.yaw < (90 + tolerance);
      // ... other pose types
    }
  }
}
```

## Camera Integration Issues

### 1. Camera Permission Errors

**Problem**: Camera access denied or permission not requested

**Solutions**:
```dart
class CameraService {
  Future<bool> requestCameraPermission() async {
    try {
      // 1. Check current permission status
      final status = await Permission.camera.status;
      
      if (status.isGranted) {
        return true;
      }

      // 2. Request permission if not granted
      if (status.isDenied) {
        final result = await Permission.camera.request();
        return result.isGranted;
      }

      // 3. Handle permanently denied
      if (status.isPermanentlyDenied) {
        // Guide user to settings
        await _showPermissionDialog();
        return false;
      }

      return false;
    } catch (e) {
      debugPrint('Camera permission error: $e');
      return false;
    }
  }

  Future<void> _showPermissionDialog() async {
    // Show dialog to guide user to app settings
    await showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: Text('Camera Permission Required'),
        content: Text('Please enable camera permission in app settings.'),
        actions: [
          TextButton(
            onPressed: () => openAppSettings(),
            child: Text('Open Settings'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
```

### 2. Camera Preview Issues

**Problem**: Black screen, stretched preview, or camera not starting

**Solutions**:
```dart
class CameraController {
  CameraController? _controller;
  
  Future<void> initializeCamera() async {
    try {
      // 1. Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('No cameras available');
      }

      // 2. Use front camera for face capture
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // 3. Initialize with proper settings
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      // 4. Set flash mode
      await _controller!.setFlashMode(FlashMode.off);

    } catch (e) {
      debugPrint('Camera initialization error: $e');
      throw CameraException('Failed to initialize camera: $e');
    }
  }

  Widget buildCameraPreview() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const CircularProgressIndicator();
    }

    // 5. Handle aspect ratio properly
    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: CameraPreview(_controller!),
    );
  }
}
```

## Database Problems

### 1. Migration Errors

**Problem**: Database schema changes causing app crashes

**Solutions**:
```dart
class DatabaseHelper {
  static const int _databaseVersion = 2;
  static const String _databaseName = 'hadir.db';

  static Future<Database> _database() async {
    return await openDatabase(
      join(await getDatabasesPath(), _databaseName),
      version: _databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,  // Handle migrations
    );
  }

  static Future<void> _createDatabase(Database db, int version) async {
    // Create all tables for fresh install
    await _createStudentsTable(db);
    await _createRegistrationSessionsTable(db);
    await _createSelectedFramesTable(db);
  }

  static Future<void> _upgradeDatabase(
    Database db, 
    int oldVersion, 
    int newVersion,
  ) async {
    // Handle incremental migrations
    if (oldVersion < 2) {
      // Migration from version 1 to 2
      await db.execute('ALTER TABLE students ADD COLUMN face_embedding BLOB');
    }
    
    // Add more migrations as needed
    // if (oldVersion < 3) { ... }
  }
}
```

### 2. Query Performance Issues

**Problem**: Slow database queries causing UI lag

**Solutions**:
```dart
class StudentRepository {
  // 1. Add proper indexes
  Future<void> createIndexes(Database db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_students_student_id ON students(student_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_students_status ON students(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_student_id ON registration_sessions(student_id)');
  }

  // 2. Use pagination for large datasets
  Future<List<Student>> getAllStudents({
    int offset = 0,
    int limit = 50,
    String? searchQuery,
  }) async {
    final db = await DatabaseHelper.database;
    
    String whereClause = '';
    List<Object> whereArgs = [];
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause = 'WHERE first_name LIKE ? OR last_name LIKE ?';
      whereArgs = ['%$searchQuery%', '%$searchQuery%'];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'students',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => Student.fromJson(map)).toList();
  }

  // 3. Use transactions for bulk operations
  Future<void> createMultipleStudents(List<Student> students) async {
    final db = await DatabaseHelper.database;
    
    await db.transaction((txn) async {
      for (final student in students) {
        await txn.insert('students', student.toJson());
      }
    });
  }
}
```

## Build and Deployment Issues

### 1. Android Build Failures

**Problem**: Gradle build errors or dependency conflicts

**Solutions**:
```groovy
// android/app/build.gradle
android {
    compileSdkVersion 34
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    defaultConfig {
        minSdkVersion 21  // Increase if needed for ML Kit
        targetSdkVersion 34
        multiDexEnabled true  // For large apps
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true              // Enable code shrinking
            useProguard true               // Enable obfuscation
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'  // If using multidex
}
```

### 2. iOS Build Issues

**Problem**: Xcode build failures or code signing issues

**Solutions**:
```xml
<!-- ios/Runner/Info.plist -->
<key>NSCameraUsageDescription</key>
<string>This app needs camera access for face recognition.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to save captured images.</string>

<!-- Update minimum iOS version in ios/Flutter/AppFrameworkInfo.plist -->
<key>MinimumOSVersion</key>
<string>11.0</string>
```

## Performance Issues

### 1. Memory Leaks

**Problem**: App crashes due to memory issues during pose detection

**Solutions**:
```dart
class PoseCaptureProvider extends StateNotifier<PoseCaptureState> {
  Timer? _processingTimer;
  StreamSubscription? _cameraSubscription;

  PoseCaptureProvider() : super(PoseCaptureState.initial());

  @override
  void dispose() {
    // 1. Cancel all timers and subscriptions
    _processingTimer?.cancel();
    _cameraSubscription?.cancel();
    
    // 2. Dispose camera controller
    _cameraController?.dispose();
    
    // 3. Clear image data
    _clearImageCache();
    
    // 4. Dispose ML model
    YOLOv7PoseDetector.instance.dispose();
    
    super.dispose();
  }

  void _clearImageCache() {
    // Clear any cached images to free memory
    state = state.copyWith(
      capturedFrames: [],
      processingImages: {},
    );
  }
}
```

### 2. UI Performance Issues

**Problem**: Laggy UI during camera preview and processing

**Solutions**:
```dart
// 1. Use efficient widgets
class OptimizedCameraPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final cameraState = ref.watch(poseCaptureProvider);
        
        // Only rebuild when necessary
        return RepaintBoundary(
          child: cameraState.when(
            loading: () => const CircularProgressIndicator(),
            data: (state) => CameraPreview(state.controller),
            error: (error, stack) => ErrorWidget(error.toString()),
          ),
        );
      },
    );
  }
}

// 2. Debounce expensive operations
class PoseDetectionService {
  Timer? _debounceTimer;
  
  void processFrame(Uint8List imageData) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performPoseDetection(imageData);
    });
  }
}

// 3. Use compute for heavy operations
Future<Map<String, dynamic>> _performPoseDetection(Uint8List imageData) {
  return compute(_detectPoseIsolate, imageData);
}

static Map<String, dynamic> _detectPoseIsolate(Uint8List imageData) {
  // Perform CPU-intensive pose detection in isolate
  return YOLOv7PoseDetector.processImage(imageData);
}
```

## Common Error Messages and Solutions

| Error Message | Cause | Solution |
|---------------|-------|----------|
| `Target of URI doesn't exist` | Missing import or file | Check file path and add proper import |
| `The named parameter 'X' isn't defined` | Constructor parameter mismatch | Update constructor call to match definition |
| `isn't a valid override` | Mock interface mismatch | Update mock to match current interface |
| `StateNotifier was disposed` | Using disposed provider | Check `mounted` before state updates |
| `Camera permission denied` | Missing camera permissions | Add permission request and proper manifest entries |
| `Model initialization failed` | ML model issues | Check model files and device compatibility |
| `Database is locked` | Concurrent database access | Use proper transaction handling |
| `Build failed with exit code 1` | Various build issues | Check specific error logs and update dependencies |

## Getting Help

### 1. Debug Information Collection
```dart
// Add this to collect debug info
void collectDebugInfo() {
  debugPrint('Flutter Version: ${Platform.operatingSystem}');
  debugPrint('App Version: ${packageInfo.version}');
  debugPrint('Device Model: ${deviceInfo.model}');
  debugPrint('Memory Usage: ${ProcessInfo.currentRss}');
}
```

### 2. Log Analysis
```dart
// Use structured logging
class Logger {
  static void logError(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('ERROR: $message');
    if (error != null) debugPrint('Error details: $error');
    if (stackTrace != null) debugPrint('Stack trace: $stackTrace');
  }
  
  static void logPerformance(String operation, Duration duration) {
    debugPrint('PERFORMANCE: $operation took ${duration.inMilliseconds}ms');
  }
}
```

### 3. Issue Reporting Template
```markdown
## Bug Report

**Environment:**
- Flutter version: 
- Dart version: 
- Device/OS: 
- App version: 

**Steps to Reproduce:**
1. 
2. 
3. 

**Expected Behavior:**

**Actual Behavior:**

**Error Messages:**
```
[Paste error messages here]
```

**Screenshots:**
[If applicable]

**Additional Context:**
[Any other relevant information]
```

---

*Last Updated: October 8, 2025*
*Version: 1.0.0*
*For additional support, check the project documentation or create an issue in the repository.*