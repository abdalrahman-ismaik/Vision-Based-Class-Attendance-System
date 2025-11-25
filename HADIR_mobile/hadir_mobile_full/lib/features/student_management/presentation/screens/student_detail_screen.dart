import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/student_detail_provider.dart';
import '../providers/student_list_provider.dart';
import '../widgets/frame_gallery_grid.dart';
import '../widgets/student_sync_button.dart';
import '../../../../shared/domain/entities/student.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_spacing.dart';

/// Screen for viewing detailed student information and frames
class StudentDetailScreen extends ConsumerWidget {
  final String studentId;

  const StudentDetailScreen({
    super.key,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentDetail = ref.watch(studentDetailProvider(studentId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        title: Text(
          'Student Details',
          style: AppTextStyles.headingLarge.copyWith(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Sync button will be shown when student is loaded
          studentDetail.maybeWhen(
            data: (detail) {
              if (detail != null) {
                // Create a Student entity from StudentDetail for sync button
                final student = Student(
                  id: detail.id,
                  studentId: detail.studentId,
                  fullName: detail.fullName,
                  email: detail.email ?? '',
                  dateOfBirth: detail.dateOfBirth ?? DateTime.now(),
                  department: detail.department ?? '',
                  program: detail.program ?? '',
                  status: detail.status,
                  createdAt: detail.createdAt,
                  lastUpdatedAt: detail.lastUpdatedAt,
                  registrationSessionId: detail.registrationSessionId, // Critical for finding images!
                );
                return StudentSyncButton(student: student);
              }
              return const SizedBox.shrink();
            },
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () => _confirmDelete(context, ref, studentId),
          ),
        ],
      ),
      body: studentDetail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Failed to load student details',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade700),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(studentDetailProvider(studentId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (detail) {
          if (detail == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Student not found',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student header
                _buildStudentHeader(context, detail),
                
                const Divider(height: 1),
                
                // Student information
                _buildStudentInfo(detail),
                
                const Divider(height: 32, thickness: 8),
                
                // Frames section
                _buildFramesSection(context, detail),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentHeader(BuildContext context, dynamic detail) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: _getStatusGradient(detail.status),
              shape: BoxShape.circle,
              boxShadow: AppElevation.shadowMD,
            ),
            child: Center(
              child: Text(
                _getInitials(detail.fullName),
                style: AppTextStyles.displaySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          
          // Name and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.fullName,
                  style: AppTextStyles.displaySmall.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${detail.studentId}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStatusChip(detail.status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfo(dynamic detail) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Information',
            style: AppTextStyles.headingLarge.copyWith(
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          
          if (detail.email != null)
            _buildInfoRow(Icons.email, 'Email', detail.email!),
          if (detail.department != null)
            _buildInfoRow(Icons.business, 'Department', detail.department!),
          if (detail.program != null)
            _buildInfoRow(Icons.school, 'Program', detail.program!),
          if (detail.phoneNumber != null)
            _buildInfoRow(Icons.phone, 'Phone', detail.phoneNumber!),
          if (detail.nationality != null)
            _buildInfoRow(Icons.flag, 'Nationality', detail.nationality!),
          
          _buildInfoRow(
            Icons.calendar_today,
            'Registered',
            _formatDate(detail.createdAt),
          ),
          _buildInfoRow(
            Icons.photo_library,
            'Total Frames',
            '${detail.frameCount}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: AppRadius.circularMD,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppRadius.circularSM,
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFramesSection(BuildContext context, dynamic detail) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Captured Frames',
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              if (detail.hasAllPoses)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Complete',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (detail.frames.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No frames captured yet',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else
            FrameGalleryGrid(
              studentId: studentId,
              frames: detail.frames,
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(StudentStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _getStatusLabel(status),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _getStatusColor(status),
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

  Gradient _getStatusGradient(StudentStatus status) {
    switch (status) {
      case StudentStatus.registered:
        return AppColors.successGradient;
      case StudentStatus.pending:
        return AppColors.warningGradient;
      default:
        return AppColors.primaryGradient;
    }
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String studentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: const Text('Are you sure you want to delete this student? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(studentListProvider.notifier).deleteStudent(studentId);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student deleted successfully')),
        );
        Navigator.pop(context);
      }
    }
  }
}
