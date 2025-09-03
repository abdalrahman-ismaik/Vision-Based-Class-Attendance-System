# System Design Document
## Vision-based Class Attendance System

### Document Information
- **Project**: Vision-based Class Attendance System
- **Course**: COSC3030 - Introduction to Artificial Intelligence
- **Version**: 1.0
- **Date**: September 2025

---

## 1. System Architecture Overview

### 1.1 High-Level Architecture
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Mobile App    │───▶│   Server/API     │───▶│    Database     │
│  (Enrollment)   │    │                  │    │   (Students)    │
└─────────────────┘    │                  │    └─────────────────┘
                       │                  │
┌─────────────────┐    │                  │    ┌─────────────────┐
│  CCTV Cameras   │───▶│  Core Engine     │───▶│   Web Dashboard │
│ (Live Streams)  │    │ (Face Detection  │    │  (Attendance)   │
└─────────────────┘    │ & Recognition)   │    └─────────────────┘
                       └──────────────────┘
```

### 1.2 Component Architecture
The system follows a modular architecture with the following components:

1. **Data Layer**: Database management and storage
2. **Service Layer**: Core business logic and AI processing
3. **API Layer**: RESTful services for client communication
4. **Presentation Layer**: Mobile app and web dashboard
5. **Integration Layer**: CCTV camera interfaces

---

## 2. Detailed Component Design

### 2.1 Face Detection Module
**Purpose**: Detect and locate faces in video frames

**Key Components**:
- **Face Detector**: MTCNN or YOLO-based face detection
- **Face Cropper**: Extract face regions from detected bounding boxes
- **Quality Assessor**: Filter low-quality face images

**Input**: Video frames from CCTV
**Output**: Cropped face images with bounding box coordinates

**Algorithm Flow**:
```python
def detect_faces(frame):
    # 1. Preprocess frame (resize, normalize)
    processed_frame = preprocess(frame)
    
    # 2. Run face detection model
    detections = face_detector.detect(processed_frame)
    
    # 3. Filter detections by confidence threshold
    valid_faces = filter_by_confidence(detections, threshold=0.8)
    
    # 4. Extract face crops
    face_crops = extract_face_regions(frame, valid_faces)
    
    return face_crops, valid_faces
```

### 2.2 Face Recognition Module
**Purpose**: Extract face embeddings and perform recognition

**Key Components**:
- **FaceNet Model**: Pre-trained deep neural network
- **Feature Extractor**: Generate 128-dimensional embeddings
- **Similarity Matcher**: Compare embeddings using cosine distance

**Algorithm Flow**:
```python
def recognize_faces(face_crops):
    results = []
    for face_crop in face_crops:
        # 1. Preprocess face for FaceNet
        normalized_face = preprocess_for_facenet(face_crop)
        
        # 2. Extract 128-D embedding
        embedding = facenet_model.predict(normalized_face)
        
        # 3. Compare with enrolled students
        best_match = find_best_match(embedding, student_gallery)
        
        # 4. Apply threshold for recognition
        if best_match['distance'] < RECOGNITION_THRESHOLD:
            results.append({
                'student_id': best_match['student_id'],
                'confidence': 1 - best_match['distance'],
                'status': 'recognized'
            })
        else:
            results.append({
                'student_id': None,
                'confidence': 0,
                'status': 'unknown'
            })
    
    return results
```

### 2.3 Student Gallery Management
**Purpose**: Manage enrolled student face embeddings

**Data Structure**:
```python
class StudentGallery:
    def __init__(self):
        self.students = {}  # student_id -> embeddings
        
    def enroll_student(self, student_id, face_images):
        """Extract and store multiple embeddings per student"""
        embeddings = []
        for image in face_images:
            embedding = self.extract_embedding(image)
            embeddings.append(embedding)
        
        self.students[student_id] = {
            'embeddings': embeddings,
            'enrolled_date': datetime.now(),
            'metadata': {}
        }
    
    def find_match(self, query_embedding):
        """Find best matching student using cosine distance"""
        best_match = None
        min_distance = float('inf')
        
        for student_id, data in self.students.items():
            for embedding in data['embeddings']:
                distance = cosine_distance(query_embedding, embedding)
                if distance < min_distance:
                    min_distance = distance
                    best_match = student_id
        
        return best_match, min_distance
```

### 2.4 Database Schema

**Students Table**:
```sql
CREATE TABLE students (
    id INTEGER PRIMARY KEY,
    student_id VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    enrolled_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    face_embedding BLOB,  -- Serialized numpy array
    is_active BOOLEAN DEFAULT TRUE
);
```

**Attendance Table**:
```sql
CREATE TABLE attendance (
    id INTEGER PRIMARY KEY,
    student_id VARCHAR(20) NOT NULL,
    class_date DATE NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    confidence FLOAT,
    camera_id VARCHAR(50),
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    UNIQUE(student_id, class_date)  -- Prevent duplicate attendance
);
```

**Classes Table**:
```sql
CREATE TABLE classes (
    id INTEGER PRIMARY KEY,
    class_name VARCHAR(100) NOT NULL,
    class_code VARCHAR(20) UNIQUE,
    schedule_time TIME,
    room_number VARCHAR(20)
);
```

### 2.5 API Endpoints Design

**Student Enrollment API**:
```python
@app.route('/api/enroll', methods=['POST'])
def enroll_student():
    """
    Endpoint for mobile app enrollment
    Expected payload:
    {
        "student_id": "12345",
        "name": "John Doe",
        "face_image": "base64_encoded_image"
    }
    """
    data = request.json
    
    # Validate input
    if not validate_enrollment_data(data):
        return {"error": "Invalid input data"}, 400
    
    # Process face image
    face_image = decode_base64_image(data['face_image'])
    embedding = extract_face_embedding(face_image)
    
    # Store in database
    student_db.enroll_student(
        student_id=data['student_id'],
        name=data['name'],
        embedding=embedding
    )
    
    return {"status": "success", "message": "Student enrolled"}, 200
```

**Recognition API**:
```python
@app.route('/api/recognize', methods=['POST'])
def recognize_frame():
    """
    Process single frame for recognition
    Expected payload: video frame as base64 or multipart
    """
    frame = decode_uploaded_frame(request)
    
    # Detect faces
    face_crops, detections = detect_faces(frame)
    
    # Recognize faces
    recognition_results = recognize_faces(face_crops)
    
    # Log attendance
    for result in recognition_results:
        if result['status'] == 'recognized':
            log_attendance(result['student_id'])
    
    return {"results": recognition_results}, 200
```

### 2.6 Mobile App Design

**Enrollment Screen Flow**:
1. **Student ID Input**: Enter student identification
2. **Camera Capture**: Take multiple face photos (3-5 shots)
3. **Photo Review**: Allow user to retake if needed
4. **Submit**: Upload to server with progress indicator
5. **Confirmation**: Success/error feedback

**Key Features**:
- Real-time face detection preview
- Image quality validation
- Offline storage with sync capability
- Progress tracking for uploads

### 2.7 Web Dashboard Design

**Main Dashboard Components**:
- **Live Feed Monitor**: Display current camera status
- **Attendance Summary**: Today's attendance statistics
- **Student List**: Enrolled students management
- **Reports Section**: Generate and view attendance reports

**Pages Structure**:
```
Dashboard/
├── Home (attendance overview)
├── Students/
│   ├── List (enrolled students)
│   ├── Add (manual enrollment)
│   └── Details (individual student)
├── Reports/
│   ├── Daily
│   ├── Weekly
│   └── Export
└── Settings/
    ├── Camera Configuration
    └── Recognition Parameters
```

---

## 3. AI/ML Model Architecture

### 3.1 FaceNet Implementation
**Model Architecture**:
- **Input**: 160x160 RGB face image
- **Backbone**: Inception ResNet v1
- **Output**: 128-dimensional L2-normalized embedding

**Pre-processing Pipeline**:
```python
def preprocess_face(face_image):
    # 1. Resize to 160x160
    resized = cv2.resize(face_image, (160, 160))
    
    # 2. Normalize pixel values
    normalized = (resized - 127.5) / 128.0
    
    # 3. Expand dimensions for batch processing
    batch_ready = np.expand_dims(normalized, axis=0)
    
    return batch_ready
```

### 3.2 Recognition Threshold Optimization
**Approach**: Use validation dataset to determine optimal threshold

```python
def optimize_threshold(validation_data):
    thresholds = np.arange(0.3, 1.0, 0.05)
    best_threshold = 0.5
    best_f1 = 0.0
    
    for threshold in thresholds:
        predictions = []
        ground_truth = []
        
        for sample in validation_data:
            distance = compute_similarity(sample['embedding'], 
                                        sample['reference'])
            prediction = 1 if distance < threshold else 0
            predictions.append(prediction)
            ground_truth.append(sample['label'])
        
        f1 = f1_score(ground_truth, predictions)
        if f1 > best_f1:
            best_f1 = f1
            best_threshold = threshold
    
    return best_threshold, best_f1
```

---

## 4. Performance Considerations

### 4.1 Optimization Strategies
- **Model Quantization**: Reduce FaceNet model size for faster inference
- **Batch Processing**: Process multiple faces simultaneously
- **Caching**: Store recent embeddings to avoid recomputation
- **Async Processing**: Use queue-based processing for real-time streams

### 4.2 Scalability Design
- **Horizontal Scaling**: Support multiple processing nodes
- **Load Balancing**: Distribute camera streams across servers
- **Database Optimization**: Index critical fields for fast queries

### 4.3 Error Handling
- **Network Failures**: Implement retry mechanisms
- **Model Failures**: Fallback to alternative detection methods
- **Data Corruption**: Validate inputs and handle gracefully

---

## 5. Security and Privacy

### 5.1 Data Protection
- **Encryption**: AES-256 for face embeddings storage
- **Access Control**: Role-based permissions
- **Data Retention**: Automatic cleanup policies

### 5.2 Privacy Considerations
- **Consent Management**: Student opt-in/opt-out mechanisms
- **Data Minimization**: Store only necessary information
- **Anonymization**: Option to process without storing faces

---

## 6. Testing Strategy

### 6.1 Unit Testing
- Individual component functionality
- AI model accuracy validation
- Database operations testing

### 6.2 Integration Testing
- API endpoint testing
- Mobile app connectivity
- Camera integration validation

### 6.3 Performance Testing
- Load testing with multiple concurrent users
- Stress testing with high-volume video streams
- Memory and CPU usage monitoring

### 6.4 Acceptance Testing
- End-to-end user scenarios
- Accuracy testing with validation dataset
- Real-world classroom deployment testing