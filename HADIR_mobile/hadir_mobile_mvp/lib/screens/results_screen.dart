import 'package:flutter/material.dart';
import 'dart:io';
import '../models/student.dart';
import '../models/registration_session.dart';
import '../services/database_service.dart';
import '../services/export_service.dart';
import '../services/frame_selection_service.dart';
import '../utils/constants.dart';
import 'student_input_screen.dart';

class ResultsScreen extends StatefulWidget {
  final Student student;
  final String videoPath;

  const ResultsScreen({
    super.key,
    required this.student,
    required this.videoPath,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final ExportService _exportService = ExportService();
  final FrameSelectionService _frameSelectionService = FrameSelectionService();
  RegistrationSession? _session;
  bool _isProcessing = true;
  bool _isExporting = false;
  String? _exportMessage;

  @override
  void initState() {
    super.initState();
    _processRegistration();
  }

  Future<void> _processRegistration() async {
    try {
      // For MVP, simulate frame processing
      await Future.delayed(const Duration(seconds: 1));

      // Use frame selection service to get optimal frames
      final selectedFrames = await _frameSelectionService.selectOptimalFrames(widget.videoPath);

      // Create registration session
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final session = RegistrationSession(
        id: sessionId,
        student: widget.student,
        videoPath: widget.videoPath,
        selectedFramePaths: selectedFrames,
        status: 'completed',
      );

      // Save to database
      await _databaseService.insertRegistrationSession(session);

      setState(() {
        _session = session;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Processing failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportData() async {
    if (_session == null) return;

    setState(() {
      _isExporting = true;
      _exportMessage = null;
    });

    try {
      final exportPath = await _exportService.exportRegistrationSession(_session!);
      
      setState(() {
        _isExporting = false;
        _exportMessage = 'Data exported successfully to:\n$exportPath\n\n📁 Video and images also copied to:\nDownloads/hadir_media_${_session!.student.id}/';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export completed: $exportPath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
        _exportMessage = 'Export failed: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startNewRegistration() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const StudentInputScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Results'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isProcessing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing registration...'),
            SizedBox(height: 8),
            Text('Extracting optimal frames from video'),
          ],
        ),
      );
    }

    if (_session == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Processing failed'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _startNewRegistration,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Success header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle, 
                     size: 48, 
                     color: Colors.green.shade700),
                const SizedBox(height: 8),
                Text(
                  'Registration Completed Successfully!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Student details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Student ID:', _session!.student.id),
                  _buildDetailRow('Name:', _session!.student.name),
                  _buildDetailRow('Email:', _session!.student.email),
                  _buildDetailRow('Registration Time:', 
                    '${_session!.createdAt.day}/${_session!.createdAt.month}/${_session!.createdAt.year} '
                    '${_session!.createdAt.hour}:${_session!.createdAt.minute.toString().padLeft(2, '0')}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Processing results
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Processing Results',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Video File:', File(_session!.videoPath).uri.pathSegments.last),
                  _buildDetailRow('Selected Frames:', '${_session!.selectedFramePaths.length}'),
                  _buildDetailRow('Status:', _session!.status.toUpperCase()),
                  _buildDetailRow('Session ID:', _session!.id),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Export section
          if (_exportMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _exportMessage!.contains('successfully') 
                    ? Colors.green.shade50 
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(
                  color: _exportMessage!.contains('successfully') 
                      ? Colors.green.shade200 
                      : Colors.red.shade200,
                ),
              ),
              child: Text(
                _exportMessage!,
                style: TextStyle(
                  color: _exportMessage!.contains('successfully') 
                      ? Colors.green.shade700 
                      : Colors.red.shade700,
                ),
              ),
            ),
          if (_exportMessage != null) const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isExporting ? null : _exportData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isExporting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.download),
                            SizedBox(width: 8),
                            Text('Export Data'),
                          ],
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _startNewRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add),
                      SizedBox(width: 8),
                      Text('New Student'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}