import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:hadir_mobile_full/core/config/sync_config.dart';
import 'package:hadir_mobile_full/core/models/sync_models.dart';
import 'package:hadir_mobile_full/shared/data/data_sources/local_database_data_source.dart';
import 'package:hadir_mobile_full/shared/domain/entities/student.dart';
import 'package:hadir_mobile_full/core/services/backend_config_service.dart';

/// Service for synchronizing student data from mobile to backend
/// 
/// Handles:
/// - Uploading student data and face images to backend
/// - Tracking sync status in local database
/// - Polling backend for processing status
/// - Error handling and retry logic (Day 4)
/// - Batch sync operations (Day 5)
class SyncService {
  final Dio _dio;
  final LocalDatabaseDataSource _database;
  
  SyncService({
    required Dio dio,
    required LocalDatabaseDataSource database,
  })  : _dio = dio,
        _database = database;

  // ========================================================================
  // Public Methods
  // ========================================================================

  /// Sync a single student to the backend
  /// 
  /// This method:
  /// 1. Validates student data and image files
  /// 2. Updates local database (status = 'syncing')
  /// 3. Builds multipart form data
  /// 4. POSTs to /api/students/ endpoint
  /// 5. Updates local database with result
  /// 
  /// Returns [SyncResult] with success/failure status
  Future<SyncResult> syncStudent({
    required Student student,
    required List<File> imageFiles,
  }) async {
    final startTime = DateTime.now();
    
    // Update base URL from config service
    try {
      final currentUrl = BackendConfigService.instance.backendUrl;
      if (_dio.options.baseUrl != currentUrl) {
        _dio.options.baseUrl = currentUrl;
      }
    } catch (_) {
      // Ignore if config service not initialized
    }

    try {
      _log('[SYNC] =====================================');
      _log('[SYNC] Starting sync for student: ${student.studentId}');
      _log('[SYNC] Student ID: ${student.id}');
      _log('[SYNC] Student Name: ${student.fullName}');
      _log('[SYNC] Backend URL: ${_dio.options.baseUrl}');
      _log('[SYNC] Connection timeout: ${SyncConfig.connectionTimeout}');
      _log('[SYNC] Receive timeout: ${SyncConfig.receiveTimeout}');
      _log('[SYNC] =====================================');
      
      // Step 1: Validate inputs
      _log('[SYNC] Step 1: Validating inputs...');
      await _validateSyncInputs(student, imageFiles);
      _log('[SYNC] ✅ Step 1 complete: Validation passed');
      
      // Step 2: Update local database - syncing
      _log('[SYNC] Step 2: Updating local database status to "syncing"...');
      await _updateLocalSyncStatus(
        student.id,
        SyncStatus.syncing,
        null,
        null,
      );
      _log('[SYNC] ✅ Step 2 complete: Database updated');
      
      // Step 3: Build request
      _log('[SYNC] Step 3: Building request FormData...');
      final formData = await _buildSyncRequest(student, imageFiles);
      _log('[SYNC] ✅ Step 3 complete: FormData ready');
      
      // Step 4: Send to backend
      _log('[SYNC] Step 4: Sending POST request to backend...');
      _log('[SYNC] 📡 Attempting connection to: ${_dio.options.baseUrl}/students/');
      
      Response response;
      try {
        response = await _sendSyncRequest(formData);
      } on DioException catch (e) {
        if (e.response?.statusCode == 409) {
          _log('[SYNC] ⚠️ Student exists (409). Attempting overwrite...');
          final deleted = await _deleteStudentFromBackend(student.studentId);
          if (deleted) {
             _log('[SYNC] 🔄 Retrying upload after delete...');
             // Re-build form data (streams might be consumed)
             final newFormData = await _buildSyncRequest(student, imageFiles);
             response = await _sendSyncRequest(newFormData);
          } else {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      _log('[SYNC] ✅ Step 4 complete: Received response ${response.statusCode}');
      
      // Step 5: Handle success response
      _log('[SYNC] Step 5: Processing success response...');
      final result = await _handleSuccessResponse(student, response, startTime);
      _log('[SYNC] ✅ Step 5 complete: Sync result ready');
      
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      _log('[SYNC] =====================================');
      _log('[SYNC] ✅ SYNC SUCCESSFUL for ${student.studentId}');
      _log('[SYNC] Total duration: ${duration}ms');
      _log('[SYNC] =====================================');
      
      return result;
      
    } on DioException catch (e) {
      return await _handleDioError(student, e, startTime);
    } catch (e) {
      return await _handleGenericError(student, e, startTime);
    }
  }

  /// Check processing status of a synced student
  /// 
  /// Polls the backend to get current processing_status:
  /// - "pending" - Still processing
  /// - "completed" - Ready for attendance
  /// - "failed" - Processing failed
  /// 
  /// Returns [ProcessingStatus] or null if student not found
  Future<ProcessingStatus?> checkProcessingStatus(String studentId) async {
    try {
      _log('[SYNC] Checking processing status for: $studentId');
      
      final response = await _dio.get('/students/$studentId');
      
      if (response.statusCode == 200) {
        final data = response.data;
        final status = data['processing_status'] as String?;
        
        _log('[SYNC] Processing status for $studentId: $status');
        
        return ProcessingStatus.fromString(status);
      }
      
      return null;
    } on DioException catch (e) {
      _logError('[SYNC] Failed to check status for $studentId: ${e.message}');
      return null;
    } catch (e) {
      _logError('[SYNC] Unexpected error checking status: $e');
      return null;
    }
  }

  /// Get list of students that need syncing
  /// 
  /// Returns students where sync_status is 'not_synced' or 'failed'
  Future<List<Student>> getStudentsToSync() async {
    try {
      final db = await _database.database;
      
      final results = await db.query(
        'students',
        where: 'sync_status IN (?, ?)',
        whereArgs: ['not_synced', 'failed'],
      );
      
      _log('[SYNC] Found ${results.length} students to sync');
      
      // Convert to Student entities
      // Note: You'll need to add a fromMap method to Student class
      // For now, returning empty list
      return [];
      
    } catch (e) {
      _logError('[SYNC] Failed to get students to sync: $e');
      return [];
    }
  }

  // ========================================================================
  // Private Helper Methods
  // ========================================================================

  /// Validate sync inputs before attempting sync
  Future<void> _validateSyncInputs(Student student, List<File> imageFiles) async {
    _log('[SYNC]   → Checking student ID...');
    // Check student ID is present
    if (student.studentId.isEmpty) {
      _logError('[SYNC]   ❌ Student ID is empty!');
      throw SyncError(
        type: SyncErrorType.client,
        message: 'Student ID is required',
      );
    }
    _log('[SYNC]   ✓ Student ID valid: ${student.studentId}');
    
    _log('[SYNC]   → Checking image files...');
    if (imageFiles.isEmpty) {
      _logError('[SYNC]   ❌ No image files provided');
      throw SyncError(
        type: SyncErrorType.file,
        message: 'No image files provided',
      );
    }

    for (var i = 0; i < imageFiles.length; i++) {
      final imageFile = imageFiles[i];
      _log('[SYNC]   → Checking image ${i + 1} exists...');
      _log('[SYNC]   → Image path: ${imageFile.path}');
      
      // Check image file exists
      if (!await imageFile.exists()) {
        _logError('[SYNC]   ❌ Image file not found at: ${imageFile.path}');
        throw SyncError(
          type: SyncErrorType.file,
          message: 'Image file not found: ${imageFile.path}',
        );
      }
      
      _log('[SYNC]   → Checking image ${i + 1} size...');
      // Check image file size
      final fileSize = await imageFile.length();
      _log('[SYNC]   → Image size: ${(fileSize / 1024).toStringAsFixed(2)} KB');
      if (!SyncConfig.isImageValid(imageFile.path, fileSize)) {
        _logError('[SYNC]   ❌ Invalid image: size=$fileSize bytes, path=${imageFile.path}');
        throw SyncError(
          type: SyncErrorType.file,
          message: 'Invalid image file (check size/format)',
        );
      }
    }
    _log('[SYNC]   ✓ All ${imageFiles.length} image files valid');
  }

  /// Build FormData for sync request
  Future<FormData> _buildSyncRequest(Student student, List<File> imageFiles) async {
    _log('[SYNC]   → Building FormData...');
    _log('[SYNC]   → Field: student_id = ${student.studentId}');
    _log('[SYNC]   → Field: name = ${student.fullName}');
    _log('[SYNC]   → Field: email = ${student.email}');
    _log('[SYNC]   → Field: department = ${student.department}');
    _log('[SYNC]   → Field: year = ${student.enrollmentYear ?? 0}');
    _log('[SYNC]   → Field: images count = ${imageFiles.length}');
    
    final formData = FormData();
    
    // Add fields
    formData.fields.addAll([
      MapEntry('student_id', student.studentId),
      MapEntry('name', student.fullName),
      MapEntry('email', student.email),
      MapEntry('department', student.department),
      MapEntry('year', (student.enrollmentYear ?? 0).toString()),
    ]);

    // Add images
    for (var i = 0; i < imageFiles.length; i++) {
      // Fix orientation (rotate 180 degrees) before upload
      final fixedImage = await _fixImageOrientation(imageFiles[i]);
      
      formData.files.add(MapEntry(
        'images',
        await MultipartFile.fromFile(
          fixedImage.path,
          filename: '${student.studentId}_pose${i + 1}.jpg',
        ),
      ));
    }
    
    _log('[SYNC]   ✓ FormData built successfully');
    return formData;
  }

  /// Send sync request to backend
  Future<Response> _sendSyncRequest(FormData formData) async {
    final fullUrl = '${SyncConfig.backendBaseUrl}/students/';
    _log('[SYNC]   → Attempting connection...');
    _log('[SYNC]   → Full URL: $fullUrl');
    _log('[SYNC]   → Method: POST');
    _log('[SYNC]   → Content-Type: multipart/form-data');
    
    final response = await _dio.post(
      '/students/',
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
    
    _log('[SYNC]   ✓ Connection successful!');
    _log('[SYNC]   → Response status: ${response.statusCode}');
    _log('[SYNC]   → Response data: ${response.data}');
    
    return response;
  }

  /// Handle successful sync response
  Future<SyncResult> _handleSuccessResponse(
    Student student,
    Response response,
    DateTime startTime,
  ) async {
    final data = response.data;
    final backendStudent = data['student'] as Map<String, dynamic>?;
    final backendStudentId = backendStudent?['student_id'] as String?;
    
    // Update local database - synced
    await _updateLocalSyncStatus(
      student.id,
      SyncStatus.synced,
      backendStudentId,
      null,
    );
    
    final duration = DateTime.now().difference(startTime);
    
    return SyncResult.success(
      backendStudentId: backendStudentId ?? student.studentId,
      metadata: {
        'duration_ms': duration.inMilliseconds,
        'response_code': response.statusCode,
      },
    );
  }

  /// Handle Dio (HTTP) errors
  Future<SyncResult> _handleDioError(
    Student student,
    DioException error,
    DateTime startTime,
  ) async {
    _logError('[SYNC] ❌ Dio error for ${student.studentId}');
    _logError('[SYNC] Error type: ${error.type}');
    _logError('[SYNC] Error message: ${error.message}');
    _logError('[SYNC] Request URL: ${error.requestOptions.uri}');
    _logError('[SYNC] Request method: ${error.requestOptions.method}');
    if (error.response != null) {
      _logError('[SYNC] Response status: ${error.response?.statusCode}');
      _logError('[SYNC] Response data: ${error.response?.data}');
    }
    
    SyncErrorType errorType;
    String errorMessage;
    
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        errorType = SyncErrorType.network;
        errorMessage = 'Connection timeout - Could not connect to server within 2 minutes';
        _logError('[SYNC] 🔴 CONNECTION TIMEOUT: Backend server may not be running or not reachable at ${error.requestOptions.uri}');
        break;
      case DioExceptionType.receiveTimeout:
        errorType = SyncErrorType.network;
        errorMessage = 'Receive timeout - Server took too long to respond';
        _logError('[SYNC] 🔴 RECEIVE TIMEOUT: Server connected but response too slow');
        break;
      case DioExceptionType.sendTimeout:
        errorType = SyncErrorType.network;
        errorMessage = 'Send timeout - Upload took too long';
        _logError('[SYNC] 🔴 SEND TIMEOUT: Image upload too slow');
        break;
        
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 409) {
          // Student already exists - try to delete and re-sync
          _log('[SYNC] ⚠️ Student already exists on backend (409). Attempting to overwrite...');
          
          try {
            final deleted = await _deleteStudentFromBackend(student.studentId);
            if (deleted) {
              _log('[SYNC] 🔄 Overwrite: Student deleted, retrying upload...');
              // We can't easily recurse here because we don't have the image files in this scope
              // But we can return a special error that triggers a retry in the UI or handle it differently
              // Ideally, we should have handled this in the main flow, but since we are in error handler:
              
              // Let's try to return a "failed" result but with a specific message telling user to retry
              // OR better: modify the main syncStudent flow to handle 409 explicitly instead of catching it here.
              
              // Actually, let's just mark it as failed with a "Retry to overwrite" message for now, 
              // OR since we just deleted it, the NEXT attempt will succeed.
              
              // Wait, if I deleted it successfully, I should probably tell the user to try again.
              errorType = SyncErrorType.client;
              errorMessage = 'Existing record cleared. Please tap sync again to upload.';
            } else {
              errorType = SyncErrorType.client;
              errorMessage = 'Student exists and could not be overwritten.';
            }
          } catch (e) {
            errorType = SyncErrorType.client;
            errorMessage = 'Student exists. Overwrite failed: $e';
          }
        } else if (statusCode != null && statusCode >= 400 && statusCode < 500) {
          errorType = SyncErrorType.client;
          errorMessage = 'Invalid request: ${error.response?.data?['error'] ?? error.message}';
        } else {
          errorType = SyncErrorType.server;
          errorMessage = 'Server error: ${error.response?.statusCode}';
        }
        break;
        
      case DioExceptionType.connectionError:
        errorType = SyncErrorType.network;
        errorMessage = 'No internet connection';
        break;
        
      default:
        errorType = SyncErrorType.unknown;
        errorMessage = error.message ?? 'Unknown network error';
    }
    
    // Update local database - failed
    await _updateLocalSyncStatus(
      student.id,
      SyncStatus.failed,
      null,
      errorMessage,
    );
    
    return SyncResult.failed(
      error: errorMessage,
      metadata: {
        'error_type': errorType.toString(),
        'status_code': error.response?.statusCode,
      },
    );
  }

  /// Handle generic errors
  Future<SyncResult> _handleGenericError(
    Student student,
    Object error,
    DateTime startTime,
  ) async {
    final errorMessage = error.toString();
    _logError('[SYNC] ❌ Unexpected error for ${student.studentId}: $errorMessage');
    
    // Update local database - failed
    await _updateLocalSyncStatus(
      student.id,
      SyncStatus.failed,
      null,
      errorMessage,
    );
    
    return SyncResult.failed(
      error: errorMessage,
      metadata: {
        'error_type': 'unknown',
      },
    );
  }

  /// Update local database sync status
  Future<void> _updateLocalSyncStatus(
    String studentId,
    SyncStatus status,
    String? backendStudentId,
    String? error,
  ) async {
    try {
      final db = await _database.database;
      
      await db.update(
        'students',
        {
          'sync_status': status.value,
          if (backendStudentId != null) 'backend_student_id': backendStudentId,
          'last_sync_attempt': DateTime.now().toIso8601String(),
          if (error != null) 'sync_error': error,
        },
        where: 'id = ?',
        whereArgs: [studentId],
      );
      
      _log('[SYNC] Updated local status for $studentId: ${status.value}');
      
    } catch (e) {
      _logError('[SYNC] Failed to update local database: $e');
      rethrow;
    }
  }

  /// Delete student from backend
  Future<bool> _deleteStudentFromBackend(String studentId) async {
    try {
      _log('[SYNC]   → Attempting to delete existing student $studentId from backend...');
      final response = await _dio.delete(
        '/students/$studentId',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      
      if (response.statusCode == 200 || response.statusCode == 404) {
        _log('[SYNC]   ✓ Student deleted successfully (or not found)');
        return true;
      }
      return false;
    } catch (e) {
      _logError('[SYNC]   ❌ Failed to delete student: $e');
      // If 404, it's already deleted
      if (e is DioException && e.response?.statusCode == 404) {
        return true;
      }
      return false;
    }
  }

  /// Fix image orientation by rotating 180 degrees
  Future<File> _fixImageOrientation(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return imageFile;
      
      // Rotate 180 degrees
      final rotated = img.copyRotate(image, angle: 180);
      
      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/rotated_${DateTime.now().millisecondsSinceEpoch}_${imageFile.uri.pathSegments.last}';
      final tempFile = File(tempPath);
      
      await tempFile.writeAsBytes(img.encodeJpg(rotated));
      return tempFile;
    } catch (e) {
      _logError('[SYNC] Error rotating image: $e');
      return imageFile;
    }
  }

  // ========================================================================
  // Logging Helpers
  // ========================================================================

  void _log(String message) {
    if (SyncConfig.enableDetailedLogging) {
      print(message);
    }
  }

  void _logError(String message) {
    print(message); // Always log errors
  }
}
