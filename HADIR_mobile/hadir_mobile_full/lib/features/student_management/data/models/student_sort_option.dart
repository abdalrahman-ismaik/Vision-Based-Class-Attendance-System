/// Sort options for student list
enum StudentSortOption {
  nameAsc('Name (A-Z)'),
  nameDesc('Name (Z-A)'),
  studentIdAsc('Student ID (Ascending)'),
  studentIdDesc('Student ID (Descending)'),
  dateNewest('Date (Newest First)'),
  dateOldest('Date (Oldest First)'),
  departmentAsc('Department (A-Z)');

  final String label;
  const StudentSortOption(this.label);

  /// Get SQL ORDER BY clause for this sort option
  String get sqlOrderBy {
    switch (this) {
      case StudentSortOption.nameAsc:
        return 'full_name ASC';
      case StudentSortOption.nameDesc:
        return 'full_name DESC';
      case StudentSortOption.studentIdAsc:
        return 'student_id ASC';
      case StudentSortOption.studentIdDesc:
        return 'student_id DESC';
      case StudentSortOption.dateNewest:
        return 'created_at DESC';
      case StudentSortOption.dateOldest:
        return 'created_at ASC';
      case StudentSortOption.departmentAsc:
        return 'department ASC';
    }
  }
}
