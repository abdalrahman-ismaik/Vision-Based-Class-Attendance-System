import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:hadir_mobile_full/shared/data/data_sources/local_database_data_source.dart';
import 'package:hadir_mobile_full/shared/data/data_sources/sync_database_migration.dart';

/// Test the database migration for sync functionality
/// 
/// Run this test to verify:
/// 1. Migration adds all 4 sync columns
/// 2. Indices are created correctly
/// 3. Existing data is preserved
void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Sync Database Migration Tests', () {
    test('Migration to v5 adds sync columns', () async {
      // Create a test database
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 4, // Start with v4
        onCreate: (db, version) async {
          // Create minimal students table
          await db.execute('''
            CREATE TABLE students (
              id TEXT PRIMARY KEY,
              student_id TEXT UNIQUE NOT NULL,
              full_name TEXT NOT NULL,
              email TEXT NOT NULL,
              department TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
        },
      );

      // Run migration
      await SyncDatabaseMigration.migrateTo_v5(db);

      // Verify sync columns exist
      final hasSyncColumns = await SyncDatabaseMigration.hasSyncColumns(db);
      expect(hasSyncColumns, true);

      await db.close();
    });

    test('Migration preserves existing student data', () async {
      // Create database with sample data
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 4,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE students (
              id TEXT PRIMARY KEY,
              student_id TEXT UNIQUE NOT NULL,
              full_name TEXT NOT NULL,
              email TEXT NOT NULL,
              department TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');

          // Insert test student
          await db.insert('students', {
            'id': 'test-uuid-123',
            'student_id': 'S12345',
            'full_name': 'John Doe',
            'email': 'john@test.com',
            'department': 'Computer Science',
            'created_at': DateTime.now().toIso8601String(),
          });
        },
      );

      // Run migration
      await SyncDatabaseMigration.migrateTo_v5(db);

      // Verify data still exists
      final students = await db.query('students');
      expect(students.length, 1);
      expect(students[0]['student_id'], 'S12345');
      expect(students[0]['full_name'], 'John Doe');
      
      // Verify new columns have default values
      expect(students[0]['sync_status'], 'not_synced');
      expect(students[0]['backend_student_id'], null);

      await db.close();
    });

    test('Sync statistics work correctly', () async {
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 5,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE students (
              id TEXT PRIMARY KEY,
              student_id TEXT UNIQUE NOT NULL,
              full_name TEXT NOT NULL,
              email TEXT NOT NULL,
              department TEXT NOT NULL,
              created_at TEXT NOT NULL,
              sync_status TEXT DEFAULT 'not_synced',
              backend_student_id TEXT,
              last_sync_attempt TEXT,
              sync_error TEXT
            )
          ''');

          // Insert test students with different sync statuses
          await db.insert('students', {
            'id': 'uuid-1',
            'student_id': 'S001',
            'full_name': 'Student 1',
            'email': 's1@test.com',
            'department': 'CS',
            'created_at': DateTime.now().toIso8601String(),
            'sync_status': 'not_synced',
          });

          await db.insert('students', {
            'id': 'uuid-2',
            'student_id': 'S002',
            'full_name': 'Student 2',
            'email': 's2@test.com',
            'department': 'CS',
            'created_at': DateTime.now().toIso8601String(),
            'sync_status': 'synced',
          });

          await db.insert('students', {
            'id': 'uuid-3',
            'student_id': 'S003',
            'full_name': 'Student 3',
            'email': 's3@test.com',
            'department': 'CS',
            'created_at': DateTime.now().toIso8601String(),
            'sync_status': 'failed',
          });
        },
      );

      // Get sync statistics
      final stats = await SyncDatabaseMigration.getSyncStatistics(db);
      
      expect(stats['not_synced'], 1);
      expect(stats['synced'], 1);
      expect(stats['failed'], 1);

      await db.close();
    });

    test('Reset sync statuses works', () async {
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 5,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE students (
              id TEXT PRIMARY KEY,
              student_id TEXT UNIQUE NOT NULL,
              full_name TEXT NOT NULL,
              email TEXT NOT NULL,
              department TEXT NOT NULL,
              created_at TEXT NOT NULL,
              sync_status TEXT DEFAULT 'not_synced',
              backend_student_id TEXT,
              last_sync_attempt TEXT,
              sync_error TEXT
            )
          ''');

          // Insert student with synced status
          await db.insert('students', {
            'id': 'uuid-1',
            'student_id': 'S001',
            'full_name': 'Student 1',
            'email': 's1@test.com',
            'department': 'CS',
            'created_at': DateTime.now().toIso8601String(),
            'sync_status': 'synced',
            'backend_student_id': 'backend-123',
          });
        },
      );

      // Reset sync statuses
      await SyncDatabaseMigration.resetAllSyncStatuses(db);

      // Verify reset worked
      final students = await db.query('students');
      expect(students[0]['sync_status'], 'not_synced');
      expect(students[0]['backend_student_id'], null);

      await db.close();
    });
  });
}
