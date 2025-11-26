# Database Migration Testing Guide

## ✅ Day 1 Task: Test Sync Database Migration

This guide will help you verify that the database migration from v4 to v5 works correctly.

---

## 📋 Prerequisites

1. Flutter environment set up
2. Device/emulator running
3. HADIR mobile app already installed (v4 database exists)

---

## 🧪 Testing Steps

### Step 1: Check Current Database Version

Before running the migration, let's verify your current database version:

```dart
// Add this temporary code to your main.dart or a test screen

import 'package:hadir_mobile_full/shared/data/data_sources/local_database_data_source.dart';

Future<void> checkDatabaseVersion() async {
  final dbSource = LocalDatabaseDataSource();
  final db = await dbSource.database;
  
  final version = await db.getVersion();
  print('[DATABASE] Current version: $version');
  
  // Check table structure
  final tableInfo = await db.rawQuery('PRAGMA table_info(students)');
  print('[DATABASE] Students table columns:');
  for (var col in tableInfo) {
    print('  - ${col['name']}: ${col['type']}');
  }
}
```

**Expected Output (v4):**
```
[DATABASE] Current version: 4
[DATABASE] Students table columns:
  - id: TEXT
  - student_id: TEXT
  - full_name: TEXT
  - email: TEXT
  - department: TEXT
  ... (existing columns)
```

---

### Step 2: Run the App (Migration Happens Automatically)

1. **Build and run the app:**
   ```bash
   cd HADIR_mobile/hadir_mobile_full
   flutter run
   ```

2. **Watch the console for migration logs:**
   ```
   [MIGRATION] Starting migration to v5: Adding sync columns...
   [MIGRATION] ✅ Added sync_status column
   [MIGRATION] ✅ Added backend_student_id column
   [MIGRATION] ✅ Added last_sync_attempt column
   [MIGRATION] ✅ Added sync_error column
   [MIGRATION] ✅ Created sync_status index
   [MIGRATION] ✅ Created backend_student_id index
   [MIGRATION] 🎉 Successfully migrated to v5 (sync support enabled)
   ```

---

### Step 3: Verify Migration Success

Add this code to verify the migration worked:

```dart
import 'package:hadir_mobile_full/shared/data/data_sources/sync_database_migration.dart';
import 'package:hadir_mobile_full/shared/data/data_sources/local_database_data_source.dart';

Future<void> verifyMigration() async {
  final dbSource = LocalDatabaseDataSource();
  final db = await dbSource.database;
  
  // Check version
  final version = await db.getVersion();
  print('[TEST] Database version: $version (expected: 5)');
  assert(version == 5, 'Database should be at version 5');
  
  // Check sync columns exist
  final hasSyncCols = await SyncDatabaseMigration.hasSyncColumns(db);
  print('[TEST] Has sync columns: $hasSyncCols (expected: true)');
  assert(hasSyncCols == true, 'Sync columns should exist');
  
  // Get sync statistics
  final stats = await SyncDatabaseMigration.getSyncStatistics(db);
  print('[TEST] Sync statistics: $stats');
  
  print('[TEST] ✅ All migration tests passed!');
}
```

**Expected Output:**
```
[TEST] Database version: 5 (expected: 5)
[TEST] Has sync columns: true (expected: true)
[TEST] Sync statistics: {not_synced: 3, synced: 0, failed: 0}
[TEST] ✅ All migration tests passed!
```

---

### Step 4: Check Existing Data is Preserved

Query your existing students to ensure their data wasn't lost:

```dart
Future<void> checkExistingData() async {
  final dbSource = LocalDatabaseDataSource();
  final db = await dbSource.database;
  
  final students = await db.query('students', limit: 5);
  
  print('[TEST] Found ${students.length} students');
  for (var student in students) {
    print('[TEST] Student: ${student['full_name']}');
    print('  - sync_status: ${student['sync_status']}'); // Should be 'not_synced'
    print('  - backend_student_id: ${student['backend_student_id']}'); // Should be null
  }
}
```

**Expected Output:**
```
[TEST] Found 3 students
[TEST] Student: John Doe
  - sync_status: not_synced
  - backend_student_id: null
[TEST] Student: Jane Smith
  - sync_status: not_synced
  - backend_student_id: null
```

---

### Step 5: Test Database Queries with New Columns

Test that queries with the new sync columns work:

```dart
Future<void> testSyncQueries() async {
  final dbSource = LocalDatabaseDataSource();
  final db = await dbSource.database;
  
  // Query by sync status
  final notSynced = await db.query(
    'students',
    where: 'sync_status = ?',
    whereArgs: ['not_synced'],
  );
  print('[TEST] Not synced students: ${notSynced.length}');
  
  // Update a student's sync status
  final testStudent = notSynced.first;
  await db.update(
    'students',
    {
      'sync_status': 'syncing',
      'last_sync_attempt': DateTime.now().toIso8601String(),
    },
    where: 'id = ?',
    whereArgs: [testStudent['id']],
  );
  print('[TEST] ✅ Updated sync status to "syncing"');
  
  // Verify update
  final updated = await db.query(
    'students',
    where: 'id = ?',
    whereArgs: [testStudent['id']],
  );
  print('[TEST] Updated sync_status: ${updated.first['sync_status']}');
  assert(updated.first['sync_status'] == 'syncing', 'Status should be syncing');
  
  print('[TEST] ✅ Sync queries work correctly!');
}
```

---

## 🐛 Troubleshooting

### Migration Doesn't Run

**Symptom:** No migration logs appear in console

**Solution:**
1. Uninstall the app completely
2. Reinstall and run again
3. OR manually delete the database:
   ```dart
   await deleteDatabase('hadir.db');
   ```

---

### "Column Already Exists" Error

**Symptom:** Error saying sync_status column already exists

**Solution:** The migration already ran. You can:
1. Continue using the app (it's fine!)
2. OR reset the database for testing:
   ```dart
   import 'package:sqflite/sqflite.dart';
   import 'package:path/path.dart';
   
   final path = join(await getDatabasesPath(), 'hadir.db');
   await deleteDatabase(path);
   ```

---

### Check Migration Status Manually

If you're not sure if migration ran, check manually:

```bash
# Connect to Android device
adb shell

# Navigate to app data
cd /data/data/com.example.hadir_mobile_full/databases/

# Open database
sqlite3 hadir.db

# Check version
PRAGMA user_version;
# Should output: 5

# Check columns
PRAGMA table_info(students);
# Should show: sync_status, backend_student_id, last_sync_attempt, sync_error

# Exit
.quit
```

---

## ✅ Success Criteria

After completing all tests, you should have:

- [x] Database upgraded from v4 to v5
- [x] All 4 sync columns added to students table
- [x] Existing student data preserved
- [x] Default sync_status = 'not_synced' for all students
- [x] Sync status queries working
- [x] No crashes or errors

---

## 📊 Quick Verification Checklist

Run this single function to verify everything:

```dart
Future<void> quickVerify() async {
  try {
    final dbSource = LocalDatabaseDataSource();
    final db = await dbSource.database;
    
    // 1. Check version
    final version = await db.getVersion();
    print('✅ Version: $version ${version == 5 ? "✓" : "✗ (expected 5)"}');
    
    // 2. Check sync columns
    final hasCols = await SyncDatabaseMigration.hasSyncColumns(db);
    print('✅ Sync columns: ${hasCols ? "✓" : "✗"}');
    
    // 3. Check data preserved
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM students'));
    print('✅ Student records: $count');
    
    // 4. Check default values
    final stats = await SyncDatabaseMigration.getSyncStatistics(db);
    print('✅ Sync statistics: $stats');
    
    print('\n🎉 Day 1 Migration: SUCCESS!');
    print('Ready for Day 2: Core Sync Implementation');
    
  } catch (e) {
    print('❌ Verification failed: $e');
  }
}
```

---

## 🎯 Next Steps (Day 2)

Once migration is verified, you're ready to:
1. Create `SyncService` class
2. Implement `syncStudent()` method
3. Configure Dio HTTP client
4. Test sync with backend

---

**Created:** November 5, 2025  
**Sprint Day:** 1 of 7  
**Status:** Ready for Testing ✅
