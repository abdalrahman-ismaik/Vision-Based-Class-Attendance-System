import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'dart:io';
import 'sync_database_migration.dart';

/// Local SQLite database data source for HADIR mobile app
/// Provides low-level database operations and schema management
class LocalDatabaseDataSource {
  static final LocalDatabaseDataSource _instance = LocalDatabaseDataSource._internal();
  static Database? _database;
  
  factory LocalDatabaseDataSource() => _instance;
  
  LocalDatabaseDataSource._internal();

  /// Get database instance, creating it if necessary
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the database with schema and migrations
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'hadir.db');
    
    return await openDatabase(
      path,
      version: 5, // ← Increment for sync functionality (v4 → v5)
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  /// Create database schema on first run
  Future<void> _createDatabase(Database db, int version) async {
    await _createStudentsTable(db);
    await _createAdministratorsTable(db);
    await _createRegistrationSessionsTable(db);
    await _createSelectedFramesTable(db);
    await _createIndices(db);
    
    // Add student management indices for new installations (v4+)
    if (version >= 4) {
      await _addStudentManagementIndices(db);
    }
  }

  /// Handle database schema upgrades
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Migration from version 1 to 2: Add started_at and completed_at columns
    if (oldVersion == 1 && newVersion >= 2) {
      await db.execute('''
        ALTER TABLE registration_sessions 
        ADD COLUMN started_at TEXT NOT NULL DEFAULT ''
      ''');
      
      await db.execute('''
        ALTER TABLE registration_sessions 
        ADD COLUMN completed_at TEXT
      ''');
      
      // Update existing records with current timestamps
      await db.execute('''
        UPDATE registration_sessions 
        SET started_at = created_at
        WHERE started_at = ''
      ''');
    }
    
    // Migration from version 2 to 3: Simplify selected_frames table (remove ML Kit columns)
    if (oldVersion < 3 && newVersion >= 3) {
      // Drop and recreate selected_frames table with simplified schema
      await db.execute('DROP TABLE IF EXISTS selected_frames');
      await _createSelectedFramesTable(db);
      
      // Recreate indices
      await db.execute('CREATE INDEX IF NOT EXISTS idx_selected_frames_session_id ON selected_frames (session_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_selected_frames_pose_type ON selected_frames (pose_type)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_selected_frames_quality_score ON selected_frames (quality_score)');
    }
    
    // Migration from version 3 to 4: Add optimized indices for student management
    if (oldVersion < 4 && newVersion >= 4) {
      await _addStudentManagementIndices(db);
    }
    
    // Migration from version 4 to 5: Add sync functionality columns
    if (oldVersion < 5 && newVersion >= 5) {
      await SyncDatabaseMigration.migrateTo_v5(db);
    }
  }

  /// Add optimized indices for student management module (version 4)
  Future<void> _addStudentManagementIndices(Database db) async {
    // Compound indices for filtering and sorting
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_students_status_created 
      ON students (status, created_at DESC)
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_students_department_status 
      ON students (department, status)
    ''');
    
    // Full-text search index on student name
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_students_full_name_lower 
      ON students (LOWER(full_name))
    ''');
    
    // Index for frame counting queries
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_selected_frames_session_extracted 
      ON selected_frames (session_id, extracted_at)
    ''');
  }

  /// Create students table
  Future<void> _createStudentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE students (
        id TEXT PRIMARY KEY,
        student_id TEXT UNIQUE NOT NULL,
        full_name TEXT NOT NULL,
        first_name TEXT,
        last_name TEXT,
        email TEXT NOT NULL,
        phone_number TEXT,
        date_of_birth TEXT NOT NULL,
        gender TEXT,
        nationality TEXT,
        major TEXT,
        enrollment_year INTEGER,
        academic_level TEXT,
        department TEXT NOT NULL,
        program TEXT NOT NULL,
        status TEXT NOT NULL,
        registration_session_id TEXT,
        face_embeddings TEXT,
        created_at TEXT NOT NULL,
        last_updated_at TEXT,
        FOREIGN KEY (registration_session_id) REFERENCES registration_sessions (id)
      )
    ''');
  }

  /// Create administrators table
  Future<void> _createAdministratorsTable(Database db) async {
    await db.execute('''
      CREATE TABLE administrators (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        full_name TEXT NOT NULL,
        role TEXT NOT NULL,
        status TEXT NOT NULL,
        last_login_at TEXT,
        password_changed_at TEXT,
        failed_login_attempts INTEGER DEFAULT 0,
        is_account_locked INTEGER DEFAULT 0,
        account_locked_until TEXT,
        metadata TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  /// Create registration sessions table
  Future<void> _createRegistrationSessionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE registration_sessions (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        administrator_id TEXT NOT NULL,
        video_file_path TEXT NOT NULL,
        status TEXT NOT NULL,
        started_at TEXT NOT NULL,
        completed_at TEXT,
        video_duration_ms INTEGER NOT NULL,
        total_frames_processed INTEGER NOT NULL,
        selected_frames_count INTEGER NOT NULL,
        overall_quality_score REAL NOT NULL,
        pose_coverage_percentage REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (student_id) REFERENCES students (id),
        FOREIGN KEY (administrator_id) REFERENCES administrators (id)
      )
    ''');
  }

  /// Create selected frames table
  /// Simplified schema - no ML Kit data since we're using manual validation
  Future<void> _createSelectedFramesTable(Database db) async {
    await db.execute('''
      CREATE TABLE selected_frames (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        image_file_path TEXT NOT NULL,
        timestamp_ms INTEGER NOT NULL,
        quality_score REAL NOT NULL,
        pose_type TEXT NOT NULL,
        confidence_score REAL NOT NULL,
        extracted_at TEXT NOT NULL,
        metadata TEXT,
        FOREIGN KEY (session_id) REFERENCES registration_sessions (id)
      )
    ''');
  }

  /// Create database indices for performance
  Future<void> _createIndices(Database db) async {
    // Students indices
    await db.execute('CREATE INDEX idx_students_student_id ON students (student_id)');
    await db.execute('CREATE INDEX idx_students_email ON students (email)');
    await db.execute('CREATE INDEX idx_students_status ON students (status)');
    await db.execute('CREATE INDEX idx_students_department ON students (department)');
    
    // Administrators indices
    await db.execute('CREATE INDEX idx_administrators_username ON administrators (username)');
    await db.execute('CREATE INDEX idx_administrators_email ON administrators (email)');
    await db.execute('CREATE INDEX idx_administrators_status ON administrators (status)');
    
    // Registration sessions indices
    await db.execute('CREATE INDEX idx_registration_sessions_student_id ON registration_sessions (student_id)');
    await db.execute('CREATE INDEX idx_registration_sessions_administrator_id ON registration_sessions (administrator_id)');
    await db.execute('CREATE INDEX idx_registration_sessions_status ON registration_sessions (status)');
    await db.execute('CREATE INDEX idx_registration_sessions_created_at ON registration_sessions (created_at)');
    
    // Selected frames indices
    await db.execute('CREATE INDEX idx_selected_frames_session_id ON selected_frames (session_id)');
    await db.execute('CREATE INDEX idx_selected_frames_pose_type ON selected_frames (pose_type)');
    await db.execute('CREATE INDEX idx_selected_frames_quality_score ON selected_frames (quality_score)');
  }

  /// Generic query method for SELECT operations
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// Generic insert method
  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return await db.insert(table, values);
  }

  /// Generic update method
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, values, where: where, whereArgs: whereArgs);
  }

  /// Generic delete method
  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  /// Execute raw SQL query
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  /// Execute raw SQL insert/update/delete
  Future<int> rawExecute(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return await db.rawInsert(sql, arguments);
  }

  /// Begin a database transaction
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  /// Get database file size in bytes
  Future<int> getDatabaseSize() async {
    String path = join(await getDatabasesPath(), 'hadir.db');
    File dbFile = File(path);
    if (await dbFile.exists()) {
      return await dbFile.length();
    }
    return 0;
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Delete database file (for testing or reset)
  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), 'hadir.db');
    await close();
    await databaseFactory.deleteDatabase(path);
  }

  /// Check if database file exists
  Future<bool> databaseExists() async {
    String path = join(await getDatabasesPath(), 'hadir.db');
    return await File(path).exists();
  }

  /// Get database version
  Future<int> getDatabaseVersion() async {
    final db = await database;
    return await db.getVersion();
  }
}