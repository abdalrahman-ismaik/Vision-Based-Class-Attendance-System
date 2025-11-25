import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hadir_mobile_full/core/providers/sync_provider.dart';
import 'package:hadir_mobile_full/core/models/sync_models.dart';
import 'package:hadir_mobile_full/shared/domain/entities/student.dart';

/// Quick test page for Day 2 sync functionality
/// 
/// This page allows you to:
/// 1. View all students in the database
/// 2. See their sync status
/// 3. Manually trigger sync for any student
/// 
/// To use:
/// 1. Make sure backend is running: `cd backend && python app.py`
/// 2. Run the app and navigate to this page
/// 3. Select a student and tap "Sync"
class SyncTestPage extends ConsumerStatefulWidget {
  const SyncTestPage({super.key});

  @override
  ConsumerState<SyncTestPage> createState() => _SyncTestPageState();
}

class _SyncTestPageState extends ConsumerState<SyncTestPage> {
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => isLoading = true);
    
    try {
      final database = ref.read(databaseProvider);
      final db = await database.database;
      
      final results = await db.rawQuery('''
        SELECT 
          s.*,
          COUNT(sf.id) as frame_count
        FROM students s
        LEFT JOIN registration_sessions rs ON s.registration_session_id = rs.id
        LEFT JOIN selected_frames sf ON rs.id = sf.session_id
        GROUP BY s.id
        ORDER BY s.created_at DESC
      ''');
      
      setState(() {
        students = results;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading students: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Day 2: Sync Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return _buildStudentCard(student);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No students registered yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text('Register a student first', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final studentId = student['student_id'] as String;
    final fullName = student['full_name'] as String;
    final syncStatus = SyncStatus.fromString(student['sync_status'] as String?);
    final backendId = student['backend_student_id'] as String?;
    final frameCount = student['frame_count'] as int? ?? 0;
    final syncError = student['sync_error'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: $studentId',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSyncStatusIcon(syncStatus),
              ],
            ),

            const SizedBox(height: 12),

            // Details
            _buildDetailRow('Frames', '$frameCount images'),
            _buildDetailRow('Sync Status', syncStatus.displayText),
            if (backendId != null) _buildDetailRow('Backend ID', backendId),
            if (syncError != null) _buildDetailRow('Error', syncError, isError: true),

            const SizedBox(height: 12),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (syncStatus == SyncStatus.notSynced || syncStatus == SyncStatus.failed)
                  ElevatedButton.icon(
                    onPressed: () => _handleSync(student),
                    icon: const Icon(Icons.cloud_upload, size: 18),
                    label: Text(syncStatus == SyncStatus.failed ? 'Retry Sync' : 'Sync Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: syncStatus == SyncStatus.failed ? Colors.orange : Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (syncStatus == SyncStatus.syncing)
                  const SizedBox(
                    width: 120,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                        ),
                        SizedBox(width: 8),
                        Text('Syncing...', style: TextStyle(color: Colors.blue)),
                      ],
                    ),
                  ),
                if (syncStatus == SyncStatus.synced)
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text('Synced', style: TextStyle(color: Colors.green)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isError ? Colors.red : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatusIcon(SyncStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case SyncStatus.notSynced:
        icon = Icons.cloud_upload_outlined;
        color = Colors.grey;
        break;
      case SyncStatus.syncing:
        icon = Icons.sync;
        color = Colors.blue;
        break;
      case SyncStatus.synced:
        icon = Icons.cloud_done;
        color = Colors.green;
        break;
      case SyncStatus.failed:
        icon = Icons.cloud_off;
        color = Colors.red;
        break;
    }

    return Icon(icon, color: color, size: 32);
  }

  Future<void> _handleSync(Map<String, dynamic> studentData) async {
    // Show loading dialog
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
                Text('Syncing to backend...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Get database
      final database = ref.read(databaseProvider);
      final db = await database.database;

      // Get all image paths
      final frames = await db.query(
        'selected_frames',
        columns: ['image_file_path'],
        where: 'session_id = ?',
        whereArgs: [studentData['registration_session_id']],
        orderBy: 'timestamp_ms ASC',
      );

      if (frames.isEmpty) {
        if (mounted) Navigator.of(context).pop();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ No images found for this student'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final imageFiles = frames
          .map((f) => File(f['image_file_path'] as String))
          .toList();

      // Validate all files exist
      for (var file in imageFiles) {
        if (!await file.exists()) {
          if (mounted) Navigator.of(context).pop();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Image file not found: ${file.path}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Create Student entity (simplified - only required fields)
      final student = Student(
        id: studentData['id'] as String,
        studentId: studentData['student_id'] as String,
        fullName: studentData['full_name'] as String,
        email: studentData['email'] as String? ?? '',
        dateOfBirth: DateTime.now(), // Placeholder
        department: studentData['department'] as String? ?? '',
        program: studentData['program'] as String? ?? '',
        status: StudentStatus.registered,
        createdAt: DateTime.parse(studentData['created_at'] as String),
        registrationSessionId: studentData['registration_session_id'] as String?,
      );

      // Perform sync
      final syncService = ref.read(syncServiceProvider);
      final result = await syncService.syncStudent(
        student: student,
        imageFiles: imageFiles,
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Reload students to see updated sync status
      await _loadStudents();

      // Show result
      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '✅ ${student.fullName} synced!\nBackend ID: ${result.backendStudentId}',
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
                    child: Text('❌ Sync failed: ${result.error}'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 7),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _handleSync(studentData),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
