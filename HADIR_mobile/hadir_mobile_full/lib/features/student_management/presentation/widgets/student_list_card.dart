import 'package:flutter/material.dart';
import '../../data/models/student_list_item.dart';
import '../../../../shared/domain/entities/student.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_spacing.dart';

/// Card widget for displaying student in list
class StudentListCard extends StatelessWidget {
  final StudentListItem student;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

  const StudentListCard({
    super.key,
    required this.student,
    required this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.circularMD,
        side: BorderSide(
          color: isSelected ? AppColors.primaryIndigo : AppColors.borderLight,
          width: isSelected ? 2 : 1,
        ),
      ),
      color: isSelected ? AppColors.primaryIndigo.withOpacity(0.05) : AppColors.backgroundWhite,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: AppRadius.circularMD,
        child: Padding(
          padding: AppSpacing.paddingMD,
          child: Row(
            children: [
              // Selection checkbox or Avatar
              if (isSelectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onTap(),
                )
              else
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
              
              // Status, sync status, and frame count
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatusChip(student.status),
                  const SizedBox(height: 8),
                  _buildSyncStatusIcon(student.syncStatus),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 16,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${student.frameCount}',
                        style: AppTextStyles.labelMedium,
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: AppRadius.circularMD,
      ),
      child: Text(
        _getStatusLabel(status),
        style: AppTextStyles.labelSmall.copyWith(
          color: _getStatusColor(status),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSyncStatusIcon(String syncStatus) {
    IconData icon;
    Color color;

    switch (syncStatus) {
      case 'synced':
        icon = Icons.cloud_done;
        color = AppColors.successGreen;
        break;
      case 'syncing':
        icon = Icons.cloud_sync;
        color = AppColors.secondaryBlue;
        break;
      case 'failed':
        icon = Icons.cloud_off;
        color = AppColors.warningRed;
        break;
      case 'not_synced':
      default:
        icon = Icons.cloud_upload_outlined;
        color = AppColors.textSubtle;
        break;
    }

    return Icon(
      icon,
      size: 18,
      color: color,
    );
  }

  Color _getStatusColor(StudentStatus status) {
    switch (status) {
      case StudentStatus.registered:
        return AppColors.successGreen;
      case StudentStatus.pending:
        return AppColors.warningAmber;
      case StudentStatus.incomplete:
        return AppColors.warningRed;
      case StudentStatus.archived:
        return AppColors.textSubtle;
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
