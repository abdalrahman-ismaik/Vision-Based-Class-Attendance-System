# 1-WEEK FAST-TRACK INTEGRATION ROADMAP
## Mobile App ↔ Backend Sync Implementation

**Sprint Duration:** November 5-12, 2025 (7 days)  
**Target:** MVP Sync Feature in Production  
**Strategy:** Leverage existing backend API, minimal changes

---

## 🎯 Sprint Goal

Enable students registered in HADIR mobile app to automatically sync to backend server for face recognition, with visible status tracking and basic error handling.

---

## 📊 What We Already Have (80% Done!)

✅ **Backend API** - `POST /api/students/` accepts student + image  
✅ **Face Processing** - Automatic face detection, augmentation, embeddings  
✅ **Status Tracking** - `processing_status` field in database.json  
✅ **Mobile Database** - SQLite with students table  
✅ **Registration Flow** - Complete student registration in mobile app

**What We Need to Build (20%):**
- Mobile sync service
- Status polling
- UI indicators
- Basic error handling

---

## 📅 Day-by-Day Plan

### 🌟 **DAY 1: Setup (November 5)** - 4 hours

**Morning (2h)**
```
✅ Review existing backend API
✅ Update integration plan
[ ] Create feature branch: git checkout -b feature/mobile-sync
```

**Afternoon (2h)**
```
[ ] Add sync columns to SQLite database
    ALTER TABLE students ADD COLUMN sync_status TEXT DEFAULT 'not_synced';
    ALTER TABLE students ADD COLUMN backend_student_id TEXT;
    ALTER TABLE students ADD COLUMN last_sync_attempt TEXT;
    ALTER TABLE students ADD COLUMN sync_error TEXT;

[ ] Create migration script in: 
    lib/shared/data/data_sources/sync_database_migration.dart

[ ] Test migration on emulator
```

**Output:** Database ready ✅

---

### 🔨 **DAY 2: Core Sync (November 6)** - 8 hours

**Morning (4h) - Build Sync Service**
```
[ ] Create lib/core/services/sync_service.dart

class SyncService {
  Future<SyncResult> syncStudent(Student student, File imageFile) {
    // 1. Build FormData
    // 2. POST to /api/students/
    // 3. Update local database
    // 4. Return result
  }
}

[ ] Create lib/core/models/sync_models.dart
    - SyncResult
    - SyncStatus enum

[ ] Configure Dio client with backend URL
```

**Afternoon (4h) - Implement & Test**
```
[ ] Implement syncStudent() method
[ ] Handle success case
[ ] Handle error cases
[ ] Update database sync_status
[ ] Test with 1 student
```

**Test Checklist:**
- [ ] Student data sent correctly
- [ ] Image uploaded successfully  
- [ ] Local database updated
- [ ] Backend creates student record

**Output:** Working sync for 1 student ✅

---

### 📊 **DAY 3: Status Tracking (November 7)** - 8 hours

**Morning (4h) - Polling Implementation**
```
[ ] Add checkProcessingStatus() method to SyncService

Future<String?> checkProcessingStatus(String studentId) async {
  // GET /api/students/{studentId}
  // Return processing_status field
  // "pending" | "completed" | "failed"
}

[ ] Implement polling with Timer
    - Poll every 10 seconds
    - Stop when completed or failed
    - Max 60 attempts (10 minutes)
```

**Afternoon (4h) - UI Integration**
```
[ ] Add sync status icons to student list
    - Orange cloud: not_synced
    - Blue spinner: syncing
    - Purple pulse: processing
    - Green check: completed
    - Red X: failed

[ ] Add manual sync button
[ ] Show sync progress indicator
[ ] Display error messages
```

**Test Checklist:**
- [ ] Status updates in real-time
- [ ] Icons show correct state
- [ ] Polling stops when complete
- [ ] Can manually trigger sync

**Output:** Visual status tracking ✅

---

### 🛡️ **DAY 4: Error Handling (November 8)** - 6 hours

**Morning (3h) - Retry Logic**
```
[ ] Implement exponential backoff retry

Future<SyncResult> retrySyncWithBackoff(Student student, File image) {
  for (int attempt = 1; attempt <= 3; attempt++) {
    try {
      return await syncStudent(student, image);
    } catch (e) {
      if (attempt < 3) {
        await Future.delayed(Duration(seconds: 5 * pow(2, attempt-1)));
      }
    }
  }
  return SyncResult.failed();
}
```

**Afternoon (3h) - Error Handling**
```
[ ] Handle network errors
    - Connection timeout
    - No internet
    - DNS failure

[ ] Handle backend errors
    - 400 Bad Request
    - 409 Conflict
    - 500 Server Error

[ ] Show user-friendly messages
[ ] Add "Retry" button for failed syncs
```

**Test Checklist:**
- [ ] Offline mode handled
- [ ] Backend down handled
- [ ] Invalid data handled
- [ ] Retry works correctly

**Output:** Robust error handling ✅

---

### 📝 **DAY 5: Logging & Batch (November 9)** - 6 hours

**Morning (3h) - Logging**
```
[ ] Create lib/core/utils/sync_logger.dart

class SyncLogger {
  static void logSyncStart(String studentId) {
    print('[SYNC] Starting sync for $studentId');
    // Log to file (optional)
  }
  
  static void logSyncSuccess(String studentId, int duration) {
    print('[SYNC] ✅ Success for $studentId (${duration}ms)');
  }
  
  static void logSyncError(String studentId, String error) {
    print('[SYNC] ❌ Error for $studentId: $error');
  }
}

[ ] Add logging to all sync operations
[ ] Log request/response data
[ ] Log timing metrics
```

**Afternoon (3h) - Batch Sync**
```
[ ] Implement syncMultipleStudents()

Future<BatchSyncResult> syncMultipleStudents(List<Student> students) {
  int successful = 0;
  int failed = 0;
  
  for (var student in students) {
    try {
      await syncStudent(student);
      successful++;
    } catch (e) {
      failed++;
    }
  }
  
  return BatchSyncResult(successful, failed);
}

[ ] Add progress indicator (X of Y)
[ ] Handle partial failures
```

**Test Checklist:**
- [ ] All operations logged
- [ ] Can sync 5+ students
- [ ] Progress shown correctly
- [ ] Partial failures handled

**Output:** Production logging & batch sync ✅

---

### 🧪 **DAY 6: Testing (November 10)** - 8 hours

**Morning (4h) - Integration Testing**
```
Test Scenarios:
[ ] Complete registration flow
    1. Register student in app
    2. Sync automatically
    3. Poll for status
    4. Show completion

[ ] Network failure scenarios
    - Turn off WiFi during sync
    - Turn on WiFi (should retry)
    - Slow connection

[ ] Backend scenarios
    - Backend offline
    - Backend returns error
    - Invalid student data

[ ] Edge cases
    - Large image file
    - Invalid image format
    - Duplicate student
```

**Afternoon (4h) - Bug Fixes & Polish**
```
[ ] Fix all bugs found
[ ] Improve error messages
[ ] Add loading indicators
[ ] Optimize UI transitions
[ ] Test on physical device
[ ] Memory leak check
```

**Output:** Stable, tested integration ✅

---

### 📚 **DAY 7: Documentation (November 11)** - 5 hours

**Morning (3h) - Documentation**
```
[ ] Update README.md with sync feature
[ ] Document API usage
[ ] Create troubleshooting guide
[ ] Add code comments
[ ] Create user guide
```

**Afternoon (2h) - Demo Preparation**
```
[ ] Record demo video
[ ] Prepare presentation slides
[ ] Test on clean device
[ ] Final smoke testing
```

**Output:** Production-ready with docs ✅

---

### 🎉 **DELIVERY DAY (November 12)**

```
[ ] Final review
[ ] Demo to stakeholders
[ ] Collect feedback
[ ] Plan next iteration
```

---

## 🛠️ Technical Stack

### Mobile (Flutter)
- **HTTP Client:** Dio
- **Database:** sqflite
- **State Management:** Riverpod
- **Logging:** print + optional file logging

### Backend (Python/Flask)
- **Existing API:** `/api/students/` - NO CHANGES NEEDED
- **Processing:** Already implemented
- **Storage:** database.json

---

## 📝 Code Templates

### 1. Sync Service Skeleton

```dart
// lib/core/services/sync_service.dart
import 'package:dio/dio.dart';
import 'dart:io';

class SyncService {
  final Dio _dio;
  final String _baseUrl = 'http://10.0.2.2:5000/api';
  
  SyncService(this._dio);
  
  Future<SyncResult> syncStudent(Student student, File imageFile) async {
    try {
      print('[SYNC] Starting sync for ${student.studentId}');
      
      // Build form data
      final formData = FormData.fromMap({
        'student_id': student.studentId,
        'name': student.fullName,
        'email': student.email,
        'department': student.department,
        'year': student.enrollmentYear,
        'image': await MultipartFile.fromFile(imageFile.path),
      });
      
      // Send request
      final response = await _dio.post(
        '$_baseUrl/students/',
        data: formData,
      );
      
      if (response.statusCode == 201) {
        print('[SYNC] ✅ Success for ${student.studentId}');
        return SyncResult.success();
      }
      
      return SyncResult.failed('Unexpected status: ${response.statusCode}');
    } catch (e) {
      print('[SYNC] ❌ Error: $e');
      return SyncResult.failed(e.toString());
    }
  }
  
  Future<String?> checkProcessingStatus(String studentId) async {
    try {
      final response = await _dio.get('$_baseUrl/students/$studentId');
      return response.data['processing_status'];
    } catch (e) {
      return null;
    }
  }
}
```

### 2. Sync Models

```dart
// lib/core/models/sync_models.dart
enum SyncStatus {
  notSynced,
  syncing,
  synced,
  failed,
}

class SyncResult {
  final bool success;
  final String? error;
  
  SyncResult.success() : success = true, error = null;
  SyncResult.failed(this.error) : success = false;
}
```

### 3. Database Migration

```dart
// lib/shared/data/data_sources/sync_database_migration.dart
import 'package:sqflite/sqflite.dart';

class SyncDatabaseMigration {
  static Future<void> migrateTo_v5(Database db) async {
    await db.execute('ALTER TABLE students ADD COLUMN sync_status TEXT DEFAULT "not_synced"');
    await db.execute('ALTER TABLE students ADD COLUMN backend_student_id TEXT');
    await db.execute('ALTER TABLE students ADD COLUMN last_sync_attempt TEXT');
    await db.execute('ALTER TABLE students ADD COLUMN sync_error TEXT');
    
    print('✅ Database migrated to v5 (sync support)');
  }
}
```

### 4. Usage Example

```dart
// In registration screen after successful registration
final syncService = ref.read(syncServiceProvider);
final imageFile = File(selectedFrame.imagePath);

// Trigger sync
final result = await syncService.syncStudent(student, imageFile);

if (result.success) {
  // Start polling for processing status
  Timer.periodic(Duration(seconds: 10), (timer) async {
    final status = await syncService.checkProcessingStatus(student.studentId);
    
    if (status == 'completed') {
      timer.cancel();
      showSuccessNotification();
    } else if (status == 'failed') {
      timer.cancel();
      showErrorNotification();
    }
  });
} else {
  showError(result.error);
}
```

---

## 🚨 Risk Mitigation

| Risk | Impact | Mitigation | Status |
|------|--------|------------|--------|
| Backend API changes needed | High | ✅ Confirmed no changes needed | 🟢 Clear |
| Complex sync logic | High | ✅ Simplified to use existing API | 🟢 Clear |
| Database migration issues | Medium | Test migration early (Day 1) | 🟡 Monitor |
| Network connectivity | Medium | Implement retry with backoff | 🟡 Monitor |
| Time constraint (7 days) | High | Focus on MVP, defer nice-to-haves | 🟡 Monitor |

---

## ✅ Daily Checklist Template

```
Day X: [Task Name]
Date: November X, 2025

Morning Session (4h)
⏰ Start: ___:___
[ ] Task 1
[ ] Task 2
[ ] Task 3
⏰ End: ___:___

Afternoon Session (4h)  
⏰ Start: ___:___
[ ] Task 4
[ ] Task 5
[ ] Task 6
⏰ End: ___:___

✅ Today's Achievements:
- 
- 
- 

🐛 Blockers:
- 
- 

📝 Notes for Tomorrow:
- 
- 
```

---

## 📊 Progress Tracking

```
Day 1: [░░░░░░░░░░] 0% - Not Started
Day 2: [░░░░░░░░░░] 0% - Not Started
Day 3: [░░░░░░░░░░] 0% - Not Started
Day 4: [░░░░░░░░░░] 0% - Not Started
Day 5: [░░░░░░░░░░] 0% - Not Started
Day 6: [░░░░░░░░░░] 0% - Not Started
Day 7: [░░░░░░░░░░] 0% - Not Started

Overall: [░░░░░░░░░░] 0% Complete
```

---

## 🎯 Definition of Done

- [ ] Student registered in mobile syncs to backend
- [ ] Status visible in UI (not_synced → syncing → synced → completed)
- [ ] Errors handled with retry mechanism
- [ ] Works on physical device
- [ ] No crashes during sync
- [ ] Basic logging implemented
- [ ] Code committed to git
- [ ] Documentation updated
- [ ] Demo video recorded
- [ ] Stakeholder approval

---

## 📞 Support Resources

- **Backend API Docs:** `http://localhost:5000/api/docs`
- **Existing API Analysis:** [EXISTING_API_ANALYSIS.md](./EXISTING_API_ANALYSIS.md)
- **Integration Plan:** [INTEGRATION_PLAN.md](./INTEGRATION_PLAN.md)
- **Quick Reference:** [QUICK_REFERENCE.md](./QUICK_REFERENCE.md)

---

## 🎉 Let's Ship This!

**Remember:**
- ✅ Perfect is the enemy of done
- ✅ MVP first, optimize later
- ✅ Test early, test often
- ✅ Ask for help when stuck
- ✅ Celebrate small wins

**You've got this! 🚀**

---

**Document Version:** 1.0  
**Created:** November 5, 2025  
**Sprint End:** November 12, 2025
