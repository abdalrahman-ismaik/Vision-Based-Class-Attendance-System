import '../../data/models/student_list_item.dart';
import '../../data/models/student_sort_option.dart';
import '../repositories/student_management_repository.dart';

/// Use case for retrieving paginated list of all students
class GetAllStudents {
  final StudentManagementRepository repository;

  const GetAllStudents(this.repository);

  Future<List<StudentListItem>> call({
    int limit = 20,
    int offset = 0,
    StudentSortOption? sortBy,
  }) async {
    return await repository.getAllStudents(
      limit: limit,
      offset: offset,
      sortBy: sortBy,
    );
  }
}
