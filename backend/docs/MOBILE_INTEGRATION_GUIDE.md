# Mobile App Integration Guide - Student Registration

## Overview
This guide explains how to integrate the mobile app with the backend student registration endpoint that accepts 5 face images in a single API call.

## Endpoint Details

### POST `/api/students/register`

**Purpose**: Register a new student with 5 face images captured from different poses.

**Content-Type**: `multipart/form-data`

### Request Parameters

#### Form Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `student_id` | string | Yes | Unique student identifier (e.g., "100012345") |
| `name` | string | Yes | Full name of the student |
| `email` | string | No | Student email address |
| `department` | string | No | Department/Faculty name |
| `year` | integer | No | Academic year (1-4) |

#### Image Files
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `image_1` | file | Yes | Front face pose (sharp, validated) |
| `image_2` | file | Yes | Pose variation 2 (sharp, validated) |
| `image_3` | file | Yes | Pose variation 3 (sharp, validated) |
| `image_4` | file | Yes | Pose variation 4 (sharp, validated) |
| `image_5` | file | Yes | Pose variation 5 (sharp, validated) |

**Image Requirements:**
- Format: JPG, PNG, JPEG, BMP
- All 5 images must be provided
- Images should be pre-validated for sharpness by mobile app
- Different poses/angles preferred for better face recognition

## Response Format

### Success Response (201 Created)
```json
{
  "success": true,
  "message": "Student registered successfully. Processing 5 face images in background.",
  "student": {
    "uuid": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "student_id": "100012345",
    "name": "John Doe",
    "email": "john.doe@university.edu",
    "department": "Computer Science",
    "year": 3,
    "image_paths": [
      "/path/to/student/folder/100012345_pose1_20251122_143025.jpg",
      "/path/to/student/folder/100012345_pose2_20251122_143025.jpg",
      "/path/to/student/folder/100012345_pose3_20251122_143025.jpg",
      "/path/to/student/folder/100012345_pose4_20251122_143025.jpg",
      "/path/to/student/folder/100012345_pose5_20251122_143025.jpg"
    ],
    "num_images": 5,
    "registered_at": "2025-11-22T14:30:25.123456",
    "processing_status": "pending"
  },
  "images_received": 5
}
```

### Error Responses

#### 400 Bad Request - Missing Fields
```json
{
  "error": "student_id and name are required"
}
```

#### 400 Bad Request - Missing Images
```json
{
  "error": "Missing image_3. All 5 images are required."
}
```

#### 400 Bad Request - Invalid Image
```json
{
  "error": "image_2: Invalid file type. Allowed types: png, jpg, jpeg, bmp"
}
```

#### 409 Conflict - Student Exists
```json
{
  "error": "Student already exists",
  "student_id": "100012345"
}
```

## Flutter/Dart Integration Example

### Using Dio Package

```dart
import 'package:dio/dio.dart';
import 'dart:io';

class StudentRegistrationService {
  final Dio _dio;
  final String baseUrl;

  StudentRegistrationService(this.baseUrl) 
      : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  /// Register student with 5 validated face images
  Future<Map<String, dynamic>> registerStudent({
    required String studentId,
    required String name,
    required List<File> images, // Must contain exactly 5 images
    String? email,
    String? department,
    int? year,
    Function(double)? onProgress,
  }) async {
    // Validate image count
    if (images.length != 5) {
      throw ArgumentError('Exactly 5 images are required, got ${images.length}');
    }

    try {
      // Prepare form data
      final formData = FormData.fromMap({
        'student_id': studentId,
        'name': name,
        if (email != null) 'email': email,
        if (department != null) 'department': department,
        if (year != null) 'year': year,
        // Add all 5 images
        for (int i = 0; i < images.length; i++)
          'image_${i + 1}': await MultipartFile.fromFile(
            images[i].path,
            filename: 'pose_${i + 1}.jpg',
          ),
      });

      // Send request with progress tracking
      final response = await _dio.post(
        '/api/students/register',
        data: formData,
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );

      if (response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Registration failed with status ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        throw Exception(errorData['error'] ?? 'Registration failed');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }
}
```

### Usage Example

```dart
// In your registration screen/controller

final registrationService = StudentRegistrationService('http://your-backend-url:5000');

Future<void> handleRegistration() async {
  try {
    // Show loading dialog
    showLoadingDialog();

    // Call registration API
    final result = await registrationService.registerStudent(
      studentId: studentIdController.text,
      name: nameController.text,
      images: capturedImages, // List of 5 validated File objects
      email: emailController.text.isEmpty ? null : emailController.text,
      department: selectedDepartment,
      year: selectedYear,
      onProgress: (progress) {
        // Update progress indicator
        updateProgress(progress);
      },
    );

    // Hide loading dialog
    hideLoadingDialog();

    // Show success message
    if (result['success'] == true) {
      showSuccessDialog(
        'Student registered successfully! '
        'Processing ${result['images_received']} face images.'
      );
      
      // Navigate back or clear form
      navigateToHome();
    }
  } catch (e) {
    hideLoadingDialog();
    showErrorDialog('Registration failed: ${e.toString()}');
  }
}
```

## Image Validation (Mobile App Side)

Before sending images to the backend, ensure they meet these criteria:

### 1. Sharpness Validation
```dart
import 'package:image/image.dart' as img;

double calculateSharpness(File imageFile) {
  final bytes = imageFile.readAsBytesSync();
  final image = img.decodeImage(bytes);
  
  if (image == null) return 0.0;
  
  // Calculate Laplacian variance (measure of sharpness)
  // Higher variance = sharper image
  // Implementation depends on your image processing library
  
  return laplacianVariance(image);
}

bool isImageSharp(File imageFile, {double threshold = 100.0}) {
  return calculateSharpness(imageFile) > threshold;
}
```

### 2. Face Detection Validation
```dart
// Use a face detection library (e.g., ML Kit, Firebase ML)
import 'package:google_ml_kit/google_ml_kit.dart';

Future<bool> containsFace(File imageFile) async {
  final inputImage = InputImage.fromFile(imageFile);
  final faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: true,
    ),
  );
  
  final faces = await faceDetector.processImage(inputImage);
  await faceDetector.close();
  
  return faces.isNotEmpty;
}
```

### 3. Complete Validation Flow
```dart
Future<List<File>> captureAndValidateImages() async {
  List<File> validatedImages = [];
  
  for (int pose = 1; pose <= 5; pose++) {
    File? capturedImage;
    bool isValid = false;
    
    while (!isValid) {
      // Show pose instruction to user
      showPoseInstruction(pose);
      
      // Capture image
      capturedImage = await captureImage();
      
      if (capturedImage == null) {
        throw Exception('Image capture cancelled');
      }
      
      // Validate sharpness
      if (!isImageSharp(capturedImage)) {
        showError('Image is blurry. Please try again.');
        continue;
      }
      
      // Validate face presence
      if (!await containsFace(capturedImage)) {
        showError('No face detected. Please try again.');
        continue;
      }
      
      isValid = true;
    }
    
    validatedImages.add(capturedImage!);
    showSuccess('Pose $pose captured successfully!');
  }
  
  return validatedImages;
}
```

## Testing with cURL

```bash
curl -X POST http://localhost:5000/api/students/register \
  -F "student_id=100012345" \
  -F "name=John Doe" \
  -F "email=john.doe@university.edu" \
  -F "department=Computer Science" \
  -F "year=3" \
  -F "image_1=@/path/to/pose1.jpg" \
  -F "image_2=@/path/to/pose2.jpg" \
  -F "image_3=@/path/to/pose3.jpg" \
  -F "image_4=@/path/to/pose4.jpg" \
  -F "image_5=@/path/to/pose5.jpg"
```

## Testing with Postman

1. Set request type to `POST`
2. URL: `http://your-backend-url:5000/api/students/register`
3. Go to "Body" tab
4. Select "form-data"
5. Add text fields:
   - `student_id`: 100012345
   - `name`: John Doe
   - `email`: john.doe@university.edu
   - `department`: Computer Science
   - `year`: 3
6. Add file fields (change type to "File"):
   - `image_1`: Select image file
   - `image_2`: Select image file
   - `image_3`: Select image file
   - `image_4`: Select image file
   - `image_5`: Select image file
7. Click "Send"

## Backend Processing Flow

1. **Receive Request**: Backend receives all 5 images in one call
2. **Validation**: Validates all images and student data
3. **Save Images**: Saves images to student-specific folder
4. **Create Record**: Creates student record in database with status "pending"
5. **Background Processing**: Starts background thread to:
   - Extract faces from each image
   - Generate embeddings for each face
   - Save embeddings for later classifier training
6. **Return Response**: Immediately returns success to mobile app

## Processing Status

After registration, you can check processing status:

### GET `/api/students/{student_id}`

**Response:**
```json
{
  "student_id": "100012345",
  "processing_status": "completed",  // or "pending" or "failed"
  "num_images_processed": 5,
  "processed_at": "2025-11-22T14:30:30.123456"
}
```

## Best Practices

1. **Pre-validate on Mobile**: Always validate images before sending
2. **Progress Tracking**: Show upload progress to user
3. **Error Handling**: Handle network errors gracefully with retry logic
4. **User Feedback**: Provide clear feedback during capture and upload
5. **Image Quality**: Ensure good lighting and clear face visibility
6. **Network Check**: Verify internet connection before starting
7. **Timeout Handling**: Set appropriate timeouts for large file uploads

## Troubleshooting

### Issue: Upload Timeout
- **Solution**: Increase timeout in Dio configuration
```dart
final dio = Dio(BaseOptions(
  baseUrl: baseUrl,
  connectTimeout: Duration(seconds: 30),
  receiveTimeout: Duration(seconds: 30),
  sendTimeout: Duration(minutes: 2), // For large uploads
));
```

### Issue: Out of Memory
- **Solution**: Compress images before upload
```dart
Future<File> compressImage(File file) async {
  final bytes = await file.readAsBytes();
  final image = img.decodeImage(bytes);
  
  if (image == null) return file;
  
  // Resize if too large
  final resized = img.copyResize(image, width: 800);
  
  // Compress
  final compressed = img.encodeJpg(resized, quality: 85);
  
  // Save to temporary file
  final tempFile = File('${file.path}_compressed.jpg');
  await tempFile.writeAsBytes(compressed);
  
  return tempFile;
}
```

## Support

For issues or questions:
- Check API documentation at `/api/docs`
- Review backend logs for detailed error messages
- Test with cURL/Postman before mobile implementation
