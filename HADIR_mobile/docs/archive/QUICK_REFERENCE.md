# Mobile-Backend Integration Quick Reference
## Vision-Based Class Attendance System

**Last Updated:** November 5, 2025

---

## 📚 Documentation Index

| Document | Purpose | Audience |
|----------|---------|----------|
| [INTEGRATION_PLAN.md](./INTEGRATION_PLAN.md) | Complete integration architecture | All developers |
| [IMPLEMENTATION_ROADMAP.md](./IMPLEMENTATION_ROADMAP.md) | Step-by-step implementation guide | Implementers |
| This file | Quick reference and cheat sheet | All team members |

---

## 🚀 Quick Start

### Start Backend Server
```powershell
cd backend
python app.py
```
Backend will be available at: `http://localhost:5000`

### Start Mobile App
```powershell
cd HADIR_mobile/hadir_mobile_full
flutter run
```

### Configure Mobile for Backend Connection
Edit: `lib/core/config/sync_config.dart`
```dart
static const String backendBaseUrl = 'http://10.0.2.2:5000'; // Android emulator
// OR
static const String backendBaseUrl = 'http://localhost:5000'; // iOS simulator
// OR  
static const String backendBaseUrl = 'http://192.168.1.x:5000'; // Physical device
```

---

## 🔄 Sync Flow Overview

### 1. Student Registration (Mobile)
```
User completes registration → Images captured → Data saved locally → Status: "not_synced"
```

### 2. Automatic Sync Triggered
```
App opens → SyncService checks for pending syncs → Finds "not_synced" students
```

### 3. Sync Student Data
```
POST /api/sync/student
Status: "syncing" → "synced"
Returns: sync_id
```

### 4. Sync Images
```
POST /api/sync/images (with sync_id)
Status: "processing"
Returns: job_id
```

### 5. Backend Processing
```
Face detection → Image augmentation → Embedding generation → Classifier training
Status: "completed"
```

### 6. Check Results
```
GET /api/sync/status/{sync_id}
Mobile polls every 10 seconds
```

---

## 🌐 API Endpoints

### Backend Sync Endpoints

| Method | Endpoint | Purpose | Status Code |
|--------|----------|---------|-------------|
| `POST` | `/api/sync/student` | Create/update student | 200/201 |
| `POST` | `/api/sync/images` | Upload face images | 202 |
| `GET` | `/api/sync/status/{sync_id}` | Get sync status | 200 |
| `GET` | `/api/sync/results/{student_id}` | Get processing results | 200 |
| `POST` | `/api/sync/batch` | Batch sync multiple students | 202 |

### Request Examples

#### 1. Sync Student
```bash
curl -X POST http://localhost:5000/api/sync/student \
  -H "Content-Type: application/json" \
  -d '{
    "mobile_student_id": "uuid-123",
    "student_id": "S12345",
    "full_name": "John Doe",
    "email": "john@university.edu",
    "department": "Computer Science",
    "program": "Bachelor"
  }'
```

Response:
```json
{
  "success": true,
  "sync_id": "sync_abc123",
  "backend_student_id": "S12345",
  "message": "Student created successfully"
}
```

#### 2. Upload Images
```bash
curl -X POST http://localhost:5000/api/sync/images \
  -F "sync_id=sync_abc123" \
  -F "images=@image1.jpg" \
  -F "images=@image2.jpg" \
  -F "images=@image3.jpg"
```

Response:
```json
{
  "success": true,
  "job_id": "job_xyz789",
  "images_received": 3,
  "status": "queued"
}
```

#### 3. Check Status
```bash
curl http://localhost:5000/api/sync/status/sync_abc123
```

Response:
```json
{
  "sync_id": "sync_abc123",
  "status": "processing",
  "progress": 75,
  "current_stage": "embedding_generation",
  "stages": {
    "student_created": {"status": "completed"},
    "images_received": {"status": "completed", "image_count": 3},
    "face_detection": {"status": "completed", "faces_detected": 3},
    "augmentation": {"status": "completed", "augmented_count": 60},
    "embedding_generation": {"status": "in_progress", "progress": 75}
  }
}
```

---

## 📱 Mobile Code Snippets

### Trigger Sync from Registration Screen

```dart
// After successful registration
final syncService = ref.read(syncServiceProvider);

// 1. Sync student data
final studentResult = await syncService.syncStudent(student);

if (studentResult.success && studentResult.syncId != null) {
  // 2. Sync images
  final imageResult = await syncService.syncImages(
    studentResult.syncId!,
    student.id,
    capturedImages, // List<File>
  );
  
  if (imageResult.success) {
    // 3. Start polling status
    _startStatusPolling(studentResult.syncId!);
  }
}
```

### Poll Sync Status

```dart
Timer? _statusPollTimer;

void _startStatusPolling(String syncId) {
  _statusPollTimer = Timer.periodic(
    SyncConfig.statusPollInterval, // 10 seconds
    (_) async {
      final status = await syncService.checkSyncStatus(syncId);
      
      if (status != null) {
        if (status.status == SyncStatus.completed) {
          _statusPollTimer?.cancel();
          _showSuccessNotification();
        } else if (status.status == SyncStatus.failed) {
          _statusPollTimer?.cancel();
          _showErrorNotification(status.error);
        }
      }
    },
  );
}
```

### Display Sync Status in UI

```dart
@override
Widget build(BuildContext context) {
  final syncStatus = ref.watch(syncStatusProvider(studentId));
  
  return syncStatus.when(
    data: (status) {
      return Row(
        children: [
          _getSyncIcon(status),
          SizedBox(width: 8),
          Text(_getSyncText(status)),
        ],
      );
    },
    loading: () => CircularProgressIndicator(),
    error: (err, stack) => Icon(Icons.error, color: Colors.red),
  );
}

Widget _getSyncIcon(SyncStatus status) {
  switch (status) {
    case SyncStatus.notSynced:
      return Icon(Icons.cloud_off, color: Colors.orange);
    case SyncStatus.syncing:
      return CircularProgressIndicator(strokeWidth: 2);
    case SyncStatus.synced:
      return Icon(Icons.cloud_upload, color: Colors.blue);
    case SyncStatus.processing:
      return CircularProgressIndicator(strokeWidth: 2, color: Colors.purple);
    case SyncStatus.completed:
      return Icon(Icons.cloud_done, color: Colors.green);
    case SyncStatus.failed:
      return Icon(Icons.error, color: Colors.red);
  }
}
```

---

## 🐛 Troubleshooting

### Issue: Connection Refused

**Symptom:** `DioException: Connection refused`

**Solution:**
1. Check backend is running: `http://localhost:5000/api/health/status`
2. Android emulator: Use `http://10.0.2.2:5000`
3. iOS simulator: Use `http://localhost:5000`
4. Physical device: Use computer's IP address
5. Check firewall settings

### Issue: Images Not Processing

**Symptom:** Status stuck at "synced", not moving to "processing"

**Solution:**
1. Check backend logs: `backend/logs/sync_operations.log`
2. Verify processing queue is running
3. Check image files were saved correctly
4. Verify sync_id is valid

### Issue: Sync Keeps Failing

**Symptom:** Status repeatedly goes to "failed"

**Solution:**
1. Check sync error in database:
   ```dart
   final student = await studentRepo.getById(studentId);
   print(student.syncError);
   ```
2. Check backend logs for detailed error
3. Verify all required fields are provided
4. Check image file formats (only JPG, PNG allowed)

---

## 📊 Database Queries

### Mobile (SQLite)

#### Find students pending sync
```sql
SELECT * FROM students 
WHERE sync_status = 'not_synced' 
ORDER BY created_at DESC;
```

#### View sync logs for a student
```sql
SELECT * FROM sync_log 
WHERE student_id = 'student-uuid' 
ORDER BY timestamp DESC 
LIMIT 10;
```

#### Get failed syncs
```sql
SELECT * FROM students 
WHERE sync_status = 'failed' 
AND sync_retry_count < 3
ORDER BY last_sync_attempt DESC;
```

### Backend (JSON)

#### Load sync registry
```python
import json

with open('sync_registry.json', 'r') as f:
    registry = json.load(f)

# Get specific sync
sync = registry['syncs']['sync_abc123']
print(sync['status'])
print(sync['processing_stages'])
```

#### Check processing queue
```python
# In processing_queue.py
print(f"Queue size: {processing_queue.queue.qsize()}")
print(f"Active jobs: {len([j for j in processing_queue.jobs_status.values() if j.status == 'processing'])}")
```

---

## 📝 Logging

### View Logs

**Mobile:**
```dart
// Logs stored in app documents directory
final appDir = await getApplicationDocumentsDirectory();
final logFile = File('${appDir.path}/${SyncConfig.logFileName}');
final logs = await logFile.readAsString();
print(logs);
```

**Backend:**
```powershell
# View real-time logs
Get-Content backend/logs/sync_operations.log -Wait -Tail 50

# Search for specific sync
Select-String -Path backend/logs/sync_operations.log -Pattern "sync_abc123"
```

### Log Format

**Mobile:**
```
[2025-11-05 10:30:00] [INFO] [SYNC] Sync initiated for student: uuid-123
[2025-11-05 10:30:01] [INFO] [NETWORK] POST /api/sync/student - 200 OK (234ms)
```

**Backend:**
```json
{
  "timestamp": "2025-11-05T10:30:00Z",
  "level": "INFO",
  "message": "Sync operation started",
  "sync_id": "sync_123",
  "student_id": "S12345"
}
```

---

## 🧪 Testing

### Manual Testing Checklist

- [ ] Register a new student in mobile app
- [ ] Verify student appears in mobile database with status "not_synced"
- [ ] Open app again to trigger sync
- [ ] Verify status changes: not_synced → syncing → synced → processing → completed
- [ ] Check backend database for student record
- [ ] Verify images are saved in `backend/uploads/sync_images/{student_id}/`
- [ ] Check embeddings generated: `backend/processed_faces/{student_id}/embeddings.npy`
- [ ] Verify sync logs in both mobile and backend
- [ ] Test offline: turn off wifi, verify sync is queued
- [ ] Turn on wifi, verify queued sync executes
- [ ] Test error: provide invalid sync_id, verify error handling

### Performance Benchmarks

| Operation | Target | Acceptable | Poor |
|-----------|--------|------------|------|
| Sync student data | < 1s | < 3s | > 5s |
| Upload 5 images | < 5s | < 10s | > 15s |
| Face detection | < 2s | < 5s | > 10s |
| Embedding generation | < 30s | < 60s | > 120s |
| Total processing | < 2min | < 5min | > 10min |

---

## 🔐 Security Notes

1. **Use HTTPS in production** (not HTTP)
2. **Implement JWT authentication** for API endpoints
3. **Encrypt sensitive data** in mobile database
4. **Validate all inputs** on backend
5. **Rate limit** sync endpoints
6. **Sanitize file uploads**
7. **Log all access attempts**

---

## 🚀 Production Deployment

### Backend

1. Update configuration:
   ```python
   # sync_config.py
   BACKEND_BASE_URL = 'https://api.hadir.university.edu'
   ```

2. Use production web server:
   ```bash
   gunicorn -w 4 -b 0.0.0.0:5000 app:app
   ```

3. Set up HTTPS with Let's Encrypt

4. Configure log rotation

### Mobile

1. Update backend URL:
   ```dart
   static const String backendBaseUrl = 'https://api.hadir.university.edu';
   ```

2. Build release APK/IPA:
   ```bash
   flutter build apk --release
   flutter build ios --release
   ```

3. Test on physical devices

4. Submit to app stores

---

## 📞 Support

| Issue Type | Contact |
|------------|---------|
| Technical questions | Create GitHub issue with `[SYNC]` prefix |
| Bug reports | Create GitHub issue with `[BUG]` prefix |
| Feature requests | Create GitHub issue with `[FEATURE]` prefix |

---

## 📖 Additional Resources

- [Flask Documentation](https://flask.palletsprojects.com/)
- [Flutter Dio Package](https://pub.dev/packages/dio)
- [SQLite Documentation](https://www.sqlite.org/docs.html)
- [MobileFaceNet Paper](https://arxiv.org/abs/1804.07573)

---

**Version:** 1.0  
**Maintained by:** Development Team  
**Last Review:** November 5, 2025
