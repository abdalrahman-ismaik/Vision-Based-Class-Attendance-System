import 'package:sqflite/sqflite.dart';

/// Database migration for sync functionality (v4 → v5)
/// Adds columns needed for mobile-to-backend synchronization
class SyncDatabaseMigration {
  /// Migrate from version 4 to version 5 - Add sync columns to students table
  static Future<void> migrateTo_v5(Database db) async {
    print('[MIGRATION] Starting migration to v5: Adding sync columns...');
    
    try {
      // Add sync_status column (not_synced, syncing, synced, failed)
      await db.execute('''
        ALTER TABLE students 
        ADD COLUMN sync_status TEXT DEFAULT 'not_synced'
      ''');
      print('[MIGRATION] ✅ Added sync_status column');
      
      // Add backend_student_id column (student ID on backend server)
      await db.execute('''
        ALTER TABLE students 
        ADD COLUMN backend_student_id TEXT
      ''');
      print('[MIGRATION] ✅ Added backend_student_id column');
      
      // Add last_sync_attempt column (ISO 8601 timestamp)
      await db.execute('''
        ALTER TABLE students 
        ADD COLUMN last_sync_attempt TEXT
      ''');
      print('[MIGRATION] ✅ Added last_sync_attempt column');
      
      // Add sync_error column (error message if sync failed)
      await db.execute('''
        ALTER TABLE students 
        ADD COLUMN sync_error TEXT
      ''');
      print('[MIGRATION] ✅ Added sync_error column');
      
      // Create index for faster sync status queries
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_students_sync_status 
        ON students (sync_status)
      ''');
      print('[MIGRATION] ✅ Created sync_status index');
      
      // Create index for backend student ID lookups
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_students_backend_id 
        ON students (backend_student_id)
      ''');
      print('[MIGRATION] ✅ Created backend_student_id index');
      
      print('[MIGRATION] 🎉 Successfully migrated to v5 (sync support enabled)');
      
    } catch (e) {
      print('[MIGRATION] ❌ Migration to v5 failed: $e');
      rethrow;
    }
  }
  
  /// Rollback migration (for testing purposes)
  /// Note: SQLite doesn't support DROP COLUMN directly in older versions
  /// This would require recreating the table
  static Future<void> rollbackFrom_v5(Database db) async {
    print('[MIGRATION] Rollback from v5 not supported (SQLite limitation)');
    print('[MIGRATION] To rollback, you would need to recreate the students table');
    // In a real rollback scenario, you would:
    // 1. Create a new table without sync columns
    // 2. Copy data from old table
    // 3. Drop old table
    // 4. Rename new table
  }
  
  /// Check if sync columns exist (for debugging)
  static Future<bool> hasSyncColumns(Database db) async {
    try {
      final result = await db.rawQuery('''
        PRAGMA table_info(students)
      ''');
      
      final columnNames = result.map((col) => col['name'] as String).toList();
      
      final requiredColumns = [
        'sync_status',
        'backend_student_id',
        'last_sync_attempt',
        'sync_error',
      ];
      
      final hasAllColumns = requiredColumns.every((col) => columnNames.contains(col));
      
      if (hasAllColumns) {
        print('[MIGRATION] ✅ All sync columns present');
      } else {
        print('[MIGRATION] ⚠️ Missing sync columns');
        final missing = requiredColumns.where((col) => !columnNames.contains(col)).toList();
        print('[MIGRATION] Missing: ${missing.join(", ")}');
      }
      
      return hasAllColumns;
    } catch (e) {
      print('[MIGRATION] ❌ Failed to check sync columns: $e');
      return false;
    }
  }
  
  /// Reset all sync statuses (for testing)
  static Future<void> resetAllSyncStatuses(Database db) async {
    print('[MIGRATION] Resetting all sync statuses to not_synced...');
    
    await db.execute('''
      UPDATE students 
      SET sync_status = 'not_synced',
          backend_student_id = NULL,
          last_sync_attempt = NULL,
          sync_error = NULL
    ''');
    
    print('[MIGRATION] ✅ All sync statuses reset');
  }
  
  /// Get sync statistics (for debugging)
  static Future<Map<String, int>> getSyncStatistics(Database db) async {
    final result = await db.rawQuery('''
      SELECT 
        sync_status,
        COUNT(*) as count
      FROM students
      GROUP BY sync_status
    ''');
    
    final stats = <String, int>{};
    for (var row in result) {
      final status = row['sync_status'] as String? ?? 'unknown';
      final count = row['count'] as int? ?? 0;
      stats[status] = count;
    }
    
    print('[MIGRATION] Sync Statistics: $stats');
    return stats;
  }
}
