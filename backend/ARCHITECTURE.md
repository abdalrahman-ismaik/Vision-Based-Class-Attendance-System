# System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│                         VISION-BASED ATTENDANCE SYSTEM                       │
│                         Face Processing Pipeline v1.0                        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                              CLIENT LAYER                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                  │
│   │   Web UI    │    │ Mobile App  │    │  Postman    │                  │
│   │  (Future)   │    │  (Future)   │    │   / cURL    │                  │
│   └──────┬──────┘    └──────┬──────┘    └──────┬──────┘                  │
│          │                   │                   │                          │
│          └───────────────────┴───────────────────┘                          │
│                              │                                              │
│                         HTTP/REST API                                       │
│                              │                                              │
└──────────────────────────────┼──────────────────────────────────────────────┘
                               │
┌──────────────────────────────┼──────────────────────────────────────────────┐
│                              ▼                                              │
│                         API GATEWAY                                         │
│                    Flask + Flask-RESTX                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌────────────────────────────────────────────────────────────────────┐   │
│  │                      Swagger UI (/api/docs)                        │   │
│  │          Interactive API Documentation & Testing                   │   │
│  └────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────┐  ┌──────────────────┐  ┌─────────────────────┐      │
│  │   Students NS   │  │    Classes NS    │  │   Attendance NS     │      │
│  ├─────────────────┤  ├──────────────────┤  ├─────────────────────┤      │
│  │ • Register      │  │ • Create Class   │  │ • Mark Attendance   │      │
│  │ • List          │  │ • Add Students   │  │ • View Records      │      │
│  │ • Get Details   │  │ • Remove Student │  │                     │      │
│  │ • Delete        │  │ • List Students  │  │                     │      │
│  │ • Train Model   │  │ • Update Class   │  │                     │      │
│  │ • Recognize     │  │ • Delete Class   │  │                     │      │
│  └────────┬────────┘  └────────┬─────────┘  └──────────┬──────────┘      │
│           │                    │                        │                  │
└───────────┼────────────────────┼────────────────────────┼──────────────────┘
            │                    │                        │
┌───────────┼────────────────────┼────────────────────────┼──────────────────┐
│           ▼                    ▼                        ▼                  │
│                       BUSINESS LOGIC LAYER                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────┐     │
│  │              Face Processing Pipeline Manager                    │     │
│  │                (Lazy Loading, Thread-Safe)                       │     │
│  └────────────────────────────┬─────────────────────────────────────┘     │
│                               │                                            │
│  ┌────────────────────────────┴─────────────────────────────────────┐     │
│  │                                                                   │     │
│  │   ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │     │
│  │   │     Face     │  │    Image     │  │     Embedding        │  │     │
│  │   │   Detector   │  │  Augmentor   │  │     Generator        │  │     │
│  │   ├──────────────┤  ├──────────────┤  ├──────────────────────┤  │     │
│  │   │ RetinaFace   │  │ 20+ Methods: │  │  MobileFaceNet       │  │     │
│  │   │ threshold:   │  │ • Zoom       │  │  • 512-D vectors     │  │     │
│  │   │   0.9        │  │ • Brightness │  │  • L2 normalized     │  │     │
│  │   │              │  │ • Contrast   │  │  • Pre-trained       │  │     │
│  │   │              │  │ • Rotation   │  │  • 100% accuracy     │  │     │
│  │   │              │  │ • Noise      │  │                      │  │     │
│  │   └──────────────┘  └──────────────┘  └──────────────────────┘  │     │
│  │                                                                   │     │
│  │   ┌──────────────────────────────────────────────────────────┐  │     │
│  │   │              Face Classifier (SVM)                       │  │     │
│  │   │  • Multi-class classification                            │  │     │
│  │   │  • Linear kernel                                         │  │     │
│  │   │  • Probability estimates                                 │  │     │
│  │   │  • 80/20 train-test split                               │  │     │
│  │   └──────────────────────────────────────────────────────────┘  │     │
│  │                                                                   │     │
│  └───────────────────────────────────────────────────────────────────┘     │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────┐     │
│  │                Background Processing Manager                     │     │
│  │         (Threading for Non-Blocking Operations)                  │     │
│  └──────────────────────────────────────────────────────────────────┘     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                               │
┌──────────────────────────────┼──────────────────────────────────────────────┐
│                              ▼                                              │
│                        DATA LAYER                                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────────────┐  │
│  │  database.json   │  │  classes.json    │  │  classifier_metadata    │  │
│  │                  │  │                  │  │         .json           │  │
│  │ Student Records: │  │ Class Records:   │  │                         │  │
│  │ • student_id     │  │ • class_id       │  │ Training Metadata:      │  │
│  │ • name           │  │ • class_name     │  │ • n_students            │  │
│  │ • email          │  │ • instructor     │  │ • n_embeddings          │  │
│  │ • processing_    │  │ • student_ids[]  │  │ • train_accuracy        │  │
│  │   status         │  │ • semester       │  │ • test_accuracy         │  │
│  │ • embeddings_    │  │                  │  │ • trained_at            │  │
│  │   path           │  │                  │  │                         │  │
│  └──────────────────┘  └──────────────────┘  └─────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                               │
┌──────────────────────────────┼──────────────────────────────────────────────┐
│                              ▼                                              │
│                      FILE STORAGE LAYER                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  uploads/students/{id}/                    # Original Images                │
│  ├── {id}_timestamp.jpg                                                    │
│  └── ...                                                                    │
│                                                                             │
│  processed_faces/{id}/                     # Processed Data                 │
│  ├── aug_000.jpg  ◄───────────────────── Original                          │
│  ├── aug_001.jpg  ◄───────────────────── Zoom In 1.15x                     │
│  ├── aug_002.jpg  ◄───────────────────── Zoom In 1.3x                      │
│  ├── aug_003.jpg  ◄───────────────────── Zoom Out 0.85x                    │
│  ├── aug_004.jpg  ◄───────────────────── Brightness 0.6x                   │
│  ├── aug_005.jpg  ◄───────────────────── Brightness 0.8x                   │
│  ├── aug_006.jpg  ◄───────────────────── Brightness 1.2x                   │
│  ├── aug_007.jpg  ◄───────────────────── Brightness 1.4x                   │
│  ├── aug_008.jpg  ◄───────────────────── Contrast 0.8x                     │
│  ├── aug_009.jpg  ◄───────────────────── Contrast 1.2x                     │
│  ├── aug_010.jpg  ◄───────────────────── Rotation -10°                     │
│  ├── aug_011.jpg  ◄───────────────────── Rotation +10°                     │
│  ├── aug_012.jpg  ◄───────────────────── Rotation -5°                      │
│  ├── aug_013.jpg  ◄───────────────────── Rotation +5°                      │
│  ├── aug_014.jpg  ◄───────────────────── Gaussian Noise σ=5                │
│  ├── aug_015.jpg  ◄───────────────────── Gaussian Noise σ=15               │
│  ├── aug_016.jpg  ◄───────────────────── Brightness + Zoom                 │
│  ├── aug_017.jpg  ◄───────────────────── Brightness + Zoom Out             │
│  ├── aug_018.jpg  ◄───────────────────── Contrast + Rotation               │
│  ├── aug_019.jpg  ◄───────────────────── Noise + Brightness                │
│  ├── aug_020.jpg  ◄───────────────────── Combined                          │
│  └── embeddings.npy  ◄──────────────── (21, 512) float32 array             │
│                                                                             │
│  classifiers/                              # Trained Models                 │
│  ├── face_classifier.pkl  ◄──────────── Trained SVM Classifier             │
│  └── classifier_metadata.json                                              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════════════
                              PROCESSING WORKFLOW
═══════════════════════════════════════════════════════════════════════════════

┌────────────────────────────────────────────────────────────────────────────┐
│                          STUDENT REGISTRATION                               │
└────────────────────────────────────────────────────────────────────────────┘
    │
    ├─► 1. Receive Image Upload (POST /api/students/)
    │       ├─ Validate image format
    │       ├─ Save original image
    │       └─ Create student record (status: "pending")
    │
    ├─► 2. Start Background Thread ⚡
    │       └─ Non-blocking, returns immediately
    │
    └─► 3. Background Processing (5-10 seconds)
            │
            ├─► Face Detection (RetinaFace)
            │   └─ Find face, crop with 20% margin
            │
            ├─► Generate 20 Augmentations
            │   ├─ Zoom variations
            │   ├─ Brightness adjustments
            │   ├─ Contrast changes
            │   ├─ Rotations
            │   ├─ Gaussian noise
            │   └─ Combinations
            │
            ├─► Save Augmented Images
            │   └─ processed_faces/{id}/aug_*.jpg
            │
            ├─► Generate Embeddings (MobileFaceNet)
            │   ├─ Process each augmentation
            │   ├─ Extract 512-D vector
            │   └─ L2 normalize
            │
            ├─► Save Embeddings
            │   └─ processed_faces/{id}/embeddings.npy
            │
            └─► Update Status
                └─ status: "completed" (or "failed")

┌────────────────────────────────────────────────────────────────────────────┐
│                        CLASSIFIER TRAINING                                  │
└────────────────────────────────────────────────────────────────────────────┘
    │
    ├─► 1. Trigger Training (POST /api/students/train-classifier)
    │       └─ Requires at least 2 students
    │
    ├─► 2. Collect All Embeddings
    │       ├─ Load embeddings.npy from each student
    │       └─ Stack into single array
    │
    ├─► 3. Train SVM Classifier
    │       ├─ 80/20 train-test split
    │       ├─ Fit linear SVM
    │       └─ Evaluate accuracy
    │
    └─► 4. Save Model
            ├─ classifiers/face_classifier.pkl
            └─ classifiers/classifier_metadata.json

┌────────────────────────────────────────────────────────────────────────────┐
│                         FACE RECOGNITION                                    │
└────────────────────────────────────────────────────────────────────────────┘
    │
    ├─► 1. Upload Test Image (POST /api/students/recognize)
    │
    ├─► 2. Detect Face (RetinaFace)
    │       └─ Crop with margin
    │
    ├─► 3. Generate Embedding (MobileFaceNet)
    │       └─ 512-D vector
    │
    ├─► 4. Classify (SVM)
    │       ├─ Predict student_id
    │       └─ Get confidence score
    │
    └─► 5. Return Result
            ├─ Student ID
            ├─ Confidence
            ├─ Bounding box
            └─ Student info

═══════════════════════════════════════════════════════════════════════════════
                              TECHNOLOGY STACK
═══════════════════════════════════════════════════════════════════════════════

┌──────────────────────┬────────────────────────────────────────────────────┐
│ Category             │ Technology                                         │
├──────────────────────┼────────────────────────────────────────────────────┤
│ Web Framework        │ Flask 3.0.0                                        │
│ API Framework        │ Flask-RESTX 1.3.0 (REST + Swagger)                 │
│ Face Detection       │ RetinaFace (PyPI)                                  │
│ Face Recognition     │ MobileFaceNet + ArcFace                            │
│ Deep Learning        │ PyTorch 2.0+                                       │
│ Image Processing     │ OpenCV 4.8, Pillow 10.1                            │
│ ML Classifier        │ scikit-learn 1.3 (SVM)                             │
│ Data Storage         │ JSON files (students, classes)                     │
│ Async Processing     │ Python Threading                                   │
│ Documentation        │ Swagger UI (auto-generated)                        │
└──────────────────────┴────────────────────────────────────────────────────┘
```
