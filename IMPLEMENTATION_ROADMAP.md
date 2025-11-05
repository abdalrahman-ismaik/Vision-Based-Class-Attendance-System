# Mobile-Backend Integration Implementation Roadmap
## Vision-Based Class Attendance System

**Version:** 1.0  
**Date:** November 5, 2025  
**Related Document:** [INTEGRATION_PLAN.md](./INTEGRATION_PLAN.md)

---

## 📋 Quick Start Checklist

Before starting implementation, ensure:
- ✅ Read and understand [INTEGRATION_PLAN.md](./INTEGRATION_PLAN.md)
- ✅ Backend server is running and accessible
- ✅ Mobile app builds successfully
- ✅ Git branch created: `feature/mobile-backend-sync`
- ✅ Development environment configured

---

## 🗓️ Implementation Timeline

| Phase | Duration | Status | Description |
|-------|----------|--------|-------------|
| **Phase 1: Foundation** | Week 1 | 🟡 In Progress | Database schema, basic structure |
| **Phase 2: Core Sync** | Week 2 | ⚪ Pending | Student & image sync |
| **Phase 3: Status & Logging** | Week 3 | ⚪ Pending | Tracking & monitoring |
| **Phase 4: Error Handling** | Week 4 | ⚪ Pending | Retry & offline support |
| **Phase 5: Testing** | Week 5 | ⚪ Pending | Unit & integration tests |
| **Phase 6: Deployment** | Week 6 | ⚪ Pending | Production release |

---

## 📦 Phase 1: Foundation (Week 1)

### 1.1 Backend: Database Schema Updates

**File:** `backend/database_schema.py` (NEW)

```python
"""
Database schema updates for sync functionality
Run this script to update existing database.json structure
"""

import json
import os
from datetime import datetime

def add_sync_fields_to_students():
    """Add sync-related fields to existing student records"""
    
    db_file = 'database.json'
    
    if not os.path.exists(db_file):
        print("database.json not found. Creating new database.")
        data = {"students": {}}
    else:
        with open(db_file, 'r') as f:
            data = json.load(f)
    
    # Add sync fields to each student if not present
    for student_id, student in data.get('students', {}).items():
        if 'sync_metadata' not in student:
            student['sync_metadata'] = {
                'mobile_student_id': None,
                'sync_id': None,
                'sync_status': 'not_synced',  # not_synced, syncing, synced, processing, completed, failed
                'last_sync_attempt': None,
                'last_sync_success': None,
                'sync_error': None,
                'processing_status': None,
                'sync_retry_count': 0,
                'created_from': 'manual'  # manual, mobile_app, web_app
            }
    
    # Save updated database
    with open(db_file, 'w') as f:
        json.dump(data, f, indent=2)
    
    print(f"Updated {len(data.get('students', {}))} student records")

def create_sync_registry():
    """Create sync registry file"""
    
    registry_file = 'sync_registry.json'
    
    if os.path.exists(registry_file):
        print(f"{registry_file} already exists")
        return
    
    registry = {
        "version": "1.0",
        "created_at": datetime.utcnow().isoformat(),
        "syncs": {},
        "statistics": {
            "total_syncs": 0,
            "successful_syncs": 0,
            "failed_syncs": 0,
            "total_images_processed": 0,
            "total_embeddings_generated": 0
        }
    }
    
    with open(registry_file, 'w') as f:
        json.dump(registry, f, indent=2)
    
    print(f"Created {registry_file}")

if __name__ == '__main__':
    print("Updating database schema for sync functionality...")
    add_sync_fields_to_students()
    create_sync_registry()
    print("Database schema update complete!")
```

**Run this:**
```bash
cd backend
python database_schema.py
```

### 1.2 Mobile: Database Migration

**File:** `HADIR_mobile/hadir_mobile_full/lib/shared/data/data_sources/sync_database_migration.dart` (NEW)

```dart
import 'package:sqflite/sqflite.dart';

/// Database migration for sync functionality
/// This adds sync-related tables and columns to existing database
class SyncDatabaseMigration {
  
  /// Apply sync-related schema updates
  /// Call this from LocalDatabaseDataSource._upgradeDatabase
  static Future<void> migrateTo_v5(Database db) async {
    // 1. Add sync columns to students table
    await _addSyncColumnsToStudents(db);
    
    // 2. Create sync_queue table
    await _createSyncQueueTable(db);
    
    // 3. Create sync_log table
    await _createSyncLogTable(db);
    
    // 4. Create indices
    await _createSyncIndices(db);
    
    print('✅ Database migrated to v5 (sync support)');
  }
  
  static Future<void> _addSyncColumnsToStudents(Database db) async {
    final columns = [
      'sync_status TEXT DEFAULT "not_synced"',
      'sync_id TEXT',
      'backend_student_id TEXT',
      'last_sync_attempt TEXT',
      'last_sync_success TEXT',
      'sync_error TEXT',
      'processing_status TEXT',
      'sync_retry_count INTEGER DEFAULT 0',
    ];
    
    for (final column in columns) {
      try {
        await db.execute('ALTER TABLE students ADD COLUMN $column');
      } catch (e) {
        // Column might already exist
        print('Column might already exist: $e');
      }
    }
    
    print('  ✅ Added sync columns to students table');
  }
  
  static Future<void> _createSyncQueueTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        operation_type TEXT NOT NULL,
        payload TEXT NOT NULL,
        priority INTEGER DEFAULT 5,
        created_at TEXT NOT NULL,
        scheduled_for TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_error TEXT,
        status TEXT DEFAULT 'pending',
        FOREIGN KEY (student_id) REFERENCES students (id)
      )
    ''');
    
    print('  ✅ Created sync_queue table');
  }
  
  static Future<void> _createSyncLogTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_log (
        id TEXT PRIMARY KEY,
        student_id TEXT,
        sync_id TEXT,
        operation_type TEXT NOT NULL,
        status TEXT NOT NULL,
        request_data TEXT,
        response_data TEXT,
        error_message TEXT,
        duration_ms INTEGER,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (student_id) REFERENCES students (id)
      )
    ''');
    
    print('  ✅ Created sync_log table');
  }
  
  static Future<void> _createSyncIndices(Database db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_queue_status ON sync_queue (status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_queue_scheduled ON sync_queue (scheduled_for)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_log_student ON sync_log (student_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_log_timestamp ON sync_log (timestamp DESC)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_students_sync_status ON students (sync_status)');
    
    print('  ✅ Created sync indices');
  }
}
```

**Update:** `HADIR_mobile/hadir_mobile_full/lib/shared/data/data_sources/local_database_data_source.dart`

```dart
// Import the migration
import 'sync_database_migration.dart';

class LocalDatabaseDataSource {
  // ... existing code ...
  
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'hadir.db');
    
    return await openDatabase(
      path,
      version: 5, // ← INCREMENT THIS from 4 to 5
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }
  
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // ... existing migrations ...
    
    // Migration from version 4 to 5: Add sync support
    if (oldVersion < 5 && newVersion >= 5) {
      await SyncDatabaseMigration.migrateTo_v5(db);
    }
  }
}
```

### 1.3 Backend: Sync Models

**File:** `backend/models/sync_models.py` (NEW)

```python
"""
Data models for sync operations
"""

from dataclasses import dataclass, field, asdict
from typing import Optional, Dict, List, Any
from datetime import datetime
from enum import Enum

class SyncStatus(Enum):
    """Sync operation status"""
    NOT_SYNCED = 'not_synced'
    SYNCING = 'syncing'
    SYNCED = 'synced'
    PROCESSING = 'processing'
    COMPLETED = 'completed'
    FAILED = 'failed'

class ProcessingStage(Enum):
    """Processing pipeline stages"""
    STUDENT_CREATED = 'student_created'
    IMAGES_RECEIVED = 'images_received'
    FACE_DETECTION = 'face_detection'
    AUGMENTATION = 'augmentation'
    EMBEDDING_GENERATION = 'embedding_generation'
    CLASSIFIER_TRAINING = 'classifier_training'

@dataclass
class StudentSyncRequest:
    """Request model for syncing student data"""
    mobile_student_id: str
    student_id: str
    full_name: str
    email: str
    department: str
    program: str
    date_of_birth: str
    phone_number: Optional[str] = None
    gender: Optional[str] = None
    nationality: Optional[str] = None
    major: Optional[str] = None
    enrollment_year: Optional[int] = None
    academic_level: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None

@dataclass
class SyncResponse:
    """Response model for sync operations"""
    success: bool
    sync_id: Optional[str] = None
    backend_student_id: Optional[str] = None
    message: str = ''
    error: Optional[Dict[str, Any]] = None
    timestamp: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    
    def to_dict(self):
        return asdict(self)

@dataclass
class ImageSyncRequest:
    """Request model for syncing images"""
    sync_id: str
    image_count: int
    metadata: Optional[Dict[str, Any]] = None

@dataclass
class SyncStatusResponse:
    """Response model for sync status"""
    sync_id: str
    status: str
    progress: int  # 0-100
    current_stage: Optional[str] = None
    stages: Dict[str, Any] = field(default_factory=dict)
    estimated_completion: Optional[str] = None
    results: Optional[Dict[str, Any]] = None
    error: Optional[str] = None
    
    def to_dict(self):
        return asdict(self)

@dataclass
class ProcessingJob:
    """Background processing job"""
    job_id: str
    sync_id: str
    student_id: str
    mobile_student_id: str
    images_path: str
    status: str = 'queued'
    progress: int = 0
    current_stage: Optional[str] = None
    error: Optional[str] = None
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    started_at: Optional[str] = None
    completed_at: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)
```

### 1.4 Mobile: Sync Models

**File:** `HADIR_mobile/hadir_mobile_full/lib/core/models/sync_models.dart` (NEW)

```dart
import 'package:equatable/equatable.dart';

/// Sync status enum
enum SyncStatus {
  notSynced,
  syncing,
  synced,
  processing,
  completed,
  failed;
  
  String get displayName {
    switch (this) {
      case SyncStatus.notSynced:
        return 'Not Synced';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.processing:
        return 'Processing';
      case SyncStatus.completed:
        return 'Completed';
      case SyncStatus.failed:
        return 'Failed';
    }
  }
}

/// Sync operation type
enum SyncOperationType {
  registerStudent,
  uploadImages,
  updateStudent,
  deleteStudent;
}

/// Processing stage
enum ProcessingStage {
  studentCreated,
  imagesReceived,
  faceDetection,
  augmentation,
  embeddingGeneration,
  classifierTraining;
  
  String get displayName {
    switch (this) {
      case ProcessingStage.studentCreated:
        return 'Student Created';
      case ProcessingStage.imagesReceived:
        return 'Images Received';
      case ProcessingStage.faceDetection:
        return 'Face Detection';
      case ProcessingStage.augmentation:
        return 'Image Augmentation';
      case ProcessingStage.embeddingGeneration:
        return 'Embedding Generation';
      case ProcessingStage.classifierTraining:
        return 'Classifier Training';
    }
  }
}

/// Sync operation model
class SyncOperation extends Equatable {
  const SyncOperation({
    required this.id,
    required this.studentId,
    required this.type,
    required this.payload,
    required this.createdAt,
    required this.scheduledFor,
    this.priority = 5,
    this.retryCount = 0,
    this.lastError,
    this.status = 'pending',
  });

  final String id;
  final String studentId;
  final SyncOperationType type;
  final Map<String, dynamic> payload;
  final int priority;
  final DateTime createdAt;
  final DateTime scheduledFor;
  final int retryCount;
  final String? lastError;
  final String status;

  @override
  List<Object?> get props => [
        id,
        studentId,
        type,
        priority,
        createdAt,
        scheduledFor,
        retryCount,
        status,
      ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'operation_type': type.name,
      'payload': payload.toString(),
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
      'scheduled_for': scheduledFor.toIso8601String(),
      'retry_count': retryCount,
      'last_error': lastError,
      'status': status,
    };
  }
}

/// Sync result model
class SyncResult extends Equatable {
  const SyncResult({
    required this.success,
    this.syncId,
    this.jobId,
    this.backendStudentId,
    this.error,
    this.metadata,
  });

  final bool success;
  final String? syncId;
  final String? jobId;
  final String? backendStudentId;
  final String? error;
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [success, syncId, jobId, error];
}

/// Sync status response model
class SyncStatusResponse extends Equatable {
  const SyncStatusResponse({
    required this.syncId,
    required this.status,
    required this.progress,
    this.currentStage,
    this.stages = const {},
    this.estimatedCompletion,
    this.results,
    this.error,
  });

  final String syncId;
  final SyncStatus status;
  final int progress; // 0-100
  final ProcessingStage? currentStage;
  final Map<String, dynamic> stages;
  final DateTime? estimatedCompletion;
  final Map<String, dynamic>? results;
  final String? error;

  @override
  List<Object?> get props => [
        syncId,
        status,
        progress,
        currentStage,
        estimatedCompletion,
        error,
      ];

  factory SyncStatusResponse.fromJson(Map<String, dynamic> json) {
    return SyncStatusResponse(
      syncId: json['sync_id'] as String,
      status: SyncStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SyncStatus.notSynced,
      ),
      progress: json['progress'] as int,
      currentStage: json['current_stage'] != null
          ? ProcessingStage.values.firstWhere(
              (e) => e.name == json['current_stage'],
            )
          : null,
      stages: json['stages'] as Map<String, dynamic>? ?? {},
      estimatedCompletion: json['estimated_completion'] != null
          ? DateTime.parse(json['estimated_completion'])
          : null,
      results: json['results'] as Map<String, dynamic>?,
      error: json['error'] as String?,
    );
  }
}

/// Sync log entry
class SyncLogEntry extends Equatable {
  const SyncLogEntry({
    required this.id,
    required this.operationType,
    required this.status,
    required this.timestamp,
    this.studentId,
    this.syncId,
    this.requestData,
    this.responseData,
    this.errorMessage,
    this.durationMs,
  });

  final String id;
  final String? studentId;
  final String? syncId;
  final String operationType;
  final String status;
  final Map<String, dynamic>? requestData;
  final Map<String, dynamic>? responseData;
  final String? errorMessage;
  final int? durationMs;
  final DateTime timestamp;

  @override
  List<Object?> get props => [id, operationType, status, timestamp];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'sync_id': syncId,
      'operation_type': operationType,
      'status': status,
      'request_data': requestData?.toString(),
      'response_data': responseData?.toString(),
      'error_message': errorMessage,
      'duration_ms': durationMs,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
```

### 1.5 Update Configuration Files

**Backend:** `backend/sync_config.py` (NEW)

```python
"""
Sync configuration
"""

import os

class SyncConfig:
    # Server
    BACKEND_BASE_URL = os.getenv('BACKEND_BASE_URL', 'http://localhost:5000')
    
    # Processing
    MAX_CONCURRENT_JOBS = int(os.getenv('MAX_CONCURRENT_JOBS', '2'))
    JOB_TIMEOUT_SECONDS = int(os.getenv('JOB_TIMEOUT_SECONDS', '600'))  # 10 minutes
    
    # Storage
    SYNC_IMAGES_FOLDER = 'uploads/sync_images'
    MAX_IMAGE_SIZE_MB = 5
    ALLOWED_IMAGE_FORMATS = ['jpg', 'jpeg', 'png', 'bmp']
    
    # Logging
    LOG_FOLDER = 'logs'
    LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')
    LOG_ROTATION_SIZE_MB = 10
    LOG_RETENTION_DAYS = 30
    
    # Rate limiting
    SYNC_RATE_LIMIT = os.getenv('SYNC_RATE_LIMIT', '100/hour')
    IMAGE_UPLOAD_RATE_LIMIT = os.getenv('IMAGE_UPLOAD_RATE_LIMIT', '50/hour')
    
    # Sync registry
    SYNC_REGISTRY_FILE = 'sync_registry.json'
    
    # Status check
    STATUS_POLL_INTERVAL_SECONDS = 10

# Create necessary directories
os.makedirs(SyncConfig.SYNC_IMAGES_FOLDER, exist_ok=True)
os.makedirs(SyncConfig.LOG_FOLDER, exist_ok=True)
```

**Mobile:** `HADIR_mobile/hadir_mobile_full/lib/core/config/sync_config.dart` (NEW)

```dart
/// Sync configuration
class SyncConfig {
  // Backend server
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://10.0.2.2:5000', // Android emulator localhost
  );
  
  // API endpoints
  static const String syncStudentEndpoint = '/api/sync/student';
  static const String syncImagesEndpoint = '/api/sync/images';
  static const String syncStatusEndpoint = '/api/sync/status';
  static const String syncResultsEndpoint = '/api/sync/results';
  static const String syncBatchEndpoint = '/api/sync/batch';
  
  // Sync settings
  static const Duration syncInterval = Duration(minutes: 30);
  static const Duration statusPollInterval = Duration(seconds: 10);
  static const int maxImageBatchSize = 10;
  static const int maxRetryAttempts = 3;
  static const Duration initialRetryDelay = Duration(seconds: 5);
  static const int maxRetryDelaySeconds = 60;
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);
  static const Duration statusCheckTimeout = Duration(seconds: 15);
  
  // Logging
  static const bool enableDetailedLogging = true;
  static const int maxLogFileSizeMB = 10;
  static const String logFileName = 'sync_operations.log';
  
  // Queue settings
  static const int maxQueueSize = 100;
  static const int highPriority = 1;
  static const int normalPriority = 5;
  static const int lowPriority = 10;
  
  // Build URLs
  static String get syncStudentUrl => '$backendBaseUrl$syncStudentEndpoint';
  static String get syncImagesUrl => '$backendBaseUrl$syncImagesEndpoint';
  static String syncStatusUrl(String syncId) => '$backendBaseUrl$syncStatusEndpoint/$syncId';
  static String syncResultsUrl(String studentId) => '$backendBaseUrl$syncResultsEndpoint/$studentId';
  static String get syncBatchUrl => '$backendBaseUrl$syncBatchEndpoint';
}
```

---

## 🔧 Phase 2: Core Sync Implementation (Week 2)

### 2.1 Backend: Sync API Endpoints

**File:** `backend/sync_api.py` (NEW)

```python
"""
Sync API endpoints for mobile app integration
"""

from flask import Blueprint, request, jsonify, current_app
from flask_restx import Namespace, Resource, fields
from werkzeug.utils import secure_filename
import os
import uuid
import logging
from datetime import datetime

from models.sync_models import (
    StudentSyncRequest, SyncResponse, ImageSyncRequest,
    SyncStatusResponse, ProcessingJob, SyncStatus
)
from sync_registry import SyncRegistry
from processing_queue import ProcessingQueue

logger = logging.getLogger(__name__)

# Create namespace
sync_ns = Namespace('sync', description='Mobile app synchronization operations')

# Initialize sync registry and processing queue
sync_registry = SyncRegistry()
processing_queue = ProcessingQueue(num_workers=2)
processing_queue.start()

# ==================== Request/Response Models ====================

student_sync_model = sync_ns.model('StudentSync', {
    'mobile_student_id': fields.String(required=True, description='Mobile app student UUID'),
    'student_id': fields.String(required=True, description='University student ID'),
    'full_name': fields.String(required=True, description='Student full name'),
    'email': fields.String(required=True, description='Student email'),
    'department': fields.String(required=True, description='Department'),
    'program': fields.String(required=True, description='Program'),
    'date_of_birth': fields.String(required=True, description='Date of birth (ISO 8601)'),
    'phone_number': fields.String(description='Phone number'),
    'gender': fields.String(description='Gender'),
    'nationality': fields.String(description='Nationality'),
    'major': fields.String(description='Major'),
    'enrollment_year': fields.Integer(description='Enrollment year'),
    'academic_level': fields.String(description='Academic level'),
})

sync_response_model = sync_ns.model('SyncResponse', {
    'success': fields.Boolean(description='Operation success'),
    'sync_id': fields.String(description='Sync operation ID'),
    'backend_student_id': fields.String(description='Backend student ID'),
    'message': fields.String(description='Response message'),
    'timestamp': fields.String(description='Response timestamp'),
})

# ==================== Helper Functions ====================

def load_database():
    """Load student database"""
    db_file = os.path.join(current_app.root_path, 'database.json')
    if os.path.exists(db_file):
        import json
        with open(db_file, 'r') as f:
            return json.load(f)
    return {'students': {}}

def save_database(data):
    """Save student database"""
    db_file = os.path.join(current_app.root_path, 'database.json')
    import json
    with open(db_file, 'w') as f:
        json.dump(data, f, indent=2)

def allowed_file(filename):
    """Check if file extension is allowed"""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in current_app.config.get('ALLOWED_EXTENSIONS', {'jpg', 'jpeg', 'png', 'bmp'})

# ==================== API Endpoints ====================

@sync_ns.route('/student')
class SyncStudent(Resource):
    """Sync student data from mobile app"""
    
    @sync_ns.expect(student_sync_model)
    @sync_ns.marshal_with(sync_response_model)
    @sync_ns.doc(description='Create or update student record from mobile app')
    def post(self):
        """
        Sync student data from mobile app
        
        Creates a new student record or updates existing one.
        Returns sync_id for tracking the sync operation.
        """
        try:
            data = request.get_json()
            
            # Validate required fields
            required_fields = ['mobile_student_id', 'student_id', 'full_name', 'email', 'department', 'program']
            for field in required_fields:
                if field not in data:
                    return SyncResponse(
                        success=False,
                        message=f'Missing required field: {field}',
                        error={'code': 'MISSING_FIELD', 'field': field}
                    ).to_dict(), 400
            
            mobile_student_id = data['mobile_student_id']
            student_id = data['student_id']
            
            logger.info(f"[SYNC] Received sync request for student: {student_id} (mobile: {mobile_student_id})")
            
            # Load database
            db = load_database()
            
            # Check if student already exists
            student_exists = student_id in db['students']
            
            # Create/update student record
            student_record = {
                'student_id': student_id,
                'name': data['full_name'],
                'email': data['email'],
                'department': data['department'],
                'program': data.get('program', ''),
                'phone': data.get('phone_number'),
                'date_of_birth': data.get('date_of_birth'),
                'gender': data.get('gender'),
                'nationality': data.get('nationality'),
                'major': data.get('major'),
                'enrollment_year': data.get('enrollment_year'),
                'academic_level': data.get('academic_level'),
                'created_at': datetime.utcnow().isoformat(),
                'sync_metadata': {
                    'mobile_student_id': mobile_student_id,
                    'sync_status': 'synced',
                    'last_sync_success': datetime.utcnow().isoformat(),
                    'created_from': 'mobile_app'
                }
            }
            
            # Save to database
            db['students'][student_id] = student_record
            save_database(db)
            
            # Create sync registry entry
            sync_id = sync_registry.create_sync(
                mobile_student_id=mobile_student_id,
                backend_student_id=student_id,
                student_data=student_record
            )
            
            # Update sync stage
            sync_registry.update_stage(
                sync_id=sync_id,
                stage='student_created',
                status='completed'
            )
            
            action = 'updated' if student_exists else 'created'
            logger.info(f"[SYNC] Student {action}: {student_id}, sync_id: {sync_id}")
            
            return SyncResponse(
                success=True,
                sync_id=sync_id,
                backend_student_id=student_id,
                message=f'Student {action} successfully'
            ).to_dict(), 201 if not student_exists else 200
            
        except Exception as e:
            logger.error(f"[SYNC] Error syncing student: {e}", exc_info=True)
            return SyncResponse(
                success=False,
                message='Internal server error',
                error={'code': 'INTERNAL_ERROR', 'details': str(e)}
            ).to_dict(), 500

@sync_ns.route('/images')
class SyncImages(Resource):
    """Upload student face images"""
    
    @sync_ns.doc(
        description='Upload student face images for processing',
        params={
            'sync_id': 'Sync operation ID from /sync/student',
            'images': 'Face image files (multipart/form-data)'
        }
    )
    def post(self):
        """
        Upload student face images for processing
        
        Form data should include:
        - sync_id: string
        - images: file[] (multipart)
        
        Returns job_id for tracking processing status
        """
        try:
            # Get sync_id from form data
            sync_id = request.form.get('sync_id')
            if not sync_id:
                return {'success': False, 'message': 'sync_id is required'}, 400
            
            logger.info(f"[SYNC] Received images for sync_id: {sync_id}")
            
            # Get sync record
            sync_record = sync_registry.get_sync(sync_id)
            if not sync_record:
                return {'success': False, 'message': 'Invalid sync_id'}, 404
            
            student_id = sync_record['backend_student_id']
            mobile_student_id = sync_record['mobile_student_id']
            
            # Get uploaded images
            if 'images' not in request.files:
                return {'success': False, 'message': 'No images provided'}, 400
            
            files = request.files.getlist('images')
            if len(files) == 0:
                return {'success': False, 'message': 'No images provided'}, 400
            
            logger.info(f"[SYNC] Processing {len(files)} images for student {student_id}")
            
            # Create student folder
            from sync_config import SyncConfig
            student_folder = os.path.join(SyncConfig.SYNC_IMAGES_FOLDER, student_id)
            os.makedirs(student_folder, exist_ok=True)
            
            # Save images
            saved_images = []
            for i, file in enumerate(files):
                if file and allowed_file(file.filename):
                    filename = secure_filename(f"{student_id}_{i}_{uuid.uuid4().hex[:8]}.jpg")
                    filepath = os.path.join(student_folder, filename)
                    file.save(filepath)
                    saved_images.append(filepath)
                    logger.debug(f"[SYNC] Saved image: {filename}")
            
            if len(saved_images) == 0:
                return {'success': False, 'message': 'No valid images uploaded'}, 400
            
            # Update sync registry
            sync_registry.update_stage(
                sync_id=sync_id,
                stage='images_received',
                status='completed',
                metadata={'image_count': len(saved_images)}
            )
            
            # Create processing job
            job_id = f"job_{uuid.uuid4().hex}"
            job = ProcessingJob(
                job_id=job_id,
                sync_id=sync_id,
                student_id=student_id,
                mobile_student_id=mobile_student_id,
                images_path=student_folder,
                metadata={'image_count': len(saved_images)}
            )
            
            # Enqueue for processing
            processing_queue.enqueue(job)
            
            logger.info(f"[SYNC] Images uploaded and job queued: {job_id}")
            
            return {
                'success': True,
                'job_id': job_id,
                'images_received': len(saved_images),
                'status': 'queued',
                'message': 'Images queued for processing'
            }, 202
            
        except Exception as e:
            logger.error(f"[SYNC] Error uploading images: {e}", exc_info=True)
            return {
                'success': False,
                'message': 'Internal server error',
                'error': str(e)
            }, 500

@sync_ns.route('/status/<string:sync_id>')
@sync_ns.param('sync_id', 'Sync operation ID')
class SyncStatus(Resource):
    """Get sync operation status"""
    
    @sync_ns.doc(description='Get current status of sync operation')
    def get(self, sync_id):
        """
        Get sync operation status
        
        Returns current processing status and progress
        """
        try:
            logger.debug(f"[SYNC] Status check for: {sync_id}")
            
            # Get sync record
            sync_record = sync_registry.get_sync(sync_id)
            if not sync_record:
                return {'success': False, 'message': 'Sync not found'}, 404
            
            # Calculate progress based on completed stages
            stages = sync_record.get('processing_stages', {})
            total_stages = 6  # student_created, images_received, face_detection, augmentation, embedding, classifier
            completed_stages = sum(1 for stage in stages.values() if stage.get('status') == 'completed')
            progress = int((completed_stages / total_stages) * 100)
            
            # Determine current stage
            current_stage = None
            for stage_name, stage_data in stages.items():
                if stage_data.get('status') == 'in_progress':
                    current_stage = stage_name
                    break
            
            # Determine overall status
            if sync_record.get('error'):
                status = 'failed'
            elif completed_stages == total_stages:
                status = 'completed'
            elif completed_stages >= 2:
                status = 'processing'
            elif completed_stages >= 1:
                status = 'synced'
            else:
                status = 'syncing'
            
            response = {
                'sync_id': sync_id,
                'status': status,
                'progress': progress,
                'current_stage': current_stage,
                'stages': stages,
                'error': sync_record.get('error')
            }
            
            return response, 200
            
        except Exception as e:
            logger.error(f"[SYNC] Error getting status: {e}", exc_info=True)
            return {'success': False, 'message': 'Internal server error'}, 500

# ==================== Register Namespace ====================

def register_sync_api(api):
    """Register sync namespace with API"""
    api.add_namespace(sync_ns, path='/sync')
```

**Update:** `backend/app.py`

```python
# Add at the top with other imports
from sync_api import register_sync_api

# After creating the api instance
api = Api(app, ...)

# Register sync API
register_sync_api(api)
```

---

### 2.2 Mobile: Sync Service Implementation

**File:** `HADIR_mobile/hadir_mobile_full/lib/core/services/sync_service.dart` (NEW)

```dart
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../models/sync_models.dart';
import '../config/sync_config.dart';
import '../../shared/domain/entities/student.dart';
import '../../shared/data/data_sources/local_database_data_source.dart';
import 'app_logger.dart';

/// Sync service for mobile-backend synchronization
/// 
/// Handles syncing student data and images from mobile app to backend server
class SyncService {
  final Dio _dio;
  final LocalDatabaseDataSource _database;
  final Uuid _uuid = const Uuid();
  
  SyncService({
    required Dio dio,
    required LocalDatabaseDataSource database,
  })  : _dio = dio,
        _database = database;

  /// Sync a student to the backend
  Future<SyncResult> syncStudent(Student student) async {
    final stopwatch = Stopwatch()..start();
    final String operationId = _uuid.v4();
    
    try {
      AppLogger.syncOperation(
        'Starting student sync',
        student.id,
        metadata: {'operation_id': operationId, 'student_id': student.studentId},
      );
      
      // Update local status
      await _updateStudentSyncStatus(student.id, SyncStatus.syncing);
      
      // Prepare request payload
      final payload = {
        'mobile_student_id': student.id,
        'student_id': student.studentId,
        'full_name': student.fullName,
        'email': student.email,
        'department': student.department,
        'program': student.program,
        'date_of_birth': student.dateOfBirth.toIso8601String(),
        'phone_number': student.phoneNumber,
        'gender': student.gender?.name,
        'nationality': student.nationality,
        'major': student.major,
        'enrollment_year': student.enrollmentYear,
        'academic_level': student.academicLevel?.name,
      };
      
      AppLogger.networkRequest(
        'POST',
        SyncConfig.syncStudentUrl,
        body: payload,
      );
      
      // Send request
      final response = await _dio.post(
        SyncConfig.syncStudentUrl,
        data: payload,
        options: Options(
          sendTimeout: SyncConfig.connectionTimeout,
          receiveTimeout: SyncConfig.connectionTimeout,
        ),
      );
      
      stopwatch.stop();
      
      AppLogger.networkResponse(
        SyncConfig.syncStudentUrl,
        response.statusCode ?? 0,
        duration: stopwatch.elapsedMilliseconds,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final syncId = data['sync_id'] as String;
        final backendStudentId = data['backend_student_id'] as String;
        
        // Update local database
        await _updateStudentSyncStatus(
          student.id,
          SyncStatus.synced,
          syncId: syncId,
          backendStudentId: backendStudentId,
        );
        
        // Log success
        await _logSyncOperation(
          studentId: student.id,
          syncId: syncId,
          operationType: 'sync_student',
          status: 'success',
          requestData: payload,
          responseData: data,
          durationMs: stopwatch.elapsedMilliseconds,
        );
        
        AppLogger.syncOperation(
          'Student synced successfully',
          student.id,
          metadata: {'sync_id': syncId, 'backend_student_id': backendStudentId},
        );
        
        return SyncResult(
          success: true,
          syncId: syncId,
          backendStudentId: backendStudentId,
        );
      } else {
        throw Exception('Unexpected status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      stopwatch.stop();
      
      AppLogger.error(
        'Failed to sync student',
        e,
        metadata: {'student_id': student.id, 'type': 'DioException'},
      );
      
      await _handleSyncError(student.id, e);
      
      return SyncResult(
        success: false,
        error: e.message ?? 'Network error',
      );
    } catch (e) {
      stopwatch.stop();
      
      AppLogger.error(
        'Failed to sync student',
        Exception(e.toString()),
        metadata: {'student_id': student.id},
      );
      
      await _handleSyncError(student.id, Exception(e.toString()));
      
      return SyncResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Sync student images to backend
  Future<SyncResult> syncImages(
    String syncId,
    String studentId,
    List<File> images,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      AppLogger.syncOperation(
        'Starting image sync',
        studentId,
        metadata: {'sync_id': syncId, 'image_count': images.length},
      );
      
      // Prepare multipart form data
      final formData = FormData();
      formData.fields.add(MapEntry('sync_id', syncId));
      
      for (int i = 0; i < images.length; i++) {
        final file = images[i];
        final fileName = 'image_$i.jpg';
        
        formData.files.add(MapEntry(
          'images',
          await MultipartFile.fromFile(
            file.path,
            filename: fileName,
          ),
        ));
      }
      
      AppLogger.networkRequest(
        'POST',
        SyncConfig.syncImagesUrl,
        metadata: {'sync_id': syncId, 'image_count': images.length},
      );
      
      // Send request
      final response = await _dio.post(
        SyncConfig.syncImagesUrl,
        data: formData,
        options: Options(
          sendTimeout: SyncConfig.uploadTimeout,
          receiveTimeout: SyncConfig.uploadTimeout,
        ),
      );
      
      stopwatch.stop();
      
      AppLogger.networkResponse(
        SyncConfig.syncImagesUrl,
        response.statusCode ?? 0,
        duration: stopwatch.elapsedMilliseconds,
      );
      
      if (response.statusCode == 202) {
        final data = response.data as Map<String, dynamic>;
        final jobId = data['job_id'] as String;
        
        // Update local status
        await _updateStudentSyncStatus(
          studentId,
          SyncStatus.processing,
          syncId: syncId,
        );
        
        // Log success
        await _logSyncOperation(
          studentId: studentId,
          syncId: syncId,
          operationType: 'sync_images',
          status: 'success',
          requestData: {'image_count': images.length},
          responseData: data,
          durationMs: stopwatch.elapsedMilliseconds,
        );
        
        AppLogger.syncOperation(
          'Images synced successfully',
          studentId,
          metadata: {'sync_id': syncId, 'job_id': jobId},
        );
        
        return SyncResult(
          success: true,
          syncId: syncId,
          jobId: jobId,
        );
      } else {
        throw Exception('Unexpected status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      stopwatch.stop();
      
      AppLogger.error(
        'Failed to sync images',
        e,
        metadata: {'student_id': studentId, 'sync_id': syncId},
      );
      
      return SyncResult(
        success: false,
        error: e.message ?? 'Network error',
      );
    } catch (e) {
      stopwatch.stop();
      
      AppLogger.error(
        'Failed to sync images',
        Exception(e.toString()),
        metadata: {'student_id': studentId, 'sync_id': syncId},
      );
      
      return SyncResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Check sync status on backend
  Future<SyncStatusResponse?> checkSyncStatus(String syncId) async {
    try {
      final url = SyncConfig.syncStatusUrl(syncId);
      
      AppLogger.networkRequest('GET', url);
      
      final response = await _dio.get(
        url,
        options: Options(
          receiveTimeout: SyncConfig.statusCheckTimeout,
        ),
      );
      
      AppLogger.networkResponse(url, response.statusCode ?? 0);
      
      if (response.statusCode == 200) {
        return SyncStatusResponse.fromJson(response.data);
      }
      
      return null;
    } catch (e) {
      AppLogger.error(
        'Failed to check sync status',
        Exception(e.toString()),
        metadata: {'sync_id': syncId},
      );
      return null;
    }
  }

  /// Update student sync status in local database
  Future<void> _updateStudentSyncStatus(
    String studentId,
    SyncStatus status, {
    String? syncId,
    String? backendStudentId,
    String? error,
  }) async {
    final db = await _database.database;
    
    final updates = <String, dynamic>{
      'sync_status': status.name,
      'last_sync_attempt': DateTime.now().toIso8601String(),
    };
    
    if (syncId != null) {
      updates['sync_id'] = syncId;
    }
    
    if (backendStudentId != null) {
      updates['backend_student_id'] = backendStudentId;
    }
    
    if (status == SyncStatus.synced || status == SyncStatus.completed) {
      updates['last_sync_success'] = DateTime.now().toIso8601String();
      updates['sync_error'] = null;
      updates['sync_retry_count'] = 0;
    }
    
    if (status == SyncStatus.failed && error != null) {
      updates['sync_error'] = error;
    }
    
    await db.update(
      'students',
      updates,
      where: 'id = ?',
      whereArgs: [studentId],
    );
    
    AppLogger.databaseOperation(
      'Updated student sync status',
      metadata: {'student_id': studentId, 'status': status.name},
    );
  }

  /// Handle sync error
  Future<void> _handleSyncError(String studentId, Exception error) async {
    await _updateStudentSyncStatus(
      studentId,
      SyncStatus.failed,
      error: error.toString(),
    );
    
    // Increment retry count
    final db = await _database.database;
    await db.rawUpdate(
      'UPDATE students SET sync_retry_count = sync_retry_count + 1 WHERE id = ?',
      [studentId],
    );
  }

  /// Log sync operation
  Future<void> _logSyncOperation({
    required String studentId,
    required String operationType,
    required String status,
    String? syncId,
    Map<String, dynamic>? requestData,
    Map<String, dynamic>? responseData,
    String? errorMessage,
    int? durationMs,
  }) async {
    final db = await _database.database;
    
    await db.insert('sync_log', {
      'id': _uuid.v4(),
      'student_id': studentId,
      'sync_id': syncId,
      'operation_type': operationType,
      'status': status,
      'request_data': requestData?.toString(),
      'response_data': responseData?.toString(),
      'error_message': errorMessage,
      'duration_ms': durationMs,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
```

---

## 📊 Phase 3-6 Summary

Due to length constraints, here's a summary of remaining phases:

### **Phase 3: Status & Logging** (Week 3)
- Implement backend sync registry manager
- Add comprehensive logging infrastructure (both mobile & backend)
- Create status polling mechanism
- Build sync history/audit trail

### **Phase 4: Error Handling** (Week 4)
- Implement retry logic with exponential backoff
- Add offline queue for failed syncs
- Handle edge cases (no face detected, poor quality, etc.)
- Add user-friendly error messages

### **Phase 5: Testing** (Week 5)
- Unit tests for all sync operations
- Integration tests for end-to-end flow
- Performance testing (large batches, concurrent syncs)
- Error scenario testing

### **Phase 6: Deployment** (Week 6)
- Deploy backend updates
- Release mobile app update
- Set up monitoring dashboards
- Create user documentation

---

## 🎯 Next Steps

1. **Review this document** with your team
2. **Set up development environment**
3. **Create feature branch**: `git checkout -b feature/mobile-backend-sync`
4. **Start with Phase 1**: Run database migrations
5. **Test each phase** before moving to next
6. **Document any issues** or deviations

---

## 📞 Questions?

Create an issue with the `[SYNC]` prefix for any questions or problems during implementation.

**Happy Coding! 🚀**
