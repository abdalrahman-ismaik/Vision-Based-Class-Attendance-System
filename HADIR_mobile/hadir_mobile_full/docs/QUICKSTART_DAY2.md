# 🚀 Quick Start: Test Sync Now!

## 1️⃣ Start Backend (1 minute)

```powershell
cd c:\Users\4bais\Vision-Based-Class-Attendance-System\backend
C:\Users\4bais\Vision-Based-Class-Attendance-System\.venv\Scripts\python.exe app.py
```

Or if `.venv` is activated:
```powershell
cd c:\Users\4bais\Vision-Based-Class-Attendance-System\backend
python app.py
```

**Expected**:
```
* Running on http://127.0.0.1:5000
* Debug mode: on
```

---

## 2️⃣ Run Flutter App (1 minute)

```powershell
cd c:\Users\4bais\Vision-Based-Class-Attendance-System\HADIR_mobile\hadir_mobile_full
flutter run
```

**Expected**:
```
✓ Built build\app\outputs\flutter-apk\app-debug.apk
```

---

## 3️⃣ Register Test Student (2 minutes)

1. Open app
2. Tap "Register Student"
3. Fill form:
   - Student ID: `S12345`
   - Name: `Test Student`
   - Email: `test@test.com`
   - Department: `CS`
4. Capture 3+ face poses
5. Tap "Finish Registration"

---

## 4️⃣ Open Sync Test Page (30 seconds)

**Option A**: Add route temporarily to `lib/app/router/app_router.dart`:

```dart
// Add after dashboard route
GoRoute(
  path: '/sync-test',
  builder: (context, state) => const SyncTestPage(),
),
```

Then from dashboard, navigate:
```dart
context.push('/sync-test');
```

**Option B**: Use Flutter DevTools to navigate:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const SyncTestPage(),
  ),
);
```

---

## 5️⃣ Sync the Student (1 minute)

1. See your test student in the list
2. **Verify**: Grey cloud icon (not synced)
3. **Tap**: "Sync Now"
4. **Wait**: Loading dialog (1-3 seconds)
5. **See**: ✅ Success message + green cloud icon

---

## 6️⃣ Verify Success (1 minute)

### Mobile App
- Cloud done icon (green)
- Backend ID displayed
- Status: "Synced"

### Backend Console
```
INFO:werkzeug:127.0.0.1 - - [05/Nov/2025 14:30:00] "POST /api/students/ HTTP/1.1" 201 -
[INFO] Received student registration: S12345
[INFO] Processing images for student S12345...
[INFO] ✅ Student S12345 saved to database
```

### Backend Database (`backend/database.json`)
```json
{
  "students": [
    {
      "id": 12345,
      "student_id": "S12345",
      "name": "Test Student",
      ...
    }
  ]
}
```

---

## ✅ Success Checklist

- [ ] Backend server running
- [ ] Flutter app running
- [ ] Test student registered
- [ ] Sync test page opened
- [ ] Student synced successfully
- [ ] Green cloud icon visible
- [ ] Backend ID displayed
- [ ] Backend console shows success
- [ ] database.json has new student

---

## 🐛 Troubleshooting

### "Connection refused"
**Fix**: Check backend is running on port 5000

### "Image file not found"
**Fix**: Ensure student was registered with face images

### "No images available"
**Fix**: Re-register student and capture images

---

## 🎉 Done!

**Total Time**: ~6 minutes

If sync works, **Day 2 is COMPLETE!** 🚀

---

## 📝 Import Statement for SyncTestPage

Add to file that needs it:
```dart
import 'package:hadir_mobile_full/features/student_management/presentation/pages/sync_test_page.dart';
```

---

*Next: Day 3 - Status Polling & Real-time Updates* 💪
