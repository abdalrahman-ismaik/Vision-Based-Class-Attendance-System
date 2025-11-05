import '../../data/models/student_detail.dart';
import '../repositories/student_management_repository.dart';

/// Use case for retrieving complete student details with frames
class GetStudentDetails {
  final StudentManagementRepository repository;

  const GetStudentDetails(this.repository);

  Future<StudentDetail?> call(String studentId) async {
    if (studentId.trim().isEmpty) {
      return null;
    }

    return await repository.getStudentDetail(studentId);
  }
}
