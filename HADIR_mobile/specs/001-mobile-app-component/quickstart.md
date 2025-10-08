# Quickstart Guide: Mobile Student Registration App

**Purpose**: Get the Flutter mobile app running locally for development and testing  
**Prerequisites**: Flutter SDK, Android Studio, Git  
**Time Estimate**: 30-45 minutes

---

## Prerequisites Setup

### 1. Flutter Development Environment

**Install Flutter SDK 3.16+**:
```bash
# On Windows (using Chocolatey)
choco install flutter

# On macOS (using Homebrew)
brew install flutter

# Verify installation
flutter doctor
```

**Required Output**: All Flutter Doctor checks should pass except for optional items.

### 2. Android Development Setup

**Install Android Studio**:
- Download from [https://developer.android.com/studio](https://developer.android.com/studio)
- Install Android SDK 33+ and build tools
- Set up Android emulator or connect physical device

**Verify Android setup**:
```bash
flutter doctor --android-licenses
flutter devices
```

**Expected**: At least one Android device should be listed (emulator or physical).

### 3. Development Tools

**Required IDE Extensions**:
- VS Code: Flutter + Dart extensions
- Android Studio: Flutter + Dart plugins

**Verify tools**:
```bash
dart --version  # Should show Dart 3.0+
flutter --version  # Should show Flutter 3.16+
```

---

## Project Setup

### 1. Create Flutter Project

```bash
# Create new Flutter project
flutter create --org edu.university.hadir mobile_registration_app
cd mobile_registration_app

# Add to version control
git init
git add .
git commit -m "Initial Flutter project setup"
```

### 2. Configure Dependencies

**Update `pubspec.yaml`**:
```yaml
name: mobile_registration_app
description: AI-Enhanced Face Registration for Student Attendance
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.16.0"

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  riverpod: ^2.4.0
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0
  
  # Navigation
  go_router: ^12.0.0
  
  # Database & Storage
  sqflite: ^2.3.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.1
  
  # Computer Vision & Camera
  camera: ^0.10.5
  google_ml_kit: ^0.16.0
  image: ^4.1.3
  
  # UI & Theming
  cupertino_icons: ^1.0.6
  material_color_utilities: ^0.5.0
  
  # Utilities
  uuid: ^4.1.0
  json_annotation: ^4.8.1
  dio: ^5.3.2
  logger: ^2.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  
  # Code Generation
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
  riverpod_generator: ^2.3.0
  
  # Testing
  mockito: ^5.4.2
  test: ^1.24.6
  
  # Linting
  flutter_lints: ^3.0.1

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/icons/
  
  fonts:
    - family: Roboto
      fonts:
        - asset: assets/fonts/Roboto-Regular.ttf
        - asset: assets/fonts/Roboto-Bold.ttf
          weight: 700
```

**Install dependencies**:
```bash
flutter pub get
flutter pub run build_runner build
```

### 3. Configure Android Permissions

**Update `android/app/src/main/AndroidManifest.xml`**:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Camera and storage permissions -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    
    <!-- Network permissions for future API integration -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <!-- Hardware requirements -->
    <uses-feature android:name="android.hardware.camera" android:required="true" />
    <uses-feature android:name="android.hardware.camera.autofocus" />

    <application
        android:label="HADIR Registration"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme" />
              
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

---

## Basic App Structure Setup

### 1. Create Directory Structure

```bash
# Create feature-based directory structure
mkdir -p lib/app/{router,theme,providers}
mkdir -p lib/features/{auth,registration,export}/{data,domain,presentation}
mkdir -p lib/shared/{data,domain,presentation,utils}
mkdir -p lib/core/{computer_vision,quality_assessment,pose_estimation,frame_selection}
mkdir -p test/{features,shared,core,integration_test,widget_test}
mkdir -p assets/{images,icons,fonts}
```

### 2. Main App Entry Point

**Create `lib/main.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/hadir_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  runApp(
    ProviderScope(
      child: HadirApp(),
    ),
  );
}
```

**Create `lib/app/hadir_app.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

class HadirApp extends ConsumerWidget {
  const HadirApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: 'HADIR Registration',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

### 3. Basic Theme Configuration

**Create `lib/app/theme/app_theme.dart`**:
```dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF2196F3),
      brightness: Brightness.light,
      
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
```

### 4. Basic Router Setup

**Create `lib/app/router/app_router.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/registration/presentation/screens/registration_screen.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.registration,
        name: 'registration',
        builder: (context, state) => const RegistrationScreen(),
      ),
    ],
  );
});
```

**Create `lib/app/router/app_routes.dart`**:
```dart
class AppRoutes {
  static const String login = '/login';
  static const String registration = '/registration';
  static const String export = '/export';
}
```

### 5. Basic Screen Scaffolds

**Create `lib/features/auth/presentation/screens/login_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HADIR Login'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.face,
              size: 80,
              color: Colors.blue,
            ),
            SizedBox(height: 24),
            Text(
              'Administrator Login',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Please login to access student registration',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

**Create `lib/features/registration/presentation/screens/registration_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegistrationScreen extends ConsumerWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Registration'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam,
              size: 80,
              color: Colors.green,
            ),
            SizedBox(height: 24),
            Text(
              'Face Registration',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Camera and ML Kit integration coming next',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Database Setup

### 1. Initialize SQLite Database

**Create `lib/shared/data/database/database_service.dart`**:
```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'hadir_registration.db';
  static const int _dbVersion = 1;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create administrators table
    await db.execute('''
      CREATE TABLE administrators (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        full_name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        role TEXT NOT NULL CHECK (role IN ('operator', 'supervisor', 'admin')),
        created_at DATETIME NOT NULL,
        last_login_at DATETIME,
        is_active BOOLEAN NOT NULL DEFAULT 1
      )
    ''');

    // Create students table
    await db.execute('''
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
      )
    ''');

    // Insert sample administrator for testing
    await db.insert('administrators', {
      'id': 'admin-001',
      'username': 'admin',
      'full_name': 'System Administrator',
      'email': 'admin@university.edu',
      'role': 'admin',
      'created_at': DateTime.now().toIso8601String(),
      'is_active': 1,
    });
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
```

### 2. Test Database Connection

**Create `test/shared/data/database/database_service_test.dart`**:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mobile_registration_app/shared/data/database/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseService', () {
    late DatabaseService databaseService;

    setUp(() {
      databaseService = DatabaseService();
    });

    test('should initialize database successfully', () async {
      final db = await databaseService.database;
      expect(db.isOpen, true);
    });

    test('should have administrators table', () async {
      final db = await databaseService.database;
      final result = await db.query('administrators');
      expect(result, isNotEmpty);
      expect(result.first['username'], 'admin');
    });

    tearDown(() async {
      await databaseService.close();
    });
  });
}
```

---

## Running the Application

### 1. Build and Run

```bash
# Check for any issues
flutter analyze

# Run tests
flutter test

# Start the app in debug mode
flutter run
```

**Expected Result**: App launches successfully showing the login screen with HADIR branding.

### 2. Hot Reload Testing

```bash
# With app running, modify a UI element in login_screen.dart
# Save the file and verify hot reload works
```

**Expected**: Changes appear instantly without full restart.

### 3. Database Verification

```bash
# Run database tests
flutter test test/shared/data/database/database_service_test.dart
```

**Expected**: All database tests pass successfully.

---

## Next Steps

### 1. Camera Integration
- Add camera permission handling
- Implement basic camera preview
- Test on physical device

### 2. ML Kit Setup
- Configure face detection
- Test with sample images
- Verify performance

### 3. State Management
- Set up Riverpod providers
- Implement basic authentication flow
- Add navigation state management

---

## Troubleshooting

### Common Issues

**Flutter Doctor Issues**:
```bash
# Fix Android licenses
flutter doctor --android-licenses

# Update Flutter
flutter upgrade
```

**Dependency Conflicts**:
```bash
# Clean and reinstall
flutter clean
flutter pub get
```

**Camera Permissions**:
- Ensure physical device or emulator with camera access
- Check AndroidManifest.xml permissions
- Test on API level 29+ for scoped storage

**Database Errors**:
- Check sqflite_common_ffi for testing
- Verify table creation SQL syntax
- Use database inspector tools

### Performance Optimization

**Development Mode**:
```bash
# Run in profile mode for performance testing
flutter run --profile

# Use performance overlay
flutter run --debug --enable-checked-mode
```

### Testing Strategy

**Unit Tests**: Focus on business logic and data models  
**Widget Tests**: Test UI components in isolation  
**Integration Tests**: Test complete user flows  
**Performance Tests**: Measure camera and ML performance

---

## Success Criteria

✅ Flutter app launches successfully  
✅ Navigation between screens works  
✅ Database initializes and queries work  
✅ Tests pass without errors  
✅ Hot reload functions properly  
✅ Android permissions configured correctly

**Time Investment**: ~30-45 minutes for complete setup  
**Next Phase**: Camera integration and face detection setup

This quickstart gets you from zero to a working Flutter app foundation, ready for computer vision feature development.