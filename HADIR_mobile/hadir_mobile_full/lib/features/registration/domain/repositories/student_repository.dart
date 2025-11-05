import 'package:hadir_mobile_full/shared/domain/entities/student.dart';

/// Abstract repository interface for student data operations
abstract class StudentRepository {
  /// Create a new student record
  /// 
  /// Throws [StudentAlreadyExistsException] if student with same ID or email exists
  /// Throws [ValidationException] if student data is invalid
  /// Throws [DatabaseException] if database operation fails
  Future<Student> create(Student student);

  /// Get a student by their unique ID
  /// 
  /// Returns null if student is not found
  /// Throws [DatabaseException] if database operation fails
  Future<Student?> getById(String id);

  /// Get a student by their email address
  /// 
  /// Returns null if student is not found
  /// Throws [DatabaseException] if database operation fails
  Future<Student?> getByEmail(String email);

  /// Update an existing student record
  /// 
  /// Throws [EntityNotFoundException] if student is not found
  /// Throws [ValidationException] if student data is invalid
  /// Throws [DatabaseException] if database operation fails
  Future<Student> update(Student student);

  /// Delete a student by their ID
  /// 
  /// Throws [EntityNotFoundException] if student is not found
  /// Throws [DatabaseException] if database operation fails
  Future<void> delete(String id);

  /// Get all students with optional filtering and pagination
  /// 
  /// [limit] - Maximum number of students to return (default: 50)
  /// [offset] - Number of students to skip (default: 0)
  /// [status] - Filter by student status (optional)
  /// [major] - Filter by major (optional)
  /// [enrollmentYear] - Filter by enrollment year (optional)
  /// [searchQuery] - Search in name or email (optional)
  /// 
  /// Returns a list of students matching the criteria
  /// Throws [DatabaseException] if database operation fails
  Future<List<Student>> getAll({
    int limit = 50,
    int offset = 0,
    StudentStatus? status,
    String? major,
    int? enrollmentYear,
    String? searchQuery,
  });

  /// Get the total count of students with optional filtering
  /// 
  /// [status] - Filter by student status (optional)
  /// [major] - Filter by major (optional)
  /// [enrollmentYear] - Filter by enrollment year (optional)
  /// [searchQuery] - Search in name or email (optional)
  /// 
  /// Returns the total number of students matching the criteria
  /// Throws [DatabaseException] if database operation fails
  Future<int> getCount({
    StudentStatus? status,
    String? major,
    int? enrollmentYear,
    String? searchQuery,
  });

  /// Check if a student exists by ID
  /// 
  /// Returns true if student exists, false otherwise
  /// Throws [DatabaseException] if database operation fails
  Future<bool> exists(String id);

  /// Check if a student exists by email
  /// 
  /// Returns true if student with email exists, false otherwise
  /// Throws [DatabaseException] if database operation fails
  Future<bool> existsByEmail(String email);

  /// Check if a student exists by student ID
  /// 
  /// Returns true if student with student_id exists, false otherwise
  /// Throws [DatabaseException] if database operation fails
  Future<bool> existsByStudentId(String studentId);

  /// Get students by their status
  /// 
  /// [status] - The status to filter by
  /// [limit] - Maximum number of students to return (default: 50)
  /// [offset] - Number of students to skip (default: 0)
  /// 
  /// Returns a list of students with the specified status
  /// Throws [DatabaseException] if database operation fails
  Future<List<Student>> getByStatus(
    StudentStatus status, {
    int limit = 50,
    int offset = 0,
  });

  /// Get students by their major
  /// 
  /// [major] - The major to filter by
  /// [limit] - Maximum number of students to return (default: 50)
  /// [offset] - Number of students to skip (default: 0)
  /// 
  /// Returns a list of students with the specified major
  /// Throws [DatabaseException] if database operation fails
  Future<List<Student>> getByMajor(
    String major, {
    int limit = 50,
    int offset = 0,
  });

  /// Get students by enrollment year
  /// 
  /// [year] - The enrollment year to filter by
  /// [limit] - Maximum number of students to return (default: 50)
  /// [offset] - Number of students to skip (default: 0)
  /// 
  /// Returns a list of students enrolled in the specified year
  /// Throws [DatabaseException] if database operation fails
  Future<List<Student>> getByEnrollmentYear(
    int year, {
    int limit = 50,
    int offset = 0,
  });

  /// Search students by name or email
  /// 
  /// [query] - The search query (searches in firstName, lastName, and email)
  /// [limit] - Maximum number of students to return (default: 50)
  /// [offset] - Number of students to skip (default: 0)
  /// 
  /// Returns a list of students matching the search query
  /// Throws [DatabaseException] if database operation fails
  Future<List<Student>> search(
    String query, {
    int limit = 50,
    int offset = 0,
  });

  /// Get students with face embeddings (registered for face recognition)
  /// 
  /// [limit] - Maximum number of students to return (default: 50)
  /// [offset] - Number of students to skip (default: 0)
  /// 
  /// Returns a list of students that have face embeddings
  /// Throws [DatabaseException] if database operation fails
  Future<List<Student>> getStudentsWithFaceEmbeddings({
    int limit = 50,
    int offset = 0,
  });

  /// Update student's face embeddings
  /// 
  /// [studentId] - ID of the student to update
  /// [faceEmbeddings] - List of face embeddings to add
  /// 
  /// Throws [EntityNotFoundException] if student is not found
  /// Throws [ValidationException] if face embeddings data is invalid
  /// Throws [DatabaseException] if database operation fails
  Future<Student> updateFaceEmbeddings(
    String studentId,
    List<List<double>> faceEmbeddings,
  );

  /// Update student's status
  /// 
  /// [studentId] - ID of the student to update
  /// [status] - New status for the student
  /// 
  /// Throws [EntityNotFoundException] if student is not found
  /// Throws [DatabaseException] if database operation fails
  Future<Student> updateStatus(String studentId, StudentStatus status);

  /// Get students created within a date range
  /// 
  /// [startDate] - Start of the date range (inclusive)
  /// [endDate] - End of the date range (inclusive)
  /// [limit] - Maximum number of students to return (default: 50)
  /// [offset] - Number of students to skip (default: 0)
  /// 
  /// Returns a list of students created within the date range
  /// Throws [DatabaseException] if database operation fails
  Future<List<Student>> getByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int limit = 50,
    int offset = 0,
  });

  /// Get students grouped by their major
  /// 
  /// Returns a map where keys are majors and values are student counts
  /// Throws [DatabaseException] if database operation fails
  Future<Map<String, int>> getStudentCountByMajor();

  /// Get students grouped by their status
  /// 
  /// Returns a map where keys are status values and values are student counts
  /// Throws [DatabaseException] if database operation fails
  Future<Map<StudentStatus, int>> getStudentCountByStatus();

  /// Get students grouped by enrollment year
  /// 
  /// Returns a map where keys are enrollment years and values are student counts
  /// Throws [DatabaseException] if database operation fails
  Future<Map<int, int>> getStudentCountByEnrollmentYear();

  /// Bulk update student status
  /// 
  /// [studentIds] - List of student IDs to update
  /// [status] - New status for all specified students
  /// 
  /// Returns the number of students successfully updated
  /// Throws [DatabaseException] if database operation fails
  Future<int> bulkUpdateStatus(List<String> studentIds, StudentStatus status);

  /// Bulk delete students
  /// 
  /// [studentIds] - List of student IDs to delete
  /// 
  /// Returns the number of students successfully deleted
  /// Throws [DatabaseException] if database operation fails
  Future<int> bulkDelete(List<String> studentIds);

  /// Archive old students (students who haven't updated in X days)
  /// 
  /// [daysThreshold] - Number of days after which to consider students old
  /// 
  /// Returns the number of students archived
  /// Throws [DatabaseException] if database operation fails
  Future<int> archiveOldStudents(int daysThreshold);
}