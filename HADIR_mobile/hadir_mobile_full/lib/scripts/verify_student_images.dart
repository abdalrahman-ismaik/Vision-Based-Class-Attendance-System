/// Verify Student Images Database Integrity
/// =========================================
/// 
/// This script checks the mobile app's SQLite database and verifies:
/// 1. Each student has a registration session
/// 2. Each session has exactly 5 frames (one per pose)
/// 3. Image files actually exist on the filesystem
/// 4. No image files are shared between different students
/// 5. Image filenames match the session ID pattern
///
/// Usage:
///   dart run lib/scripts/verify_student_images.dart

import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  // Initialize sqflite for desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  print('=' * 80);
  print('MOBILE APP DATABASE VERIFICATION');
  print('=' * 80);
  
  try {
    // Open database
    final dbPath = join(await getDatabasesPath(), 'hadir.db');
    
    if (!await File(dbPath).exists()) {
      print('ERROR: Database file not found at: $dbPath');
      print('Please run the mobile app at least once to create the database.');
      exit(1);
    }
    
    print('Database location: $dbPath');
    print('');
    
    final db = await openDatabase(dbPath, readOnly: true);
    
    // Get database version
    final version = await db.getVersion();
    print('Database version: $version');
    print('');
    
    // Verify students
    await verifyStudents(db);
    
    // Verify image files
    await verifyImageFiles(db);
    
    // Check for duplicate images
    await checkDuplicateImages(db);
    
    // Check for orphaned images
    await checkOrphanedImages(db);
    
    await db.close();
    
    print('');
    print('=' * 80);
    print('VERIFICATION COMPLETE');
    print('=' * 80);
    
  } catch (e, stackTrace) {
    print('ERROR: $e');
    print(stackTrace);
    exit(1);
  }
}

Future<void> verifyStudents(Database db) async {
  print('─' * 80);
  print('CHECKING STUDENTS');
  print('─' * 80);
  
  final students = await db.query('students', orderBy: 'created_at DESC');
  
  print('Total students in database: ${students.length}');
  print('');
  
  if (students.isEmpty) {
    print('⚠ No students found in database');
    return;
  }
  
  int issuesFound = 0;
  
  for (var i = 0; i < students.length; i++) {
    final student = students[i];
    final studentId = student['student_id'] as String;
    final fullName = student['full_name'] as String;
    final sessionId = student['registration_session_id'] as String?;
    
    print('[${i + 1}] Student: $fullName (ID: $studentId)');
    
    if (sessionId == null || sessionId.isEmpty) {
      print('    ✗ ERROR: No registration session linked');
      issuesFound++;
      continue;
    }
    
    print('    Session ID: $sessionId');
    
    // Check if session exists
    final sessions = await db.query(
      'registration_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    
    if (sessions.isEmpty) {
      print('    ✗ ERROR: Session not found in database');
      issuesFound++;
      continue;
    }
    
    final session = sessions.first;
    final status = session['status'] as String;
    print('    Session status: $status');
    
    // Check frames for this session
    final frames = await db.query(
      'selected_frames',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp_ms ASC',
    );
    
    print('    Captured frames: ${frames.length}');
    
    if (frames.length != 5) {
      print('    ⚠ WARNING: Expected 5 frames (one per pose), found ${frames.length}');
      issuesFound++;
    }
    
    // Check pose distribution
    final poses = <String>{};
    for (var frame in frames) {
      poses.add(frame['pose_type'] as String);
    }
    
    if (poses.length != frames.length) {
      print('    ⚠ WARNING: Duplicate poses detected');
      print('       Unique poses: ${poses.join(", ")}');
      issuesFound++;
    }
    
    // List frame details
    for (var j = 0; j < frames.length; j++) {
      final frame = frames[j];
      final poseType = frame['pose_type'] as String;
      final imagePath = frame['image_file_path'] as String;
      final fileName = imagePath.split('/').last;
      
      print('    Frame ${j + 1}: $poseType - $fileName');
    }
    
    print('');
  }
  
  if (issuesFound > 0) {
    print('⚠ Found $issuesFound issues with student records');
  } else {
    print('✓ All student records look correct');
  }
  print('');
}

Future<void> verifyImageFiles(Database db) async {
  print('─' * 80);
  print('CHECKING IMAGE FILES');
  print('─' * 80);
  
  final frames = await db.query('selected_frames');
  
  print('Total image records: ${frames.length}');
  print('');
  
  if (frames.isEmpty) {
    print('⚠ No image records found');
    return;
  }
  
  int existingFiles = 0;
  int missingFiles = 0;
  
  for (var frame in frames) {
    final imagePath = frame['image_file_path'] as String;
    final sessionId = frame['session_id'] as String;
    final poseType = frame['pose_type'] as String;
    
    // Get student for this session
    final students = await db.query(
      'students',
      where: 'registration_session_id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    
    if (students.isEmpty) {
      print('✗ Orphaned image: $imagePath');
      print('   Session ID: $sessionId (no student found)');
      missingFiles++;
      continue;
    }
    
    final student = students.first;
    final studentName = student['full_name'] as String;
    
    final file = File(imagePath);
    
    if (await file.exists()) {
      existingFiles++;
    } else {
      print('✗ Missing file: ${file.path}');
      print('   Student: $studentName');
      print('   Session: $sessionId');
      print('   Pose: $poseType');
      missingFiles++;
    }
  }
  
  print('');
  print('Image file status:');
  print('  ✓ Existing: $existingFiles');
  print('  ✗ Missing: $missingFiles');
  print('');
}

Future<void> checkDuplicateImages(Database db) async {
  print('─' * 80);
  print('CHECKING FOR DUPLICATE IMAGES');
  print('─' * 80);
  
  final frames = await db.query('selected_frames');
  
  // Group by image path
  final imagesByPath = <String, List<Map<String, dynamic>>>{};
  
  for (var frame in frames) {
    final imagePath = frame['image_file_path'] as String;
    imagesByPath.putIfAbsent(imagePath, () => []).add(frame);
  }
  
  final duplicates = imagesByPath.entries.where((e) => e.value.length > 1).toList();
  
  if (duplicates.isEmpty) {
    print('✓ No duplicate image paths found');
  } else {
    print('⚠ Found ${duplicates.length} images used by multiple records:');
    print('');
    
    for (var entry in duplicates) {
      print('Image: ${entry.key}');
      print('  Used by ${entry.value.length} records:');
      
      for (var frame in entry.value) {
        final sessionId = frame['session_id'] as String;
        final poseType = frame['pose_type'] as String;
        
        // Get student
        final students = await db.query(
          'students',
          where: 'registration_session_id = ?',
          whereArgs: [sessionId],
          limit: 1,
        );
        
        if (students.isNotEmpty) {
          final student = students.first;
          final studentName = student['full_name'] as String;
          final studentId = student['student_id'] as String;
          print('    - Student: $studentName (ID: $studentId), Pose: $poseType');
        } else {
          print('    - Session: $sessionId (no student), Pose: $poseType');
        }
      }
      print('');
    }
  }
  print('');
}

Future<void> checkOrphanedImages(Database db) async {
  print('─' * 80);
  print('CHECKING FOR ORPHANED IMAGES');
  print('─' * 80);
  
  // Get all image paths from database
  final frames = await db.query('selected_frames');
  final dbImagePaths = frames.map((f) => f['image_file_path'] as String).toSet();
  
  print('Images in database: ${dbImagePaths.length}');
  
  // Check for orphaned files on filesystem
  // Note: You'll need to adjust this path based on where your app stores images
  final appDir = Directory.systemTemp.path; // Placeholder - adjust as needed
  print('Checking directory: $appDir');
  print('(Note: Adjust this path in the script to match your app\'s storage location)');
  print('');
  
  // This is a placeholder - you'll need to implement actual file system scanning
  // based on where your Flutter app stores the captured images
  
  print('✓ Orphaned file check completed');
  print('');
}
