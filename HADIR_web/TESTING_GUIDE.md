# HADIR_web Testing Guide

## 🧪 How to Test HADIR_web

### Prerequisites

Before testing, ensure:
- ✅ Backend API is running (port 5000)
- ✅ At least one student is registered in the system
- ✅ Face recognition classifier is trained
- ✅ Webcam is connected and working

---

## Test 1: Basic Setup ✅

### Steps:
1. Open PowerShell in HADIR_web directory
2. Run: `python app.py`
3. Expected output:
   ```
   ============================================================
     🎓 HADIR Live Attendance System
   ============================================================

     📹 Camera: 0
     🔗 Backend API: http://127.0.0.1:5000/api/students/recognize
     🌐 Server: http://127.0.0.1:5001
   ```

### Pass Criteria:
- ✅ No errors displayed
- ✅ Server starts successfully
- ✅ Camera opens (no "Failed to open camera" error)

---

## Test 2: Web Dashboard Loads ✅

### Steps:
1. Open browser
2. Navigate to: http://127.0.0.1:5001
3. Wait 2-3 seconds for page to load

### Expected Results:
- ✅ Dashboard page loads
- ✅ Live video feed displays
- ✅ You can see yourself in the camera
- ✅ Header shows "HADIR Live Attendance"
- ✅ Backend status shows "Connected" (green)
- ✅ Camera status shows "Active" (green)

### Pass Criteria:
- Page loads without errors
- Video feed is visible and moving
- Status indicators are green

---

## Test 3: Face Detection (Unknown) 🔴

### Steps:
1. Position your face in front of camera
2. Look directly at camera
3. Wait 2-3 seconds
4. Observe the video feed

### Expected Results:
- ✅ Red bounding box appears around your face
- ✅ Label shows "Unknown"
- ✅ Box follows your face as you move

### Pass Criteria:
- Face is detected (box appears)
- Box color is RED
- Label says "Unknown"

**Screenshot this result!**

---

## Test 4: Face Recognition (Registered Student) 🟢

### Prerequisites:
- You must be registered in the system
- Classifier must be trained with your face

### Steps:
1. Position yourself in front of camera
2. Look directly at camera
3. Wait 2-3 seconds for "Processing..."
4. Wait additional 1-2 seconds for recognition
5. Observe the bounding box and label

### Expected Results:
- ✅ Box initially shows "Processing..." (green)
- ✅ After ~1-2 seconds, box turns GREEN
- ✅ Label shows: "Your Name (Your ID) (0.XX)"
  - Example: "John Doe (S12345) (0.95)"
- ✅ Confidence score is > 0.7

### Pass Criteria:
- Box color changes to GREEN
- Your name appears in the label
- Your student ID appears in parentheses
- Confidence score is displayed

**Screenshot this result!**

---

## Test 5: Multiple Faces 👥

### Steps:
1. Have 2-3 people stand in front of camera
2. Mix registered and unregistered people if possible
3. Wait 2-3 seconds
4. Observe the detections

### Expected Results:
- ✅ Multiple bounding boxes appear (one per face)
- ✅ Registered students have GREEN boxes with names
- ✅ Unknown faces have RED boxes with "Unknown"
- ✅ Each face tracked independently

### Pass Criteria:
- All faces detected
- Boxes colored correctly (green/red)
- Labels show correct information

---

## Test 6: Statistics Update 📊

### Steps:
1. Note the statistics cards (top right):
   - Total Detected: X
   - Registered: Y
   - Unknown: Z
2. Move away from camera (face disappears)
3. Move back into frame (face reappears)
4. Check if statistics updated

### Expected Results:
- ✅ "Total Detected" increases when you reappear
- ✅ "Registered" or "Unknown" count increases appropriately
- ✅ "Last Update" timestamp updates

### Pass Criteria:
- Statistics reflect current detections
- Counters increment correctly

---

## Test 7: Recent Detections List 📋

### Steps:
1. Look at "Recent Detections" panel (right side)
2. Position face in camera
3. Wait for detection
4. Check if detection appears in list

### Expected Results:
- ✅ New entry appears in "Recent Detections"
- ✅ Entry shows:
  - Name (if registered) or "Unknown"
  - Student ID (if registered)
  - Confidence score (if registered)
  - Timestamp
- ✅ Entry has colored left border (green/red)

### Pass Criteria:
- Detections appear in list
- Information is correct
- Timestamps are accurate

---

## Test 8: Fullscreen Mode 🖥️

### Steps:
1. Click "⛶ Fullscreen" button above video
2. Observe video feed
3. Press ESC key

### Expected Results:
- ✅ Video expands to fullscreen
- ✅ Face detection continues working
- ✅ Bounding boxes still visible
- ✅ ESC exits fullscreen

### Pass Criteria:
- Fullscreen mode works
- Detection continues in fullscreen
- ESC key exits properly

---

## Test 9: FPS Counter 🎯

### Steps:
1. Look at top-left overlay on video
2. Check "FPS: XX" display

### Expected Results:
- ✅ FPS counter shows value between 10-25
- ✅ Value updates regularly
- ✅ FPS is relatively stable (not fluctuating wildly)

### Pass Criteria:
- FPS displayed
- Value is reasonable (>10)
- Video feels smooth

---

## Test 10: Clear Detections 🧹

### Steps:
1. Ensure some detections are in the list
2. Note the statistics (Total Detected, etc.)
3. Click "Clear" button (top-right of Recent Detections)
4. Confirm in popup
5. Check statistics and list

### Expected Results:
- ✅ Confirmation dialog appears
- ✅ After confirming:
  - All statistics reset to 0
  - Recent detections list clears
  - Toast notification appears: "Detections cleared"

### Pass Criteria:
- Statistics reset correctly
- List is empty
- Toast notification appears

---

## 🔧 Troubleshooting Tests

### If Face Not Detected:

**Test:** Lighting
1. Turn on room lights
2. Position face near window (daylight)
3. Try again

**Test:** Distance
1. Move closer to camera (1-2 meters)
2. Try again

**Test:** Angle
1. Face camera directly (not from side)
2. Try again

### If Recognition Fails (Always Unknown):

**Test:** Backend Connection
1. Open: http://127.0.0.1:5000/api/health/status
2. Should return JSON with "status": "ok"

**Test:** Classifier Trained
1. Check backend terminal for errors
2. Verify classifier file exists: `backend/classifiers/face_classifier.pkl`

**Test:** Student Registered
1. Open: http://127.0.0.1:5000/api/docs
2. Navigate to: GET /api/students/
3. Execute to see list of students
4. Verify your student_id exists

---

## 📊 Test Results Summary

After completing all tests, fill out this checklist:

### Core Functionality
- [ ] Test 1: Basic Setup - PASS / FAIL
- [ ] Test 2: Web Dashboard Loads - PASS / FAIL
- [ ] Test 3: Unknown Face Detection (Red Box) - PASS / FAIL
- [ ] Test 4: Registered Student Recognition (Green Box) - PASS / FAIL
- [ ] Test 5: Multiple Faces - PASS / FAIL

### UI Features
- [ ] Test 6: Statistics Update - PASS / FAIL
- [ ] Test 7: Recent Detections List - PASS / FAIL
- [ ] Test 8: Fullscreen Mode - PASS / FAIL
- [ ] Test 9: FPS Counter - PASS / FAIL
- [ ] Test 10: Clear Detections - PASS / FAIL

### Performance
- [ ] FPS: _____ (should be >10)
- [ ] Detection Latency: _____ seconds (should be <1s)
- [ ] Recognition Latency: _____ seconds (should be <2s)

### Screenshots Captured
- [ ] Unknown face (red box)
- [ ] Registered student (green box with name)
- [ ] Multiple faces
- [ ] Dashboard overview

---

## 🎓 Expected Outcomes

### ✅ All Tests Pass:
System is **production-ready** for live attendance monitoring.

### ⚠️ Some Tests Fail:
- Face detection fails → Check lighting and camera
- Recognition fails → Check backend and classifier
- UI issues → Report browser console errors

### ❌ Most Tests Fail:
- Review setup steps in QUICKSTART.md
- Check backend is running
- Verify all dependencies installed
- Review error messages in terminal

---

## 📝 Report Issues

If tests fail, provide:
1. **Test number** that failed
2. **Expected result** vs **actual result**
3. **Error messages** from terminal
4. **Browser console errors** (F12 → Console)
5. **Screenshots** if applicable

---

**Happy Testing! 🚀**
