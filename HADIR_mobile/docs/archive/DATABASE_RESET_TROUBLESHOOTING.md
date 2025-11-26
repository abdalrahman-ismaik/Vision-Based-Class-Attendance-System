# Database Reset Troubleshooting Guide

## Common Issue: "Error checking student ID" After Database Reset

### Problem Description
After resetting the database, you may encounter an error when trying to check if a student ID exists during the registration process.

### Root Cause
The issue typically occurs due to one of these reasons:

1. **App not fully restarted** - The database connection is cached and still pointing to the old schema
2. **Database version mismatch** - The schema version doesn't match what the code expects
3. **Column name mismatch** - Possible case-sensitivity or typo in column names
4. **Corrupted database state** - The database file wasn't fully recreated

### Solution Steps

#### Step 1: Full App Restart (Hot Restart is NOT enough)
```bash
# Stop the app completely
flutter run  # Press 'q' to quit

# Then restart
flutter run
```

#### Step 2: Use Database Inspector
1. Tap settings icon 5 times on dashboard
2. Select "Database Inspector"
3. Check:
   - ✅ Database version should be 5
   - ✅ `student_id` column should exist in students table
   - ✅ Test query result should show "✅ student_id column accessible"

#### Step 3: If Still Having Issues - Force Clean Reinstall

**Option A: Delete database manually**
```bash
# Find the database file location
# Android: /data/data/edu.university.hadir.hadir_mobile_full/databases/hadir.db
# iOS: Library/Application Support/hadir.db

# Delete via ADB (Android)
adb shell run-as edu.university.hadir.hadir_mobile_full rm /data/data/edu.university.hadir.hadir_mobile_full/databases/hadir.db
```

**Option B: Full app reinstall**
```bash
# Uninstall the app
flutter clean
flutter pub get

# Reinstall
flutter run
```

### Verification Checklist

After fixing:
- [ ] App starts without errors
- [ ] Database Inspector shows version 5
- [ ] Database Inspector shows all expected columns including `student_id`
- [ ] Test query shows ✅ for student_id accessibility
- [ ] Can navigate to registration screen
- [ ] Can enter student ID (5 digits)
- [ ] Email auto-generates correctly
- [ ] Can click "Next" without "Error checking student ID"

### Debug Information to Collect

If the issue persists, collect this information:

1. **Database Version**
   ```dart
   // Via Database Inspector
   // Should show: 5
   ```

2. **Student Table Columns**
   ```sql
   PRAGMA table_info(students)
   -- Should include: id, student_id, full_name, email, etc.
   ```

3. **Exact Error Message**
   ```
   Look for lines containing:
   - "Error checking student ID"
   - "Failed to check if student ID exists"
   - Any SQLite errors
   ```

4. **Flutter Logs**
   ```bash
   flutter logs
   # Look for errors containing "student_id" or "existsByStudentId"
   ```

### Expected Behavior

When checking student ID during registration:

1. User enters 5 digits (e.g., "12345")
2. App constructs full ID: "100012345"
3. App queries: `SELECT student_id FROM students WHERE student_id = '100012345'`
4. If not found → Proceed to next step
5. If found → Show error "Student ID 100012345 is already registered"

### Code Location

The student ID check happens in:
```
lib/features/registration/presentation/screens/registration_screen.dart
Line ~219: Check if student ID already exists
```

The actual query is in:
```
lib/shared/data/repositories/local_student_repository.dart
Line ~241: existsByStudentId method
```

### Quick Test Query

You can test the query directly via Database Inspector or Flutter DevTools:

```dart
final db = await LocalDatabaseDataSource().database;
final result = await db.rawQuery(
  "SELECT student_id FROM students WHERE student_id = '100012345'"
);
print('Query result: $result');
```

Expected outputs:
- If student doesn't exist: `[]` (empty list)
- If student exists: `[{student_id: 100012345}]`

### Common Mistakes

❌ **Don't**: Use hot reload (r) after database reset
✅ **Do**: Full app restart (q + flutter run)

❌ **Don't**: Expect changes immediately after database operations
✅ **Do**: Always restart the app after database schema changes

❌ **Don't**: Clear database while app is running
✅ **Do**: Stop app, clear database, then restart

### Additional Resources

- **Database Fix Tool**: Settings → Tap 5 times → Database Fix Tool
- **Database Inspector**: Settings → Tap 5 times → Database Inspector
- **Migration Docs**: `HADIR_mobile/DATABASE_FIX_2025_11_20.md`
- **Schema Definition**: `lib/shared/data/data_sources/local_database_data_source.dart`

### Still Having Issues?

If none of these steps work, please provide:

1. Full error message from logs
2. Screenshot of Database Inspector page
3. Output of: `flutter doctor -v`
4. Database version shown in Database Inspector
5. List of columns shown in Database Inspector

This will help diagnose the specific issue you're encountering.
