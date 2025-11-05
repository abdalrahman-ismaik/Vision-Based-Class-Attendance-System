import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/utils/app_config.dart';
import '../../../core/utils/app_logger.dart';

/// API service for communicating with the HADIR Frame Selection Service
/// 
/// This service handles all communication with the Python microservice
/// that provides ML Kit Face Detection powered frame selection capabilities.
class FrameSelectionApiService {
  late final Dio _dio;
  
  FrameSelectionApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      sendTimeout: AppConfig.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Add logging interceptor
    if (AppConfig.enableLogging) {
      _dio.interceptors.add(_LoggingInterceptor());
    }
  }
  
  /// Check if the frame selection service is healthy
  Future<ApiResponse<Map<String, dynamic>>> checkHealth() async {
    try {
      AppLogger.logNetworkRequest('GET', AppConfig.healthCheckUrl);
      
      final response = await _dio.get(AppConfig.healthCheckEndpoint);
      
      AppLogger.logNetworkResponse(
        AppConfig.healthCheckUrl, 
        response.statusCode ?? 0,
        responseBody: response.data?.toString(),
      );
      
      return ApiResponse.success(response.data);
    } catch (e) {
      AppLogger.error('Health check failed', error: e);
      return ApiResponse.error(_handleError(e));
    }
  }
  
  /// Select best frames from a list of image files
  Future<ApiResponse<FrameSelectionResult>> selectFrames({
    required List<File> imageFiles,
    int maxFrames = 5,
    Map<String, dynamic>? options,
  }) async {
    try {
      AppLogger.logFrameProcessing(
        'Starting frame selection',
        metrics: {'imageCount': imageFiles.length, 'maxFrames': maxFrames},
      );
      
      // Prepare multipart form data
      final formData = FormData();
      
      // Add image files
      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        final fileName = 'frame_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        formData.files.add(MapEntry(
          'images',
          await MultipartFile.fromFile(
            file.path,
            filename: fileName,
          ),
        ));
      }
      
      // Add options
      formData.fields.add(MapEntry('max_frames', maxFrames.toString()));
      if (options != null) {
        formData.fields.add(MapEntry('options', jsonEncode(options)));
      }
      
      AppLogger.logNetworkRequest('POST', AppConfig.frameSelectionUrl, 
          params: {'imageCount': imageFiles.length, 'maxFrames': maxFrames});
      
      final response = await _dio.post(
        AppConfig.frameSelectionEndpoint,
        data: formData,
      );
      
      AppLogger.logNetworkResponse(
        AppConfig.frameSelectionUrl,
        response.statusCode ?? 0,
      );
      
      final result = FrameSelectionResult.fromJson(response.data);
      
      AppLogger.logFrameProcessing(
        'Frame selection completed',
        metrics: {
          'selectedFrames': result.selectedFrames.length,
          'processingTime': result.processingTimeMs,
        },
      );
      
      return ApiResponse.success(result);
    } catch (e) {
      AppLogger.error('Frame selection failed', error: e);
      return ApiResponse.error(_handleError(e));
    }
  }
  
  /// Get service information and capabilities
  Future<ApiResponse<Map<String, dynamic>>> getServiceInfo() async {
    try {
      AppLogger.logNetworkRequest('GET', '${AppConfig.apiBaseUrl}/info');
      
      final response = await _dio.get('/info');
      
      AppLogger.logNetworkResponse(
        '${AppConfig.apiBaseUrl}/info',
        response.statusCode ?? 0,
        responseBody: response.data?.toString(),
      );
      
      return ApiResponse.success(response.data);
    } catch (e) {
      AppLogger.error('Get service info failed', error: e);
      return ApiResponse.error(_handleError(e));
    }
  }
  
  /// Handle API errors and convert to user-friendly messages
  String _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please check your internet connection.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 404) {
            return 'Service not found. Please ensure the frame selection service is running.';
          } else if (statusCode == 500) {
            return 'Server error occurred. Please try again later.';
          }
          return 'Request failed with status code: $statusCode';
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        case DioExceptionType.unknown:
          if (error.error is SocketException) {
            return 'No internet connection. Please check your network settings.';
          }
          return 'An unexpected error occurred.';
        default:
          return 'Network error occurred. Please try again.';
      }
    }
    return error.toString();
  }
}

/// Generic API response wrapper
class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;
  
  ApiResponse.success(this.data)
      : error = null,
        isSuccess = true;
  
  ApiResponse.error(this.error)
      : data = null,
        isSuccess = false;
}

/// Frame selection result model
class FrameSelectionResult {
  final List<SelectedFrame> selectedFrames;
  final int processingTimeMs;
  final Map<String, dynamic> metadata;
  
  FrameSelectionResult({
    required this.selectedFrames,
    required this.processingTimeMs,
    required this.metadata,
  });
  
  factory FrameSelectionResult.fromJson(Map<String, dynamic> json) {
    return FrameSelectionResult(
      selectedFrames: (json['selected_frames'] as List)
          .map((frame) => SelectedFrame.fromJson(frame))
          .toList(),
      processingTimeMs: json['processing_time_ms'] ?? 0,
      metadata: json['metadata'] ?? {},
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'selected_frames': selectedFrames.map((frame) => frame.toJson()).toList(),
      'processing_time_ms': processingTimeMs,
      'metadata': metadata,
    };
  }
}

/// Selected frame model
class SelectedFrame {
  final int originalIndex;
  final String frameId;
  final double qualityScore;
  final double sharpnessScore;
  final double brightnessScore;
  final int faceCount;
  final List<FaceDetection> faces;
  final String? base64Image;
  
  SelectedFrame({
    required this.originalIndex,
    required this.frameId,
    required this.qualityScore,
    required this.sharpnessScore,
    required this.brightnessScore,
    required this.faceCount,
    required this.faces,
    this.base64Image,
  });
  
  factory SelectedFrame.fromJson(Map<String, dynamic> json) {
    return SelectedFrame(
      originalIndex: json['original_index'] ?? 0,
      frameId: json['frame_id'] ?? '',
      qualityScore: (json['quality_score'] ?? 0.0).toDouble(),
      sharpnessScore: (json['sharpness_score'] ?? 0.0).toDouble(),
      brightnessScore: (json['brightness_score'] ?? 0.0).toDouble(),
      faceCount: json['face_count'] ?? 0,
      faces: (json['faces'] as List? ?? [])
          .map((face) => FaceDetection.fromJson(face))
          .toList(),
      base64Image: json['base64_image'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'original_index': originalIndex,
      'frame_id': frameId,
      'quality_score': qualityScore,
      'sharpness_score': sharpnessScore,
      'brightness_score': brightnessScore,
      'face_count': faceCount,
      'faces': faces.map((face) => face.toJson()).toList(),
      'base64_image': base64Image,
    };
  }
}

/// Face detection model
class FaceDetection {
  final double confidence;
  final BoundingBox boundingBox;
  final List<KeyPoint> keypoints;
  final Map<String, double> angles;
  
  FaceDetection({
    required this.confidence,
    required this.boundingBox,
    required this.keypoints,
    required this.angles,
  });
  
  factory FaceDetection.fromJson(Map<String, dynamic> json) {
    return FaceDetection(
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      boundingBox: BoundingBox.fromJson(json['bounding_box'] ?? {}),
      keypoints: (json['keypoints'] as List? ?? [])
          .map((kp) => KeyPoint.fromJson(kp))
          .toList(),
      angles: Map<String, double>.from(json['angles'] ?? {}),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'confidence': confidence,
      'bounding_box': boundingBox.toJson(),
      'keypoints': keypoints.map((kp) => kp.toJson()).toList(),
      'angles': angles,
    };
  }
}

/// Bounding box model
class BoundingBox {
  final double x;
  final double y;
  final double width;
  final double height;
  
  BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
  
  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      x: (json['x'] ?? 0.0).toDouble(),
      y: (json['y'] ?? 0.0).toDouble(),
      width: (json['width'] ?? 0.0).toDouble(),
      height: (json['height'] ?? 0.0).toDouble(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }
}

/// Key point model for pose estimation
class KeyPoint {
  final double x;
  final double y;
  final double confidence;
  final String name;
  
  KeyPoint({
    required this.x,
    required this.y,
    required this.confidence,
    required this.name,
  });
  
  factory KeyPoint.fromJson(Map<String, dynamic> json) {
    return KeyPoint(
      x: (json['x'] ?? 0.0).toDouble(),
      y: (json['y'] ?? 0.0).toDouble(),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      name: json['name'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'confidence': confidence,
      'name': name,
    };
  }
}

/// Logging interceptor for Dio requests
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.logNetworkRequest(
      options.method.toUpperCase(),
      options.uri.toString(),
      params: options.queryParameters,
    );
    super.onRequest(options, handler);
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.logNetworkResponse(
      response.requestOptions.uri.toString(),
      response.statusCode ?? 0,
    );
    super.onResponse(response, handler);
  }
  
  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    AppLogger.error(
      'Network request failed: ${error.requestOptions.uri}',
      error: error,
    );
    super.onError(error, handler);
  }
}