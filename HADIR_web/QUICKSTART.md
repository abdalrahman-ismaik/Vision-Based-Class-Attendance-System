# HADIR_web Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Step 1: Ensure Backend is Running

First, make sure the backend API is running:

```powershell
cd backend
python app.py
```

You should see:
```
* Running on http://127.0.0.1:5000
```

Keep this terminal open!

### Step 2: Get YuNet Model

Copy the face detection model from the demo:

```powershell
cd HADIR_web
copy "..\intro to ai demo\attendance_demo\face_detection_yunet_2023mar.onnx" .
```

**OR** download it directly:

```powershell
curl -L -o face_detection_yunet_2023mar.onnx https://github.com/opencv/opencv_zoo/raw/main/models/face_detection_yunet/face_detection_yunet_2023mar.onnx
```

### Step 3: Install Dependencies

```powershell
cd HADIR_web
pip install -r requirements.txt
```

### Step 4: Start HADIR_web

```powershell
python app.py
```

You should see:
```
============================================================
  🎓 HADIR Live Attendance System
============================================================

  📹 Camera: 0
  🔗 Backend API: http://127.0.0.1:5000/api/students/recognize
  🌐 Server: http://127.0.0.1:5001

  Open http://127.0.0.1:5001 in your browser

  Press Ctrl+C to stop the server
============================================================
```

### Step 5: Open in Browser

Open your web browser and navigate to:

**http://127.0.0.1:5001**

You should see:
- Live camera feed
- Face detection boxes
- Green boxes for registered students
- Red boxes for unknown faces

## ✅ Verification Checklist

- [ ] Backend running on port 5000
- [ ] HADIR_web running on port 5001
- [ ] Browser shows live video feed
- [ ] Camera permission granted (if prompted)
- [ ] Backend status shows "Connected" (green)
- [ ] Camera status shows "Active" (green)

## 🎯 Testing Face Recognition

### With Registered Student:

1. Position a registered student in front of camera
2. Wait 2-3 seconds for detection
3. Box should turn **green**
4. Label shows: **"Name (Student ID)" (confidence)**
5. Student appears in "Recent Detections" list

### With Unknown Person:

1. Position an unregistered person in front of camera
2. Wait 2-3 seconds for detection
3. Box should turn **red**
4. Label shows: **"Unknown"**
5. Appears in "Recent Detections" as Unknown

## 🐛 Common Issues

### Issue: "Failed to open camera 0"

**Solution:** Camera is in use by another app

```powershell
# Try camera index 1
python app.py --camera 1
```

### Issue: Backend status shows "Disconnected"

**Solution:** Backend not running

```powershell
# In another terminal
cd backend
python app.py
```

### Issue: No faces detected

**Solutions:**
- Ensure good lighting
- Face the camera directly
- Move closer to camera
- Check camera is working (test in Windows Camera app)

### Issue: "YuNet model not found"

**Solution:** Download the model

```powershell
cd HADIR_web
curl -L -o face_detection_yunet_2023mar.onnx https://github.com/opencv/opencv_zoo/raw/main/models/face_detection_yunet/face_detection_yunet_2023mar.onnx
```

## 📊 Expected Performance

| Metric | Expected Value |
|--------|----------------|
| FPS | 15-20 |
| Detection Time | 50-100ms |
| Recognition Time | 200-500ms |
| Latency | <1 second |

## 🎨 UI Features

### Statistics Cards
- **Total Detected:** Count of all face detections
- **Registered:** Count of recognized students
- **Unknown:** Count of unregistered faces
- **Last Update:** Current time

### Recent Detections List
- Shows last 50 detections
- Sorted by newest first
- Green border for registered
- Red border for unknown
- Includes timestamp and confidence

### Video Controls
- **Fullscreen button:** Expand video to full screen
- **ESC key:** Exit fullscreen

### Other Features
- **Clear button:** Clear all detections
- **FPS counter:** Shows current frame rate
- **Faces counter:** Shows current face count

## 🔧 Advanced Configuration

### Change Camera

```powershell
python app.py --camera 1
```

### Use Video File

```powershell
python app.py --camera path/to/video.mp4
```

### Change Port

```powershell
python app.py --port 8080
```

### Enable Debug Mode

```powershell
python app.py --debug
```

## 📝 Next Steps

Now that HADIR_web is running:

1. ✅ Test with multiple students
2. ✅ Verify recognition accuracy
3. ✅ Test in different lighting conditions
4. ✅ Monitor performance (FPS, latency)
5. 🔲 Implement attendance logging (coming soon)

## 💡 Tips for Best Results

1. **Lighting:** Ensure bright, even lighting
2. **Position:** Face camera directly, 1-2 meters away
3. **Background:** Plain background works best
4. **Movement:** Stay relatively still during detection
5. **Multiple Faces:** System handles multiple faces simultaneously

## 🆘 Need Help?

Check the full README.md for:
- Detailed architecture
- Troubleshooting guide
- Performance optimization
- Development guide
- API documentation

---

**Enjoy using HADIR_web! 🎓**
