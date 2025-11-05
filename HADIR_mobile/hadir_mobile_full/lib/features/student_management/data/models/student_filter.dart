import '../../../../shared/domain/entities/student.dart';

/// Filter criteria for student queries
class StudentFilter {
  final List<StudentStatus>? statuses;
  final String? department;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? minFrameCount;

  const StudentFilter({
    this.statuses,
    this.department,
    this.startDate,
    this.endDate,
    this.minFrameCount,
  });

  /// Check if any filters are active
  bool get hasActiveFilters =>
      statuses != null ||
      department != null ||
      startDate != null ||
      endDate != null ||
      minFrameCount != null;

  /// Count of active filters
  int get activeFilterCount {
    int count = 0;
    if (statuses != null && statuses!.isNotEmpty) count++;
    if (department != null) count++;
    if (startDate != null || endDate != null) count++;
    if (minFrameCount != null && minFrameCount! > 0) count++;
    return count;
  }

  /// Create a copy with updated fields
  StudentFilter copyWith({
    List<StudentStatus>? statuses,
    String? department,
    DateTime? startDate,
    DateTime? endDate,
    int? minFrameCount,
  }) {
    return StudentFilter(
      statuses: statuses ?? this.statuses,
      department: department ?? this.department,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minFrameCount: minFrameCount ?? this.minFrameCount,
    );
  }

  /// Clear all filters
  StudentFilter clear() {
    return const StudentFilter();
  }
}
