# Database Reset Instructions

## What Changed

The database schema has been updated to **version 3** to match the current implementation without ML Kit:

### Old Schema (Version 2) - Had ML Kit Fields
```sql
CREATE TABLE selected_frames (
  id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL,
  image_file_path TEXT NOT NULL,
  timestamp_ms INTEGER NOT NULL,
  quality_score REAL NOT NULL,
  pose_angles TEXT NOT NULL,      -- ❌ Required ML Kit data
  face_metrics TEXT NOT NULL,      -- ❌ Required ML Kit data
  bounding_box TEXT,               -- ❌ Required ML Kit data
  pose_type TEXT NOT NULL,
  confidence_score REAL NOT NULL,
  quality_metrics TEXT,
  extracted_at TEXT NOT NULL,
  metadata TEXT,
  FOREIGN KEY (session_id) REFERENCES registration_sessions (id)
)
```

### New Schema (Version 3) - Manual Validation Only
```sql
CREATE TABLE selected_frames (
  id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL,
  image_file_path TEXT NOT NULL,
  timestamp_ms INTEGER NOT NULL,
  quality_score REAL NOT NULL,
  pose_type TEXT NOT NULL,
  confidence_score REAL NOT NULL,
  extracted_at TEXT NOT NULL,
  metadata TEXT,                   -- ✓ Stores capture method info
  FOREIGN KEY (session_id) REFERENCES registration_sessions (id)
)
```

## Option 1: Automatic Migration (Recommended)

The database will **automatically migrate** from version 2 to version 3 when you run the app.

**What Happens:**
1. App detects old version (2)
2. Drops the old `selected_frames` table
3. Creates new simplified table
4. Recreates indices

**Note:** This will delete any existing frame data in the `selected_frames` table, but students and sessions are preserved.

Just run the app normally:
```bash
flutter run
```

## Option 2: Manual Database Reset (Clean Start)

If you want to completely delete the database and start fresh:

### Method A: Uninstall and Reinstall App
```bash
# Uninstall from device/emulator
flutter clean
flutter run
```

### Method B: Delete Database via ADB (Android)
```bash
# Find the package path
adb shell run-as edu.university.hadir.hadir_mobile_full ls /data/data/edu.university.hadir.hadir_mobile_full/databases/

# Delete the database
adb shell run-as edu.university.hadir.hadir_mobile_full rm /data/data/edu.university.hadir.hadir_mobile_full/databases/hadir.db
adb shell run-as edu.university.hadir.hadir_mobile_full rm /data/data/edu.university.hadir.hadir_mobile_full/databases/hadir.db-shm
adb shell run-as edu.university.hadir.hadir_mobile_full rm /data/data/edu.university.hadir.hadir_mobile_full/databases/hadir.db-wal

# Then run the app
flutter run
```

### Method C: Use Device Settings (Easiest)
1. Go to device **Settings** → **Apps**
2. Find **HADIR Mobile Full**
3. Tap **Storage**
4. Tap **Clear Data** or **Clear Storage**
5. Run the app again

## Verify Migration

After the migration, check the logs for:
```
✓ Database migrated to version 3
✓ Selected frames table recreated with simplified schema
```

## What Data is Stored Now

Since ML Kit was removed, frames now store:
- ✅ Image file path
- ✅ Timestamp
- ✅ Quality score (from sharpness analysis)
- ✅ Pose type (frontal, leftProfile, etc.)
- ✅ Confidence score (set to 1.0 for manual validation)
- ✅ Metadata (JSON with capture method info)

**No longer stored:**
- ❌ Pose angles (yaw, pitch, roll)
- ❌ Face metrics (bounding box, symmetry, etc.)
- ❌ ML Kit detection data

These will be calculated by the backend YOLOv7 service during frame selection.
