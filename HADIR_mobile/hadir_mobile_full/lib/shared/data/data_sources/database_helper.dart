import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'local_database_data_source.dart';

/// Helper class for database operations like reset and upgrade
class DatabaseHelper {
  /// Force upgrade the database to the latest version
  /// This will run all necessary migrations
  static Future<void> forceUpgrade() async {
    final dbPath = join(await getDatabasesPath(), 'hadir.db');
    
    // Close any existing connection
    final dataSource = LocalDatabaseDataSource();
    final db = await dataSource.database;
    await db.close();
    
    // Reopen to trigger migrations
    final newDb = await openDatabase(
      dbPath,
      version: 5,
      onUpgrade: (db, oldVersion, newVersion) async {
        print('[DB] Upgrading from version $oldVersion to $newVersion');
        
        // Run all migrations
        if (oldVersion < 5 && newVersion >= 5) {
          print('[DB] Adding sync_status column...');
          await db.execute('''
            ALTER TABLE students 
            ADD COLUMN sync_status TEXT DEFAULT 'not_synced'
          ''');
          
          await db.execute('''
            ALTER TABLE students 
            ADD COLUMN backend_student_id TEXT
          ''');
          
          await db.execute('''
            ALTER TABLE students 
            ADD COLUMN sync_error TEXT
          ''');
          
          await db.execute('''
            ALTER TABLE students 
            ADD COLUMN last_sync_attempt TEXT
          ''');
          
          await db.execute('''
            CREATE INDEX IF NOT EXISTS idx_students_sync_status 
            ON students (sync_status)
          ''');
          
          await db.execute('''
            CREATE INDEX IF NOT EXISTS idx_students_backend_id 
            ON students (backend_student_id)
          ''');
          
          print('[DB] ✅ Sync columns added successfully');
        }
      },
    );
    
    await newDb.close();
    print('[DB] Database upgrade complete');
  }
  
  /// Check the current database version
  static Future<int> getDatabaseVersion() async {
    final dbPath = join(await getDatabasesPath(), 'hadir.db');
    final db = await openDatabase(dbPath);
    final version = await db.getVersion();
    await db.close();
    return version;
  }
  
  /// Reset the entire database (CAUTION: This will delete all data!)
  static Future<void> resetDatabase() async {
    final dbPath = join(await getDatabasesPath(), 'hadir.db');
    await deleteDatabase(dbPath);
    print('[DB] Database deleted successfully');
  }
}
