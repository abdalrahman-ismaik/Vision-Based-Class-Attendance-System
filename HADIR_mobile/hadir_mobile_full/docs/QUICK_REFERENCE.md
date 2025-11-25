# HADIR Mobile - Quick Reference

**Last Updated:** 2025-10-26  
**Status:** Development - Post-Cleanup

## 📁 Project Structure

```
hadir_mobile_full/
├── lib/                    # Source code
├── docs/                   # Current documentation
├── archive/                # Old files (safe to review/delete)
├── test/                   # Tests
└── PROJECT_ORGANIZATION.md # Full structure details
```

## 🗂️ Documentation Locations

| Category | Location | Contents |
|----------|----------|----------|
| **Architecture** | `docs/architecture/` | System design, architecture patterns |
| **Features** | `docs/features/` | Feature-specific documentation |
| **Guides** | `docs/guides/` | Development workflows, setup guides |
| **API** | `docs/api/` | API documentation (empty - to be added) |
| **Archive** | `archive/old_documentation/` | Legacy docs (30+ files) |

## 🎯 Active Features

### 1. Authentication
- **Path:** `lib/features/auth/`
- **Route:** `/login`
- **Files:** 8 files (data, domain, presentation layers)

### 2. Student Registration
- **Path:** `lib/features/registration/`
- **Route:** `/registration`
- **Key Features:** 5-pose capture, YOLOv7-Pose integration
- **Files:** 15+ files

### 3. Dashboard
- **Path:** `lib/features/dashboard/`
- **Route:** `/dashboard`
- **Key Features:** Navigation cards, statistics
- **Files:** 6 files

### 4. Student Management (NEW)
- **Path:** `lib/features/student_management/`
- **Routes:** `/students`, `/students/:id`
- **Key Features:** CRUD operations, search, filter, sort
- **Files:** 21 files
- **Status:** ⚠️ Testing pending (app crash issue)

## 🔧 Common Commands

```powershell
# Run app in debug mode
flutter run

# Run with verbose logging
flutter run --verbose

# Clean build artifacts
flutter clean

# Get dependencies
flutter pub get

# Run tests
flutter test

# Build debug APK
flutter build apk --debug

# Check for errors
flutter analyze
```

## 📊 Database Schema

**Version:** 4  
**Tables:** students, student_frames  
**Indices:** 4 compound indices for optimized queries

### Students Table
```sql
- id (TEXT PRIMARY KEY)
- name (TEXT NOT NULL)
- email (TEXT)
- phone (TEXT)
- created_at (INTEGER)
- registration_status (TEXT)
```

### Student Frames Table
```sql
- id (INTEGER PRIMARY KEY)
- student_id (TEXT, FK to students)
- pose_type (TEXT)
- image_path (TEXT)
- captured_at (INTEGER)
- confidence_score (REAL)
```

## 🛠️ Router Configuration

**Active Router:** `lib/app/router/auth_router.dart`  
**Router Type:** `simpleRouter` (GoRouter)

### Routes
```
/login              -> LoginScreen
/registration       -> RegistrationScreen
/dashboard          -> DashboardScreen
/students           -> StudentListScreen
/students/:id       -> StudentDetailScreen
```

**Dev Mode Start:** `/registration`

## 📦 Key Dependencies

```yaml
# State Management
flutter_riverpod: ^2.4.0

# Navigation
go_router: ^12.0.0

# Database
sqflite: ^2.3.0

# Camera
camera: ^0.10.5

# Path
path: ^1.8.3
path_provider: ^2.1.1

# Image
image: ^4.1.3
```

## ⚠️ Known Issues

### Critical: App Crash on Launch
- **Status:** 🔴 Unresolved
- **Impact:** Blocks testing of Student Management module
- **Symptom:** Immediate crash after "Using Impeller rendering backend"
- **Next Steps:**
  1. Run `flutter run --verbose`
  2. Check `adb logcat` for errors
  3. Review recent router changes

## 📝 Recent Changes

### 2025-10-26: Project Cleanup
- ✅ 44+ files archived
- ✅ Documentation organized
- ✅ Build artifacts cleaned
- ✅ Directory structure optimized

### 2025-10-26: Student Management Module
- ✅ 21 files implemented
- ✅ Routes registered
- ✅ Database migration v3 → v4
- ⚠️ Testing blocked by crash

## 🔍 Troubleshooting

### App won't start
```powershell
flutter clean
flutter pub get
flutter run
```

### Hot reload not working
- Use **Hot Restart** (Ctrl+Shift+F5) for route changes
- Or run: `r` in terminal, `R` for full restart

### Database errors
- Check `DATABASE_RESET_INSTRUCTIONS.md`
- Uninstall app to reset database
- Or increment version in `database_helper.dart`

### Build errors
```powershell
flutter clean
flutter pub get
flutter pub upgrade
flutter run
```

## 📚 Important Files

| File | Purpose |
|------|---------|
| `PROJECT_ORGANIZATION.md` | Full project structure |
| `CLEANUP_SUCCESS_SUMMARY.md` | Cleanup details |
| `DATABASE_RESET_INSTRUCTIONS.md` | Database management |
| `PROGRESS_LOG.md` | Development progress |
| `README.md` | Project overview |

## 🎨 Code Style

- **Architecture:** Clean Architecture (Data, Domain, Presentation)
- **State Management:** Riverpod 2.4+
- **Naming:** snake_case for files, camelCase for code
- **Folders:** Feature-based organization
- **Tests:** Mirror lib/ structure

## 🚀 Next Steps

1. **Fix app crash** (CRITICAL)
2. Test student management features
3. Add unit tests for new module
4. Document API endpoints
5. Add architecture diagrams

## 📞 Quick Help

**Stuck?** Check these files:
1. `docs/guides/DEVELOPMENT_WORKFLOW.md` - Development guide
2. `docs/guides/DEV_MODE_QUICK_REFERENCE.md` - Dev mode help
3. `TROUBLESHOOTING.md` - Common issues
4. `archive/old_documentation/` - Historical context

---

**For detailed information, see:** `PROJECT_ORGANIZATION.md`  
**For cleanup details, see:** `CLEANUP_SUCCESS_SUMMARY.md`
