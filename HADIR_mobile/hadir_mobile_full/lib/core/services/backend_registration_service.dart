/// Backend Registration Service
/// 
/// Handles direct upload of student registration to backend server.
/// Replaces the complex sync system with immediate upload during registration.
library;

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hadir_mobile_full/shared/domain/entities/student.dart';
import 'backend_config_service.dart';

/// Result of backend registration attempt
class BackendRegistrationResult {
  final bool success;
  final String? backendStudentId;
  final String? message;
  final String? error;
  
  const BackendRegistrationResult({
    required this.success,
    this.backendStudentId,
    this.message,
    this.error,
  });
  
  factory BackendRegistrationResult.success({
    required String backendStudentId,
    String? message,
  }) {
    return BackendRegistrationResult(
      success: true,
      backendStudentId: backendStudentId,
      message: message ?? 'Student registered successfully',
    );
  }
  
  factory BackendRegistrationResult.failure({
    required String error,
  }) {
    return BackendRegistrationResult(
      success: false,
      error: error,
    );
  }
}

/// Service for registering students directly to backend
class BackendRegistrationService {
  final Dio _dio;
  
  BackendRegistrationService({Dio? dio, String? customBaseUrl})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: customBaseUrl ?? _getDefaultBaseUrl(),
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(minutes: 3),
              sendTimeout: const Duration(minutes: 5),
              headers: {
                'Accept': 'application/json',
                'User-Agent': 'HADIR-Mobile/1.0.0',
                'bypass-tunnel-reminder': 'true',
              },
            ));
  
  /// Get backend URL from config service or use default
  static String _getDefaultBaseUrl() {
    try {
      // Try to get from config service if initialized
      return BackendConfigService.instance.backendUrl;
    } catch (e) {
      // Fallback to default if service not initialized
      return BackendConfigService.defaultAndroidEmulator;
    }
  }
  
  /// Register student to backend server
  /// 
  /// Uploads student data + 5 face images from different poses to backend.
  /// Backend will handle face detection, augmentation, embedding generation, and storage.
  /// Backend generates 20 augmentations per pose = 100 total training samples.
  /// 
  /// Parameters:
  /// - [student]: Student entity with all details
  /// - [imageFiles]: List of exactly 5 face images from different poses (validated for sharpness)
  /// 
  /// Returns:
  /// - [BackendRegistrationResult] with success status and backend ID
  Future<BackendRegistrationResult> registerStudent({
    required Student student,
    required List<File> imageFiles,
  }) async {
    // Update base URL from config service to ensure we use the latest one
    try {
      final currentUrl = BackendConfigService.instance.backendUrl;
      if (_dio.options.baseUrl != currentUrl) {
        _dio.options.baseUrl = currentUrl;
      }
    } catch (_) {
      // Ignore if config service not initialized
    }

    try {
      // Validate input count
      if (imageFiles.length != 5) {
        return BackendRegistrationResult.failure(
          error: 'Exactly 5 images required, got ${imageFiles.length}',
        );
      }
      
      // Validate all files exist
      for (var i = 0; i < imageFiles.length; i++) {
        if (!await imageFiles[i].exists()) {
          return BackendRegistrationResult.failure(
            error: 'Image ${i + 1} not found: ${imageFiles[i].path}',
          );
        }
      }
      
      // Build FormData with 5 images under the same 'images' field name
      // Backend uses request.files.getlist('images') to handle multiple files
      final formData = FormData();
      
      // Add student data fields
      formData.fields.addAll([
        MapEntry('student_id', student.studentId),
        MapEntry('name', student.fullName),
        MapEntry('email', student.email),
        MapEntry('department', student.department),
        MapEntry('year', (student.enrollmentYear ?? 0).toString()),
      ]);
      
      // Add all 5 images with the SAME field name 'images'
      // This allows backend to use request.files.getlist('images')
      for (var i = 0; i < imageFiles.length; i++) {
        formData.files.add(MapEntry(
          'images',  // Same field name for all images
          await MultipartFile.fromFile(
            imageFiles[i].path,
            filename: '${student.studentId}_pose${i + 1}.jpg',
          ),
        ));
      }
      
      // Send POST request
      final response = await _dio.post(
        '/students/',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      
      // Handle success (201 Created)
      if (response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        return BackendRegistrationResult.success(
          backendStudentId: student.studentId,
          message: data['message'] as String? ?? 'Student registered successfully',
        );
      }
      
      // Unexpected success code
      return BackendRegistrationResult.failure(
        error: 'Unexpected response code: ${response.statusCode}',
      );
      
    } on DioException catch (e) {
      // Handle specific Dio errors
      if (e.response?.statusCode == 409) {
        // Student already exists - try to delete and re-register
        try {
          final deleted = await deleteStudent(student.studentId);
          if (deleted) {
            // Retry registration recursively
            return registerStudent(student: student, imageFiles: imageFiles);
          }
        } catch (_) {
          // Ignore delete error and fall through to return success (existing behavior)
        }

        // Fallback: Student already exists - could be considered success
        return BackendRegistrationResult.success(
          backendStudentId: student.studentId,
          message: 'Student already registered in backend',
        );
      }
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return BackendRegistrationResult.failure(
          error: 'Connection timeout. Please check your internet connection.',
        );
      }
      
      if (e.type == DioExceptionType.connectionError) {
        return BackendRegistrationResult.failure(
          error: 'Cannot connect to server. Please ensure backend is running.',
        );
      }
      
      // Other Dio errors
      final errorMessage = e.response?.data?['error'] as String? ??
          e.message ??
          'Network error occurred';
      
      return BackendRegistrationResult.failure(error: errorMessage);
      
    } catch (e) {
      // Generic errors
      return BackendRegistrationResult.failure(
        error: 'Unexpected error: ${e.toString()}',
      );
    }
  }
  
  /// Check if backend is reachable (health check)
  Future<bool> isBackendAvailable() async {
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
      final response = await _dio.get(
        '/health/status',  // Correct endpoint path
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Delete student from backend
  Future<bool> deleteStudent(String studentId) async {
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
      final response = await _dio.delete(
        '/students/$studentId',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      // If student not found (404), consider it deleted
      if (e is DioException && e.response?.statusCode == 404) {
        return true;
      }
      return false;
    }
  }
}
