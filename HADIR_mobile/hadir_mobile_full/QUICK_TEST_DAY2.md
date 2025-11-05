# 🧪 Quick Test Script - Day 2

**Run this after adding sync button to your UI**

---

## 🚀 Quick Start (5 Minutes)

### 1. Start Backend
```bash
cd backend
python app.py
```

### 2. Run App
```bash
cd HADIR_mobile/hadir_mobile_full
flutter run
```

### 3. Test Sync
1. Register new student (use unique ID like `TEST_001`)
2. Complete face capture
3. Tap "Sync to Backend" button
4. Watch for success message

---

## ✅ Quick Verification

### Check Console Output
```
[SYNC] Starting sync for student: TEST_001
[SYNC] Validation passed for TEST_001
[DIO] POST http://10.0.2.2:5000/api/students/
[DIO] Response: 201
[SYNC] ✅ Sync completed for TEST_001 (1234ms)
```

### Check Backend
```bash
# Check backend/database.json
cat backend/database.json | grep TEST_001

# Should see:
"TEST_001": {
  "student_id": "TEST_001",
  "processing_status": "pending",
  ...
}
```

### Check Local Database
```bash
adb shell
cd /data/data/com.example.hadir_mobile_full/databases/
sqlite3 hadir.db
SELECT student_id, sync_status FROM students WHERE student_id='TEST_001';

# Should show:
# TEST_001|synced
```

---

## 🐛 Quick Fixes

### "Connection refused"
```dart
// In sync_config.dart, try:
baseUrl: 'http://localhost:5000/api'  // iOS
// or
baseUrl: 'http://YOUR_IP:5000/api'    // Physical device
```

### "Student already exists"
```dart
// Use different student ID:
student_id: 'TEST_002', 'TEST_003', etc.
```

### "Image not found"
```dart
// Verify file exists:
print('Image exists: ${await File(imagePath).exists()}');
print('Image path: $imagePath');
```

---

## 📊 Test Scenarios

### ✅ Test 1: Happy Path
- Register student
- Sync immediately
- Verify success

### ✅ Test 2: Duplicate
- Register student
- Sync (success)
- Sync again (should get 409)

### ✅ Test 3: No Backend
- Stop backend
- Try sync
- Should show connection error

---

## 🎯 Success = All Green

- ✅ App doesn't crash
- ✅ Success message appears
- ✅ Backend has student
- ✅ Local DB shows 'synced'
- ✅ Console shows ✅ emoji

---

**If all checks pass: Day 2 COMPLETE! 🎉**

**Next: Day 3 - Status Polling & UI**
