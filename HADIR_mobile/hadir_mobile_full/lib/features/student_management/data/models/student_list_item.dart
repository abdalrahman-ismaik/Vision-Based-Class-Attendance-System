import '../../../../shared/domain/entities/student.dart';

/// Lightweight model for displaying students in a list
class StudentListItem {
  final String id;
  final String studentId;
  final String fullName;
  final String? department;
  final StudentStatus status;
  final int frameCount;
  final DateTime createdAt;
  final String syncStatus;

  const StudentListItem({
    required this.id,
    required this.studentId,
    required this.fullName,
    this.department,
    required this.status,
    required this.frameCount,
    required this.createdAt,
    this.syncStatus = 'not_synced',
  });

  /// Create from database map
  factory StudentListItem.fromMap(Map<String, dynamic> map) {
    return StudentListItem(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      fullName: map['full_name'] as String,
      department: map['department'] as String?,
      status: StudentStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => StudentStatus.pending,
      ),
      frameCount: map['frame_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      syncStatus: map['sync_status'] as String? ?? 'not_synced',
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'full_name': fullName,
      'department': department,
      'status': status.name,
      'frame_count': frameCount,
      'created_at': createdAt.toIso8601String(),
      'sync_status': syncStatus,
    };
  }
  
  /// Check if student is synced to backend
  bool get isSynced => syncStatus == 'synced';
  
  /// Check if student needs syncing
  bool get needsSync => syncStatus == 'not_synced' || syncStatus == 'failed';
}
