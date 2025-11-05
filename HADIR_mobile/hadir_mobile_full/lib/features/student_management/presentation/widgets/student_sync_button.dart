import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/sync_provider.dart';
import '../../../../shared/domain/entities/student.dart';
import '../../../../core/models/sync_models.dart';

/// Sync button widget for individual student cards
/// Shows sync status and allows manual sync trigger
class StudentSyncButton extends ConsumerWidget {
  final Student student;

  const StudentSyncButton({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch sync status for this specific student
    final syncStatusAsync = ref.watch(syncStatusStreamProvider(student.id));
    
    return syncStatusAsync.when(
      data: (syncStatusString) {
        final syncStatus = SyncStatus.fromString(syncStatusString);
        return _buildButton(context, ref, syncStatus);
      },
      loading: () => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const Icon(Icons.error, size: 24, color: Colors.red),
    );
  }

  Widget _buildButton(BuildContext context, WidgetRef ref, SyncStatus syncStatus) {
    switch (syncStatus) {
      case SyncStatus.notSynced:
        return IconButton(
          icon: const Icon(Icons.cloud_upload_outlined, color: Colors.grey),
          tooltip: 'Sync to backend',
          onPressed: () => _handleSync(context, ref),
        );
      
      case SyncStatus.syncing:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      
      case SyncStatus.synced:
        return IconButton(
          icon: const Icon(Icons.cloud_done, color: Colors.green),
          tooltip: 'Synced successfully',
          onPressed: () => _showSyncInfo(context, 'Student synced successfully'),
        );
      
      case SyncStatus.failed:
        return IconButton(
          icon: const Icon(Icons.cloud_off, color: Colors.red),
          tooltip: 'Sync failed - tap to retry',
          onPressed: () => _handleSync(context, ref),
        );
    }
  }

  Future<void> _handleSync(BuildContext context, WidgetRef ref) async {
    // Get image path from database (query first selected frame)
    final database = ref.read(databaseProvider);
    final db = await database.database;
    
    // Query for first selected frame image path using registration_session_id from student
    final frames = await db.query(
      'selected_frames',
      columns: ['image_file_path'],
      where: 'session_id = ?',
      whereArgs: [student.registrationSessionId],
      orderBy: 'timestamp_ms ASC',
      limit: 1,
    );

    if (frames.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ No images available for this student'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final imagePath = frames.first['image_file_path'] as String;

    // Check if file exists
    final imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Image file not found: $imagePath'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Syncing student to backend...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      // Perform sync
      final syncService = ref.read(syncServiceProvider);
      final result = await syncService.syncStudent(
        student: student,
        imageFile: imageFile,
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show result
      if (context.mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '✅ ${student.fullName} synced successfully!\n'
                      'Backend ID: ${result.backendStudentId ?? 'N/A'}',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '❌ Sync failed: ${result.error ?? 'Unknown error'}',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 7),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _handleSync(context, ref),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Unexpected error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showSyncInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
