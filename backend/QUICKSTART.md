# Quick Start Guide - Face Processing Pipeline

## Prerequisites

1. **Python 3.8+** installed
2. **CUDA** (optional, for GPU acceleration)
3. **FaceNet Model** checkpoint at: `../FaceNet/mobilefacenet_arcface/best_model_epoch43_acc100.00.pth`

## Installation

### 1. Install Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 2. Verify FaceNet Model

Ensure the model checkpoint exists:

```bash
ls ../FaceNet/mobilefacenet_arcface/best_model_epoch43_acc100.00.pth
```

If not found, download or train the model first.

## Quick Start

### Option 1: Using the Test Script

```bash
# Start the Flask server (in one terminal)
python app.py

# Run tests (in another terminal)
python test_pipeline.py --test all
```

### Option 2: Manual API Testing

#### Step 1: Start Server

```bash
python app.py
```

Server will start at: `http://localhost:5000`  
Swagger UI at: `http://localhost:5000/api/docs`

#### Step 2: Register Students

**Single Image (for backwards compatibility):**

```bash
curl -X POST http://localhost:5000/api/students/ \
  -F "student_id=S001" \
  -F "name=John Doe" \
  -F "email=john@example.com" \
  -F "image=@path/to/john.jpg"
```

**Multiple Images (recommended - different poses):**

```bash
# Register with multiple poses for better accuracy
curl -X POST http://localhost:5000/api/students/ \
  -F "student_id=S002" \
  -F "name=Jane Smith" \
  -F "email=jane@example.com" \
  -F "images=@path/to/jane_front.jpg" \
  -F "images=@path/to/jane_left.jpg" \
  -F "images=@path/to/jane_right.jpg"
```

**Response:**

```json
{
  "message": "Student registered successfully. Face processing started in background.",
  "student": {
    "student_id": "S002",
    "processing_status": "pending",
    "num_poses": 3,
    ...
  }
}
```

#### Step 3: Wait for Processing

Check status (wait until `processing_status` is `completed`):

```bash
curl http://localhost:5000/api/students/S001
```

**Response:**

```json
{
  "student_id": "S002",
  "name": "Jane Smith",
  "processing_status": "completed",
  "num_poses": 3,
  "num_poses_captured": 3,
  "num_samples_total": 63,
  "embeddings_path": "/path/to/processed_faces/S002/embeddings.npy",
  ...
}
```

Note: With 3 poses and 20 augmentations per pose, you get 3 × 21 = 63 total samples!

#### Step 4: Train Classifier

After **at least 2 students** are processed:

```bash
curl -X POST http://localhost:5000/api/students/train-classifier
```

**Response:**

```json
{
  "message": "Classifier trained successfully",
  "metadata": {
    "n_students": 2,
    "n_embeddings": 42,
    "train_accuracy": 0.97,
    "test_accuracy": 0.95
  }
}
```

#### Step 5: Recognize Faces

```bash
curl -X POST http://localhost:5000/api/students/recognize \
  -F "image=@path/to/test_photo.jpg"
```

**Response:**

```json
{
  "recognized": true,
  "student_id": "S001",
  "confidence": 0.87,
  "bbox": [120, 80, 320, 280],
  "student_info": {
    "student_id": "S001",
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

## Using Swagger UI

Visit `http://localhost:5000/api/docs` for interactive API documentation.

### Available Endpoints:

**Students:**

- `GET /api/students/` - List all students
- `POST /api/students/` - Register new student
- `GET /api/students/{student_id}` - Get student details
- `DELETE /api/students/{student_id}` - Delete student
- `POST /api/students/train-classifier` - Train face classifier
- `POST /api/students/recognize` - Recognize face in image

**Classes:**

- `GET /api/classes/` - List all classes
- `POST /api/classes/` - Create new class
- `GET /api/classes/{class_id}` - Get class details
- `PUT /api/classes/{class_id}` - Update class
- `DELETE /api/classes/{class_id}` - Delete class
- `GET /api/classes/{class_id}/students` - Get students in class
- `POST /api/classes/{class_id}/students` - Add student to class
- `DELETE /api/classes/{class_id}/students` - Remove student from class

## What Happens Automatically?

When you register a student, the system automatically:

1. **Saves Original Images** → `uploads/students/{student_id}/` (supports multiple poses)
2. **Detects Faces** → Using RetinaFace on each image
3. **Generates 20 Augmentations per Pose:**
   - Zoom variations (in/out)
   - Brightness adjustments (dim/bright)
   - Contrast changes
   - Rotations
   - Gaussian noise
   - Combinations
4. **Saves Processed Images** → `processed_faces/{student_id}/pose{X}_aug{Y}.jpg`
5. **Generates Embeddings** → 512-dimensional vectors for each sample
6. **Saves All Embeddings** → `processed_faces/{student_id}/embeddings.npy`
7. **Updates Status** → `processing_status: "completed"`

**Performance:**
- Single pose: ~5-10 seconds
- Multiple poses (3): ~15-25 seconds
- More poses = better recognition accuracy!

## Troubleshooting

### "Pipeline not available"

```bash
# Check if FaceNet model exists
ls ../FaceNet/mobilefacenet_arcface/*.pth
```

### "No face detected"

- Ensure face is clearly visible
- Use well-lit, front-facing photos
- Face should be at least 50x50 pixels

### "Need at least 2 students"

```bash
# Register more students first
# Check registered count
curl http://localhost:5000/api/students/
```

### Low accuracy

- Add more students
- Use better quality images
- Retrain classifier
- Check processed augmentations

## Directory Structure After Processing

```
backend/
├── uploads/
│   └── students/
│       ├── S001/
│       │   └── S001_pose1_20251020_120000.jpg  # Single pose
│       └── S002/
│           ├── S002_pose1_20251020_120100.jpg  # Multiple poses
│           ├── S002_pose2_20251020_120101.jpg
│           └── S002_pose3_20251020_120102.jpg
├── processed_faces/
│   ├── S001/
│   │   ├── pose1_aug0.jpg   # Original from pose 1
│   │   ├── pose1_aug1.jpg   # Augmentations from pose 1
│   │   ├── ...
│   │   ├── pose1_aug20.jpg
│   │   └── embeddings.npy   # (21, 512) array - single pose
│   └── S002/
│       ├── pose1_aug0.jpg   # Pose 1 original
│       ├── pose1_aug1.jpg   # Pose 1 augmentations
│       ├── ...
│       ├── pose2_aug0.jpg   # Pose 2 original
│       ├── pose2_aug1.jpg   # Pose 2 augmentations
│       ├── ...
│       ├── pose3_aug0.jpg   # Pose 3 original
│       ├── pose3_aug1.jpg   # Pose 3 augmentations
│       ├── ...
│       └── embeddings.npy   # (63, 512) array - 3 poses × 21 samples
└── classifiers/
    ├── face_classifier.pkl          # Binary SVM per student
    └── classifier_metadata.json
```

## Performance

- **Registration**: ~1 second
- **Face Processing**: ~5-10 seconds per student (background)
- **Classifier Training**: ~1-2 seconds for 10 students
- **Recognition**: ~200ms per image

## Next Steps

1. **Add more students** to improve accuracy
2. **Create classes** and add students to them
3. **Integrate with attendance marking**
4. **Build frontend** for easy interaction

## Support

For issues or questions, check:

- `PIPELINE_README.md` - Detailed documentation
- API logs - Console output from `app.py`
- Swagger UI - Interactive API docs

## Example: Complete Workflow

```bash
# Terminal 1: Start server
cd backend
python app.py

# Terminal 2: Run complete test
python test_pipeline.py --test all

# Or step by step:
python test_pipeline.py --test health
python test_pipeline.py --test register
python test_pipeline.py --test status
python test_pipeline.py --test train
python test_pipeline.py --test recognize
```

Done! 🎉
