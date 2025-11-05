import '../../data/models/student_list_item.dart';
import '../../data/models/student_filter.dart';
import '../../data/models/student_sort_option.dart';
import '../repositories/student_management_repository.dart';

/// Use case for filtering students by multiple criteria
class FilterStudents {
  final StudentManagementRepository repository;

  const FilterStudents(this.repository);

  Future<List<StudentListItem>> call({
    required StudentFilter filter,
    int limit = 20,
    int offset = 0,
    StudentSortOption? sortBy,
  }) async {
    return await repository.filterStudents(
      filter: filter,
      limit: limit,
      offset: offset,
      sortBy: sortBy,
    );
  }
}
