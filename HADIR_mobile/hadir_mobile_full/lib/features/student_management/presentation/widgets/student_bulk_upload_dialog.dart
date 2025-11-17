import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/sync_provider.dart';
import '../../../../shared/domain/entities/student.dart';
import '../../../../core/models/sync_models.dart';
import '../../data/models/student_list_item.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_spacing.dart';

/// Dialog for bulk uploading students to backend
/// Shows progress and results for each student
class StudentBulkUploadDialog extends ConsumerStatefulWidget {
  final List<StudentListItem> students;
  final List<Student> fullStudents;

  const StudentBulkUploadDialog({
    super.key,
    required this.students,
    required this.fullStudents,
  });

  @override
  ConsumerState<StudentBulkUploadDialog> createState() => _StudentBulkUploadDialogState();
}

class _StudentBulkUploadDialogState extends ConsumerState<StudentBulkUploadDialog> {
  final Map<String, SyncResult?> _results = {};
  bool _isUploading = false;
  int _currentIndex = 0;
  int _successCount = 0;
  int _failureCount = 0;

  @override
  void initState() {
    super.initState();
    // Initialize results map
    for (var student in widget.students) {
      _results[student.id] = null;
    }
    // Start upload automatically
    _startBulkUpload();
  }

  Future<void> _startBulkUpload() async {
    setState(() {
      _isUploading = true;
    });

    final database = ref.read(databaseProvider);
    final syncService = ref.read(syncServiceProvider);

    for (int i = 0; i < widget.students.length; i++) {
      if (!mounted) break;

      setState(() {
        _currentIndex = i;
      });

      final studentItem = widget.students[i];
      final fullStudent = widget.fullStudents.firstWhere(
        (s) => s.id == studentItem.id,
      );

      try {
        // Get image path from database
        final db = await database.database;
        final frames = await db.query(
          'selected_frames',
          columns: ['image_file_path'],
          where: 'session_id = ?',
          whereArgs: [fullStudent.registrationSessionId],
          orderBy: 'timestamp_ms ASC',
          limit: 1,
        );

        if (frames.isEmpty) {
          setState(() {
            _results[studentItem.id] = SyncResult.failed(
              error: 'No images available',
            );
            _failureCount++;
          });
          continue;
        }

        final imagePath = frames.first['image_file_path'] as String;
        final imageFile = File(imagePath);

        if (!await imageFile.exists()) {
          setState(() {
            _results[studentItem.id] = SyncResult.failed(
              error: 'Image file not found',
            );
            _failureCount++;
          });
          continue;
        }

        // Perform sync
        final result = await syncService.syncStudent(
          student: fullStudent,
          imageFile: imageFile,
        );

        setState(() {
          _results[studentItem.id] = result;
          if (result.success) {
            _successCount++;
          } else {
            _failureCount++;
          }
        });

        // Small delay between uploads to avoid overwhelming the server
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        setState(() {
          _results[studentItem.id] = SyncResult.failed(
            error: e.toString(),
          );
          _failureCount++;
        });
      }
    }

    setState(() {
      _isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isUploading,
      child: AlertDialog(
        title: const Text('Bulk Upload to Backend'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress summary
              if (_isUploading) ...[
                Text(
                  'Uploading ${_currentIndex + 1} of ${widget.students.length}...',
                  style: AppTextStyles.headingSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                LinearProgressIndicator(
                  value: (_currentIndex + 1) / widget.students.length,
                  backgroundColor: AppColors.backgroundGray,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryIndigo),
                ),
                const SizedBox(height: AppSpacing.md),
              ] else ...[
                Text(
                  'Upload Complete',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: _failureCount == 0 ? AppColors.successGreen : AppColors.warningAmber,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.successGreen, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Text('$_successCount successful', style: AppTextStyles.bodyMedium),
                    const SizedBox(width: AppSpacing.md),
                    Icon(Icons.error, color: AppColors.warningRed, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Text('$_failureCount failed', style: AppTextStyles.bodyMedium),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Student list with results
              Text(
                'Students:',
                style: AppTextStyles.labelLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.students.length,
                  itemBuilder: (context, index) {
                    final student = widget.students[index];
                    final result = _results[student.id];
                    final isProcessing = _isUploading && index == _currentIndex;

                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: _buildStatusIcon(result, isProcessing),
                      title: Text(
                        student.fullName,
                        style: AppTextStyles.bodyMedium,
                      ),
                      subtitle: Text(
                        student.studentId,
                        style: AppTextStyles.labelSmall,
                      ),
                      trailing: result != null && !result.success
                          ? IconButton(
                              icon: const Icon(Icons.info_outline, size: 18),
                              onPressed: () => _showErrorDetails(context, student, result),
                              tooltip: 'Error details',
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (!_isUploading)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(SyncResult? result, bool isProcessing) {
    if (isProcessing) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryIndigo),
        ),
      );
    }

    if (result == null) {
      return Icon(Icons.pending, color: AppColors.textSubtle, size: 20);
    }

    if (result.success) {
      return Icon(Icons.check_circle, color: AppColors.successGreen, size: 20);
    }

    return Icon(Icons.error, color: AppColors.warningRed, size: 20);
  }

  void _showErrorDetails(BuildContext context, StudentListItem student, SyncResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.circularLG,
        ),
        title: Text(
          'Error: ${student.fullName}',
          style: AppTextStyles.headingMedium,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student ID: ${student.studentId}',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Error:',
              style: AppTextStyles.labelLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: AppSpacing.paddingSM,
              decoration: BoxDecoration(
                color: AppColors.warningRed.withOpacity(0.1),
                borderRadius: AppRadius.circularMD,
              ),
              child: Text(
                result.error ?? 'Unknown error',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.warningRed,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryIndigo,
            ),
            child: Text(
              'OK',
              style: AppTextStyles.button.copyWith(
                color: AppColors.primaryIndigo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
