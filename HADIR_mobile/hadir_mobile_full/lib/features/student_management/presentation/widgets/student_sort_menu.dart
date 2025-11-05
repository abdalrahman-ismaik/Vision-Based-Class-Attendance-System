import 'package:flutter/material.dart';
import '../../data/models/student_sort_option.dart';

/// Sort menu widget for student list
class StudentSortMenu extends StatelessWidget {
  final StudentSortOption currentSort;
  final ValueChanged<StudentSortOption> onSortChanged;

  const StudentSortMenu({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<StudentSortOption>(
      icon: const Icon(Icons.sort),
      tooltip: 'Sort students',
      onSelected: onSortChanged,
      itemBuilder: (context) => [
        _buildMenuItem(
          StudentSortOption.nameAsc,
          'Name (A-Z)',
          Icons.sort_by_alpha,
        ),
        _buildMenuItem(
          StudentSortOption.nameDesc,
          'Name (Z-A)',
          Icons.sort_by_alpha,
        ),
        const PopupMenuDivider(),
        _buildMenuItem(
          StudentSortOption.studentIdAsc,
          'ID (Ascending)',
          Icons.numbers,
        ),
        _buildMenuItem(
          StudentSortOption.studentIdDesc,
          'ID (Descending)',
          Icons.numbers,
        ),
        const PopupMenuDivider(),
        _buildMenuItem(
          StudentSortOption.dateNewest,
          'Recently Added',
          Icons.access_time,
        ),
        _buildMenuItem(
          StudentSortOption.dateOldest,
          'Oldest First',
          Icons.access_time,
        ),
        const PopupMenuDivider(),
        _buildMenuItem(
          StudentSortOption.departmentAsc,
          'Department (A-Z)',
          Icons.business,
        ),
      ],
    );
  }

  PopupMenuItem<StudentSortOption> _buildMenuItem(
    StudentSortOption option,
    String label,
    IconData icon,
  ) {
    final isSelected = currentSort == option;
    return PopupMenuItem<StudentSortOption>(
      value: option,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.blue : Colors.grey.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue : null,
                fontWeight: isSelected ? FontWeight.w600 : null,
              ),
            ),
          ),
          if (isSelected)
            const Icon(Icons.check, size: 20, color: Colors.blue),
        ],
      ),
    );
  }
}
