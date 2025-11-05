import '../../data/models/student_list_item.dart';
import '../repositories/student_management_repository.dart';

/// Use case for searching students by name, ID, or email
class SearchStudents {
  final StudentManagementRepository repository;

  const SearchStudents(this.repository);

  Future<List<StudentListItem>> call({
    required String query,
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    return await repository.searchStudents(
      query: query.trim(),
      limit: limit,
    );
  }
}
