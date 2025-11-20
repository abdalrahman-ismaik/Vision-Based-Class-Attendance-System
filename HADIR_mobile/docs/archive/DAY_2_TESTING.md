# Day 2 Afternoon: Testing Guide

## ✅ Status
**Core Sync Service**: COMPLETE (710 lines)  
**Test Page**: COMPLETE (450 lines)  
**Ready for**: Manual testing

---

## 📋 Prerequisites

### 1. Backend Server Running
```bash
cd backend
python app.py
```

You should see:
```
* Running on http://127.0.0.1:5000
* Debug mode: on
```

### 2. Flutter App Running
```bash
cd HADIR_mobile/hadir_mobile_full
flutter run
```

---

## 🧪 Test Scenario: Sync 1 Student

### Step 1: Register a Test Student

1. **Open the app** and navigate to registration
2. **Register a new student**:
   - Student ID: `S12345`
   - Name: `Test Student`
   - Email: `test@example.com`
   - Department: `Computer Science`
   - Year: `2024`
3. **Capture face images** (at least 3 poses)
4. **Complete registration**
5. **Note**: Student is now in local database with `sync_status = 'not_synced'`

### Step 2: Access Sync Test Page

**Option A: Add to router (Recommended)**

Add this route to `lib/app/router/app_router.dart`:

```dart
GoRoute(
  path: '/sync-test',
  name: 'sync-test',
  builder: (context, state) => const SyncTestPage(),
),
```

Then navigate from dashboard or use:
```dart
context.push('/sync-test');
```

**Option B: Direct Navigation**

From any screen:
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const SyncTestPage()),
);
```

### Step 3: Sync the Student

1. **Open Sync Test Page** - you should see your test student
2. **Verify initial state**:
   - ☁️ Cloud upload icon (grey) = Not synced
   - Frame count shows captured images
   - "Sync Now" button visible
3. **Tap "Sync Now"**
4. **Observe**:
   - Loading dialog appears: "Syncing to backend..."
   - Console logs show sync progress (if debug enabled)
   - Button changes to syncing state

### Step 4: Verify Success

**Expected Result**: ✅ Success message
```
✅ Test Student synced!
Backend ID: 12345
```

**UI Updates**:
- ☁️ Cloud done icon (green) = Synced
- Backend ID displayed
- Button disabled (already synced)

**Backend Console Output**:
```
[INFO] POST /api/students/ - Received student: S12345
[INFO] Processing images for student S12345...
[INFO] Face detection: SUCCESS
[INFO] Embedding generation: SUCCESS
[INFO] Student S12345 saved to database
```

### Step 5: Verify Database Updates

**Mobile Database** (SQLite):
```sql
SELECT id, student_id, full_name, sync_status, backend_student_id 
FROM students 
WHERE student_id = 'S12345';
```

Expected:
- `sync_status`: `synced`
- `backend_student_id`: `12345` (or similar)
- `last_sync_attempt`: Current timestamp

**Backend Database** (`backend/database.json`):
```json
{
  "students": [
    {
      "id": 12345,
      "student_id": "S12345",
      "name": "Test Student",
      "email": "test@example.com",
      "department": "Computer Science",
      "year": "2024",
      "processing_status": "pending",
      "created_at": "2025-11-05T14:30:00"
    }
  ]
}
```

---

## 🔴 Error Scenarios

### Test 1: Network Error

**Simulate**: Stop backend server  
**Action**: Try to sync  
**Expected**:
```
❌ Sync failed: DioException [connection error]: Connection refused
```
- Status remains `not_synced` or changes to `failed`
- "Retry" button appears

### Test 2: Invalid Image Path

**Simulate**: Manually delete image file  
**Action**: Try to sync  
**Expected**:
```
❌ Image file not found: /path/to/image.jpg
```

### Test 3: Missing Images

**Simulate**: Student with no selected frames  
**Action**: Try to sync  
**Expected**:
```
❌ No images available for this student
```

### Test 4: Backend Validation Error

**Simulate**: Send invalid data (e.g., empty email)  
**Expected**:
```
❌ Sync failed: Validation error - email is required
```

---

## 📊 Success Criteria

- [ ] Student syncs successfully on first attempt
- [ ] Backend receives correct FormData (student_id, name, email, department, year, image)
- [ ] Backend processes image and creates embedding
- [ ] Mobile database updates: `sync_status = 'synced'`, `backend_student_id = XXX`
- [ ] Backend database contains new student entry
- [ ] UI shows green cloud icon and backend ID
- [ ] Retry works after network error
- [ ] Error messages are clear and actionable

---

## 🐛 Troubleshooting

### Issue: "Connection refused"
**Fix**: Ensure backend is running on `http://127.0.0.1:5000`  
**Android Emulator**: Backend URL should be `http://10.0.2.2:5000`  
**iOS Simulator**: Backend URL should be `http://localhost:5000`

### Issue: "Image file not found"
**Fix**: Check `selected_frames.image_file_path` in database  
**Verify**: File exists at that path  
**Debug**: Print `imagePath` before sync

### Issue: "No images available"
**Fix**: Ensure student has `registration_session_id` set  
**Verify**: Query `selected_frames` table for that session  
**Debug**: Check frame capture during registration

### Issue: Backend 422 Unprocessable Entity
**Fix**: Check backend logs for validation errors  
**Common**: Missing required fields (student_id, name, email)  
**Debug**: Add request body logging in `sync_config.dart`

---

## 📝 Configuration Check

### Backend URL (sync_config.dart)
```dart
// Android Emulator
static const String backendBaseUrl = 'http://10.0.2.2:5000/api';

// iOS Simulator
static const String backendBaseUrl = 'http://localhost:5000/api';

// Physical Device (same network)
static const String backendBaseUrl = 'http://192.168.X.X:5000/api';
```

### Enable Debug Logging
```dart
static const bool enableDetailedLogging = true;
static const bool logRequestBodies = true;
static const bool logResponseBodies = true;
```

---

## 🎯 Next Steps (Day 3)

After successful Day 2 testing:

1. **Status Polling**: Implement `checkProcessingStatus()`
2. **Real-time Updates**: Add Stream for sync status changes
3. **UI Indicators**: Show processing status (pending → completed)
4. **Bulk Sync**: Sync multiple students at once
5. **Offline Queue**: Queue syncs when offline, retry when online

---

## 📸 Expected Console Output

### Mobile App (Sync Service)
```
[SYNC] Starting sync for student: S12345
[SYNC] Validating input...
[SYNC] ✅ Validation passed
[SYNC] Updating database: sync_status = 'syncing'
[SYNC] Building FormData...
[SYNC] ✅ FormData built (5 fields + 1 file)
[SYNC] Sending POST request to http://10.0.2.2:5000/api/students/
[DIO] --> POST /api/students/
[DIO] Content-Type: multipart/form-data
[DIO] Content-Length: 1234567
[DIO] <-- 201 CREATED (1234ms)
[DIO] Response: {"id": 12345, "student_id": "S12345", ...}
[SYNC] ✅ Sync successful (backend_student_id: 12345)
[SYNC] Updating database: sync_status = 'synced'
[SYNC] ✅ Sync completed for S12345 (1234ms)
```

### Backend (Flask)
```
INFO:werkzeug:127.0.0.1 - - [05/Nov/2025 14:30:00] "POST /api/students/ HTTP/1.1" 201 -
[INFO] Received student registration: S12345
[INFO] Validating request data...
[INFO] ✅ Validation passed
[INFO] Saving image: /path/to/backend/uploads/S12345.jpg
[INFO] Starting background processing for student 12345
[INFO] Detecting faces with RetinaFace...
[INFO] ✅ Face detected
[INFO] Generating embeddings with MobileFaceNet...
[INFO] ✅ Embedding generated (512 dimensions)
[INFO] Applying 20 augmentations...
[INFO] ✅ 20 augmented embeddings generated
[INFO] Saving student to database.json
[INFO] ✅ Student 12345 processing complete
```

---

## ✅ Day 2 Deliverables

**Code Files** (✅ All Complete):
1. `lib/core/config/sync_config.dart` - Configuration (210 lines)
2. `lib/core/services/sync_service.dart` - Core sync logic (380 lines)
3. `lib/core/providers/sync_provider.dart` - Riverpod providers (140 lines)
4. `lib/features/student_management/presentation/widgets/student_sync_button.dart` - Reusable button (220 lines)
5. `lib/features/student_management/presentation/pages/sync_test_page.dart` - Test UI (450 lines)

**Documentation** (✅ All Complete):
1. `DAY_2_IMPLEMENTATION_GUIDE.md` - Step-by-step guide
2. `DAY_2_SUMMARY.md` - Progress summary
3. `DAY_2_TESTING.md` - This file

**Total Lines**: 1,400+ lines of production code

---

## 🎉 Success!

If you can sync 1 student successfully, **Day 2 is COMPLETE!** 🚀

The system now has:
- ✅ Database migration (Day 1)
- ✅ Sync models and enums (Day 1)
- ✅ Core sync service (Day 2)
- ✅ HTTP client with error handling (Day 2)
- ✅ Riverpod providers for dependency injection (Day 2)
- ✅ Test UI for manual verification (Day 2)

**Ready for Day 3**: Status polling and real-time UI updates! 💪
