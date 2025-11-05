# Mobile App & Backend Integration Plan
## Vision-Based Class Attendance System

**Version:** 2.0 - FAST TRACK (1-Week Sprint)  
**Date:** November 5, 2025  
**Status:** Active Development  
**Timeline:** 7 Days (November 5-12, 2025)

---

## 🚨 IMPORTANT: Existing API Discovery

**Good News:** The backend already has a working API endpoint that accepts face images!
- ✅ `POST /api/students/` - Registers students with face images
- ✅ Background processing (face detection, augmentation, embeddings)
- ✅ Status tracking in database
- ✅ Error handling and logging

**Impact on Timeline:** This reduces implementation time from 6 weeks to **1 week** by leveraging existing infrastructure.

See [EXISTING_API_ANALYSIS.md](./EXISTING_API_ANALYSIS.md) for full details.

---

## 📋 Executive Summary

This document outlines the **fast-track integration strategy** between the **HADIR Mobile App** (Flutter) and the **Backend Face Processing System** (Flask/Python). By leveraging the existing `/api/students/` endpoint, we can achieve full integration in **1 week** instead of 6 weeks.

### Key Objectives (Updated for 1-Week Sprint)
1. **Seamless Data Sync**: Use existing API to sync student data and images from mobile to backend
2. **Background Processing**: Already implemented - face embeddings and processing work out of the box
3. **Status Visibility**: Implement lightweight status polling using existing database fields
4. **Error Resilience**: Basic retry logic with exponential backoff
5. **Essential Logging**: Focus on critical sync operations only
6. **MVP Feature Set**: Deliver working solution, optimize later

---

## 🏗️ System Architecture Overview (Fast-Track Version)

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
│                     │  • Simple API Client       │◄─── 1 Week Sprint
│                     │  • Status Polling          │                 │
│                     │  • Basic Error Handling    │                 │
│                     │  • Essential Logging       │                 │
│                     └────────────┬───────────────┘                 │
│                                  │                                  │
│  ┌──────────────────────────────┴───────────────────────┐         │
│  │         Local SQLite Database (Minimal Changes)      │         │
│  │  • students table (add sync_status column)           │         │
│  │  • selected_frames table (existing)                  │         │
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
│  │        ✅ EXISTING API (Already Working!)              │        │
│  │  POST /api/students/  ◄─── Use this! No changes needed │        │
│  │    • Accepts student data + face image                 │        │
│  │    • Background processing (face detection, etc.)      │        │
│  │    • Status tracking in database.json                  │        │
│  └────────────────┬───────────────────────────────────────┘        │
│                   │                                                  │
│  ┌────────────────┴───────────────────────────────────┐            │
│  │    ✅ Background Processing (Already Implemented!)  │            │
│  │  • Face Detection (RetinaFace)                     │            │
│  │  • Image Augmentation (20 variations)              │            │
│  │  • Embedding Generation (MobileFaceNet)            │            │
│  │  • Status Updates (processing_status field)        │            │
│  └────────────────┬───────────────────────────────────┘            │
│                   │                                                  │
│  ┌────────────────┴───────────────────────────────────┐            │
│  │    ✅ Backend Storage (Already Working!)           │            │
│  │  • database.json (student records)                  │            │
│  │  • processed_faces/<student_id>/embeddings.npy      │            │
│  │  • classifiers/<class_id>.pkl                       │            │
│  └─────────────────────────────────────────────────────┘            │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
                                   │
                                   │ Used by
                                   ▼
                    ┌─────────────────────────────┐
                    │   Web Face Recognition App  │
                    │   (Ready to use!)           │
                    └─────────────────────────────┘
```

**Key Changes from Original Plan:**
- ❌ No new backend endpoints needed (use existing `/api/students/`)
- ❌ No background processing queue (already implemented)
- ❌ No sync registry (use existing database.json)
- ✅ Focus only on mobile app integration
- ✅ Minimal database changes
- ✅ Leverage 80% of existing infrastructure

---

## 🔄 Integration Flow (Fast-Track Version)

### 1. Student Registration Flow (Mobile → Backend) - SIMPLIFIED

```
Mobile App                          Backend Server (Existing API)
    │                                      │
    │ 1. Student completes registration   │
    │    (personal info + face images)    │
    │                                      │
    │ 2. Data saved to local SQLite DB    │
    │    sync_status = 'not_synced'       │
    │                                      │
    │ 3. SyncService triggered             │
    │    (on app resume or manual)        │
    │                                      │
    ├─ 4. POST /api/students/ ────────────→│ ✅ EXISTING ENDPOINT!
    │    FormData:                         │
    │    - student_id                      │
    │    - name, email, department         │
    │    - image file                      │
    │                                      │
    │                                      │ 5. ✅ Save student to database.json
    │                                      │    Save image to uploads/students/
    │                                      │    Start background processing
    │                                      │    Return student record
    │←─── 6. Response {student, uuid} ─────┤
    │                                      │
    │ 7. Update local:                     │
    │    sync_status = 'synced'            │
    │    backend_student_id = student_id   │
    │                                      │
    │ 8. Start status polling (optional)   │
    │                                      │
    │                                      │ 9. ✅ Background Processing:
    │                                      │    (Already implemented!)
    │                                      │     - Face detection
    │                                      │     - Image augmentation
    │                                      │     - Embedding generation
    │                                      │    Update: processing_status
    │                                      │
    ├─ 10. GET /api/students/{id} ────────→│ ✅ EXISTING ENDPOINT!
    │     (poll every 10 seconds)          │
    │                                      │
    │←─── 11. Response {processing_status}─┤
    │      "pending" | "completed" | "failed"
    │                                      │
    │ 12. Update local when completed      │
    │     Display success notification     │
    │                                      │
```

**Key Simplifications:**
- ✅ Only **2 API endpoints** needed (both already exist!)
- ✅ No sync_id tracking needed
- ✅ Use student_id for correlation
- ✅ Simpler status: not_synced → synced → (poll for) completed
- ⚡ **90% less complexity** than original plan

### 2. Sync Trigger Scenarios (Fast-Track)

| Trigger Event | Description | Priority | Implementation |
|--------------|-------------|----------|----------------|
| **Registration Complete** | Immediately after student registration | High | ✅ Day 2 |
| **Manual Sync** | User-initiated sync button | High | ✅ Day 3 |
| **App Resume** | When app comes to foreground | Medium | ⚠️ Nice-to-have |
| **Retry on Failure** | Automatic retry (3 attempts) | Medium | ✅ Day 4 |

**Removed for 1-week timeline:**
- ❌ Periodic sync (not essential)
- ❌ Network change detection (can add later)
- ❌ Complex queue system (use simple retry instead)

---

## 📊 Database Schema Updates (MINIMAL - Fast-Track)

### Mobile App (SQLite) - Minimal Changes Only

#### 1. Students Table - Add Essential Sync Columns Only
```sql
-- Only 4 essential columns needed for 1-week sprint
ALTER TABLE students ADD COLUMN sync_status TEXT DEFAULT 'not_synced';
ALTER TABLE students ADD COLUMN backend_student_id TEXT;
ALTER TABLE students ADD COLUMN last_sync_attempt TEXT;
ALTER TABLE students ADD COLUMN sync_error TEXT;
```

**Sync Status Values (Simplified):**
- `not_synced` - New record, not sent to backend
- `syncing` - Currently uploading to backend
- `synced` - Successfully sent to backend (can poll for processing_status)
- `failed` - Sync failed (see sync_error)

**Removed/Deferred:**
- ❌ sync_id (not needed - use student_id)
- ❌ processing_status (get from backend via polling)
- ❌ sync_retry_count (track in memory, not DB)
- ❌ last_sync_success (not essential for MVP)

#### 2. ❌ Sync Queue Table - NOT NEEDED
**Reason:** Simple retry logic in memory is sufficient for 1-week MVP

#### 3. ❌ Sync Log Table - NOT NEEDED  
**Reason:** Use console logging and optional in-memory logs for debugging
**Alternative:** Can add simple logging to app documents directory if needed

### Backend (JSON/Files) - ✅ NO CHANGES NEEDED!

#### ✅ database.json (Already Has Everything We Need!)
```json
{
  "S12345": {
    "uuid": "abc-123-def-456",
    "student_id": "S12345",
    "name": "John Doe",
    "email": "john@university.edu",
    "department": "Computer Science",
    "year": 3,
    "image_path": "uploads/students/S12345/S12345_20251105_103000.jpg",
    "registered_at": "2025-11-05T10:30:00.123456",
    "processing_status": "completed",  // ✅ Use this for status tracking!
    "processed_at": "2025-11-05T10:32:00.123456",
    "num_augmentations": 20,
    "embeddings_path": "processed_faces/S12345/embeddings.npy",
    "processing_error": null  // ✅ Use this for error tracking!
  }
}
```

**What We're Using:**
- ✅ `processing_status`: "pending" | "completed" | "failed"
- ✅ `processing_error`: Error message if failed
- ✅ `student_id`: Correlation key between mobile and backend
- ✅ All student data already stored

**What We're NOT Adding:**
- ❌ No sync_registry.json (not needed)
- ❌ No processing_stages tracking (too complex for 1 week)
- ❌ No sync_id (student_id is sufficient)

---

## 🛠️ Implementation Components (FAST-TRACK)

### A. Mobile App Components (Flutter) - SIMPLIFIED

#### 1. Sync Service (`lib/core/services/sync_service.dart`) - MINIMAL VERSION
```dart
class SyncService {
  final Dio _dio;
  final LocalDatabaseDataSource _database;
  
  // ✅ ONLY 3 METHODS NEEDED FOR MVP!
  
  /// Sync student to backend using existing /api/students/ endpoint
  Future<SyncResult> syncStudent(Student student, File imageFile);
  
  /// Check processing status using existing /api/students/{id} endpoint
  Future<ProcessingStatus> checkProcessingStatus(String studentId);
  
  /// Retry failed sync with exponential backoff
  Future<SyncResult> retrySyncWithBackoff(Student student, File imageFile);
}
```

**Removed for 1-week sprint:**
- ❌ syncImages() - not needed, single image in syncStudent()
- ❌ enqueueSyncOperation() - simple retry is enough
- ❌ processSyncQueue() - no queue needed
- ❌ watchStudentSyncStatus() - simple polling is enough
- ❌ retryFailedSyncs() - replaced with retrySyncWithBackoff()

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

## 🚀 Implementation Timeline - 1-WEEK SPRINT

### **Day 1 (November 5): Setup & Database** ⚡
**Duration:** 3-4 hours  
**Focus:** Minimal setup, no backend changes

- [x] ✅ Review existing API (`/api/students/`)
- [x] ✅ Update integration plan with fast-track approach
- [ ] Add 4 sync columns to mobile SQLite database
- [ ] Test database migration on dev device
- [ ] Create basic sync models (SyncStatus, SyncResult)

**Deliverable:** Database ready for sync fields

---

### **Day 2 (November 6): Core Sync Implementation** 🔨
**Duration:** 6-8 hours  
**Focus:** Basic sync from mobile to backend

- [ ] Create `SyncService` class with `syncStudent()` method
- [ ] Implement HTTP client using Dio
- [ ] Build multipart form data with student info + image
- [ ] POST to existing `/api/students/` endpoint
- [ ] Update local database sync_status on success/failure
- [ ] Add basic error handling
- [ ] Test with 1 student

**Deliverable:** Can sync 1 student from mobile to backend

---

### **Day 3 (November 7): Status Polling & UI** 📊
**Duration:** 6-8 hours  
**Focus:** Track processing status and show in UI

- [ ] Implement `checkProcessingStatus()` method
- [ ] Poll backend every 10 seconds for processing_status
- [ ] Update local database when completed
- [ ] Add sync status icons to student list UI
- [ ] Add manual sync button
- [ ] Add sync status indicators (not_synced, syncing, synced, completed, failed)
- [ ] Test complete flow: register → sync → poll → complete

**Deliverable:** User can see sync status in real-time

---

### **Day 4 (November 8): Error Handling & Retry** 🛡️
**Duration:** 5-6 hours  
**Focus:** Handle failures gracefully

- [ ] Implement exponential backoff retry (3 attempts)
- [ ] Handle network errors (connection timeout, no internet)
- [ ] Handle backend errors (400, 500 responses)
- [ ] Display user-friendly error messages
- [ ] Add "Retry" button for failed syncs
- [ ] Test offline scenario
- [ ] Test backend unavailable scenario

**Deliverable:** App handles errors and retries automatically

---

### **Day 5 (November 9): Logging & Batch Sync** 📝
**Duration:** 5-6 hours  
**Focus:** Multiple students and debugging

- [ ] Add console logging for all sync operations
- [ ] Log request/response data
- [ ] Log timing metrics
- [ ] Implement sync for multiple students (loop)
- [ ] Add sync progress indicator (X of Y students)
- [ ] Handle partial failures (some sync, some fail)
- [ ] Test with 5+ students

**Deliverable:** Can sync multiple students with detailed logs

---

### **Day 6 (November 10): Testing & Polish** 🧪
**Duration:** 6-8 hours  
**Focus:** End-to-end testing and bug fixes

- [ ] Test complete registration flow
- [ ] Test sync on app resume
- [ ] Test various network conditions
- [ ] Test with different image formats
- [ ] Fix any bugs found
- [ ] Improve error messages
- [ ] Add loading indicators
- [ ] Polish UI/UX

**Deliverable:** Stable, working integration

---

### **Day 7 (November 11): Documentation & Demo** 📚
**Duration:** 4-5 hours  
**Focus:** Documentation and demo preparation

- [ ] Document API usage in README
- [ ] Create user guide for sync feature
- [ ] Record demo video
- [ ] Test on physical device
- [ ] Prepare presentation
- [ ] Final smoke testing

**Deliverable:** Production-ready integration with documentation

---

### **Delivery Day (November 12)** 🎉
- [ ] Final review and testing
- [ ] Deploy/demo to stakeholders
- [ ] Celebrate! 🎊

---

## ⏱️ Time Budget

| Task | Time | Percentage |
|------|------|------------|
| Database setup | 4h | 8% |
| Core sync implementation | 8h | 16% |
| Status polling & UI | 8h | 16% |
| Error handling | 6h | 12% |
| Logging & batch | 6h | 12% |
| Testing & polish | 8h | 16% |
| Documentation | 5h | 10% |
| **Buffer for issues** | 5h | 10% |
| **TOTAL** | **50h** | **100%** |

**Daily Commitment:** ~7 hours/day for 7 days

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

## 🎯 Success Criteria (1-Week MVP)

✅ **Functional Requirements (MVP)**
- [ ] Students registered in mobile app sync to backend automatically
- [ ] Student data + 1 face image uploaded successfully
- [ ] Sync status visible in mobile UI (not_synced → syncing → synced)
- [ ] Processing status tracked (pending → completed/failed)
- [ ] Failed syncs can be retried manually or automatically (3 attempts)
- [ ] Error messages displayed to user

✅ **Performance Requirements (Relaxed for MVP)**
- [ ] Sync initiates within 2 seconds of trigger
- [ ] Mobile app remains responsive during sync
- [ ] Backend processes images within 5 minutes (already working)
- [ ] Status polls every 10 seconds without blocking UI

✅ **Quality Requirements (Essential Only)**
- [ ] 80%+ sync success rate (realistic for first version)
- [ ] Basic error handling for common failures
- [ ] Console logs for debugging
- [ ] No app crashes during sync

**Deferred to Future Versions:**
- ⏭️ Offline queue (simple retry is enough for now)
- ⏭️ Batch image upload (1 image per student is MVP)
- ⏭️ Comprehensive audit trail
- ⏭️ Unit test coverage (functional testing for now)
- ⏭️ Performance optimization

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
