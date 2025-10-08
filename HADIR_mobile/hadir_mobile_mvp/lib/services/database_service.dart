import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/student.dart';
import '../models/registration_session.dart';
import '../utils/constants.dart';

// Simple database service for MVP
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Students table
    await db.execute('''
      CREATE TABLE students (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Registration sessions table
    await db.execute('''
      CREATE TABLE registration_sessions (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        video_path TEXT NOT NULL,
        selected_frames TEXT,
        created_at INTEGER NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY (student_id) REFERENCES students (id)
      )
    ''');
  }

  // Student operations
  Future<void> insertStudent(Student student) async {
    final db = await database;
    await db.insert(
      'students',
      student.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Student?> getStudent(String id) async {
    final db = await database;
    final maps = await db.query(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Student.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Student>> getAllStudents() async {
    final db = await database;
    final maps = await db.query('students', orderBy: 'created_at DESC');
    return maps.map((map) => Student.fromMap(map)).toList();
  }

  // Registration session operations
  Future<void> insertRegistrationSession(RegistrationSession session) async {
    final db = await database;
    
    // Insert student first if not exists
    await insertStudent(session.student);
    
    // Insert session
    await db.insert(
      'registration_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<RegistrationSession?> getRegistrationSession(String id) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT rs.*, s.name, s.email, s.created_at as student_created_at
      FROM registration_sessions rs
      JOIN students s ON rs.student_id = s.id
      WHERE rs.id = ?
    ''', [id]);

    if (maps.isNotEmpty) {
      final map = maps.first;
      final student = Student.fromMap({
        'id': map['student_id'],
        'name': map['name'],
        'email': map['email'],
        'created_at': map['student_created_at'],
      });
      return RegistrationSession.fromMap(map, student);
    }
    return null;
  }

  Future<List<RegistrationSession>> getAllRegistrationSessions() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT rs.*, s.name, s.email, s.created_at as student_created_at
      FROM registration_sessions rs
      JOIN students s ON rs.student_id = s.id
      ORDER BY rs.created_at DESC
    ''');

    return maps.map((map) {
      final student = Student.fromMap({
        'id': map['student_id'],
        'name': map['name'],
        'email': map['email'],
        'created_at': map['student_created_at'],
      });
      return RegistrationSession.fromMap(map, student);
    }).toList();
  }

  Future<void> updateRegistrationSession(RegistrationSession session) async {
    final db = await database;
    await db.update(
      'registration_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  // Cleanup
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}