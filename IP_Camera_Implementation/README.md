# HADIR_web - Live Attendance Monitoring

Web-based real-time attendance monitoring system with face detection and recognition.

## Features

✅ **Real-time Face Detection**
- YuNet face detector (OpenCV)
- Fast and accurate detection
- Multiple faces per frame

✅ **Face Recognition**
- Integration with backend API
- MobileFaceNet + ArcFace embeddings
- Confidence scores

✅ **Visual Indicators**
- 🟢 Green boxes for registered students (with name + ID)
- 🔴 Red boxes for unknown faces
- Real-time bounding box overlay

✅ **Modern Web Dashboard**
- Live video feed (MJPEG stream)
- Statistics display
- Recent detections list
- Fullscreen mode

## Prerequisites

1. **Backend API Running**
   - The main backend API must be running at `http://127.0.0.1:5000`
   - Ensure face recognition classifier is trained
   - Students must be registered in the system

2. **YuNet Model**
   - Download the YuNet face detection model:
   ```
   https://github.com/opencv/opencv_zoo/raw/main/models/face_detection_yunet/face_detection_yunet_2023mar.onnx
   ```
   - Place in `HADIR_web/` directory or copy from `intro to ai demo/attendance_demo/`

3. **Camera**
   - Webcam or USB camera connected
   - Camera index typically 0 for default webcam

## Installation

1. **Navigate to HADIR_web directory:**
   ```bash
   cd HADIR_web
   ```

2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Copy YuNet model (if not already present):**
   ```bash
   copy "..\intro to ai demo\attendance_demo\face_detection_yunet_2023mar.onnx" .
   ```

## Usage

### Basic Usage

Start with default settings (camera 0, backend at localhost:5000):

```bash
python app.py
```

Then open in browser: **http://127.0.0.1:5001**

### Advanced Usage

Custom camera and backend:

```bash
python app.py --camera 0 --backend http://127.0.0.1:5000/api/students/recognize
```

Use video file instead of camera:

```bash
python app.py --camera path/to/video.mp4
```

Bind to all network interfaces:

```bash
python app.py --host 0.0.0.0 --port 5001
```

### Command Line Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `--camera` | Camera index or video file path | 0 |
| `--backend` | Backend recognition API URL | http://127.0.0.1:5000/api/students/recognize |
| `--host` | Host to bind server to | 127.0.0.1 |
| `--port` | Port to bind server to | 5001 |
| `--debug` | Enable debug mode | False |

## Architecture

```
HADIR_web/
├── app.py                      # Flask web server
├── realtime_recognition.py     # Recognition logic
├── requirements.txt            # Python dependencies
├── face_detection_yunet_2023mar.onnx  # Face detector model
├── templates/
│   └── index.html              # Main dashboard UI
├── static/
│   ├── css/
│   │   └── style.css           # Styles
│   └── js/
│       └── app.js              # Client-side logic
```

## How It Works

1. **Video Capture**
   - OpenCV captures frames from camera
   - Frames are flipped horizontally (mirror effect)

2. **Face Detection**
   - YuNet detector runs every 3 frames (optimized)
   - Detections are downscaled to 50% for performance
   - Bounding boxes are scaled back to full resolution

3. **Face Tracking**
   - Simple IoU-based tracker maintains face IDs
   - Prevents duplicate recognition requests
   - Handles faces entering/leaving frame

4. **Face Recognition**
   - New faces trigger background API call to backend
   - Face crop sent to `/api/students/recognize`
   - Backend returns: student ID, name, confidence
   - Label updated on tracked face

5. **Display**
   - Green box + "Name (ID)" for registered students
   - Red box + "Unknown" for unregistered faces
   - Confidence scores shown for registered students

6. **Streaming**
   - MJPEG stream to browser via `/video_feed`
   - ~15-20 FPS depending on hardware
   - Quality optimized to 80% JPEG

## API Endpoints

- `GET /` - Main dashboard page
- `GET /video_feed` - MJPEG video stream
- `GET /health` - Health check

## Troubleshooting

### Camera Not Opening

**Error:** `Failed to open camera 0`

**Solutions:**
- Check camera is not in use by another application
- Try different camera index: `--camera 1`
- Check camera permissions in Windows settings

### Backend Connection Failed

**Error:** `Backend connection failed`

**Solutions:**
- Ensure backend is running: `cd backend && python app.py`
- Verify backend URL is correct
- Check firewall settings
- Test backend: `http://127.0.0.1:5000/api/health/status`

### YuNet Model Not Found

**Error:** `YuNet model not found`

**Solution:**
Download the model:
```bash
curl -L -o face_detection_yunet_2023mar.onnx https://github.com/opencv/opencv_zoo/raw/main/models/face_detection_yunet/face_detection_yunet_2023mar.onnx
```

### No Faces Detected

**Issues:**
- Poor lighting
- Face too small or too far
- Face angle too extreme

**Solutions:**
- Ensure good lighting
- Move closer to camera
- Face camera directly
- Lower detection threshold (edit `realtime_recognition.py`, line 30)

### Low FPS

**Solutions:**
- Increase `detection_interval` in `realtime_recognition.py` (line 427)
- Reduce `detect_scale` (line 442)
- Lower camera resolution
- Close other resource-intensive applications

## Performance Tips

1. **Optimize Detection Frequency**
   - Increase `detection_interval` from 3 to 5 frames
   - Detection only runs every Nth frame

2. **Adjust Detection Scale**
   - Reduce `detect_scale` from 0.5 to 0.3
   - Smaller images process faster

3. **Lower Stream Quality**
   - Reduce JPEG quality from 80 to 60
   - In `realtime_recognition.py`, line 499

4. **Hardware Acceleration**
   - Use GPU-enabled OpenCV if available
   - Use webcam with hardware encoding

## Development

### Adding New Features

**Example: Save snapshots of detected faces**

Edit `realtime_recognition.py`:

```python
def recognize_face_async(self, face_id: int, face_crop: np.ndarray):
    # Save snapshot
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    cv2.imwrite(f'snapshots/face_{face_id}_{timestamp}.jpg', face_crop)
    
    # ... rest of recognition code
```

### Customizing UI

Edit `static/css/style.css` to change colors, fonts, layout.

Edit `static/js/app.js` to add client-side features.

## Integration with Backend

The system integrates with the main backend API:

**Endpoint:** `POST /api/students/recognize`

**Request:**
```
multipart/form-data
image: <face_crop.jpg>
```

**Response:**
```json
{
  "recognized": true,
  "student_id": "S12345",
  "confidence": 0.95,
  "bbox": [x, y, w, h],
  "student_info": {
    "name": "John Doe",
    "email": "john@university.edu",
    "department": "Computer Science"
  }
}
```

## Future Enhancements

- [ ] Attendance logging (auto-log detected students)
- [ ] Session management (morning/afternoon classes)
- [ ] Export attendance to CSV/Excel
- [ ] Multiple camera support
- [ ] WebSocket for real-time updates
- [ ] Face spoofing detection
- [ ] Mobile app integration

## Credits

- Face Detection: OpenCV YuNet
- Face Recognition: MobileFaceNet + ArcFace (from main backend)
- Web Framework: Flask
- UI Design: Custom CSS

## License

Part of Vision-Based Class Attendance System project.
