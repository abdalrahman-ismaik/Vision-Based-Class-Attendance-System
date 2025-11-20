# Database Migration Fix - November 20, 2025

## Issues Fixed

### 1. Missing `sync_status` Column Error
**Error**: `no such column: s.sync_status`

**Cause**: The database schema was updated to include sync functionality columns (`sync_status`, `backend_student_id`, `sync_error`, `last_sync_attempt`), but existing databases weren't migrated properly.

**Solution**:
- Updated `_createStudentsTable()` to include sync columns for new installations
- Added indices for `sync_status` and `backend_student_id` in `_createIndices()`
- Enhanced migration logic in `_upgradeDatabase()` to handle v4 → v5 upgrade

### 2. UI Overflow in Student List Screen
**Error**: `RenderFlex overflowed by 45 pixels on the bottom`

**Cause**: The error state Column widget was using `mainAxisSize: max` without allowing scrolling, causing overflow when content exceeded available height.

**Solution**:
- Wrapped the error Column in `SingleChildScrollView`
- Changed `mainAxisSize` from `max` to `min`
- This allows the error message to scroll if needed

## Files Modified

1. `lib/shared/data/data_sources/local_database_data_source.dart`
   - Added sync columns to students table schema
   - Added indices for sync functionality

2. `lib/features/student_management/presentation/screens/student_list_screen.dart`
   - Fixed overflow by wrapping error state in SingleChildScrollView

3. `lib/features/student_management/presentation/pages/database_fix_page.dart` (NEW)
   - Created utility page for database maintenance
   - Allows force upgrade or reset

4. `lib/features/dashboard/presentation/pages/dashboard_page.dart`
   - Added developer menu (tap settings 5 times)
   - Provides access to Database Fix Tool

## How to Fix Your Database

### Method 1: Force Upgrade (Recommended - Keeps Data)
1. Open the HADIR app
2. On the dashboard, tap the settings icon 5 times quickly
3. Select "Database Fix Tool" from the developer menu
4. Tap "Force Upgrade Database"
5. Restart the app

### Method 2: Reset Database (Last Resort - Deletes All Data)
1. Follow steps 1-3 above
2. Tap "Reset Database" (red button)
3. Confirm the action
4. Restart the app

### Method 3: Manual via Flutter DevTools
```dart
// In Dart DevTools console or debug mode:
import 'package:hadir_mobile_full/shared/data/data_sources/database_helper.dart';

// To upgrade:
await DatabaseHelper.forceUpgrade();

// To reset (DELETES ALL DATA):
await DatabaseHelper.resetDatabase();
```

## Testing

After applying the fix:
1. ✅ Navigate to Student Management → Student List
2. ✅ Verify no SQLite errors in logs
3. ✅ Verify error states display correctly without overflow
4. ✅ Test filtering and searching students

## Database Schema (Version 5)

The students table now includes:
```sql
CREATE TABLE students (
  -- Existing columns...
  sync_status TEXT DEFAULT 'not_synced',
  backend_student_id TEXT,
  sync_error TEXT,
  last_sync_attempt TEXT,
  -- ...
);

CREATE INDEX idx_students_sync_status ON students (sync_status);
CREATE INDEX idx_students_backend_id ON students (backend_student_id);
```

## Future Prevention

- All new database columns should be added via migrations in `_upgradeDatabase()`
- Increment the database version number when schema changes
- Test migrations with existing data
- Always provide a migration path for existing users
