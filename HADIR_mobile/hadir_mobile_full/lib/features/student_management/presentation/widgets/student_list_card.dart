import 'package:flutter/material.dart';
import '../../data/models/student_list_item.dart';
import '../../../../shared/domain/entities/student.dart';

/// Card widget for displaying student in list
class StudentListCard extends StatelessWidget {
  final StudentListItem student;
  final VoidCallback onTap;

  const StudentListCard({
    super.key,
    required this.student,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: _getStatusColor(student.status).withOpacity(0.2),
                child: Text(
                  _getInitials(student.fullName),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(student.status),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Student info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${student.studentId}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (student.department != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        student.department!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Status and frame count
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatusChip(student.status),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${student.frameCount}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  Widget _buildStatusChip(StudentStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusLabel(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _getStatusColor(status),
        ),
      ),
    );
  }

  Color _getStatusColor(StudentStatus status) {
    switch (status) {
      case StudentStatus.registered:
        return Colors.green;
      case StudentStatus.pending:
        return Colors.orange;
      case StudentStatus.incomplete:
        return Colors.red;
      case StudentStatus.archived:
        return Colors.grey;
    }
  }

  String _getStatusLabel(StudentStatus status) {
    switch (status) {
      case StudentStatus.registered:
        return 'Registered';
      case StudentStatus.pending:
        return 'Pending';
      case StudentStatus.incomplete:
        return 'Incomplete';
      case StudentStatus.archived:
        return 'Archived';
    }
  }
}
