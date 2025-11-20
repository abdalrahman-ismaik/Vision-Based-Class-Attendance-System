# 🚀 1-Week Sprint - Quick Reference Card

**Project:** HADIR Mobile ↔ Backend Integration  
**Sprint:** November 5-12, 2025  
**Goal:** MVP Sync Feature in Production

---

## 📅 Daily Quick View

| Day | Date | Focus | Deliverable | Hours | Status |
|-----|------|-------|-------------|-------|--------|
| **1** | Nov 5 | Database Setup | DB migrated to v5 | 4h | ✅ DONE |
| **2** | Nov 6 | Core Sync | Sync 1 student works | 8h | 🔜 NEXT |
| **3** | Nov 7 | Status & UI | Real-time status visible | 8h | ⏳ Pending |
| **4** | Nov 8 | Error Handling | Retry logic works | 6h | ⏳ Pending |
| **5** | Nov 9 | Logging & Batch | Sync 5+ students | 6h | ⏳ Pending |
| **6** | Nov 10 | Testing | No bugs, stable | 8h | ⏳ Pending |
| **7** | Nov 11 | Documentation | Demo ready | 5h | ⏳ Pending |
| **D** | Nov 12 | **DELIVERY** | 🎉 DEMO DAY | - | 🎯 TARGET |

---

## 🎯 Critical Path

### Day 1 ✅ (COMPLETED)
```
Database Migration → Sync Models → Testing Guide
```

### Day 2 🔜 (NEXT)
```
Dio Client → SyncService → syncStudent() → Test with 1 student
```

### Day 3-7 ⏳
```
Status Polling → UI → Errors → Logging → Testing → Docs
```

---

## 🔧 Key Files by Day

### Day 1 (✅ Done)
- `lib/shared/data/data_sources/sync_database_migration.dart`
- `lib/core/models/sync_models.dart`
- `lib/shared/data/data_sources/local_database_data_source.dart` (modified)

### Day 2 (🔜 Next)
- `lib/core/services/sync_service.dart` ← **CREATE THIS**
- `lib/core/config/sync_config.dart` ← **CREATE THIS**
- `lib/core/providers/sync_provider.dart` ← **CREATE THIS**

### Day 3
- Modify student list UI
- Add sync status indicators
- Add manual sync button

### Day 4
- Add retry logic to SyncService
- Handle network errors
- Add user-friendly error messages

### Day 5
- Add logging utilities
- Implement batch sync
- Add progress indicators

### Day 6-7
- Testing, bug fixes, documentation

---

## 📞 Quick Commands

### Run App
```bash
cd HADIR_mobile/hadir_mobile_full
flutter run
```

### Start Backend
```bash
cd backend
python app.py
```

### Check Backend
```bash
curl http://localhost:5000/api/docs
```

### Test Sync (curl)
```bash
curl -X POST http://localhost:5000/api/students/ \
  -F "student_id=TEST123" \
  -F "name=Test Student" \
  -F "email=test@test.com" \
  -F "department=CS" \
  -F "year=3" \
  -F "image=@/path/to/image.jpg"
```

### Check Database
```bash
adb shell
cd /data/data/com.example.hadir_mobile_full/databases/
sqlite3 hadir.db
PRAGMA user_version;
SELECT * FROM students LIMIT 1;
.quit
```

---

## 🌐 API Quick Reference

### Register Student
```
POST /api/students/

Form Data:
- student_id (required)
- name (required)
- email (optional)
- department (optional)
- year (optional)
- image (required, file)

Response: 201 Created
{
  "message": "Student registered successfully...",
  "student": { ... }
}
```

### Get Student Status
```
GET /api/students/{student_id}

Response: 200 OK
{
  "student_id": "S12345",
  "processing_status": "pending" | "completed" | "failed",
  ...
}
```

---

## 💡 Quick Tips

### Android Emulator Backend URL
```dart
baseUrl: 'http://10.0.2.2:5000/api'  // NOT localhost!
```

### iOS Simulator Backend URL
```dart
baseUrl: 'http://localhost:5000/api'  // localhost works on iOS
```

### Physical Device Backend URL
```dart
baseUrl: 'http://192.168.x.x:5000/api'  // Your computer's IP
```

---

## 🐛 Common Issues

| Problem | Solution |
|---------|----------|
| Connection refused | Check backend is running |
| 10.0.2.2 not working | Try localhost (iOS) or device IP |
| Image upload fails | Check file exists & is valid image |
| 409 Conflict | Student already exists in backend |
| Migration doesn't run | Uninstall app & reinstall |

---

## ✅ Daily Checklist Template

```
□ Morning standup (5 min)
□ Review yesterday's work
□ Code implementation (4h)
□ Lunch break
□ Testing & debugging (4h)
□ Update progress
□ Commit code
□ Plan tomorrow
□ End-of-day summary
```

---

## 📊 Progress Tracking

```
Overall Sprint: [██░░░░░░░░] 14% (Day 1/7)

Day 1: [██████████] 100% ✅
Day 2: [░░░░░░░░░░]   0% 🔜
Day 3: [░░░░░░░░░░]   0% ⏳
Day 4: [░░░░░░░░░░]   0% ⏳
Day 5: [░░░░░░░░░░]   0% ⏳
Day 6: [░░░░░░░░░░]   0% ⏳
Day 7: [░░░░░░░░░░]   0% ⏳
```

---

## 🎯 Definition of Done

- [x] Day 1: Database migrated ✅
- [ ] Day 2: Can sync 1 student
- [ ] Day 3: Status visible in UI
- [ ] Day 4: Errors handled with retry
- [ ] Day 5: Can sync 5+ students with logs
- [ ] Day 6: No crashes, stable
- [ ] Day 7: Documentation complete
- [ ] Demo: Working end-to-end flow

---

## 📚 Essential Documents

- `1_WEEK_SPRINT.md` - Full implementation plan
- `INTEGRATION_PLAN.md` - Architecture & strategy
- `EXISTING_API_ANALYSIS.md` - Backend API details
- `QUICK_REFERENCE.md` - Troubleshooting guide
- `DAY_1_SUMMARY.md` - Today's work summary
- `SYNC_MIGRATION_TEST_GUIDE.md` - Testing instructions

---

## 🚨 Emergency Contacts

- Backend API Docs: `http://localhost:5000/api/docs`
- Sprint Plan: `1_WEEK_SPRINT.md`
- Architecture: `INTEGRATION_PLAN.md`
- Testing: `SYNC_MIGRATION_TEST_GUIDE.md`

---

## 🎉 Motivation

```
Day 1: ✅ Foundation laid
Day 2: 🔨 Build the core
Day 3: 🎨 Make it visible
Day 4: 🛡️ Make it robust
Day 5: 📝 Make it observable
Day 6: 🧪 Make it stable
Day 7: 📚 Make it documented
Day 8: 🎊 SHIP IT!
```

**You've got this! 💪**

---

**Last Updated:** November 5, 2025  
**Current Status:** Day 1 Complete ✅  
**Next Action:** Day 2 - Core Sync Implementation
