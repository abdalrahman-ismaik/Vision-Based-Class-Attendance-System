"""
realtime_recognition.py
-----------------------

Real-time face detection and recognition service for HADIR_web.
Integrates with the backend API for face recognition.

Features:
- Face detection using YuNet (OpenCV)
- Real-time video streaming with MJPEG
- Green boxes for registered students (with name + ID)
- Red boxes for unknown faces
- Background recognition using backend API
- Performance optimization (frame skipping, downscaling)
"""

import cv2
import numpy as np
import os
import requests
import threading
import logging
from typing import Generator, Dict, Tuple, Optional
import os
from datetime import datetime
import time

logger = logging.getLogger(__name__)


class FaceDetector:
    """Lightweight face detector using OpenCV YuNet."""
    
    def __init__(self, 
                 model_path: str = "face_detection_yunet_2023mar.onnx",
                 score_threshold: float = 0.6,
                 nms_threshold: float = 0.3):
        """
        Initialize YuNet face detector.
        
        Args:
            model_path: Path to YuNet ONNX model
            score_threshold: Minimum confidence threshold
            nms_threshold: Non-maximum suppression threshold
        """
        # Try to find model in current directory or parent directories
        if not os.path.isabs(model_path):
            current_dir = os.path.dirname(os.path.abspath(__file__))
            possible_paths = [
                os.path.join(current_dir, model_path),
                os.path.join(current_dir, '..', 'intro to ai demo', 'attendance_demo', model_path),
            ]
            
            for path in possible_paths:
                if os.path.exists(path):
                    model_path = path
                    break
            else:
                # If not found, use the first path and let user know
                model_path = possible_paths[0]
                logger.warning(f"YuNet model not found. Please download from: "
                             f"https://github.com/opencv/opencv_zoo/raw/main/models/face_detection_yunet/face_detection_yunet_2023mar.onnx")
        
        if not os.path.exists(model_path):
            raise FileNotFoundError(
                f"YuNet model not found at {model_path}. \n"
                "Please download it from: "
                "https://github.com/opencv/opencv_zoo/raw/main/models/face_detection_yunet/face_detection_yunet_2023mar.onnx"
            )
        
        self.detector = cv2.FaceDetectorYN.create(
            model=model_path,
            config="",
            input_size=(320, 320),
            score_threshold=score_threshold,
            nms_threshold=nms_threshold,
            top_k=5000
        )
        logger.info(f"Face detector initialized (threshold={score_threshold})")
    
    def detect(self, image: np.ndarray) -> list:
        """
        Detect faces in image.
        
        Args:
            image: BGR image from OpenCV
            
        Returns:
            List of bounding boxes [(x, y, w, h), ...]
        """
        h, w = image.shape[:2]
        self.detector.setInputSize((w, h))
        
        _, faces = self.detector.detect(image)
        
        bboxes = []
        if faces is not None:
            for face in faces:
                x, y, w, h = face[:4].astype(int)
                
                # Ensure within bounds
                x = max(0, x)
                y = max(0, y)
                w = min(w, image.shape[1] - x)
                h = min(h, image.shape[0] - y)
                
                if w > 0 and h > 0:
                    bboxes.append((x, y, w, h))
        
        return bboxes


class FaceTracker:
    """Simple face tracker to maintain consistent IDs across frames."""
    
    def __init__(self, iou_threshold: float = 0.3, max_disappeared: int = 10):
        """
        Initialize face tracker.
        
        Args:
            iou_threshold: Minimum IoU to consider same face
            max_disappeared: Max frames before removing tracked face
        """
        self.iou_threshold = iou_threshold
        self.max_disappeared = max_disappeared
        self.next_id = 0
        self.faces: Dict[int, dict] = {}  # {face_id: {bbox, label, confidence, disappeared}}
    
    def _compute_iou(self, box1: Tuple, box2: Tuple) -> float:
        """Compute Intersection over Union."""
        x1, y1, w1, h1 = box1
        x2, y2, w2, h2 = box2
        
        x1_max, y1_max = x1 + w1, y1 + h1
        x2_max, y2_max = x2 + w2, y2 + h2
        
        inter_x1 = max(x1, x2)
        inter_y1 = max(y1, y2)
        inter_x2 = min(x1_max, x2_max)
        inter_y2 = min(y1_max, y2_max)
        
        inter_area = max(0, inter_x2 - inter_x1) * max(0, inter_y2 - inter_y1)
        box1_area = w1 * h1
        box2_area = w2 * h2
        union_area = box1_area + box2_area - inter_area
        
        return inter_area / union_area if union_area > 0 else 0.0
    
    def update(self, detections: list) -> Dict[int, dict]:
        """
        Update tracker with new detections.
        
        Args:
            detections: List of bounding boxes [(x, y, w, h), ...]
            
        Returns:
            Dictionary of tracked faces {face_id: {'bbox': ..., 'label': ..., 'is_new': ...}}
        """
        # Mark all existing faces as potentially disappeared
        for face_id in self.faces:
            self.faces[face_id]['disappeared'] = self.faces[face_id].get('disappeared', 0) + 1
        
        # Match detected faces to existing tracked faces
        matched = set()
        results = {}
        
        for det_bbox in detections:
            best_match_id = None
            best_iou = self.iou_threshold
            
            # Find best matching existing face
            for face_id, face_data in self.faces.items():
                if face_id in matched:
                    continue
                
                iou = self._compute_iou(det_bbox, face_data['bbox'])
                if iou > best_iou:
                    best_iou = iou
                    best_match_id = face_id
            
            if best_match_id is not None:
                # Update existing face
                self.faces[best_match_id]['bbox'] = det_bbox
                self.faces[best_match_id]['disappeared'] = 0
                matched.add(best_match_id)
                results[best_match_id] = {
                    'bbox': det_bbox,
                    'label': self.faces[best_match_id]['label'],
                    'confidence': self.faces[best_match_id].get('confidence', 0.0),
                    'is_new': False
                }
            else:
                # New face detected - assign ID
                new_id = self.next_id
                self.next_id += 1

                self.faces[new_id] = {
                    'bbox': det_bbox,
                    'label': None,
                    'confidence': 0.0,
                    'disappeared': 0
                }
                results[new_id] = {
                    'bbox': det_bbox,
                    'label': None,
                    'confidence': 0.0,
                    'is_new': True
                }
        
        # Remove faces that disappeared for too long (use list() to avoid RuntimeError)
        to_remove = [face_id for face_id, face_data in list(self.faces.items())
                     if face_data.get('disappeared', 0) > self.max_disappeared]
        for face_id in to_remove:
            del self.faces[face_id]
        
        return results
    
    def set_label(self, face_id: int, label: str, confidence: float = 0.0):
        """Update label and confidence for a tracked face."""
        if face_id in self.faces:
            self.faces[face_id]['label'] = label
            self.faces[face_id]['confidence'] = confidence


class RealtimeRecognitionSystem:
    """Main real-time recognition system."""
    
    def __init__(self, 
                 camera_source: int = 0,
                 backend_url: str = 'http://127.0.0.1:5000/api/students/recognize'):
        """
        Initialize real-time recognition system.
        
        Args:
            camera_source: Camera index or video file path
            backend_url: Backend recognition API endpoint
        """
        # Allow overriding via environment variable if provided
        self.backend_url = os.environ.get('BACKEND_RECOGNITION_URL', backend_url)
        self.detector = FaceDetector()
        self.tracker = FaceTracker(iou_threshold=0.3, max_disappeared=10)

        # Track unique registered IDs and count
        self.registered_ids: set[str] = set()
        self.registered_count: int = 0
        
        # Request throttling to prevent overwhelming backend
        self.pending_recognitions = {}  # {face_id: timestamp}
        self.recognition_cooldown = 2.0  # seconds between recognition requests per face
        
        # Open camera
        self.camera = cv2.VideoCapture(camera_source, cv2.CAP_DSHOW)
        if not self.camera.isOpened():
            self.camera = cv2.VideoCapture(camera_source)
        
        if not self.camera.isOpened():
            raise IOError(f"Failed to open camera {camera_source}")
        
        # Set resolution
        self.camera.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
        self.camera.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
        
        logger.info(f"Camera opened successfully (source={camera_source})")
        logger.info(f"Backend API: {backend_url}")
    
    def recognize_face_async(self, face_id: int, face_crop: np.ndarray):
        """
        Send face crop to backend for recognition (runs in background thread).
        
        Args:
            face_id: Tracked face ID
            face_crop: Cropped face image
        """
        try:
            # Check if we're in cooldown period for this face
            current_time = time.time()
            last_request = self.pending_recognitions.get(face_id, 0)
            if current_time - last_request < self.recognition_cooldown:
                return  # Skip this request to avoid overwhelming backend
            
            # Mark request time
            self.pending_recognitions[face_id] = current_time
            
            # Encode image as JPEG
            _, buffer = cv2.imencode('.jpg', face_crop, [cv2.IMWRITE_JPEG_QUALITY, 85])
            
            # Send to backend
            files = {'image': ('face.jpg', buffer.tobytes(), 'image/jpeg')}
            response = requests.post(self.backend_url, files=files, timeout=30)
            response.raise_for_status()
            
            data = response.json()
            
            # Parse response
            if data.get('recognized') and data.get('student_id') not in (None, 'Unknown'):
                student_id = data.get('student_id', 'Unknown')
                label = student_id  # Use ID as the label per requirement
                confidence = data.get('confidence', 0.0)

                # Increment unique registered count only once per unique student ID
                if student_id not in self.registered_ids:
                    self.registered_ids.add(student_id)
                    self.registered_count += 1
            else:
                label = 'Unknown'
                confidence = data.get('confidence', 0.0)
            
            # Update tracker
            self.tracker.set_label(face_id, label, confidence)
            logger.info(f"Face {face_id} recognized: {label} (confidence={confidence:.2f})")
            
        except Exception as e:
            logger.error(f"Recognition error for face {face_id}: {e}")
            self.tracker.set_label(face_id, 'Unknown', 0.0)
    
    def draw_detection(self, frame: np.ndarray, face_id: int, face_data: dict):
        """
        Draw bounding box and label on frame.
        
        Args:
            frame: Image frame
            face_id: Face ID
            face_data: Face tracking data
        """
        x, y, w, h = face_data['bbox']
        label = face_data.get('label')
        confidence = face_data.get('confidence', 0.0)
        
        # Determine color: green for recognized, red for unknown
        if label and label != 'Unknown' and 'Processing' not in label:
            color = (0, 255, 0)  # Green for registered
        else:
            color = (0, 0, 255)  # Red for unknown
        
        # Draw bounding box
        cv2.rectangle(frame, (x, y), (x + w, y + h), color, 2)
        
        # Prepare label text
        if label and label != 'Unknown':
            text = f"{label}"
            if confidence > 0:
                text += f" ({confidence:.2f})"
        elif label == 'Unknown':
            text = "Unknown"
        else:
            text = "Processing..."
        
        # Draw label background
        (text_w, text_h), baseline = cv2.getTextSize(
            text, cv2.FONT_HERSHEY_SIMPLEX, 0.6, 2
        )
        cv2.rectangle(
            frame, 
            (x, y - text_h - 10), 
            (x + text_w + 10, y), 
            color, 
            -1
        )
        
        # Draw label text
        cv2.putText(
            frame, 
            text, 
            (x + 5, y - 5), 
            cv2.FONT_HERSHEY_SIMPLEX, 
            0.6, 
            (255, 255, 255), 
            2
        )
    
    def generate_frames(self) -> Generator[bytes, None, None]:
        """
        Generate video frames with face detection and recognition.
        
        Yields:
            MJPEG frame bytes
        """
        frame_count = 0
        detection_interval = 3  # Run detection every N frames
        last_faces = []
        
        logger.info("Starting video stream...")
        
        while True:
            success, frame = self.camera.read()
            if not success or frame is None:
                logger.warning("Failed to read frame, attempting reconnect...")
                self.camera.release()
                self.camera.open(0)
                continue
            
            # Flip for mirror effect
            frame = cv2.flip(frame, 1)
            frame_count += 1
            
            # Run detection (optimized with frame skipping and downscaling)
            if frame_count % detection_interval == 0 or not last_faces:
                # Downscale for detection
                detect_scale = 0.5
                small_frame = cv2.resize(frame, None, fx=detect_scale, fy=detect_scale)
                small_faces = self.detector.detect(small_frame)
                
                # Scale bounding boxes back up
                faces = [
                    (int(x / detect_scale), int(y / detect_scale),
                     int(w / detect_scale), int(h / detect_scale))
                    for x, y, w, h in small_faces
                ]
                last_faces = faces
            else:
                faces = last_faces
            
            # Update tracker
            tracked_faces = self.tracker.update(faces)
            
            # Process each tracked face
            for face_id, face_data in tracked_faces.items():
                x, y, w, h = face_data['bbox']
                is_new = face_data.get('is_new', False)
                
                # If new face, trigger background recognition
                if is_new:
                    # Extract face crop with padding
                    pad = int(0.2 * max(w, h))
                    x0 = max(x - pad, 0)
                    y0 = max(y - pad, 0)
                    x1 = min(x + w + pad, frame.shape[1])
                    y1 = min(y + h + pad, frame.shape[0])
                    face_crop = frame[y0:y1, x0:x1].copy()
                    
                    # Set processing label
                    self.tracker.set_label(face_id, 'Processing...', 0.0)
                    
                    # Start background recognition
                    threading.Thread(
                        target=self.recognize_face_async,
                        args=(face_id, face_crop),
                        daemon=True
                    ).start()
                
                # Draw detection
                self.draw_detection(frame, face_id, face_data)
            
            # Add frame info
            info_text = f"Faces: {len(tracked_faces)} | Registered: {self.registered_count} | Frame: {frame_count}"
            cv2.putText(
                frame, info_text, (10, frame.shape[0] - 10),
                cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1
            )
            
            # Encode frame as JPEG
            ret, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 80])
            if not ret:
                continue
            
            frame_bytes = buffer.tobytes()
            
            # Yield frame in MJPEG format
            yield (
                b'--frame\r\n'
                b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n'
            )
    
    def release(self):
        """Release camera resources."""
        if self.camera:
            self.camera.release()
        logger.info("Camera released")
