# HADIR Frame Selection Microservice

AI-powered frame selection service for the HADIR student registration system. This microservice uses advanced computer vision algorithms to select optimal frames from video recordings based on face quality, pose diversity, and lighting conditions.

## Features

- **Face Detection**: MediaPipe-based face detection with confidence scoring
- **Pose Estimation**: Head pose analysis (yaw, pitch, roll) for diversity assessment
- **Quality Assessment**: Image sharpness and lighting quality evaluation
- **Diversity Scoring**: Intelligent selection of diverse poses for better coverage
- **FastAPI Framework**: High-performance REST API with automatic documentation

## API Endpoints

### POST /select-frames
Select optimal frames from uploaded video file.

**Parameters:**
- `video`: Video file (multipart/form-data)
- `quality_threshold`: Minimum quality score (0.0-1.0, default: 0.8)
- `target_frame_count`: Number of frames to select (default: 5)
- `diversity_weight`: Weight for pose diversity (0.0-1.0, default: 0.3)
- `quality_weight`: Weight for frame quality (0.0-1.0, default: 0.7)

**Response:**
```json
{
  "selected_frames": [
    {
      "timestamp": 2.5,
      "quality_score": 0.85,
      "pose_angles": {"yaw": -15.2, "pitch": 5.1, "roll": 2.3},
      "face_confidence": 0.92,
      "sharpness_score": 0.78,
      "lighting_score": 0.81,
      "diversity_score": 0.95
    }
  ],
  "total_analyzed": 45,
  "processing_time_seconds": 3.2,
  "quality_metrics": {
    "average_quality": 0.83,
    "total_candidates": 45,
    "quality_candidates": 12,
    "pose_diversity": 0.87
  }
}
```

### GET /health
Health check endpoint.

### GET /
Service information and available endpoints.

### GET /docs
Interactive API documentation (Swagger UI).

## Installation

1. **Create virtual environment:**
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. **Install dependencies:**
```bash
pip install -r requirements.txt
```

3. **Run the service:**
```bash
python main.py
```

The service will start on `http://localhost:8000`

## Development

### Running with Uvicorn (for development):
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Testing the API:
1. Open `http://localhost:8000/docs` for interactive documentation
2. Upload a video file using the `/select-frames` endpoint
3. Review the selected frames and quality metrics

## Algorithm Details

### Frame Analysis Pipeline
1. **Face Detection**: Uses MediaPipe Face Detection for robust face identification
2. **Pose Estimation**: Calculates head pose angles using facial landmarks
3. **Quality Assessment**: 
   - Sharpness: Laplacian variance method
   - Lighting: Histogram analysis for balanced exposure
   - Face confidence: Detection confidence score
4. **Diversity Scoring**: Euclidean distance in pose space to ensure varied poses

### Selection Algorithm
1. **Filtering**: Remove frames below quality threshold
2. **Diversity Selection**: Greedy algorithm to maximize pose coverage
3. **Scoring**: Combined quality and diversity score with configurable weights
4. **Temporal Ordering**: Final frames sorted by timestamp

## Integration with Flutter App

The Flutter app communicates with this service via HTTP requests:

```dart
// Example Dart integration
final response = await dio.post(
  'http://localhost:8000/select-frames',
  data: FormData.fromMap({
    'video': await MultipartFile.fromFile(videoPath),
    'quality_threshold': 0.8,
    'target_frame_count': 5,
  }),
);
```

## Performance

- **Processing Speed**: ~10-15 frames per second analysis
- **Memory Usage**: ~100-200MB for typical videos
- **Accuracy**: >90% face detection accuracy in good lighting
- **Pose Coverage**: Optimized for diverse head pose selection

## Production Deployment

For production deployment:

1. **Docker Container:**
```dockerfile
FROM python:3.9-slim
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

2. **Environment Variables:**
- `HOST`: Service host (default: 0.0.0.0)
- `PORT`: Service port (default: 8000)
- `LOG_LEVEL`: Logging level (default: INFO)

3. **Scaling:** Use multiple instances behind a load balancer for high throughput

## License

Part of the HADIR project - University of Kuwait, Fall 2025.