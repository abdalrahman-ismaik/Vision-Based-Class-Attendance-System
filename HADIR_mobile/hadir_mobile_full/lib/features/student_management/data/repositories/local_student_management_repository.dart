import '../../domain/repositories/student_management_repository.dart';
import '../models/student_list_item.dart';
import '../models/student_detail.dart';
import '../models/student_filter.dart';
import '../models/student_sort_option.dart';
import '../../../../shared/domain/entities/student.dart';
import '../../../../shared/domain/entities/selected_frame.dart';
import '../../../../shared/data/data_sources/local_database_data_source.dart';

/// Local database implementation of student management repository
class LocalStudentManagementRepository implements StudentManagementRepository {
  final LocalDatabaseDataSource _dataSource;

  LocalStudentManagementRepository(this._dataSource);

  @override
  Future<List<StudentListItem>> getAllStudents({
    int limit = 20,
    int offset = 0,
    StudentSortOption? sortBy,
  }) async {
    final sortClause = sortBy?.sqlOrderBy ?? 's.full_name ASC';
    
    final results = await _dataSource.rawQuery('''
      SELECT 
        s.id,
        s.student_id,
        s.full_name,
        s.email,
        s.department,
        s.status,
        s.created_at,
        s.sync_status,
        COUNT(DISTINCT sf.id) as frame_count
      FROM students s
      LEFT JOIN selected_frames sf ON s.registration_session_id = sf.session_id
      GROUP BY s.id
      ORDER BY $sortClause
      LIMIT ? OFFSET ?
    ''', [limit, offset]);

    return results.map((map) => StudentListItem.fromMap(map)).toList();
  }

  @override
  Future<List<StudentListItem>> searchStudents({
    required String query,
    int limit = 20,
  }) async {
    // Use FTS5 for full-text search if available
    // Otherwise fall back to LIKE queries
    final searchTerm = '%$query%';
    
    final results = await _dataSource.rawQuery('''
      SELECT 
        s.id,
        s.student_id,
        s.full_name,
        s.email,
        s.department,
        s.status,
        s.created_at,
        s.sync_status,
        COUNT(DISTINCT sf.id) as frame_count
      FROM students s
      LEFT JOIN selected_frames sf ON s.registration_session_id = sf.session_id
      WHERE 
        s.full_name LIKE ? OR
        s.student_id LIKE ? OR
        s.email LIKE ?
      GROUP BY s.id
      ORDER BY 
        CASE 
          WHEN s.full_name LIKE ? THEN 1
          WHEN s.student_id LIKE ? THEN 2
          ELSE 3
        END,
        s.full_name ASC
      LIMIT ?
    ''', [searchTerm, searchTerm, searchTerm, '$query%', '$query%', limit]);

    return results.map((map) => StudentListItem.fromMap(map)).toList();
  }

  @override
  Future<List<StudentListItem>> filterStudents({
    required StudentFilter filter,
    int limit = 20,
    int offset = 0,
    StudentSortOption? sortBy,
  }) async {
    final sortClause = sortBy?.sqlOrderBy ?? 'name ASC';
    
    // Build WHERE clause based on active filters
    final whereClauses = <String>[];
    final args = <dynamic>[];

    if (filter.statuses != null && filter.statuses!.isNotEmpty) {
      final placeholders = filter.statuses!.map((_) => '?').join(',');
      whereClauses.add('s.status IN ($placeholders)');
      args.addAll(filter.statuses!.map((s) => s.name));
    }

    if (filter.department != null && filter.department!.isNotEmpty) {
      whereClauses.add('s.department = ?');
      args.add(filter.department);
    }

    if (filter.startDate != null) {
      whereClauses.add('s.created_at >= ?');
      args.add(filter.startDate!.toIso8601String());
    }

    if (filter.endDate != null) {
      whereClauses.add('s.created_at <= ?');
      args.add(filter.endDate!.toIso8601String());
    }

    if (filter.minFrameCount != null) {
      whereClauses.add('frame_count >= ?');
      args.add(filter.minFrameCount);
    }

    final whereClause = whereClauses.isEmpty 
        ? '' 
        : 'WHERE ${whereClauses.join(' AND ')}';

    // Add pagination args
    args.addAll([limit, offset]);

    final results = await _dataSource.rawQuery('''
      SELECT 
        s.id,
        s.student_id,
        s.full_name,
        s.email,
        s.department,
        s.status,
        s.created_at,
        s.sync_status,
        COUNT(DISTINCT sf.id) as frame_count
      FROM students s
      LEFT JOIN selected_frames sf ON s.registration_session_id = sf.session_id
      $whereClause
      GROUP BY s.id
      HAVING 1=1 ${whereClauses.where((c) => c.contains('frame_count')).join(' AND ')}
      ORDER BY $sortClause
      LIMIT ? OFFSET ?
    ''', args);

    return results.map((map) => StudentListItem.fromMap(map)).toList();
  }

  @override
  Future<StudentDetail?> getStudentDetail(String studentId) async {
    print('🔍 [getStudentDetail] Fetching student with ID: $studentId');
    
    // Get student data
    final studentResults = await _dataSource.rawQuery('''
      SELECT * FROM students WHERE id = ? LIMIT 1
    ''', [studentId]);

    print('📊 [getStudentDetail] Query returned ${studentResults.length} results');
    
    if (studentResults.isEmpty) {
      print('⚠️ [getStudentDetail] No student found with ID: $studentId');
      return null;
    }

    print('📦 [getStudentDetail] Raw student data: ${studentResults.first}');
    print('🔑 [getStudentDetail] Available keys: ${studentResults.first.keys.toList()}');
    
    try {
      final student = Student.fromJson(studentResults.first);
      print('✅ [getStudentDetail] Successfully parsed student: ${student.fullName}');
      print('🔗 [getStudentDetail] Registration session ID: ${student.registrationSessionId}');

      // Get all frames for this student (session_id matches registration_session_id)
      final frameResults = student.registrationSessionId != null
          ? await _dataSource.rawQuery('''
              SELECT * FROM selected_frames 
              WHERE session_id = ?
              ORDER BY extracted_at
            ''', [student.registrationSessionId!])
          : <Map<String, dynamic>>[];

      print('🖼️ [getStudentDetail] Found ${frameResults.length} frames for student');

      final frames = frameResults
          .map((map) => SelectedFrame.fromJson(map))
          .toList();

      return StudentDetail.fromStudentAndFrames(student: student, frames: frames);
    } catch (e, stackTrace) {
      print('❌ [getStudentDetail] Error parsing student data: $e');
      print('📍 [getStudentDetail] Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<List<SelectedFrame>> getStudentFrames(String studentId) async {
    // First get the student's registration_session_id
    final studentResults = await _dataSource.rawQuery('''
      SELECT registration_session_id FROM students WHERE id = ? LIMIT 1
    ''', [studentId]);

    if (studentResults.isEmpty) {
      return [];
    }

    final sessionId = studentResults.first['registration_session_id'] as String?;
    
    // If no session ID, return empty list
    if (sessionId == null) {
      return [];
    }

    final results = await _dataSource.rawQuery('''
      SELECT * FROM selected_frames 
      WHERE session_id = ?
      ORDER BY extracted_at
    ''', [sessionId]);

    return results.map((map) => SelectedFrame.fromJson(map)).toList();
  }

  @override
  Future<int> getTotalStudentCount() async {
    final results = await _dataSource.rawQuery('''
      SELECT COUNT(*) as count FROM students
    ''');

    return results.first['count'] as int;
  }

  @override
  Future<Map<String, int>> getStudentCountByStatus() async {
    final results = await _dataSource.rawQuery('''
      SELECT status, COUNT(*) as count 
      FROM students 
      GROUP BY status
    ''');

    return {
      for (var row in results)
        row['status'] as String: row['count'] as int,
    };
  }
}
