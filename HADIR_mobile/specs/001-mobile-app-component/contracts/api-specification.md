# API Contracts: Mobile Student Registration App

**Version**: 1.0  
**Date**: September 28, 2025  
**API Standard**: RESTful JSON API

---

## Authentication Contracts

### POST /api/v1/auth/login
**Purpose**: Administrator authentication

**Request**:
```json
{
  "username": "string",
  "password": "string",
  "deviceId": "string"
}
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "token": "jwt_token_string",
    "refreshToken": "refresh_token_string",
    "administrator": {
      "id": "uuid",
      "username": "string",
      "fullName": "string",
      "role": "operator|supervisor|admin",
      "permissions": ["string"]
    },
    "expiresAt": "2025-09-28T15:30:00Z"
  }
}
```

**Response (401 Unauthorized)**:
```json
{
  "success": false,
  "error": {
    "code": "AUTH_FAILED",
    "message": "Invalid credentials"
  }
}
```

### POST /api/v1/auth/refresh
**Purpose**: Refresh authentication token

**Request**:
```json
{
  "refreshToken": "string"
}
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "token": "new_jwt_token",
    "expiresAt": "2025-09-28T16:30:00Z"
  }
}
```

### POST /api/v1/auth/logout
**Purpose**: Administrator logout

**Request**:
```json
{
  "token": "string"
}
```

**Response (200 OK)**:
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

## Student Management Contracts

### POST /api/v1/students
**Purpose**: Create a new student profile

**Request**:
```json
{
  "studentId": "string",
  "fullName": "string", 
  "email": "string?",
  "dateOfBirth": "string?",
  "department": "string?",
  "program": "string?"
}
```

**Response (201 Created)**:
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "studentId": "string",
    "fullName": "string",
    "email": "string?",
    "dateOfBirth": "string?", 
    "department": "string?",
    "program": "string?",
    "status": "pending",
    "createdAt": "2025-09-28T10:00:00Z"
  }
}
```

**Response (409 Conflict)**:
```json
{
  "success": false,
  "error": {
    "code": "STUDENT_EXISTS",
    "message": "Student with this ID already exists",
    "field": "studentId"
  }
}
```

### GET /api/v1/students/{id}
**Purpose**: Retrieve student by ID

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "studentId": "string",
    "fullName": "string",
    "email": "string?",
    "status": "pending|registered|incomplete|archived",
    "createdAt": "2025-09-28T10:00:00Z",
    "lastUpdatedAt": "2025-09-28T10:30:00Z"
  }
}
```

**Response (404 Not Found)**:
```json
{
  "success": false,
  "error": {
    "code": "STUDENT_NOT_FOUND",
    "message": "Student not found"
  }
}
```

### GET /api/v1/students
**Purpose**: List students with optional filtering

**Query Parameters**:
- `status`: Filter by status (optional)
- `limit`: Number of results (default: 20, max: 100)
- `offset`: Pagination offset (default: 0)
- `search`: Search by name or student ID (optional)

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "students": [
      {
        "id": "uuid",
        "studentId": "string", 
        "fullName": "string",
        "status": "string",
        "createdAt": "2025-09-28T10:00:00Z"
      }
    ],
    "pagination": {
      "total": 150,
      "limit": 20,
      "offset": 0,
      "hasNext": true
    }
  }
}
```

---

## Registration Session Contracts

### POST /api/v1/registrations
**Purpose**: Create a new registration session

**Request**:
```json
{
  "studentId": "string",
  "administratorId": "string"
}
```

**Response (201 Created)**:
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "studentId": "string",
    "administratorId": "string",
    "status": "inProgress",
    "startedAt": "2025-09-28T10:00:00Z",
    "expiresAt": "2025-09-28T10:10:00Z"
  }
}
```

### PUT /api/v1/registrations/{id}/video
**Purpose**: Upload registration video

**Request**: Multipart form data
- `video`: Video file (MP4, max 50MB)
- `metadata`: JSON string with video metadata

**Metadata JSON**:
```json
{
  "durationMs": 12000,
  "frameRate": 30,
  "resolution": "1920x1080",
  "deviceInfo": "Samsung Galaxy S21"
}
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "videoId": "uuid",
    "processingStatus": "queued"
  }
}
```

### GET /api/v1/registrations/{id}/status
**Purpose**: Get registration processing status

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "status": "inProgress|completed|failed|cancelled",
    "progress": {
      "currentStep": "processing_video",
      "completedSteps": 3,
      "totalSteps": 5,
      "percentage": 60
    },
    "qualityMetrics": {
      "overallQuality": 0.85,
      "poseCoverage": 88.5,
      "selectedFrames": 18
    },
    "errors": []
  }
}
```

### POST /api/v1/registrations/{id}/frames
**Purpose**: Submit selected frames with metadata

**Request**:
```json
{
  "frames": [
    {
      "imageData": "base64_string",
      "timestampMs": 1500,
      "qualityScore": 0.89,
      "poseAngles": {
        "yaw": -15.5,
        "pitch": 5.2,
        "roll": 1.8,
        "confidence": 0.92
      },
      "faceMetrics": {
        "boundingBox": {
          "x": 0.2,
          "y": 0.15,
          "width": 0.6,
          "height": 0.7
        },
        "faceSize": 0.42,
        "sharpnessScore": 0.87,
        "lightingScore": 0.91,
        "symmetryScore": 0.88,
        "hasGlasses": false,
        "hasHat": false,
        "isSmiling": true
      }
    }
  ],
  "qualityMetrics": {
    "overallQuality": 0.85,
    "poseCoverage": {
      "frontal": 95.0,
      "leftProfile": 88.0,
      "rightProfile": 82.0,
      "uptilt": 75.0,
      "downtilt": 90.0,
      "overall": 86.0
    },
    "qualityDistribution": {
      "highQuality": 12,
      "mediumQuality": 6,
      "lowQuality": 0,
      "averageScore": 0.87,
      "standardDeviation": 0.04
    }
  }
}
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "sessionId": "uuid",
    "status": "completed",
    "framesProcessed": 18,
    "completedAt": "2025-09-28T10:05:30Z"
  }
}
```

---

## Export & Sync Contracts

### POST /api/v1/exports
**Purpose**: Create export package for AI system

**Request**:
```json
{
  "sessionId": "string",
  "format": "json|zip",
  "includeOriginalVideo": false
}
```

**Response (201 Created)**:
```json
{
  "success": true,
  "data": {
    "exportId": "uuid",
    "status": "preparing",
    "estimatedCompletionTime": "2025-09-28T10:07:00Z"
  }
}
```

### GET /api/v1/exports/{id}
**Purpose**: Get export package status and download

**Response (200 OK - Ready)**:
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "sessionId": "string",
    "status": "ready",
    "format": "json",
    "fileSize": 2048576,
    "downloadUrl": "https://api.example.com/downloads/uuid",
    "expiresAt": "2025-09-30T10:00:00Z",
    "createdAt": "2025-09-28T10:05:00Z"
  }
}
```

**Response (202 Accepted - Processing)**:
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "status": "preparing",
    "progress": 45,
    "estimatedCompletion": "2025-09-28T10:07:30Z"
  }
}
```

### POST /api/v1/sync/registrations
**Purpose**: Bulk sync registration data

**Request**:
```json
{
  "registrations": [
    {
      "localId": "uuid",
      "studentId": "string",
      "administratorId": "string",
      "completedAt": "2025-09-28T10:05:00Z",
      "qualityScore": 0.85,
      "framesCount": 18,
      "metadata": {}
    }
  ],
  "syncTimestamp": "2025-09-28T11:00:00Z"
}
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "processed": 1,
    "successful": 1,
    "failed": 0,
    "results": [
      {
        "localId": "uuid",
        "remoteId": "uuid",
        "status": "synced"
      }
    ],
    "nextSyncTimestamp": "2025-09-28T11:30:00Z"
  }
}
```

---

## Real-time Communication Contracts (WebSocket)

### Connection: /ws/registration/{sessionId}
**Purpose**: Real-time registration updates

**Authentication**: JWT token in query parameter or header

### Message Types

#### Client → Server Messages

**Start Video Processing**:
```json
{
  "type": "start_processing",
  "data": {
    "videoMetadata": {
      "durationMs": 12000,
      "frameCount": 360
    }
  }
}
```

**Frame Quality Update**:
```json
{
  "type": "frame_quality",
  "data": {
    "frameIndex": 45,
    "qualityScore": 0.87,
    "poseAngles": {
      "yaw": -10.5,
      "pitch": 3.2,
      "roll": 0.8
    },
    "timestamp": "2025-09-28T10:01:30Z"
  }
}
```

#### Server → Client Messages

**Processing Progress**:
```json
{
  "type": "progress_update",
  "data": {
    "step": "extracting_frames",
    "progress": 65,
    "message": "Analyzing frame quality...",
    "timestamp": "2025-09-28T10:01:45Z"
  }
}
```

**Real-time Guidance**:
```json
{
  "type": "pose_guidance", 
  "data": {
    "instruction": "Please turn head slightly to the left",
    "missingCoverage": ["leftProfile", "uptilt"],
    "currentCoverage": 45.0,
    "targetCoverage": 80.0
  }
}
```

**Quality Alert**:
```json
{
  "type": "quality_alert",
  "data": {
    "level": "warning|error",
    "message": "Lighting conditions poor, consider adjusting position",
    "suggestion": "Move closer to window or turn on lights",
    "currentScore": 0.72
  }
}
```

**Session Complete**:
```json
{
  "type": "session_complete",
  "data": {
    "sessionId": "uuid",
    "finalQuality": 0.89,
    "selectedFrames": 20,
    "poseCoverage": 87.5,
    "status": "completed"
  }
}
```

---

## Error Response Schema

### Standard Error Format
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": {},
    "timestamp": "2025-09-28T10:00:00Z",
    "requestId": "uuid"
  }
}
```

### Common Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `INVALID_REQUEST` | 400 | Request validation failed |
| `AUTH_REQUIRED` | 401 | Authentication required |
| `AUTH_FAILED` | 401 | Invalid credentials |
| `ACCESS_DENIED` | 403 | Insufficient permissions |
| `RESOURCE_NOT_FOUND` | 404 | Requested resource not found |
| `RESOURCE_CONFLICT` | 409 | Resource already exists |
| `VALIDATION_ERROR` | 422 | Input validation failed |
| `RATE_LIMITED` | 429 | Too many requests |
| `SERVER_ERROR` | 500 | Internal server error |
| `SERVICE_UNAVAILABLE` | 503 | Service temporarily unavailable |

### Validation Error Details
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
    "details": {
      "field_errors": [
        {
          "field": "studentId",
          "code": "REQUIRED",
          "message": "Student ID is required"
        },
        {
          "field": "email",
          "code": "INVALID_FORMAT", 
          "message": "Invalid email format"
        }
      ]
    }
  }
}
```

---

## Rate Limiting

### Default Limits
- Authentication endpoints: 5 requests per minute per IP
- Data endpoints: 100 requests per minute per authenticated user
- Upload endpoints: 10 requests per minute per authenticated user
- WebSocket connections: 5 concurrent connections per user

### Rate Limit Headers
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1632847200
```

---

## Versioning Strategy

### API Versioning
- Version in URL path: `/api/v1/`
- Backward compatibility maintained for at least 2 major versions
- Deprecation warnings in response headers

### Response Headers
```
API-Version: 1.0
API-Deprecation-Date: 2026-01-01
API-Sunset-Date: 2026-06-01
```

This contract specification provides a complete API definition for the mobile registration app with proper error handling, real-time communication, and integration capabilities.