import 'package:hadir_mobile_full/features/student_management/data/models/student_filter.dart';
import 'package:hadir_mobile_full/features/student_management/data/models/student_sort_option.dart';
import 'package:hadir_mobile_full/features/student_management/data/models/student_list_item.dart';
import 'package:hadir_mobile_full/features/student_management/data/models/student_detail.dart';
import 'package:hadir_mobile_full/shared/domain/entities/selected_frame.dart';

/// Repository interface for student management operations
/// 
/// Defines contracts for accessing and managing student data
abstract class StudentManagementRepository {
  /// Get all students with pagination and optional sorting
  Future<List<StudentListItem>> getAllStudents({
    int limit = 20,
    int offset = 0,
    StudentSortOption? sortBy,
  });

  /// Search students by query (name, student ID, or email)
  Future<List<StudentListItem>> searchStudents({
    required String query,
    int limit = 20,
  });

  /// Filter students by multiple criteria
  Future<List<StudentListItem>> filterStudents({
    required StudentFilter filter,
    int limit = 20,
    int offset = 0,
    StudentSortOption? sortBy,
  });

  /// Get complete student details including frames
  Future<StudentDetail?> getStudentDetail(String studentId);

  /// Get all frames for a specific student
  Future<List<SelectedFrame>> getStudentFrames(String studentId);

  /// Get total count of students (for statistics)
  Future<int> getTotalStudentCount();

  /// Get count of students by status
  Future<Map<String, int>> getStudentCountByStatus();
}
