/// Backend Registration Service
/// 
/// Handles direct upload of student registration to backend server.
/// Replaces the complex sync system with immediate upload during registration.
library;

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hadir_mobile_full/shared/domain/entities/student.dart';

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
  
  /// Backend base URL (configure for your environment)
  /// 
  /// - Android Emulator: 'http://10.0.2.2:5000/api'
  /// - iOS Simulator: 'http://localhost:5000/api'
  /// - Physical Device: 'http://YOUR_IP:5000/api'
  static const String backendBaseUrl = 'http://10.0.2.2:5000/api';
  
  BackendRegistrationService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: backendBaseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(minutes: 3),
              sendTimeout: const Duration(minutes: 5),
              headers: {
                'Accept': 'application/json',
                'User-Agent': 'HADIR-Mobile/1.0.0',
              },
            ));
  
  /// Register student to backend server
  /// 
  /// Uploads student data + one face image to backend for processing.
  /// Backend will handle face detection, embedding generation, and storage.
  /// 
  /// Parameters:
  /// - [student]: Student entity with all details
  /// - [imageFile]: One representative face image (best quality)
  /// 
  /// Returns:
  /// - [BackendRegistrationResult] with success status and backend ID
  Future<BackendRegistrationResult> registerStudent({
    required Student student,
    required File imageFile,
  }) async {
    try {
      // Validate inputs
      if (!await imageFile.exists()) {
        return BackendRegistrationResult.failure(
          error: 'Image file not found: ${imageFile.path}',
        );
      }
      
      // Build FormData
      final formData = FormData.fromMap({
        'student_id': student.studentId,
        'name': student.fullName,
        'email': student.email,
        'department': student.department,
        'year': student.enrollmentYear ?? 0,
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: '${student.studentId}_face.jpg',
        ),
      });
      
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
        // Student already exists - could be considered success
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
    try {
      final response = await _dio.get(
        '/health',
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
}
