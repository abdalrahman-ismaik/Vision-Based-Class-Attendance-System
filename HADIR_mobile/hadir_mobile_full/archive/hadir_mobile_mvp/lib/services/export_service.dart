import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/registration_session.dart';
import '../utils/constants.dart';

// Simple export service for MVP
class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  /// Export registration session data to JSON file
  Future<String> exportRegistrationSession(RegistrationSession session) async {
    try {
      // Create export data structure
      final exportData = {
        'export_info': {
          'timestamp': DateTime.now().toIso8601String(),
          'version': '1.0.0-mvp',
          'app': AppConstants.appTitle,
        },
        'student': session.student.toJson(),
        'registration_session': {
          'id': session.id,
          'video_path': session.videoPath,
          'selected_frames': session.selectedFramePaths,
          'created_at': session.createdAt.toIso8601String(),
          'status': session.status,
        },
        'metadata': {
          'frame_count': session.selectedFramePaths.length,
          'processing_method': 'basic_mvp',
          'quality_threshold': AppConstants.minFaceConfidence,
        },
      };

      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Get export directory (Downloads folder)
      final exportDir = await _getExportDirectory();
      
      // Create filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'hadir_export_${session.student.id}_$timestamp.json';
      final filePath = path.join(exportDir.path, fileName);

      // Write file
      final file = File(filePath);
      await file.writeAsString(jsonString);

      // Also copy video and frame files to Downloads for easy access
      await _copyMediaFilesToDownloads(session, exportDir);

      return filePath;
    } catch (e) {
      throw Exception('Export failed: ${e.toString()}');
    }
  }

  /// Export multiple sessions (batch export)
  Future<String> exportMultipleSessions(List<RegistrationSession> sessions) async {
    try {
      final exportData = {
        'export_info': {
          'timestamp': DateTime.now().toIso8601String(),
          'version': '1.0.0-mvp',
          'app': AppConstants.appTitle,
          'session_count': sessions.length,
        },
        'sessions': sessions.map((session) => {
          'student': session.student.toJson(),
          'registration_session': {
            'id': session.id,
            'video_path': session.videoPath,
            'selected_frames': session.selectedFramePaths,
            'created_at': session.createdAt.toIso8601String(),
            'status': session.status,
          },
        }).toList(),
        'metadata': {
          'total_frames': sessions.fold(0, (sum, session) => sum + session.selectedFramePaths.length),
          'processing_method': 'basic_mvp',
          'quality_threshold': AppConstants.minFaceConfidence,
        },
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      final exportDir = await _getExportDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'hadir_batch_export_$timestamp.json';
      final filePath = path.join(exportDir.path, fileName);

      final file = File(filePath);
      await file.writeAsString(jsonString);

      return filePath;
    } catch (e) {
      throw Exception('Batch export failed: ${e.toString()}');
    }
  }

  /// Get the directory for export files
  Future<Directory> _getExportDirectory() async {
    // For MVP, use app documents directory
    // In production, you might want to use external storage with permissions
    Directory appDocDir;
    
    if (Platform.isAndroid) {
      // Try to use Downloads directory, fallback to app documents
      try {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (await downloadsDir.exists()) {
          appDocDir = downloadsDir;
        } else {
          // Fallback to app documents directory
          appDocDir = Directory('/data/data/edu.university.hadir.hadir_mobile_mvp/files');
        }
      } catch (e) {
        appDocDir = Directory('/data/data/edu.university.hadir.hadir_mobile_mvp/files');
      }
    } else {
      // iOS or other platforms - use app documents directory
      appDocDir = Directory('/var/mobile/Containers/Data/Application/Documents');
    }

    // Create HADIR export subdirectory
    final exportDir = Directory(path.join(appDocDir.path, 'hadir_exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    return exportDir;
  }

  /// Get list of exported files
  Future<List<File>> getExportedFiles() async {
    try {
      final exportDir = await _getExportDirectory();
      if (!await exportDir.exists()) {
        return [];
      }

      final files = exportDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();

      // Sort by modification date (newest first)
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      return files;
    } catch (e) {
      return [];
    }
  }

  /// Delete an exported file
  Future<void> deleteExportedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete file: ${e.toString()}');
    }
  }

  /// Get export directory path for display
  Future<String> getExportDirectoryPath() async {
    final exportDir = await _getExportDirectory();
    return exportDir.path;
  }

  /// Copy media files (video and frames) to Downloads folder for easy access
  Future<void> _copyMediaFilesToDownloads(RegistrationSession session, Directory exportDir) async {
    try {
      // Create a subfolder for this student's media files
      final studentFolder = Directory(path.join(exportDir.path, 'hadir_media_${session.student.id}'));
      if (!await studentFolder.exists()) {
        await studentFolder.create(recursive: true);
      }

      // Copy video file if it exists
      if (await File(session.videoPath).exists()) {
        final videoFile = File(session.videoPath);
        final videoFileName = path.basename(session.videoPath);
        final destinationVideoPath = path.join(studentFolder.path, videoFileName);
        await videoFile.copy(destinationVideoPath);
      }

      // Copy frame files if they exist
      for (final framePath in session.selectedFramePaths) {
        if (await File(framePath).exists()) {
          final frameFile = File(framePath);
          final frameFileName = path.basename(framePath);
          final destinationFramePath = path.join(studentFolder.path, frameFileName);
          await frameFile.copy(destinationFramePath);
        }
      }
    } catch (e) {
      // Don't fail the export if media copying fails, just log it
      print('Warning: Failed to copy media files to Downloads: $e');
    }
  }
}