# Mobile App & Backend Integration Plan
## Vision-Based Class Attendance System

**Version:** 1.0  
**Date:** November 5, 2025  
**Status:** Planning Phase

---

## 📋 Executive Summary

This document outlines the comprehensive integration strategy between the **HADIR Mobile App** (Flutter) and the **Backend Face Processing System** (Flask/Python). The integration enables automatic synchronization of student registration data and face images from the mobile app to the backend server, where face embeddings are generated, classifiers are trained, and the data is prepared for web-based face recognition attendance marking.

### Key Objectives
1. **Seamless Data Sync**: Automatically sync student data and images from mobile to backend
2. **Background Processing**: Process face embeddings and train classifiers on the backend
3. **Status Visibility**: Provide real-time sync status and processing feedback
4. **Error Resilience**: Implement robust error handling and retry mechanisms
5. **Offline Support**: Queue sync operations when backend is unavailable
6. **Audit Trail**: Comprehensive logging for debugging and compliance

---

## 🏗️ System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        HADIR MOBILE APP (Flutter)                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────────┐      ┌──────────────────────────┐         │
│  │  Registration      │      │  Student Management      │         │
│  │  Module            │──────│  Module                  │         │
│  └────────┬───────────┘      └──────────┬───────────────┘         │
│           │                              │                          │
│           │         ┌────────────────────┴───────┐                 │
│           └────────→│   Sync Service (NEW)       │                 │
│                     │  • Queue Management        │                 │
│                     │  • Status Tracking         │                 │
│                     │  • Error Handling          │                 │
│                     │  • Comprehensive Logging   │                 │
│                     └────────────┬───────────────┘                 │
│                                  │                                  │
│  ┌──────────────────────────────┴───────────────────────┐         │
│  │         Local SQLite Database                        │         │
│  │  • students table (with sync_status)                 │         │
│  │  • selected_frames table (images)                    │         │
│  │  • sync_queue table (pending operations)             │         │
│  │  • sync_log table (audit trail)                      │         │
│  └──────────────────────────────────────────────────────┘         │
│                                  │                                  │
└──────────────────────────────────┼──────────────────────────────────┘
                                   │
                         HTTPS/REST API
                                   │
┌──────────────────────────────────┼──────────────────────────────────┐
│                                  ▼                                   │
│                    BACKEND SERVER (Flask/Python)                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────────────────────────────────────────────┐        │
│  │            NEW SYNC API ENDPOINTS                       │        │
│  │  POST /api/sync/student                                 │        │
│  │  POST /api/sync/images                                  │        │
│  │  GET  /api/sync/status/<sync_id>                       │        │
│  │  GET  /api/sync/results/<student_id>                   │        │
│  │  POST /api/sync/batch                                   │        │
│  └────────────────┬───────────────────────────────────────┘        │
│                   │                                                  │
│  ┌────────────────┴───────────────────────────────────┐            │
│  │         Background Processing Queue                │            │
│  │  • Face Detection (RetinaFace)                     │            │
│  │  • Image Augmentation (20+ variations)             │            │
│  │  • Embedding Generation (MobileFaceNet)            │            │
│  │  • Classifier Training (SVM)                       │            │
│  │  • Status Updates                                  │            │
│  └────────────────┬───────────────────────────────────┘            │
│                   │                                                  │
│  ┌────────────────┴───────────────────────────────────┐            │
│  │         Backend Storage                             │            │
│  │  • database.json (student records)                  │            │
│  │  • processed_faces/<student_id>/embeddings.npy      │            │
│  │  • classifiers/<class_id>.pkl                       │            │
│  │  • sync_log.json (audit trail)                      │            │
│  └─────────────────────────────────────────────────────┘            │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
                                   │
                                   │ Used by
                                   ▼
                    ┌─────────────────────────────┐
                    │   Web Face Recognition App  │
                    │   (Future Implementation)   │
                    └─────────────────────────────┘
```

---

## 🔄 Integration Flow

### 1. Student Registration Flow (Mobile → Backend)

```
Mobile App                          Backend Server
    │                                      │
    │ 1. Student completes registration   │
    │    (personal info + face images)    │
    │                                      │
    │ 2. Data saved to local SQLite DB    │
    │    status = 'pending_sync'          │
    │                                      │
    │ 3. SyncService detects new record   │
    │    (triggered on app resume)        │
    │                                      │
    ├─ 4. POST /api/sync/student ─────────→│
    │    {student_id, name, email, etc}    │
    │                                      │
    │                                      │ 5. Validate & create student record
    │                                      │    Generate sync_id
    │                                      │    Return sync_id
    │←─── 6. Response {sync_id} ───────────┤
    │                                      │
    │ 7. Update local: sync_id saved       │
    │                                      │
    ├─ 8. POST /api/sync/images ──────────→│
    │    {sync_id, images[]}               │
    │                                      │
    │                                      │ 9. Save images
    │                                      │    Queue processing job
    │                                      │    Status = 'processing'
    │←─── 10. Response {job_id} ───────────┤
    │                                      │
    │ 11. Status = 'synced'                │
    │     Poll for results                 │
    │                                      │
    │                                      │ 12. Background Processing:
    │                                      │     - Face detection
    │                                      │     - Image augmentation
    │                                      │     - Embedding generation
    │                                      │     - Classifier training
    │                                      │     Status = 'completed'
    │                                      │
    ├─ 13. GET /api/sync/status/{sync_id}─→│
    │                                      │
    │←─── 14. Response {status, progress}──┤
    │                                      │
    │ 15. Update local: status='completed' │
    │     Display success notification     │
    │                                      │
```

### 2. Sync Trigger Scenarios

| Trigger Event | Description | Priority |
|--------------|-------------|----------|
| **App Resume** | When app comes to foreground | High |
| **Registration Complete** | Immediately after student registration | High |
| **Manual Sync** | User-initiated sync button | High |
| **Periodic Sync** | Every 30 minutes (configurable) | Medium |
| **Network Available** | When internet connection restored | Medium |
| **Retry Queue** | Failed sync attempts (exponential backoff) | Low |

---

## 📊 Database Schema Updates

### Mobile App (SQLite) - New/Modified Tables

#### 1. Students Table - Add Sync Columns
```sql
ALTER TABLE students ADD COLUMN sync_status TEXT DEFAULT 'not_synced';
ALTER TABLE students ADD COLUMN sync_id TEXT;
ALTER TABLE students ADD COLUMN backend_student_id TEXT;
ALTER TABLE students ADD COLUMN last_sync_attempt TEXT;
ALTER TABLE students ADD COLUMN last_sync_success TEXT;
ALTER TABLE students ADD COLUMN sync_error TEXT;
ALTER TABLE students ADD COLUMN processing_status TEXT;
ALTER TABLE students ADD COLUMN sync_retry_count INTEGER DEFAULT 0;
```

**Sync Status Values:**
- `not_synced` - New record, not sent to backend
- `syncing` - Currently uploading to backend
- `synced` - Successfully sent to backend
- `processing` - Backend is processing images
- `completed` - Backend processing complete
- `failed` - Sync failed (see sync_error)

#### 2. Sync Queue Table (NEW)
```sql
CREATE TABLE sync_queue (
  id TEXT PRIMARY KEY,
  student_id TEXT NOT NULL,
  operation_type TEXT NOT NULL, -- 'register', 'update', 'images'
  payload TEXT NOT NULL, -- JSON data
  priority INTEGER DEFAULT 5,
  created_at TEXT NOT NULL,
  scheduled_for TEXT NOT NULL,
  retry_count INTEGER DEFAULT 0,
  last_error TEXT,
  status TEXT DEFAULT 'pending', -- 'pending', 'in_progress', 'completed', 'failed'
  FOREIGN KEY (student_id) REFERENCES students (id)
);

CREATE INDEX idx_sync_queue_status ON sync_queue (status);
CREATE INDEX idx_sync_queue_scheduled ON sync_queue (scheduled_for);
```

#### 3. Sync Log Table (NEW)
```sql
CREATE TABLE sync_log (
  id TEXT PRIMARY KEY,
  student_id TEXT,
  sync_id TEXT,
  operation_type TEXT NOT NULL,
  status TEXT NOT NULL, -- 'started', 'success', 'error'
  request_data TEXT, -- JSON
  response_data TEXT, -- JSON
  error_message TEXT,
  duration_ms INTEGER,
  timestamp TEXT NOT NULL,
  FOREIGN KEY (student_id) REFERENCES students (id)
);

CREATE INDEX idx_sync_log_student ON sync_log (student_id);
CREATE INDEX idx_sync_log_timestamp ON sync_log (timestamp DESC);
CREATE INDEX idx_sync_log_status ON sync_log (status);
```

### Backend (JSON/Files) - New Structure

#### sync_registry.json
```json
{
  "syncs": {
    "sync_id_123": {
      "sync_id": "sync_id_123",
      "mobile_student_id": "uuid-from-mobile",
      "backend_student_id": "S12345",
      "status": "completed",
      "created_at": "2025-11-05T10:30:00Z",
      "updated_at": "2025-11-05T10:35:00Z",
      "student_data": {
        "student_id": "S12345",
        "name": "John Doe",
        "email": "john@university.edu"
      },
      "processing_stages": {
        "student_created": {
          "status": "completed",
          "timestamp": "2025-11-05T10:30:05Z"
        },
        "images_received": {
          "status": "completed",
          "image_count": 5,
          "timestamp": "2025-11-05T10:31:00Z"
        },
        "face_detection": {
          "status": "completed",
          "faces_detected": 5,
          "timestamp": "2025-11-05T10:32:00Z"
        },
        "augmentation": {
          "status": "completed",
          "augmented_count": 100,
          "timestamp": "2025-11-05T10:33:00Z"
        },
        "embedding_generation": {
          "status": "completed",
          "embeddings_count": 100,
          "timestamp": "2025-11-05T10:34:00Z"
        },
        "classifier_training": {
          "status": "completed",
          "accuracy": 98.5,
          "timestamp": "2025-11-05T10:35:00Z"
        }
      },
      "error": null
    }
  }
}
```

---

## 🛠️ Implementation Components

### A. Mobile App Components (Flutter)

#### 1. Sync Service (`lib/core/services/sync_service.dart`)
```dart
class SyncService {
  // Core sync operations
  Future<SyncResult> syncStudent(Student student);
  Future<SyncResult> syncImages(String syncId, List<File> images);
  Future<SyncStatusResponse> checkSyncStatus(String syncId);
  
  // Queue management
  Future<void> enqueueSyncOperation(SyncOperation operation);
  Future<void> processSyncQueue();
  
  // Status tracking
  Stream<SyncStatus> watchStudentSyncStatus(String studentId);
  
  // Error handling
  Future<void> retryFailedSyncs();
  Future<void> handleSyncError(String studentId, Exception error);
}
```

#### 2. Sync Models (`lib/core/models/sync_models.dart`)
```dart
class SyncOperation {
  final String id;
  final String studentId;
  final SyncOperationType type;
  final Map<String, dynamic> payload;
  final int priority;
  final DateTime scheduledFor;
  final int retryCount;
}

enum SyncOperationType {
  registerStudent,
  uploadImages,
  updateStudent,
}

class SyncResult {
  final bool success;
  final String? syncId;
  final String? jobId;
  final String? error;
  final Map<String, dynamic>? metadata;
}

class SyncStatusResponse {
  final String syncId;
  final SyncStatus status;
  final int progress; // 0-100
  final ProcessingStage currentStage;
  final Map<String, dynamic>? results;
  final String? error;
}

enum SyncStatus {
  notSynced,
  syncing,
  synced,
  processing,
  completed,
  failed,
}
```

#### 3. Backend API Client (`lib/core/services/backend_api_client.dart`)
```dart
class BackendApiClient {
  final Dio _dio;
  
  // Sync endpoints
  Future<Response> syncStudent(StudentSyncRequest request);
  Future<Response> syncImages(ImageSyncRequest request);
  Future<Response> getSyncStatus(String syncId);
  Future<Response> getSyncResults(String studentId);
  Future<Response> batchSync(BatchSyncRequest request);
  
  // Health check
  Future<bool> checkBackendAvailability();
}
```

#### 4. Sync Provider (`lib/core/providers/sync_provider.dart`)
```dart
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    apiClient: ref.watch(backendApiClientProvider),
    database: ref.watch(databaseProvider),
    logger: ref.watch(loggerProvider),
  );
});

final syncStatusProvider = StreamProvider.family<SyncStatus, String>(
  (ref, studentId) {
    return ref.watch(syncServiceProvider).watchStudentSyncStatus(studentId);
  },
);
```

### B. Backend Components (Python/Flask)

#### 1. Sync API Endpoints (`backend/sync_api.py`)
```python
from flask import Blueprint, request, jsonify
from flask_restx import Namespace, Resource

sync_ns = Namespace('sync', description='Mobile app synchronization operations')

@sync_ns.route('/student')
class SyncStudent(Resource):
    """Sync student data from mobile app"""
    
    def post(self):
        """
        Create/update student record from mobile app
        
        Request Body:
        {
          "mobile_student_id": "uuid",
          "student_id": "S12345",
          "name": "John Doe",
          "email": "john@university.edu",
          "department": "CS",
          "metadata": {...}
        }
        
        Response:
        {
          "success": true,
          "sync_id": "sync_123",
          "backend_student_id": "S12345",
          "message": "Student record created"
        }
        """
        pass

@sync_ns.route('/images')
class SyncImages(Resource):
    """Upload student face images"""
    
    def post(self):
        """
        Upload student face images for processing
        
        Form Data:
        - sync_id: string
        - images: file[] (multipart)
        
        Response:
        {
          "success": true,
          "job_id": "job_456",
          "images_received": 5,
          "status": "queued",
          "message": "Images queued for processing"
        }
        """
        pass

@sync_ns.route('/status/<string:sync_id>')
class SyncStatus(Resource):
    """Get sync operation status"""
    
    def get(self, sync_id):
        """
        Get current status of sync operation
        
        Response:
        {
          "sync_id": "sync_123",
          "status": "processing",
          "progress": 75,
          "current_stage": "embedding_generation",
          "stages": {
            "student_created": {"status": "completed", "timestamp": "..."},
            "images_received": {"status": "completed", "timestamp": "..."},
            "face_detection": {"status": "completed", "faces": 5},
            "augmentation": {"status": "completed", "augmented": 100},
            "embedding_generation": {"status": "in_progress", "progress": 75}
          },
          "estimated_completion": "2025-11-05T10:35:00Z"
        }
        """
        pass
```

#### 2. Background Processing Queue (`backend/processing_queue.py`)
```python
import queue
import threading
from dataclasses import dataclass
from typing import Optional, Dict, Any

@dataclass
class ProcessingJob:
    job_id: str
    sync_id: str
    student_id: str
    images_path: str
    status: str = 'queued'
    progress: int = 0
    error: Optional[str] = None
    metadata: Dict[str, Any] = None

class ProcessingQueue:
    def __init__(self, num_workers=2):
        self.queue = queue.Queue()
        self.workers = []
        self.jobs_status = {}
        self.num_workers = num_workers
        
    def start(self):
        """Start worker threads"""
        for i in range(self.num_workers):
            worker = threading.Thread(
                target=self._worker,
                name=f"ProcessingWorker-{i}",
                daemon=True
            )
            worker.start()
            self.workers.append(worker)
    
    def enqueue(self, job: ProcessingJob):
        """Add job to queue"""
        self.jobs_status[job.job_id] = job
        self.queue.put(job)
        logger.info(f"Job {job.job_id} enqueued for student {job.student_id}")
    
    def _worker(self):
        """Worker thread to process jobs"""
        while True:
            job = self.queue.get()
            try:
                self._process_job(job)
            except Exception as e:
                logger.error(f"Job {job.job_id} failed: {e}")
                job.status = 'failed'
                job.error = str(e)
            finally:
                self.queue.task_done()
    
    def _process_job(self, job: ProcessingJob):
        """Process a single job"""
        # Implementation in next section
        pass
```

#### 3. Sync Registry Manager (`backend/sync_registry.py`)
```python
import json
import os
from datetime import datetime
from typing import Dict, Optional

class SyncRegistry:
    def __init__(self, registry_file='sync_registry.json'):
        self.registry_file = registry_file
        self.registry = self._load()
    
    def create_sync(self, mobile_student_id: str, backend_student_id: str, 
                    student_data: Dict) -> str:
        """Create new sync record"""
        sync_id = self._generate_sync_id()
        
        self.registry['syncs'][sync_id] = {
            'sync_id': sync_id,
            'mobile_student_id': mobile_student_id,
            'backend_student_id': backend_student_id,
            'status': 'created',
            'created_at': datetime.utcnow().isoformat(),
            'updated_at': datetime.utcnow().isoformat(),
            'student_data': student_data,
            'processing_stages': {},
            'error': None
        }
        
        self._save()
        logger.info(f"Created sync record: {sync_id}")
        return sync_id
    
    def update_stage(self, sync_id: str, stage: str, 
                     status: str, metadata: Optional[Dict] = None):
        """Update processing stage"""
        if sync_id not in self.registry['syncs']:
            raise ValueError(f"Sync {sync_id} not found")
        
        sync = self.registry['syncs'][sync_id]
        sync['processing_stages'][stage] = {
            'status': status,
            'timestamp': datetime.utcnow().isoformat(),
            **(metadata or {})
        }
        sync['updated_at'] = datetime.utcnow().isoformat()
        
        self._save()
        logger.info(f"Sync {sync_id} stage {stage}: {status}")
```

---

## 📝 Comprehensive Logging Strategy

### Mobile App Logging

#### Log Categories
1. **Sync Operations** (`SYNC`)
   - Sync initiated
   - Queue operations
   - API requests/responses
   - Status updates

2. **Network** (`NETWORK`)
   - HTTP requests
   - Response times
   - Connection errors
   - Retry attempts

3. **Database** (`DATABASE`)
   - Record inserts/updates
   - Query performance
   - Migration events

4. **Errors** (`ERROR`)
   - Exception details
   - Stack traces
   - Context information

#### Log Format
```dart
class AppLogger {
  static void syncOperation(
    String operation,
    String studentId, {
    Map<String, dynamic>? metadata,
  }) {
    final log = {
      'timestamp': DateTime.now().toIso8601String(),
      'level': 'INFO',
      'category': 'SYNC',
      'operation': operation,
      'student_id': studentId,
      'metadata': metadata,
    };
    
    print('[SYNC] $operation - Student: $studentId');
    _writeToFile(log);
  }
  
  static void error(
    String message,
    Exception error, {
    StackTrace? stackTrace,
  }) {
    final log = {
      'timestamp': DateTime.now().toIso8601String(),
      'level': 'ERROR',
      'message': message,
      'error': error.toString(),
      'stack_trace': stackTrace?.toString(),
    };
    
    print('[ERROR] $message: $error');
    _writeToFile(log);
    _reportToAnalytics(log);
  }
}
```

#### Example Log Output
```
[2025-11-05 10:30:00] [INFO] [SYNC] Sync initiated for student: uuid-123
[2025-11-05 10:30:01] [INFO] [NETWORK] POST /api/sync/student - 200 OK (234ms)
[2025-11-05 10:30:01] [INFO] [DATABASE] Updated student sync_status: syncing -> synced
[2025-11-05 10:30:02] [INFO] [NETWORK] POST /api/sync/images - 202 Accepted (1.2s)
[2025-11-05 10:30:02] [INFO] [SYNC] Images uploaded successfully, job_id: job_456
[2025-11-05 10:30:05] [ERROR] [NETWORK] GET /api/sync/status/sync_123 - Connection timeout
[2025-11-05 10:30:05] [INFO] [SYNC] Retry scheduled for 10:30:30 (attempt 1/3)
```

### Backend Logging

#### Log Configuration (`backend/logging_config.py`)
```python
import logging
import json
from datetime import datetime
from logging.handlers import RotatingFileHandler

class StructuredLogger:
    def __init__(self, name):
        self.logger = logging.getLogger(name)
        self.logger.setLevel(logging.INFO)
        
        # Console handler
        console = logging.StreamHandler()
        console.setFormatter(ColoredFormatter())
        self.logger.addHandler(console)
        
        # File handler (rotating)
        file_handler = RotatingFileHandler(
            'logs/sync_operations.log',
            maxBytes=10*1024*1024,  # 10MB
            backupCount=10
        )
        file_handler.setFormatter(JSONFormatter())
        self.logger.addHandler(file_handler)
    
    def sync_started(self, sync_id, student_id, operation):
        self.logger.info(
            'Sync operation started',
            extra={
                'sync_id': sync_id,
                'student_id': student_id,
                'operation': operation,
                'timestamp': datetime.utcnow().isoformat()
            }
        )
    
    def processing_stage(self, sync_id, stage, status, **kwargs):
        self.logger.info(
            f'Processing stage: {stage}',
            extra={
                'sync_id': sync_id,
                'stage': stage,
                'status': status,
                **kwargs
            }
        )
```

#### Example Log Output
```json
{
  "timestamp": "2025-11-05T10:30:00Z",
  "level": "INFO",
  "message": "Sync operation started",
  "sync_id": "sync_123",
  "student_id": "S12345",
  "operation": "register",
  "source": "sync_api.py:45"
}

{
  "timestamp": "2025-11-05T10:32:15Z",
  "level": "INFO",
  "message": "Processing stage: face_detection",
  "sync_id": "sync_123",
  "stage": "face_detection",
  "status": "completed",
  "faces_detected": 5,
  "duration_ms": 2150
}

{
  "timestamp": "2025-11-05T10:35:30Z",
  "level": "INFO",
  "message": "Processing stage: classifier_training",
  "sync_id": "sync_123",
  "stage": "classifier_training",
  "status": "completed",
  "accuracy": 98.5,
  "training_samples": 100,
  "duration_ms": 3450
}
```

---

## 🚨 Error Handling Strategy

### Error Categories

#### 1. Network Errors
**Mobile App:**
- Connection timeout → Retry with exponential backoff
- No internet → Queue for later, show offline notice
- Server unavailable → Retry, check backend health
- 5xx errors → Retry after delay

**Backend:**
- Request validation → Return 400 with detailed error
- Authentication → Return 401
- Resource not found → Return 404
- Internal error → Return 500, log for investigation

#### 2. Processing Errors
**Backend:**
- No face detected → Mark as failed, notify mobile
- Poor image quality → Request re-capture
- Augmentation failed → Log error, continue with original
- Embedding generation failed → Retry with different model params
- Classifier training failed → Log error, use previous classifier

#### 3. Data Errors
**Mobile:**
- Missing required fields → Validate before sync
- Image file corrupted → Re-capture or skip
- Database error → Rollback transaction

**Backend:**
- Duplicate student → Return conflict, use existing
- Invalid data format → Return validation error
- Storage full → Alert admin, cleanup old files

### Error Response Format

```json
{
  "success": false,
  "error": {
    "code": "FACE_NOT_DETECTED",
    "message": "No face detected in uploaded images",
    "details": {
      "images_processed": 5,
      "faces_found": 0
    },
    "suggestion": "Please re-capture images with clear face visibility",
    "retry_after": null,
    "is_retriable": false
  },
  "timestamp": "2025-11-05T10:30:00Z",
  "request_id": "req_789"
}
```

### Retry Logic

```dart
// Mobile App
class RetryPolicy {
  static const maxRetries = 3;
  static const initialDelaySeconds = 5;
  static const maxDelaySeconds = 60;
  
  static Duration getRetryDelay(int attemptNumber) {
    // Exponential backoff: 5s, 10s, 20s, 40s (capped at 60s)
    final delay = initialDelaySeconds * pow(2, attemptNumber - 1);
    return Duration(seconds: min(delay.toInt(), maxDelaySeconds));
  }
  
  static bool shouldRetry(Exception error, int attemptNumber) {
    if (attemptNumber >= maxRetries) return false;
    
    if (error is NetworkException) {
      return error.isRetriable;
    }
    
    return false;
  }
}
```

---

## 🔒 Security Considerations

### 1. Authentication
- Mobile app uses JWT tokens for API access
- Tokens refreshed automatically before expiry
- Secure token storage using FlutterSecureStorage

### 2. Data Encryption
- Images encrypted during transmission (HTTPS)
- Sensitive data encrypted at rest in SQLite
- Face embeddings are encrypted on backend storage

### 3. Authorization
- Mobile app can only access own student data
- Admin role required for backend management
- Rate limiting on sync endpoints

### 4. Privacy
- Student consent required before sync
- Data retention policies enforced
- GDPR compliance for data deletion

---

## 📊 Monitoring & Metrics

### Mobile App Metrics
- Sync success rate
- Average sync duration
- Queue size
- Network failure rate
- Retry attempts

### Backend Metrics
- Sync requests per minute
- Processing queue length
- Average processing time per stage
- Face detection success rate
- Classifier accuracy
- Storage usage

### Dashboards
- Real-time sync status dashboard
- Processing pipeline visualization
- Error rate trends
- Performance metrics

---

## 🧪 Testing Strategy

### Unit Tests
- SyncService methods
- API client methods
- Error handling logic
- Retry mechanisms

### Integration Tests
- End-to-end sync flow
- Backend processing pipeline
- Database operations
- API endpoint validation

### Performance Tests
- Large batch sync (100+ students)
- Concurrent syncs
- Network failure scenarios
- Backend under load

---

## 📱 User Experience

### Status Indicators
- **Not Synced** - Orange dot, "Pending sync"
- **Syncing** - Blue spinning, "Uploading..."
- **Processing** - Purple pulsing, "Processing on server..."
- **Completed** - Green checkmark, "Ready for attendance"
- **Failed** - Red exclamation, "Sync failed - Tap to retry"

### Notifications
- Sync completed successfully
- Processing complete (ready for attendance)
- Sync failed (with retry option)
- Offline mode activated

### Manual Sync Button
- Pull-to-refresh gesture on student list
- Sync button in app settings
- Shows progress during sync
- Displays last sync time

---

## 🚀 Implementation Phases

### Phase 1: Foundation (Week 1)
- ✅ Create integration plan document
- Backend: Create sync API endpoints skeleton
- Mobile: Create SyncService structure
- Database: Add sync-related tables and columns

### Phase 2: Core Sync (Week 2)
- Implement student data sync endpoint
- Implement image upload endpoint
- Add background processing queue
- Implement basic error handling

### Phase 3: Status & Logging (Week 3)
- Implement status tracking system
- Add comprehensive logging (mobile & backend)
- Create sync registry manager
- Implement status polling

### Phase 4: Error Handling (Week 4)
- Implement retry logic
- Add offline queue
- Handle edge cases
- Add detailed error messages

### Phase 5: Testing & Polish (Week 5)
- Write unit tests
- Conduct integration testing
- Performance optimization
- UI/UX improvements

### Phase 6: Deployment (Week 6)
- Deploy backend updates
- Release mobile app update
- Monitor sync operations
- Bug fixes and improvements

---

## 📋 Configuration

### Mobile App Config (`lib/core/config/sync_config.dart`)
```dart
class SyncConfig {
  // Backend server
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:5000',
  );
  
  // Sync settings
  static const Duration syncInterval = Duration(minutes: 30);
  static const Duration statusPollInterval = Duration(seconds: 10);
  static const int maxImageBatchSize = 10;
  static const int maxRetryAttempts = 3;
  static const Duration initialRetryDelay = Duration(seconds: 5);
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);
  
  // Logging
  static const bool enableDetailedLogging = true;
  static const int maxLogFileSizeMB = 10;
}
```

### Backend Config (`backend/sync_config.py`)
```python
class SyncConfig:
    # Processing
    MAX_CONCURRENT_JOBS = 2
    JOB_TIMEOUT_SECONDS = 600  # 10 minutes
    
    # Storage
    SYNC_IMAGES_FOLDER = 'uploads/sync_images'
    MAX_IMAGE_SIZE_MB = 5
    ALLOWED_IMAGE_FORMATS = ['jpg', 'jpeg', 'png']
    
    # Logging
    LOG_FOLDER = 'logs'
    LOG_LEVEL = 'INFO'
    LOG_ROTATION_SIZE_MB = 10
    LOG_RETENTION_DAYS = 30
    
    # Rate limiting
    SYNC_RATE_LIMIT = '100/hour'
    IMAGE_UPLOAD_RATE_LIMIT = '50/hour'
```

---

## 🎯 Success Criteria

✅ **Functional Requirements**
- [ ] Students can be synced from mobile to backend automatically
- [ ] Images are processed and embeddings generated successfully
- [ ] Sync status is visible and updated in real-time
- [ ] Failed syncs retry automatically with exponential backoff
- [ ] Offline mode queues operations for later sync
- [ ] Admin can view sync operations in backend

✅ **Performance Requirements**
- [ ] Sync completes within 30 seconds for single student
- [ ] Backend processes images within 5 minutes
- [ ] Mobile app remains responsive during sync
- [ ] Database queries execute in < 100ms
- [ ] API endpoints respond in < 500ms

✅ **Quality Requirements**
- [ ] 95%+ sync success rate
- [ ] < 1% data loss during sync
- [ ] Comprehensive logs for debugging
- [ ] All edge cases handled gracefully
- [ ] Unit test coverage > 80%

---

## 📚 References

### Documentation
- [Backend API Documentation](./backend/README.md)
- [Mobile App Architecture](./HADIR_mobile/PROJECT_STRUCTURE.md)
- [Face Processing Pipeline](./backend/PIPELINE_README.md)

### External Resources
- Flask-RESTX Documentation
- Flutter Dio HTTP Client
- SQLite Database Design
- MobileFaceNet Paper

---

## 🤝 Contributing

### Code Review Checklist
- [ ] Comprehensive logging added
- [ ] Error handling implemented
- [ ] Unit tests written
- [ ] Documentation updated
- [ ] Performance impact assessed

### Commit Message Format
```
[SYNC] Brief description

- Detailed change 1
- Detailed change 2

Refs: #issue_number
```

---

## 📞 Support

For questions or issues:
- Create GitHub issue with [SYNC] prefix
- Check troubleshooting guide
- Review sync logs for debugging

---

**Document Version:** 1.0  
**Last Updated:** November 5, 2025  
**Next Review:** December 5, 2025
