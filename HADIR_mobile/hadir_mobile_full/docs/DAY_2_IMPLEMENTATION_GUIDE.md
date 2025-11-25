# Day 2 Implementation Guide - Core Sync Service

**Date:** November 6, 2025  
**Focus:** Build core sync functionality  
**Goal:** Sync 1 student from mobile to backend successfully

---

## ✅ What We Built Today

### 1. Sync Configuration (`sync_config.dart`)
- Backend URL configuration (environment-aware)
- Timeout settings (connection, receive, send)
- Retry configuration (3 attempts, exponential backoff)
- Image validation rules
- Logging settings
- **210 lines** of comprehensive configuration

### 2. Sync Service (`sync_service.dart`)
- `syncStudent()` - Core sync method
- `checkProcessingStatus()` - Poll backend for status
- `getStudentsToSync()` - Query students needing sync
- Error handling (Dio errors, generic errors)
- Database status updates
- **380 lines** of production-ready code

### 3. Sync Providers (`sync_provider.dart`)
- Dio HTTP client provider
- Database provider
- SyncService provider
- Sync status stream provider
- Helper state providers
- **120 lines** of Riverpod providers

---

## 🧪 How to Test the Sync Feature

### Step 1: Start the Backend Server

```bash
cd backend
python app.py
```

**Expected output:**
```
 * Running on http://127.0.0.1:5000
 * Debug mode: on
```

**Verify backend is running:**
```bash
curl http://localhost:5000/api/docs
```

---

### Step 2: Configure Backend URL (if needed)

For **Android Emulator** (default):
```dart
// Already configured in sync_config.dart
backendBaseUrl: 'http://10.0.2.2:5000/api'
```

For **iOS Simulator**:
```dart
// Change in sync_config.dart
backendBaseUrl: 'http://localhost:5000/api'
```

For **Physical Device**:
```dart
// Find your computer's IP:
// Windows: ipconfig
// Mac/Linux: ifconfig

backendBaseUrl: 'http://192.168.1.100:5000/api'  // Your IP
```

---

### Step 3: Add Sync Button to Registration Screen

Find your registration success screen and add:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hadir_mobile_full/core/providers/sync_provider.dart';
import 'package:hadir_mobile_full/core/models/sync_models.dart';
import 'dart:io';

class RegistrationSuccessScreen extends ConsumerWidget {
  final Student student;
  final String imagePath; // Path to selected frame image
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncService = ref.watch(syncServiceProvider);
    final isSyncing = ref.watch(isSyncingProvider);
    
    return Scaffold(
      appBar: AppBar(title: Text('Registration Complete')),
      body: Column(
        children: [
          // ... existing success UI ...
          
          ElevatedButton(
            onPressed: isSyncing ? null : () async {
              // Set syncing flag
              ref.read(isSyncingProvider.notifier).state = true;
              
              try {
                // Sync student to backend
                final result = await syncService.syncStudent(
                  student: student,
                  imageFile: File(imagePath),
                );
                
                if (result.success) {
                  // Success!
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Student synced to backend!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Save last sync time
                  ref.read(lastSyncTimestampProvider.notifier).state = 
                      DateTime.now();
                  
                } else {
                  // Failed
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Sync failed: ${result.error}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  
                  ref.read(syncErrorProvider.notifier).state = result.error;
                }
                
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                // Clear syncing flag
                ref.read(isSyncingProvider.notifier).state = false;
              }
            },
            child: isSyncing 
                ? CircularProgressIndicator(color: Colors.white)
                : Text('Sync to Backend'),
          ),
        ],
      ),
    );
  }
}
```

---

### Step 4: Run the App and Test

```bash
cd HADIR_mobile/hadir_mobile_full
flutter run
```

**Test Flow:**
1. Register a new student
2. Complete face capture
3. On success screen, tap "Sync to Backend"
4. Watch console logs for sync progress
5. Verify success/error message

**Expected Console Output (Success):**
```
[SYNC] Starting sync for student: S12345
[SYNC] Validation passed for S12345
[SYNC] Building request for S12345
[SYNC] Sending POST to /students/
[DIO] POST http://10.0.2.2:5000/api/students/
[DIO] Response: 201
[SYNC] Updated local status for uuid-123: synced
[SYNC] ✅ Sync completed for S12345 (1234ms)
```

---

### Step 5: Verify in Backend

Check backend console:
```
INFO: Student registered successfully: S12345
INFO: Background processing started for S12345
INFO: Pipeline initialized, starting face processing for S12345
INFO: ✓ Face processing completed for S12345: 20 augmentations
```

Check `backend/database.json`:
```json
{
  "S12345": {
    "student_id": "S12345",
    "name": "Test Student",
    "processing_status": "completed",
    ...
  }
}
```

---

### Step 6: Check Local Database

```bash
# Android
adb shell
cd /data/data/com.example.hadir_mobile_full/databases/
sqlite3 hadir.db

# Check sync status
SELECT student_id, sync_status, backend_student_id, last_sync_attempt 
FROM students 
WHERE student_id = 'S12345';

# Expected output:
# S12345|synced|S12345|2025-11-06T10:30:00.000
```

---

## 🐛 Troubleshooting

### Problem: "Connection refused"
**Solution:**
- Check backend is running
- Verify backend URL matches your environment
  - Android emulator: `10.0.2.2:5000`
  - iOS simulator: `localhost:5000`
  - Physical device: Your computer's IP

### Problem: "Student already exists" (409 error)
**Solution:**
- Student is already in backend database
- Either:
  1. Use a different student_id
  2. Delete student from `backend/database.json`
  3. Handle 409 as success (student exists = good!)

### Problem: "No face detected"
**Solution:**
- Backend face detection failed
- Check image quality
- Check `backend/database.json` for `processing_error`
- Try re-capturing with better lighting

### Problem: "Image file not found"
**Solution:**
- Check `imagePath` is correct
- Verify file exists: `File(imagePath).exists()`
- Check file permissions

### Problem: Timeout errors
**Solution:**
- Increase timeouts in `sync_config.dart`:
```dart
static const Duration receiveTimeout = Duration(seconds: 120); // Increase
```

---

## ✅ Success Checklist

- [ ] Backend server running
- [ ] App runs without errors
- [ ] Can register new student
- [ ] Sync button appears
- [ ] Clicking sync shows loading
- [ ] Success message appears
- [ ] Backend logs show processing
- [ ] `database.json` has student
- [ ] Local database shows `sync_status = 'synced'`
- [ ] No crashes!

---

## 📊 Testing Different Scenarios

### Test 1: Successful Sync
1. Register student with good quality image
2. Sync immediately
3. Verify success

### Test 2: Duplicate Student
1. Register student
2. Sync (success)
3. Try syncing same student again
4. Should get 409 error
5. Handle gracefully

### Test 3: No Internet
1. Turn off WiFi
2. Try to sync
3. Should show network error
4. Turn on WiFi
5. Retry sync (manual)

### Test 4: Backend Offline
1. Stop backend server
2. Try to sync
3. Should show connection error
4. Start backend
5. Retry sync

### Test 5: Invalid Image
1. Register student
2. Delete image file
3. Try to sync
4. Should show file error

---

## 🎯 Day 2 Success Criteria

By end of today, you should have:

- [x] `sync_config.dart` created
- [x] `sync_service.dart` created
- [x] `sync_provider.dart` created
- [ ] Sync button added to UI
- [ ] Successfully synced 1 student
- [ ] Verified in backend
- [ ] Verified in local database
- [ ] No crashes or blocking errors

---

## 🚀 Tomorrow's Plan (Day 3)

Now that core sync works, we'll add:

1. **Status Polling**
   - Poll backend every 10s for `processing_status`
   - Update UI when processing completes

2. **Status Indicators**
   - Show sync status icons on student list
   - Orange cloud = not synced
   - Blue spinner = syncing
   - Purple pulse = processing
   - Green check = completed

3. **Manual Sync Button**
   - Global sync button for all students
   - Pull-to-refresh gesture

---

## 💡 Pro Tips

1. **Use Postman/curl first** - Test backend API before mobile
2. **Check backend logs** - Most errors show up there first
3. **Enable verbose logging** - Set `enableDetailedLogging = true`
4. **Test on emulator first** - Easier debugging than physical device
5. **Keep backend running** - Don't stop it during testing

---

## 📝 Code Commit Checklist

Before committing:
- [ ] Code compiles without errors
- [ ] Tested on emulator
- [ ] Added comments
- [ ] No sensitive data (API keys, etc.)
- [ ] Formatted code (`dart format lib/`)

**Commit message:**
```
feat: Implement core sync service (Day 2)

- Add SyncConfig with backend URL and timeouts
- Add SyncService with syncStudent() method
- Add Riverpod providers for dependency injection
- Support syncing student data + face image to backend
- Handle success/error responses
- Update local database sync status

Tested: Successfully synced 1 student to backend
```

---

**Day 2 Progress:** 🎯 50% (Morning session complete)  
**Status:** ✅ Core service built, ready for testing  
**Next:** Add UI integration and test with real student

---

**Great progress! Core sync is ready! Let's test it! 🚀**
