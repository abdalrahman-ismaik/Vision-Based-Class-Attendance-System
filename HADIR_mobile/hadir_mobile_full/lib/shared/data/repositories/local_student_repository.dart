import 'dart:convert';
import '../../domain/entities/student.dart';
import '../../../features/registration/domain/repositories/student_repository.dart';
import '../data_sources/local_database_data_source.dart';

/// SQLite implementation of StudentRepository
/// Provides concrete data persistence using local SQLite database
class LocalStudentRepository implements StudentRepository {
  final LocalDatabaseDataSource _dataSource;
  
  LocalStudentRepository(this._dataSource);

  static const String _tableName = 'students';

  @override
  Future<Student> create(Student student) async {
    try {
      final map = _studentToMap(student);
      await _dataSource.insert(_tableName, map);
      return student;
    } catch (e) {
      throw Exception('Failed to create student: $e');
    }
  }

  @override
  Future<Student?> getById(String id) async {
    try {
      final maps = await _dataSource.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (maps.isEmpty) return null;
      return _mapToStudent(maps.first);
    } catch (e) {
      throw Exception('Failed to get student by ID: $e');
    }
  }

  @override
  Future<Student?> getByEmail(String email) async {
    try {
      final maps = await _dataSource.query(
        _tableName,
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );
      
      if (maps.isEmpty) return null;
      return _mapToStudent(maps.first);
    } catch (e) {
      throw Exception('Failed to get student by email: $e');
    }
  }

  @override
  Future<Student> update(Student student) async {
    try {
      final map = _studentToMap(student);
      map['last_updated_at'] = DateTime.now().toIso8601String();
      
      final rowsAffected = await _dataSource.update(
        _tableName,
        map,
        where: 'id = ?',
        whereArgs: [student.id],
      );
      
      if (rowsAffected == 0) {
        throw Exception('Student not found for update');
      }
      
      return student.copyWith(lastUpdatedAt: DateTime.now());
    } catch (e) {
      throw Exception('Failed to update student: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      final rowsAffected = await _dataSource.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (rowsAffected == 0) {
        throw Exception('Student not found for deletion');
      }
    } catch (e) {
      throw Exception('Failed to delete student: $e');
    }
  }

  @override
  Future<List<Student>> getAll({
    int limit = 50,
    int offset = 0,
    StudentStatus? status,
    String? major,
    int? enrollmentYear,
    String? searchQuery,
  }) async {
    try {
      String? whereClause;
      List<dynamic>? whereArgs;
      
      final conditions = <String>[];
      final args = <dynamic>[];
      
      if (status != null) {
        conditions.add('status = ?');
        args.add(status.name);
      }
      
      if (major != null) {
        conditions.add('major = ?');
        args.add(major);
      }
      
      if (enrollmentYear != null) {
        conditions.add('enrollment_year = ?');
        args.add(enrollmentYear);
      }
      
      if (searchQuery != null) {
        conditions.add('(full_name LIKE ? OR email LIKE ?)');
        args.add('%$searchQuery%');
        args.add('%$searchQuery%');
      }
      
      if (conditions.isNotEmpty) {
        whereClause = conditions.join(' AND ');
        whereArgs = args;
      }
      
      final maps = await _dataSource.query(
        _tableName,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
        limit: limit,
        offset: offset,
      );
      
      return maps.map((map) => _mapToStudent(map)).toList();
    } catch (e) {
      throw Exception('Failed to get all students: $e');
    }
  }

  @override
  Future<int> getCount({
    StudentStatus? status,
    String? major,
    int? enrollmentYear,
    String? searchQuery,
  }) async {
    try {
      String whereClause = '';
      List<dynamic> whereArgs = [];
      
      final conditions = <String>[];
      
      if (status != null) {
        conditions.add('status = ?');
        whereArgs.add(status.name);
      }
      
      if (major != null) {
        conditions.add('major = ?');
        whereArgs.add(major);
      }
      
      if (enrollmentYear != null) {
        conditions.add('enrollment_year = ?');
        whereArgs.add(enrollmentYear);
      }
      
      if (searchQuery != null) {
        conditions.add('(full_name LIKE ? OR email LIKE ?)');
        whereArgs.add('%$searchQuery%');
        whereArgs.add('%$searchQuery%');
      }
      
      if (conditions.isNotEmpty) {
        whereClause = ' WHERE ${conditions.join(' AND ')}';
      }
      
      final result = await _dataSource.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName$whereClause',
        whereArgs.isEmpty ? null : whereArgs,
      );
      
      return result.first['count'] as int;
    } catch (e) {
      throw Exception('Failed to get student count: $e');
    }
  }

  @override
  Future<bool> exists(String id) async {
    try {
      final maps = await _dataSource.query(
        _tableName,
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      return maps.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check if student exists: $e');
    }
  }

  @override
  Future<bool> existsByEmail(String email) async {
    try {
      final maps = await _dataSource.query(
        _tableName,
        columns: ['email'],
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );
      
      return maps.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check if email exists: $e');
    }
  }

  @override
  Future<bool> existsByStudentId(String studentId) async {
    try {
      final maps = await _dataSource.query(
        _tableName,
        columns: ['student_id'],
        where: 'student_id = ?',
        whereArgs: [studentId],
        limit: 1,
      );
      
      return maps.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check if student ID exists: $e');
    }
  }

  @override
  Future<List<Student>> getByStatus(
    StudentStatus status, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final maps = await _dataSource.query(
        _tableName,
        where: 'status = ?',
        whereArgs: [status.name],
        orderBy: 'full_name ASC',
        limit: limit,
        offset: offset,
      );
      
      return maps.map((map) => _mapToStudent(map)).toList();
    } catch (e) {
      throw Exception('Failed to get students by status: $e');
    }
  }

  @override
  Future<List<Student>> getByMajor(
    String major, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final maps = await _dataSource.query(
        _tableName,
        where: 'major = ?',
        whereArgs: [major],
        orderBy: 'full_name ASC',
        limit: limit,
        offset: offset,
      );
      
      return maps.map((map) => _mapToStudent(map)).toList();
    } catch (e) {
      throw Exception('Failed to get students by major: $e');
    }
  }

  @override
  Future<List<Student>> getByEnrollmentYear(
    int year, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final maps = await _dataSource.query(
        _tableName,
        where: 'enrollment_year = ?',
        whereArgs: [year],
        orderBy: 'full_name ASC',
        limit: limit,
        offset: offset,
      );
      
      return maps.map((map) => _mapToStudent(map)).toList();
    } catch (e) {
      throw Exception('Failed to get students by enrollment year: $e');
    }
  }

  @override
  Future<List<Student>> search(
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final maps = await _dataSource.query(
        _tableName,
        where: 'full_name LIKE ? OR email LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'full_name ASC',
        limit: limit,
        offset: offset,
      );
      
      return maps.map((map) => _mapToStudent(map)).toList();
    } catch (e) {
      throw Exception('Failed to search students: $e');
    }
  }

  @override
  Future<List<Student>> getStudentsWithFaceEmbeddings({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final maps = await _dataSource.query(
        _tableName,
        where: 'face_embeddings IS NOT NULL AND face_embeddings != ?',
        whereArgs: ['[]'],
        orderBy: 'full_name ASC',
        limit: limit,
        offset: offset,
      );
      
      return maps.map((map) => _mapToStudent(map)).toList();
    } catch (e) {
      throw Exception('Failed to get students with face embeddings: $e');
    }
  }

  @override
  Future<Student> updateFaceEmbeddings(
    String studentId,
    List<List<double>> faceEmbeddings,
  ) async {
    try {
      final updatedAt = DateTime.now().toIso8601String();
      final rowsAffected = await _dataSource.update(
        _tableName,
        {
          'face_embeddings': jsonEncode(faceEmbeddings),
          'last_updated_at': updatedAt,
        },
        where: 'id = ?',
        whereArgs: [studentId],
      );
      
      if (rowsAffected == 0) {
        throw Exception('Student not found for face embeddings update');
      }
      
      final student = await getById(studentId);
      return student!;
    } catch (e) {
      throw Exception('Failed to update face embeddings: $e');
    }
  }

  @override
  Future<Student> updateStatus(String studentId, StudentStatus status) async {
    try {
      final updatedAt = DateTime.now().toIso8601String();
      final rowsAffected = await _dataSource.update(
        _tableName,
        {
          'status': status.name,
          'last_updated_at': updatedAt,
        },
        where: 'id = ?',
        whereArgs: [studentId],
      );
      
      if (rowsAffected == 0) {
        throw Exception('Student not found for status update');
      }
      
      final student = await getById(studentId);
      return student!;
    } catch (e) {
      throw Exception('Failed to update student status: $e');
    }
  }

  @override
  Future<List<Student>> getByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final maps = await _dataSource.query(
        _tableName,
        where: 'created_at BETWEEN ? AND ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: 'created_at DESC',
        limit: limit,
        offset: offset,
      );
      
      return maps.map((map) => _mapToStudent(map)).toList();
    } catch (e) {
      throw Exception('Failed to get students by date range: $e');
    }
  }

  @override
  Future<Map<String, int>> getStudentCountByMajor() async {
    try {
      final maps = await _dataSource.rawQuery(
        'SELECT major, COUNT(*) as count FROM $_tableName WHERE major IS NOT NULL GROUP BY major',
      );
      
      final result = <String, int>{};
      for (final map in maps) {
        result[map['major'] as String] = map['count'] as int;
      }
      
      return result;
    } catch (e) {
      throw Exception('Failed to get student count by major: $e');
    }
  }

  @override
  Future<Map<StudentStatus, int>> getStudentCountByStatus() async {
    try {
      final maps = await _dataSource.rawQuery(
        'SELECT status, COUNT(*) as count FROM $_tableName GROUP BY status',
      );
      
      final result = <StudentStatus, int>{};
      for (final map in maps) {
        final statusName = map['status'] as String;
        final status = StudentStatus.values.firstWhere(
          (s) => s.name == statusName,
          orElse: () => StudentStatus.pending,
        );
        result[status] = map['count'] as int;
      }
      
      return result;
    } catch (e) {
      throw Exception('Failed to get student count by status: $e');
    }
  }

  @override
  Future<Map<int, int>> getStudentCountByEnrollmentYear() async {
    try {
      final maps = await _dataSource.rawQuery(
        'SELECT enrollment_year, COUNT(*) as count FROM $_tableName WHERE enrollment_year IS NOT NULL GROUP BY enrollment_year',
      );
      
      final result = <int, int>{};
      for (final map in maps) {
        result[map['enrollment_year'] as int] = map['count'] as int;
      }
      
      return result;
    } catch (e) {
      throw Exception('Failed to get student count by enrollment year: $e');
    }
  }

  @override
  Future<int> bulkUpdateStatus(List<String> studentIds, StudentStatus status) async {
    try {
      int totalUpdated = 0;
      await _dataSource.transaction((txn) async {
        for (final id in studentIds) {
          final rowsAffected = await txn.update(
            _tableName,
            {
              'status': status.name,
              'last_updated_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [id],
          );
          totalUpdated += rowsAffected;
        }
      });
      
      return totalUpdated;
    } catch (e) {
      throw Exception('Failed to bulk update student status: $e');
    }
  }

  @override
  Future<int> bulkDelete(List<String> studentIds) async {
    try {
      int totalDeleted = 0;
      await _dataSource.transaction((txn) async {
        for (final id in studentIds) {
          final rowsAffected = await txn.delete(
            _tableName,
            where: 'id = ?',
            whereArgs: [id],
          );
          totalDeleted += rowsAffected;
        }
      });
      
      return totalDeleted;
    } catch (e) {
      throw Exception('Failed to bulk delete students: $e');
    }
  }

  @override
  Future<int> archiveOldStudents(int daysThreshold) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysThreshold));
      final rowsAffected = await _dataSource.update(
        _tableName,
        {
          'status': StudentStatus.archived.name,
          'last_updated_at': DateTime.now().toIso8601String(),
        },
        where: 'last_updated_at < ? AND status != ?',
        whereArgs: [cutoffDate.toIso8601String(), StudentStatus.archived.name],
      );
      
      return rowsAffected;
    } catch (e) {
      throw Exception('Failed to archive old students: $e');
    }
  }

  /// Convert database map to Student entity
  Student _mapToStudent(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      fullName: map['full_name'] as String,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      email: map['email'] as String,
      phoneNumber: map['phone_number'] as String?,
      dateOfBirth: DateTime.parse(map['date_of_birth'] as String),
      gender: map['gender'] != null 
          ? Gender.values.firstWhere(
              (g) => g.name == map['gender'],
              orElse: () => Gender.other,
            )
          : null,
      nationality: map['nationality'] as String?,
      major: map['major'] as String?,
      enrollmentYear: map['enrollment_year'] as int?,
      academicLevel: map['academic_level'] != null
          ? AcademicLevel.values.firstWhere(
              (level) => level.name == map['academic_level'],
              orElse: () => AcademicLevel.undergraduate,
            )
          : null,
      department: map['department'] as String,
      program: map['program'] as String,
      status: StudentStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => StudentStatus.pending,
      ),
      registrationSessionId: map['registration_session_id'] as String?,
      faceEmbeddings: map['face_embeddings'] != null 
          ? List<List<double>>.from(
              jsonDecode(map['face_embeddings'] as String).map(
                (item) => List<double>.from(item),
              ),
            )
          : const [],
      createdAt: DateTime.parse(map['created_at'] as String),
      lastUpdatedAt: map['last_updated_at'] != null 
          ? DateTime.parse(map['last_updated_at'] as String)
          : null,
    );
  }

  /// Convert Student entity to database map
  Map<String, dynamic> _studentToMap(Student student) {
    return {
      'id': student.id,
      'student_id': student.studentId,
      'full_name': student.fullName,
      'first_name': student.firstName,
      'last_name': student.lastName,
      'email': student.email,
      'phone_number': student.phoneNumber,
      'date_of_birth': student.dateOfBirth.toIso8601String(),
      'gender': student.gender?.name,
      'nationality': student.nationality,
      'major': student.major,
      'enrollment_year': student.enrollmentYear,
      'academic_level': student.academicLevel?.name,
      'department': student.department,
      'program': student.program,
      'status': student.status.name,
      'registration_session_id': student.registrationSessionId,
      'face_embeddings': student.faceEmbeddings.isNotEmpty 
          ? jsonEncode(student.faceEmbeddings)
          : null,
      'created_at': student.createdAt.toIso8601String(),
      'last_updated_at': student.lastUpdatedAt?.toIso8601String(),
    };
  }
}