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
                 backend_url: str = 'http://127.0.0.1:5000/api/attendance/class',
                 class_id: Optional[str] = None,
                 recognition_threshold: Optional[float] = None):
        """
        Initialize real-time recognition system.
        
        Args:
            camera_source: Camera index or video file path
            backend_url: Backend recognition API endpoint
            class_id: Class ID to attach to recognition submissions
            recognition_threshold: Optional threshold forwarded to the backend
        """
        # Allow overriding via environment variable if provided
        self.backend_url = os.environ.get('BACKEND_RECOGNITION_URL', backend_url)
        self.class_id = os.environ.get('ATTENDANCE_CLASS_ID', class_id)

        threshold_env = os.environ.get('ATTENDANCE_THRESHOLD')
        if threshold_env is not None:
            try:
                self.recognition_threshold = float(threshold_env)
            except ValueError:
                logger.warning("Invalid ATTENDANCE_THRESHOLD env value; ignoring")
                self.recognition_threshold = recognition_threshold
        else:
            self.recognition_threshold = recognition_threshold
        self._warned_missing_class = False
        self.detector = FaceDetector()
        # Increased max_disappeared to 30 to prevent ID switching on temporary detection loss
        self.tracker = FaceTracker(iou_threshold=0.3, max_disappeared=30)

        # Track unique registered IDs and count
        self.registered_ids: set[str] = set()
        self.registered_count: int = 0
        self.recognized_students: Dict[str, dict] = {}  # {student_id: {name, confidence, timestamp}}
        
        # Request throttling to prevent overwhelming backend
        self.pending_recognitions = {}  # {face_id: timestamp}
        self.active_recognitions = set()  # face_ids currently being processed
        self.recognition_cooldown = 5.0  # seconds between recognition requests per face (increased to 5)
        
        # Buffer for collecting best frames
        self.collecting_faces = {}  # {face_id: {'start_time': float, 'best_score': float, 'best_crop': img}}
        
        # Open camera
        # Use CAP_DSHOW only on Windows and for integer camera indices (webcams)
        if os.name == 'nt' and isinstance(camera_source, int):
            self.camera = cv2.VideoCapture(camera_source, cv2.CAP_DSHOW)
        else:
            self.camera = cv2.VideoCapture(camera_source)

        # If failed and it's a URL, try appending common endpoints (auto-fix for IP Webcam apps)
        if not self.camera.isOpened() and isinstance(camera_source, str) and camera_source.startswith('http'):
            suffixes = ['/video', '/video?x.mjpeg', '/mjpegfeed', '/video_feed']
            base_url = camera_source.rstrip('/')
            
            for suffix in suffixes:
                # Don't append if it already has it
                if any(base_url.endswith(s) for s in suffixes):
                    break
                    
                new_url = base_url + suffix
                logger.info(f"Initial connection failed. Retrying with suffix: {new_url}")
                temp_cap = cv2.VideoCapture(new_url)
                if temp_cap.isOpened():
                    self.camera = temp_cap
                    camera_source = new_url
                    logger.info(f"Successfully connected to {new_url}")
                    break

        if not self.camera.isOpened():
            # Fallback to default backend
            self.camera = cv2.VideoCapture(camera_source)
        
        if not self.camera.isOpened():
            raise IOError(f"Failed to open camera {camera_source}")
        
        # Set resolution
        self.camera.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
        self.camera.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
        
        logger.info(f"Camera opened successfully (source={camera_source})")
        logger.info(f"Backend API: {backend_url}")
    
    def set_class_id(self, class_id: Optional[str]):
        """Update the active class identifier used in recognition requests."""
        self.class_id = class_id
        if class_id:
            self._warned_missing_class = False

    def recognize_face_async(self, face_id: int, face_crop: np.ndarray):
        """
        Send face crop to backend for recognition (runs in background thread).
        
        Args:
            face_id: Tracked face ID
            face_crop: Cropped face image
        """
        try:
            # Check if this face is already being processed
            if face_id in self.active_recognitions:
                return  # Wait for current request to complete
            
            # Check if we're in cooldown period for this face
            current_time = time.time()
            last_request = self.pending_recognitions.get(face_id, 0)
            if current_time - last_request < self.recognition_cooldown:
                return  # Skip this request to avoid overwhelming backend
            
            # Mark face as actively being processed
            self.active_recognitions.add(face_id)
            # Mark request time
            self.pending_recognitions[face_id] = current_time
            
            # Save debug image
            debug_dir = os.path.join(os.path.dirname(__file__), 'debug_faces')
            os.makedirs(debug_dir, exist_ok=True)
            timestamp = datetime.now().strftime('%H%M%S_%f')
            debug_path = os.path.join(debug_dir, f"face_{face_id}_{timestamp}.jpg")
            cv2.imwrite(debug_path, face_crop)
            logger.info(f"Saved debug face image to {debug_path}")
            
            # Encode image as JPEG
            _, buffer = cv2.imencode('.jpg', face_crop, [cv2.IMWRITE_JPEG_QUALITY, 85])
            
            # Abort early if class ID is missing (endpoint requires it)
            if not self.class_id:
                if not self._warned_missing_class:
                    logger.warning("Class ID not set. Skipping recognition requests until one is provided.")
                    self._warned_missing_class = True
                self.tracker.set_label(face_id, 'Set Class ID', 0.0)
                return

            # Prepare payload for backend
            files = {'image': ('face.jpg', buffer.tobytes(), 'image/jpeg')}
            form_data = {'class_id': self.class_id}

            if self.recognition_threshold is not None:
                form_data['threshold'] = str(self.recognition_threshold)
            
            response = requests.post(
                self.backend_url,
                data=form_data,
                files=files,
                timeout=30
            )
            
            # Handle 404 gracefully (No face detected or classifier not trained)
            if response.status_code == 404:
                try:
                    data = response.json()
                    if 'error' in data:
                        logger.warning(f"Backend recognition info for face {face_id}: {data['error']}")
                        self.tracker.set_label(face_id, 'Unknown', 0.0)
                        return
                except ValueError:
                    # Not JSON, probably a real 404 (endpoint not found)
                    logger.error(f"Backend endpoint not found (404): {self.backend_url}")
                    pass
            
            response.raise_for_status()
            
            data = response.json()
            
            # Parse response
            if data.get('recognized') and data.get('student_id') not in (None, 'Unknown'):
                student_id = data.get('student_id', 'Unknown')
                student_name = data.get('name', student_id)
                label = student_id  # Use ID as the label per requirement
                confidence = data.get('confidence', 0.0)

                # Increment unique registered count only once per unique student ID
                if student_id not in self.registered_ids:
                    self.registered_ids.add(student_id)
                    self.registered_count += 1
                
                # Track recognized student with details
                self.recognized_students[student_id] = {
                    'name': student_name,
                    'confidence': confidence,
                    'timestamp': time.time()
                }
            else:
                label = 'Unknown'
                confidence = data.get('confidence', 0.0)
            
            # Update tracker
            self.tracker.set_label(face_id, label, confidence)
            logger.info(f"Face {face_id} recognized: {label} (confidence={confidence:.2f})")
            
        except requests.HTTPError as http_err:
            status = http_err.response.status_code if http_err.response else 'unknown'
            body = http_err.response.text if http_err.response else ''
            logger.error(f"Recognition HTTP {status} for face {face_id}: {body}")
            self.tracker.set_label(face_id, 'Error', 0.0)
        except Exception as e:
            logger.error(f"Recognition error for face {face_id}: {e}")
            self.tracker.set_label(face_id, 'Unknown', 0.0)
        finally:
            # Always remove from active recognitions when done (success or failure)
            self.active_recognitions.discard(face_id)
    
    def calculate_face_quality(self, face_img: np.ndarray) -> float:
        """
        Calculate a quality score for the face image.
        Higher is better. Based on sharpness and brightness.
        """
        if face_img is None or face_img.size == 0:
            return 0.0
            
        gray = cv2.cvtColor(face_img, cv2.COLOR_BGR2GRAY)
        
        # Sharpness (Laplacian variance)
        sharpness = cv2.Laplacian(gray, cv2.CV_64F).var()
        
        # Brightness check (penalize too dark or too bright)
        mean_brightness = np.mean(gray)
        if mean_brightness < 40 or mean_brightness > 215:
            brightness_penalty = 0.5
        else:
            brightness_penalty = 1.0
            
        # Size score (larger is better, up to a point)
        h, w = face_img.shape[:2]
        size_score = min(w * h, 40000) / 40000.0  # Normalize roughly
        
        return sharpness * brightness_penalty * (1.0 + size_score)

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
        if label and label != 'Unknown' and label != 'Scanning...' and label != 'Processing...':
            text = f"{label}"
            if confidence > 0:
                text += f" ({confidence:.2f})"
        elif label == 'Unknown':
            text = "Unknown"
        elif label == 'Scanning...':
            text = "Scanning..."
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
                
                # Extract face crop with padding (needed for quality check)
                # Increased padding to 40% to give backend more context
                pad = int(0.4 * max(w, h))
                x0 = max(x - pad, 0)
                y0 = max(y - pad, 0)
                x1 = min(x + w + pad, frame.shape[1])
                y1 = min(y + h + pad, frame.shape[0])
                face_crop = frame[y0:y1, x0:x1].copy()
                
                # Calculate quality
                quality_score = self.calculate_face_quality(face_crop)

                # Logic for new/collecting faces
                if is_new:
                    logger.info(f"New face detected (ID: {face_id}). Starting scan...")
                    # Start collecting
                    self.collecting_faces[face_id] = {
                        'start_time': time.time(),
                        'best_score': quality_score,
                        'best_crop': face_crop,
                        'frames_collected': 1
                    }
                    self.tracker.set_label(face_id, 'Scanning...', 0.0)
                
                elif face_id in self.collecting_faces:
                    # Continue collecting
                    collector = self.collecting_faces[face_id]
                    collector['frames_collected'] += 1
                    
                    # Update best if current is better
                    if quality_score > collector['best_score']:
                        collector['best_score'] = quality_score
                        collector['best_crop'] = face_crop
                    
                    # Check if done collecting (e.g., 0.8s or 15 frames)
                    elapsed = time.time() - collector['start_time']
                    if elapsed > 0.8 or collector['frames_collected'] > 15:
                        # Check minimum quality threshold
                        MIN_QUALITY_THRESHOLD = 80.0  # Lowered to be more permissive for webcams
                        
                        if collector['best_score'] >= MIN_QUALITY_THRESHOLD:
                            # Send best frame
                            logger.info(f"Sending best frame for face {face_id} (Score: {collector['best_score']:.2f})")
                            self.tracker.set_label(face_id, 'Processing...', 0.0)
                            threading.Thread(
                                target=self.recognize_face_async,
                                args=(face_id, collector['best_crop']),
                                daemon=True
                            ).start()
                            del self.collecting_faces[face_id]
                        else:
                            # Quality too low, reset collection or mark as unknown/low quality
                            # For now, let's retry collection by resetting start time but keeping ID
                            # Or just give up to avoid infinite scanning loop if camera is bad
                            logger.warning(f"Face {face_id} quality too low ({collector['best_score']:.2f}). Retrying scan...")
                            collector['start_time'] = time.time()
                            collector['frames_collected'] = 0
                            collector['best_score'] = 0.0
                            self.tracker.set_label(face_id, 'Low Quality', 0.0)
                    else:
                         # Debug log for quality (throttled)
                         if collector['frames_collected'] % 5 == 0:
                             logger.debug(f"Face {face_id} scanning... Current score: {quality_score:.2f}")
                         self.tracker.set_label(face_id, 'Scanning...', 0.0)
                
                else:
                    # Not new, and not collecting.
                    
                    # CONTINUOUS RETRY LOGIC: Always keep trying to recognize the face
                    current_label = face_data.get('label')
                    current_conf = face_data.get('confidence', 0.0)
                    
                    # Retry for any face that has a result (not currently Processing/Scanning)
                    # This includes both 'Unknown' faces and recognized faces
                    if current_label not in (None, 'Processing...', 'Scanning...'):
                        # Check if not currently being processed and cooldown has passed
                        last_request = self.pending_recognitions.get(face_id, 0)
                        if (face_id not in self.active_recognitions and 
                            time.time() - last_request > self.recognition_cooldown):
                            logger.info(f"Face {face_id} rescanning (current: {current_label}, conf: {current_conf:.2f})...")
                            self.collecting_faces[face_id] = {
                                'start_time': time.time(),
                                'best_score': quality_score,
                                'best_crop': face_crop,
                                'frames_collected': 1
                            }
                            # Keep showing current label during rescan
                            # Note: Label will update to 'Scanning...' on next iteration when in collecting_faces

                    # If label is 'Scanning...', it means we lost state (e.g. cleanup). Restart collection.
                    if face_data.get('label') == 'Scanning...':
                        self.collecting_faces[face_id] = {
                            'start_time': time.time(),
                            'best_score': quality_score,
                            'best_crop': face_crop,
                            'frames_collected': 1
                        }

                # Draw detection
                self.draw_detection(frame, face_id, face_data)
                
            # Cleanup stale collectors (e.g. face lost before collection finished)
            now = time.time()
            stale_ids = [fid for fid, data in self.collecting_faces.items() 
                         if now - data['start_time'] > 5.0]
            for fid in stale_ids:
                del self.collecting_faces[fid]
            
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
