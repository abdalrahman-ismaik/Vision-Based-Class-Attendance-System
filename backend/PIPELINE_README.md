# Face Processing Pipeline

This document describes the automated face processing pipeline integrated into the Vision-Based Class Attendance System backend.

## Overview

When a student image is uploaded, the system automatically:

1. **Detects the face** using RetinaFace detector
2. **Generates augmentations** (zoom, brightness, rotation, noise, etc.)
3. **Extracts face embeddings** using MobileFaceNet (FaceNet)
4. **Trains a classifier** to recognize the student among all registered students

## Pipeline Components

### 1. Face Detection

- **Detector**: RetinaFace (via PyPI package)
- **Threshold**: 0.9 (high confidence)
- **Margin**: 20% padding around detected face

### 2. Image Augmentation

The system generates **20 augmentations** per student image:

#### Augmentation Types:

- **Zoom Variations**

  - Zoom in 1.15x
  - Zoom in 1.3x
  - Zoom out 0.85x

- **Brightness Adjustments**

  - Dim: 0.6x, 0.8x
  - Bright: 1.2x, 1.4x

- **Contrast Adjustments**

  - 0.8x, 1.2x

- **Rotation**

  - -10°, -5°, +5°, +10°

- **Gaussian Noise**

  - σ = 5, σ = 15

- **Combinations**
  - Brightness + Zoom
  - Contrast + Rotation
  - Noise + Brightness

### 3. Embedding Generation

- **Model**: MobileFaceNet with ArcFace loss
- **Checkpoint**: `best_model_epoch43_acc100.00.pth` (100% accuracy on training data)
- **Embedding Size**: 512 dimensions
- **Normalization**: L2 normalized (for cosine similarity)
- **Preprocessing**:
  - Resize to 112x112
  - Normalize with FaceNet mean/std

### 4. Classifier Training

- **Algorithm**: Support Vector Machine (SVM) with linear kernel
- **Input**: 512-dimensional embeddings from all students
- **Output**: Multi-class classifier for student identification
- **Evaluation**: 80/20 train-test split with stratification

## API Endpoints

### Student Registration (Automatic Processing)

```http
POST /api/students/
Content-Type: multipart/form-data

student_id: "S12345"
name: "John Doe"
email: "john@example.com"
image: <file>
```

**Response:**

```json
{
  "message": "Student registered successfully. Face processing started in background.",
  "student": {
    "student_id": "S12345",
    "name": "John Doe",
    "processing_status": "pending",
    ...
  }
}
```

The system automatically:

- Saves the image
- Starts background face processing
- Updates `processing_status` to `completed` or `failed`

### Train Classifier

```http
POST /api/students/train-classifier
```

**Response:**

```json
{
  "message": "Classifier trained successfully",
  "metadata": {
    "trained_at": "2025-10-20T...",
    "n_students": 10,
    "n_embeddings": 200,
    "train_accuracy": 0.98,
    "test_accuracy": 0.95
  }
}
```

**Requirements:**

- At least 2 students with processed faces
- All students must have completed processing

### Recognize Face

```http
POST /api/students/recognize
Content-Type: multipart/form-data

image: <file>
```

**Response:**

```json
{
  "recognized": true,
  "student_id": "S12345",
  "confidence": 0.87,
  "bbox": [120, 80, 320, 280],
  "student_info": {
    "student_id": "S12345",
    "name": "John Doe",
    "email": "john@example.com",
    ...
  }
}
```

## Directory Structure

```
backend/
├── app.py                          # Main Flask app
├── face_processing_pipeline.py    # Pipeline implementation
├── database.json                   # Student database
├── classes.json                    # Class database
├── uploads/
│   ├── students/                   # Original uploaded images
│   │   └── S12345/
│   │       └── S12345_20251020_120000.jpg
│   └── temp/                       # Temporary files
├── processed_faces/                # Processed augmented images
│   └── S12345/
│       ├── aug_000.jpg            # Original
│       ├── aug_001.jpg            # Zoom in
│       ├── aug_002.jpg            # Brightness adjusted
│       ├── ...
│       └── embeddings.npy         # All embeddings (20x512)
└── classifiers/
    ├── face_classifier.pkl        # Trained SVM classifier
    └── classifier_metadata.json   # Training metadata
```

## Processing Status

Students have a `processing_status` field with these values:

- **`pending`**: Face processing not started yet
- **`completed`**: Successfully processed, embeddings saved
- **`failed`**: Processing failed (no face detected or error)

You can check status:

```http
GET /api/students/{student_id}
```

## Example Workflow

### 1. Register Multiple Students

```bash
# Register student 1
curl -X POST http://localhost:5000/api/students/ \
  -F "student_id=S12345" \
  -F "name=John Doe" \
  -F "image=@john.jpg"

# Register student 2
curl -X POST http://localhost:5000/api/students/ \
  -F "student_id=S67890" \
  -F "name=Jane Smith" \
  -F "image=@jane.jpg"
```

### 2. Wait for Processing

Check status:

```bash
curl http://localhost:5000/api/students/S12345
```

Wait until `processing_status` is `completed` for all students.

### 3. Train Classifier

```bash
curl -X POST http://localhost:5000/api/students/train-classifier
```

### 4. Recognize Faces

```bash
curl -X POST http://localhost:5000/api/students/recognize \
  -F "image=@test_photo.jpg"
```

## Performance Considerations

### Background Processing

- Image processing runs in a **background thread**
- API responds immediately after saving the image
- Processing takes ~5-10 seconds per student
- Multiple students can be processed in parallel

### Memory Usage

- Pipeline loaded once and cached
- Model kept in GPU/CPU memory
- ~500MB GPU memory for MobileFaceNet

### Training Time

- SVM training is fast: ~1-2 seconds for 10 students
- Retrain after adding new students

## Error Handling

The pipeline handles various error cases:

1. **No face detected**: Status set to `failed` with error message
2. **Pipeline initialization failure**: Returns appropriate error response
3. **Classifier not trained**: Returns helpful error with hint
4. **Invalid image format**: Validated before processing

## Configuration

Key parameters in `face_processing_pipeline.py`:

```python
# Face detection
DETECTOR_THRESHOLD = 0.9
FACE_MARGIN = 0.2  # 20% padding

# Augmentation
NUM_AUGMENTATIONS = 20

# Recognition
RECOGNITION_THRESHOLD = 0.5  # Confidence threshold
```

## Dependencies

Required packages:

```txt
torch
torchvision
numpy
PIL
opencv-python
scikit-learn
retinaface-pytorch (or retina-face)
```

Install with:

```bash
pip install -r requirements.txt
```

## Troubleshooting

### Issue: "Pipeline not available"

**Solution**: Check that FaceNet model checkpoint exists at:

```
../FaceNet/mobilefacenet_arcface/best_model_epoch43_acc100.00.pth
```

### Issue: "No face detected"

**Solutions**:

- Ensure face is clearly visible in image
- Face should be front-facing
- Adequate lighting
- Lower detection threshold if needed

### Issue: "Classifier not trained yet"

**Solution**: Train classifier first:

```bash
POST /api/students/train-classifier
```

### Issue: Low recognition accuracy

**Solutions**:

- Add more students (better training data)
- Ensure high-quality images
- Retrain classifier
- Adjust recognition threshold

## Advanced Features

### Custom Augmentations

Modify `ImageAugmentor.generate_augmentations()` to add custom augmentation strategies.

### Different Classifiers

Replace SVM with other classifiers in `FaceClassifier` class:

- Random Forest
- K-Nearest Neighbors
- Neural Network

### Batch Processing

Process multiple students at once using threading or multiprocessing.

## License

This pipeline uses:

- MobileFaceNet (Apache 2.0)
- RetinaFace (MIT)
- scikit-learn (BSD)
