import '../../../../shared/domain/entities/student.dart';
import '../../../../shared/domain/entities/selected_frame.dart';

/// Complete student model with frames for detail view
class StudentDetail {
  final String id;
  final String studentId;
  final String fullName;
  final String? email;
  final String? department;
  final String? program;
  final DateTime? dateOfBirth;
  final String? nationality;
  final String? phoneNumber;
  final StudentStatus status;
  final DateTime createdAt;
  final DateTime? lastUpdatedAt;
  final List<SelectedFrame> frames;

  const StudentDetail({
    required this.id,
    required this.studentId,
    required this.fullName,
    this.email,
    this.department,
    this.program,
    this.dateOfBirth,
    this.nationality,
    this.phoneNumber,
    required this.status,
    required this.createdAt,
    this.lastUpdatedAt,
    this.frames = const [],
  });

  /// Create from Student entity and frames
  factory StudentDetail.fromStudentAndFrames({
    required Student student,
    required List<SelectedFrame> frames,
  }) {
    return StudentDetail(
      id: student.id,
      studentId: student.studentId,
      fullName: student.fullName,
      email: student.email,
      department: student.department,
      program: student.program,
      dateOfBirth: student.dateOfBirth,
      nationality: student.nationality,
      phoneNumber: student.phoneNumber,
      status: student.status,
      createdAt: student.createdAt,
      lastUpdatedAt: student.lastUpdatedAt,
      frames: frames,
    );
  }

  /// Get frame count
  int get frameCount => frames.length;

  /// Get frames by pose type
  List<SelectedFrame> getFramesByPose(String poseType) {
    return frames.where((f) => f.poseType == poseType).toList();
  }

  /// Check if student has all required poses
  bool get hasAllPoses {
    final poses = frames.map((f) => f.poseType).toSet();
    return poses.length >= 5; // Expecting 5 different poses
  }
}
