import '../../../../shared/domain/entities/selected_frame.dart';
import '../repositories/student_management_repository.dart';

/// Use case for retrieving all frames for a student
class GetStudentFrames {
  final StudentManagementRepository repository;

  const GetStudentFrames(this.repository);

  Future<List<SelectedFrame>> call(String studentId) async {
    if (studentId.trim().isEmpty) {
      return [];
    }

    return await repository.getStudentFrames(studentId);
  }
}
