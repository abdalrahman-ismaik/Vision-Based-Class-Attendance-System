"""
app.py
---------

Flask application for streaming the annotated video from the real‑time
attendance system with integrated backend processing.

Usage::

    python app.py --camera 0 --host 0.0.0.0 --port 5001
"""

from __future__ import annotations

import argparse
import cv2
import os
import sys
import threading
import time
import logging
from typing import Generator, Optional
from flask import Flask, render_template, Response, request, jsonify
from datetime import datetime

# Add parent directory to path to import backend modules
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from detector import FaceDetector
from face_tracker import FaceTracker

# Import backend modules directly
from backend.database.core import load_classes, load_database
from backend.services.manager import get_pipeline

# Configure detailed logging
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s [%(name)s]: %(message)s',
    datefmt='%H:%M:%S'
)
logger = logging.getLogger(__name__)

# Suppress verbose logs from other libraries
logging.getLogger('werkzeug').setLevel(logging.WARNING)
logging.getLogger('PIL').setLevel(logging.WARNING)

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run the attendance demo web server.")
    parser.add_argument('--camera', type=str, default='0', help='Video source index or path.')
    parser.add_argument('--host', type=str, default='127.0.0.1', help='Host interface.')
    parser.add_argument('--port', type=int, default=5001, help='Port number.')
    return parser.parse_args()

def open_video_source(src: str) -> cv2.VideoCapture:
    """Open a video capture from a camera index or file/stream path."""
    print(f"Attempting to open video source: {src}")
    if src.isdigit():
        cap = cv2.VideoCapture(int(src), cv2.CAP_DSHOW) # DirectShow for Windows
        if not cap.isOpened():
             print(f"Failed to open with CAP_DSHOW, trying default backend...")
             cap = cv2.VideoCapture(int(src))
    else:
        cap = cv2.VideoCapture(src)
    
    if not cap.isOpened():
        raise IOError(f"Failed to open video source {src}")
    
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
    return cap

class CameraManager:
    def __init__(self, source: str):
        self.source = source
        self.cap: Optional[cv2.VideoCapture] = None
        self.class_id: Optional[str] = None
        self.lock = threading.Lock()
        self.is_running = False
        
        # Stats tracking
        self.registered_students = set()  # Track unique recognized students
        self.total_detections = 0  # Total faces detected
        self.unknown_count = 0  # Unknown faces count
        self.session_start_time = None
        self.recent_detections = []  # List of recent detection events
        self.max_detections_history = 50  # Keep last 50 detections

    def start(self, class_id: str):
        with self.lock:
            if self.is_running:
                self.stop()
            
            self.class_id = class_id
            self.registered_students.clear()
            self.total_detections = 0
            self.unknown_count = 0
            self.session_start_time = time.time()
            self.recent_detections.clear()
            
            try:
                self.cap = open_video_source(self.source)
                self.is_running = True
                print(f"Camera started for class: {class_id}")
                return True
            except Exception as e:
                print(f"Failed to start camera: {e}")
                return False

    def stop(self):
        with self.lock:
            if self.cap and self.cap.isOpened():
                self.cap.release()
            self.cap = None
            self.is_running = False
            self.class_id = None
            self.session_start_time = None
            print("Camera stopped")
    
    def record_recognition(self, student_id: str = None, student_name: str = None, confidence: float = 0.0, is_unknown: bool = False):
        """Record a successful recognition with full details"""
        with self.lock:
            timestamp = time.time()
            
            if is_unknown:
                self.unknown_count += 1
                detection_event = {
                    'student_id': 'Unknown',
                    'student_name': 'Unknown',
                    'confidence': confidence,
                    'timestamp': timestamp,
                    'is_unknown': True
                }
                # Add to recent detections (newest first)
                self.recent_detections.insert(0, detection_event)
            elif student_id and student_id != 'Unknown':
                self.registered_students.add(student_id)
                detection_event = {
                    'student_id': student_id,
                    'student_name': student_name,
                    'confidence': confidence,
                    'timestamp': timestamp,
                    'is_unknown': False
                }
                # Add to recent detections (newest first)
                self.recent_detections.insert(0, detection_event)
            
            # Keep only the most recent detections
            if len(self.recent_detections) > self.max_detections_history:
                self.recent_detections = self.recent_detections[:self.max_detections_history]
    
    def get_stats(self):
        """Get current session statistics"""
        with self.lock:
            uptime = 0
            if self.session_start_time:
                uptime = int(time.time() - self.session_start_time)
            
            return {
                'is_running': self.is_running,
                'class_id': self.class_id,
                'registered_count': len(self.registered_students),
                'unknown_count': self.unknown_count,
                'total_detections': self.total_detections,
                'session_uptime': uptime,
                'registered_students': list(self.registered_students)
            }
    
    def get_recent_detections(self):
        """Get recent detection events"""
        with self.lock:
            return self.recent_detections.copy()

    def get_frame(self):
        with self.lock:
            if self.is_running and self.cap and self.cap.isOpened():
                return self.cap.read()
            return False, None

def create_app(video_source: str) -> Flask:
    app = Flask(__name__, template_folder='templates')
    
    # Drawing helper functions for face annotations
    def draw_recognized_box(frame, x, y, w, h, color, student_name, student_id, confidence):
        """Draw box with name header, confidence top, ID bottom for recognized student."""
        # Calculate dynamic font scale based on box width
        font_scale = max(0.4, min(0.8, w / 200))
        thickness = max(1, int(font_scale * 2))
        
        # Draw main tracking box
        cv2.rectangle(frame, (x, y), (x+w, y+h), color, 2)
        
        # Draw name box above tracking box (same width)
        name_box_height = int(30 * font_scale)
        name_y_start = y - name_box_height - 5
        
        # Ensure name box doesn't go off screen
        if name_y_start < 0:
            name_y_start = y + h + 5
        
        # Draw filled rectangle for name
        cv2.rectangle(frame, (x, name_y_start), (x+w, name_y_start+name_box_height), color, -1)
        
        # Draw student name centered in name box with dynamic scaling to fit width
        # Calculate text size and scale down if needed
        name_font_scale = font_scale
        name_thickness = thickness
        padding = 10  # Padding on each side
        max_text_width = w - (2 * padding)
        
        # Iteratively reduce font scale until text fits
        for scale_attempt in range(10):  # Max 10 attempts
            name_text_size = cv2.getTextSize(student_name, cv2.FONT_HERSHEY_SIMPLEX, name_font_scale, name_thickness)[0]
            if name_text_size[0] <= max_text_width:
                break
            name_font_scale *= 0.85  # Reduce by 15% each iteration
            name_thickness = max(1, int(name_font_scale * 2))
        
        name_text_x = x + (w - name_text_size[0]) // 2
        name_text_y = name_y_start + (name_box_height + name_text_size[1]) // 2
        cv2.putText(frame, student_name, (name_text_x, name_text_y), 
                   cv2.FONT_HERSHEY_SIMPLEX, name_font_scale, (0, 0, 0), name_thickness)  # Black and bold
        
        # Draw confidence on top line inside box
        conf_text = f"Conf: {confidence:.2f}"
        cv2.putText(frame, conf_text, (x + 5, y + 20), 
                   cv2.FONT_HERSHEY_SIMPLEX, font_scale * 0.7, color, thickness)
        
        # Draw student ID on bottom line inside box
        id_text = f"ID: {student_id}"
        cv2.putText(frame, id_text, (x + 5, y + h - 10), 
                   cv2.FONT_HERSHEY_SIMPLEX, font_scale * 0.7, color, thickness)
    
    def draw_unknown_box(frame, x, y, w, h, color, confidence):
        """Draw box for unknown face."""
        font_scale = max(0.4, min(0.8, w / 200))
        thickness = max(1, int(font_scale * 2))
        
        # Draw tracking box
        cv2.rectangle(frame, (x, y), (x+w, y+h), color, 2)
        
        # Draw "Unknown" label above box
        label_text = "Unknown"
        text_size = cv2.getTextSize(label_text, cv2.FONT_HERSHEY_SIMPLEX, font_scale, thickness)[0]
        label_x = x + (w - text_size[0]) // 2
        label_y = y - 10
        
        if label_y < 20:
            label_y = y + 25
        
        cv2.putText(frame, label_text, (label_x, label_y), 
                   cv2.FONT_HERSHEY_SIMPLEX, font_scale, color, thickness)
        
        # Draw confidence if available
        if confidence > 0:
            conf_text = f"{confidence:.2f}"
            cv2.putText(frame, conf_text, (x + 5, y + h - 10), 
                       cv2.FONT_HERSHEY_SIMPLEX, font_scale * 0.7, color, thickness)
    
    def draw_scanning_box(frame, x, y, w, h, color):
        """Draw box for face being processed."""
        font_scale = max(0.4, min(0.8, w / 200))
        thickness = max(1, int(font_scale * 2))
        
        # Draw tracking box
        cv2.rectangle(frame, (x, y), (x+w, y+h), color, 2)
        
        # Draw "Scanning..." label
        label_text = "Scanning..."
        text_size = cv2.getTextSize(label_text, cv2.FONT_HERSHEY_SIMPLEX, font_scale, thickness)[0]
        label_x = x + (w - text_size[0]) // 2
        label_y = y - 10
        
        if label_y < 20:
            label_y = y + h // 2
        
        cv2.putText(frame, label_text, (label_x, label_y), 
                   cv2.FONT_HERSHEY_SIMPLEX, font_scale, color, thickness)
    
    # Initialize components
    logger.info("Initializing face detector...")
    detector = FaceDetector()
    logger.info("✓ Face detector initialized")
    
    logger.info("Initializing face tracker...")
    tracker = FaceTracker(iou_threshold=0.3, max_disappeared=10)
    logger.info("✓ Face tracker initialized")
    
    logger.info("Initializing camera manager...")
    camera_manager = CameraManager(video_source)
    logger.info("✓ Camera manager initialized")
    
    # Initialize backend pipeline
    logger.info("Initializing face recognition pipeline...")
    try:
        pipeline = get_pipeline()
        logger.info("✓ Face recognition pipeline initialized successfully")
    except Exception as e:
        logger.error(f"✗ Failed to initialize pipeline: {e}")
        pipeline = None
    
    # Multi-sample verification system for reliable recognition
    # Collects 10 predictions over 5 seconds and uses most frequent result
    # Format: {face_id: {'predictions': [list], 'samples_collected': int, 'processing': bool, 
    #                     'last_sample_time': float, 'first_prediction_time': float}}
    multi_sample_queue = {}
    multi_sample_lock = threading.Lock()
    MAX_SAMPLES = 10  # Collect 10 samples per face
    SAMPLE_INTERVAL = 0.5  # 0.5 seconds between samples
    MIN_SAMPLES_FOR_DECISION = 5  # Minimum samples before making a decision

    def recognize_face_direct(face_id: int, face_crop, current_class_id: str):
        """Process cropped face using backend pipeline directly with multi-sample verification."""
        try:
            current_time = time.time()
            
            # Check if we should collect a sample for this face
            with multi_sample_lock:
                if face_id in multi_sample_queue:
                    queue_entry = multi_sample_queue[face_id]
                    
                    # Check if still processing
                    if queue_entry.get('processing', False):
                        logger.debug(f"[Face {face_id}] Already being processed by another thread, skipping")
                        return
                    
                    # Check if enough time has passed since last sample
                    last_sample_time = queue_entry.get('last_sample_time', 0)
                    if current_time - last_sample_time < SAMPLE_INTERVAL:
                        logger.debug(f"[Face {face_id}] Too soon since last sample, skipping")
                        return
                    
                    # Check if we've collected enough samples
                    samples_collected = queue_entry.get('samples_collected', 0)
                    if samples_collected >= MAX_SAMPLES:
                        logger.debug(f"[Face {face_id}] Already collected {MAX_SAMPLES} samples, skipping")
                        return
                    
                    # Mark as processing and update time
                    queue_entry['processing'] = True
                    queue_entry['last_sample_time'] = current_time
                else:
                    # Initialize new entry for first sample
                    multi_sample_queue[face_id] = {
                        'predictions': [],
                        'samples_collected': 0,
                        'processing': True,
                        'last_sample_time': current_time,
                        'first_prediction_time': current_time
                    }
            
            try:
                logger.info(f"[Face {face_id}] Collecting sample for class: {current_class_id}")
                
                if pipeline is None:
                    logger.error(f"[Face {face_id}] Pipeline not initialized")
                    tracker.set_label(face_id, "Error: No Pipeline", 0.0)
                    return
                
                if not pipeline.classifier.is_trained:
                    logger.error(f"[Face {face_id}] Classifier not trained - please train the classifier first")
                    tracker.set_label(face_id, "Not Trained", 0.0)
                    return
                
                # Load class data
                logger.debug(f"[Face {face_id}] Loading class data...")
                classes = load_classes()
                if current_class_id not in classes:
                    logger.warning(f"[Face {face_id}] Class {current_class_id} not found in database")
                    tracker.set_label(face_id, "Unknown Class", 0.0)
                    return
                
                class_data = classes[current_class_id]
                # Support both field names for backward compatibility
                enrolled_ids = class_data.get('student_ids', class_data.get('enrolled_students', []))
                logger.info(f"[Face {face_id}] Class has {len(enrolled_ids)} enrolled students")
                
                if not enrolled_ids:
                    logger.warning(f"[Face {face_id}] No students enrolled in class {current_class_id}")
                    tracker.set_label(face_id, "No Students", 0.0)
                    return
                
                # Save temp image for processing
                temp_dir = os.path.join(os.path.dirname(__file__), 'temp_faces')
                os.makedirs(temp_dir, exist_ok=True)
                timestamp_ms = int(time.time()*1000)
                temp_path = os.path.join(temp_dir, f'face_{face_id}_{timestamp_ms}.jpg')
                
                # Also save a permanent debug copy
                debug_dir = os.path.join(os.path.dirname(__file__), 'debug_faces')
                os.makedirs(debug_dir, exist_ok=True)
                debug_path = os.path.join(debug_dir, f'face_{face_id}_{timestamp_ms}.jpg')
                
                logger.info(f"[Face {face_id}] Saving face image for recognition...")
                logger.info(f"[Face {face_id}]   - Temp path: {temp_path}")
                logger.info(f"[Face {face_id}]   - Debug path: {debug_path}")
                logger.info(f"[Face {face_id}]   - Image shape: {face_crop.shape}")
                
                cv2.imwrite(temp_path, face_crop)
                cv2.imwrite(debug_path, face_crop)
                logger.info(f"[Face {face_id}] ✓ Images saved successfully")
                
                # Recognize using pipeline (using crop method to skip redundant face detection)
                logger.info(f"[Face {face_id}] Running recognition pipeline...")
                logger.info(f"[Face {face_id}]   - Threshold: 0.60 (lowered for less strict matching)")
                logger.info(f"[Face {face_id}]   - Allowed students: {enrolled_ids}")
                
                result = pipeline.recognize_face_from_crop(
                    face_crop_path=temp_path,
                    threshold=0.60,  # Lowered from 0.70 to 0.60 for less strict matching
                    allowed_student_ids=enrolled_ids
                )
                
                logger.info(f"[Face {face_id}] Recognition result: {result}")
                
                # Clean up temp file (keep debug file)
                try:
                    os.remove(temp_path)
                    logger.debug(f"[Face {face_id}] Cleaned up temporary file")
                except Exception as cleanup_error:
                    logger.warning(f"[Face {face_id}] Could not delete temp file: {cleanup_error}")
                
                # Check for error first
                if 'error' in result:
                    error_msg = result['error']
                    logger.error(f"[Face {face_id}] ✗ Recognition error: {error_msg}")
                    tracker.set_label(face_id, "Error", 0.0)
                    return
                
                # Extract prediction from result
                prediction = result.get('prediction', {})
                label = prediction.get('label', 'Unknown')
                confidence = prediction.get('confidence', 0.0)
                all_predictions = prediction.get('all_predictions', {})
                
                # Check for quality issues first
                quality_issue = prediction.get('quality_issue')
                if quality_issue:
                    logger.warning(f"[Face {face_id}] ✗ Quality check failed: {quality_issue}")
                    tracker.set_label(face_id, "Low Quality", 0.0)
                    with multi_sample_lock:
                        if face_id in multi_sample_queue:
                            multi_sample_queue[face_id]['processing'] = False
                    return
                
                logger.info(f"[Face {face_id}] Prediction details:")
                logger.info(f"[Face {face_id}]   - Label: {label}")
                logger.info(f"[Face {face_id}]   - Confidence: {confidence:.4f}")
                logger.info(f"[Face {face_id}]   - All predictions: {all_predictions}")
                
                # Log additional metrics
                if 'confidence_margin' in prediction:
                    logger.info(f"[Face {face_id}]   - Confidence margin: {prediction['confidence_margin']:.4f}")
                if 'reason' in prediction:
                    logger.info(f"[Face {face_id}]   - Decision reason: {prediction['reason']}")
                
                # Add prediction to multi-sample queue
                with multi_sample_lock:
                    if face_id not in multi_sample_queue:
                        logger.warning(f"[Face {face_id}] Face entry disappeared from queue")
                        return
                    
                    queue_entry = multi_sample_queue[face_id]
                    queue_entry['predictions'].append({
                        'label': label,
                        'confidence': confidence,
                        'all_predictions': all_predictions
                    })
                    queue_entry['samples_collected'] += 1
                    queue_entry['processing'] = False
                    
                    samples_collected = queue_entry['samples_collected']
                    logger.info(f"[Face {face_id}] Sample {samples_collected}/{MAX_SAMPLES} collected")
                    
                    # Update UI to show progress
                    tracker.set_label(face_id, f"Sampling... {samples_collected}/{MAX_SAMPLES}", confidence)
                    
                    # Check if we should make a decision
                    should_decide = samples_collected >= MIN_SAMPLES_FOR_DECISION
                    time_elapsed = current_time - queue_entry['first_prediction_time']
                    
                    # Force decision after 6 seconds or when we hit MAX_SAMPLES
                    if samples_collected >= MAX_SAMPLES or time_elapsed > 6.0:
                        should_decide = True
                        logger.info(f"[Face {face_id}] Forcing decision: samples={samples_collected}, time_elapsed={time_elapsed:.1f}s")
                    
                    if not should_decide:
                        logger.info(f"[Face {face_id}] Need more samples before decision")
                        return
                    
                    # MAKE DECISION using majority voting
                    logger.info(f"[Face {face_id}] Making decision based on {samples_collected} samples")
                    
                    predictions = queue_entry['predictions']
                    
                    # Count votes for each student
                    vote_counts = {}
                    confidence_sums = {}
                    
                    for pred in predictions:
                        pred_label = pred['label']
                        pred_conf = pred['confidence']
                        
                        if pred_label != 'Unknown':
                            vote_counts[pred_label] = vote_counts.get(pred_label, 0) + 1
                            confidence_sums[pred_label] = confidence_sums.get(pred_label, 0) + pred_conf
                    
                    # Also count Unknown votes
                    unknown_votes = sum(1 for pred in predictions if pred['label'] == 'Unknown')
                    
                    logger.info(f"[Face {face_id}] Vote distribution: {vote_counts}, Unknown: {unknown_votes}")
                    
                    final_label = 'Unknown'
                    final_confidence = 0.0
                    
                    if vote_counts:
                        # Get student with most votes
                        winner = max(vote_counts, key=vote_counts.get)
                        winner_votes = vote_counts[winner]
                        avg_confidence = confidence_sums[winner] / winner_votes
                        
                        # Require at least 40% of samples to agree (4 out of 10, or 2 out of 5)
                        vote_percentage = winner_votes / samples_collected
                        
                        logger.info(f"[Face {face_id}] Winner: {winner}, votes: {winner_votes}/{samples_collected} ({vote_percentage*100:.1f}%), avg_conf: {avg_confidence:.4f}")
                        
                        if vote_percentage >= 0.4 and avg_confidence >= 0.55:
                            final_label = winner
                            final_confidence = avg_confidence
                            logger.info(f"[Face {face_id}] ✓ ACCEPTED by majority voting")
                        else:
                            logger.warning(f"[Face {face_id}] ✗ Insufficient votes or confidence")
                    
                    # Clean up queue
                    del multi_sample_queue[face_id]
                
                # Process final decision
                if final_label != 'Unknown':
                    student_id = final_label
                    
                    # Load student name from database
                    db = load_database()
                    student_info = db.get(student_id, {})
                    student_name = student_info.get('name', student_id)
                    
                    logger.info(f"[Face {face_id}] ✓ RECOGNIZED: {student_name} (ID: {student_id}) with confidence {final_confidence:.2f}")
                    tracker.set_label(face_id, student_name, final_confidence, student_id=student_id)
                    
                    # Record recognition in stats
                    camera_manager.record_recognition(student_id, student_name=student_name, confidence=final_confidence, is_unknown=False)
                    
                    # TODO: Mark attendance in database
                    # This should update the attendance record for this student in this class
                    logger.info(f"[Face {face_id}] Attendance marked for {student_id} in class {current_class_id}")
                    
                else:
                    logger.warning(f"[Face {face_id}] ✗ NOT RECOGNIZED after {samples_collected} samples")
                    tracker.set_label(face_id, "Unknown", 0.0)
                    
                    # Record unknown face in stats
                    camera_manager.record_recognition(None, confidence=final_confidence, is_unknown=True)
            
            finally:
                # Always clear processing flag when done
                with multi_sample_lock:
                    if face_id in multi_sample_queue:
                        multi_sample_queue[face_id]['processing'] = False
                
        except Exception as e:
            logger.error(f"[Face {face_id}] Recognition error: {e}", exc_info=True)
            tracker.set_label(face_id, "Error", 0.0)
            # Clear from queue on error
            with multi_sample_lock:
                if face_id in multi_sample_queue:
                    del multi_sample_queue[face_id]

    def generate_frames() -> Generator[bytes, None, None]:
        frame_count = 0
        while True:
            if not camera_manager.is_running:
                time.sleep(0.1)
                continue

            ret, frame = camera_manager.get_frame()
            if not ret:
                logger.warning("Failed to read frame from camera")
                break
            
            frame_count += 1
            
            # 1. Detect faces
            faces = detector.detect(frame)
            if frame_count % 30 == 0:  # Log every 30 frames
                logger.debug(f"Frame {frame_count}: Detected {len(faces)} face(s)")
            
            # Update total detections counter
            if len(faces) > 0:
                camera_manager.total_detections = len(faces)
            
            # 2. Update tracker
            tracked_faces = tracker.update(faces)
            
            # 3. Process new faces and retry ambiguous ones
            current_class_id = camera_manager.class_id
            
            for face_id, data in tracked_faces.items():
                # Check if this face needs sampling (either new or still collecting samples)
                needs_sampling = face_id in multi_sample_queue
                is_new_face = data['is_new']
                
                if (is_new_face or needs_sampling) and current_class_id:
                    x, y, w, h = data['bbox']
                    
                    # Filter out very small faces (likely false detections or too far away)
                    MIN_FACE_SIZE = 40  # Minimum width/height in pixels
                    if w < MIN_FACE_SIZE or h < MIN_FACE_SIZE:
                        if is_new_face:
                            logger.warning(f"Face {face_id} too small ({w}x{h}), skipping recognition")
                            tracker.set_label(face_id, "Too Small", 0.0)
                        continue
                    
                    if is_new_face:
                        logger.info(f"New face detected: ID={face_id}, bbox=({x},{y},{w},{h})")
                    elif needs_sampling:
                        logger.debug(f"Re-processing face {face_id} for next sample")
                    
                    # Add margin to the crop (30% on each side for better context)
                    margin_x = int(w * 0.3)
                    margin_y = int(h * 0.3)
                    
                    x1 = max(0, x - margin_x)
                    y1 = max(0, y - margin_y)
                    x2 = min(frame.shape[1], x + w + margin_x)
                    y2 = min(frame.shape[0], y + h + margin_y)
                    
                    face_crop = frame[y1:y2, x1:x2]
                    
                    if face_crop.size > 0:
                        logger.debug(f"[Face {face_id}] Cropped face size: {face_crop.shape}")
                        threading.Thread(
                            target=recognize_face_direct,
                            args=(face_id, face_crop.copy(), current_class_id),
                            daemon=True
                        ).start()
                    else:
                        logger.warning(f"[Face {face_id}] Invalid face crop")
            
            # 4. Draw annotations
            for face_id, data in tracked_faces.items():
                x, y, w, h = data['bbox']
                label = data['label']
                confidence = data.get('confidence', 0)
                
                # Determine color and display information
                if label.startswith('face'):
                    # Processing/Scanning state
                    color = (255, 165, 0)  # Orange
                    draw_scanning_box(frame, x, y, w, h, color)
                elif label == 'Unknown':
                    # Unknown face
                    color = (0, 0, 255)  # Red
                    draw_unknown_box(frame, x, y, w, h, color, confidence)
                else:
                    # Recognized student
                    color = (0, 255, 0)  # Green
                    # Get student ID from tracker data or parse from label
                    student_id = data.get('student_id', '')
                    draw_recognized_box(frame, x, y, w, h, color, label, student_id, confidence)
            
            # Encode frame
            ret, buffer = cv2.imencode('.jpg', frame)
            frame_bytes = buffer.tobytes()
            
            yield (b'--frame\r\n'
                   b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')

    @app.route('/')
    def index():
        return render_template('index.html')

    @app.route('/start_class', methods=['POST'])
    def start_class():
        data = request.json
        class_id = data.get('class_id')
        if not class_id:
            logger.warning("Start class request missing class_id")
            return jsonify({'error': 'Class ID is required'}), 400
        
        logger.info(f"Starting class session: {class_id}")
        
        # Verify class exists
        classes = load_classes()
        if class_id not in classes:
            logger.error(f"Class {class_id} not found in database")
            return jsonify({'error': f'Class {class_id} not found'}), 404
        
        if camera_manager.start(class_id):
            logger.info(f"✓ Class {class_id} started successfully")
            return jsonify({'status': 'started', 'class_id': class_id})
        else:
            logger.error(f"✗ Failed to start camera for class {class_id}")
            return jsonify({'error': 'Failed to start camera'}), 500

    @app.route('/stop_class', methods=['POST'])
    def stop_class():
        logger.info("Stopping class session")
        camera_manager.stop()
        logger.info("✓ Class session stopped")
        return jsonify({'status': 'stopped'})

    @app.route('/video_feed')
    def video_feed():
        return Response(generate_frames(),
                        mimetype='multipart/x-mixed-replace; boundary=frame')
    
    @app.route('/api/stats')
    def get_stats():
        """Return current session statistics."""
        stats = camera_manager.get_stats()
        return jsonify(stats)
    
    @app.route('/api/detections')
    def get_detections():
        """Return recent detection events."""
        detections = camera_manager.get_recent_detections()
        return jsonify({'detections': detections})
    
    @app.route('/api/classes/')
    def get_classes():
        """Return list of all classes."""
        try:
            classes = load_classes()
            class_list = list(classes.values())
            logger.info(f"Loaded {len(class_list)} classes")
            return jsonify({
                'count': len(class_list),
                'classes': class_list
            })
        except Exception as e:
            logger.error(f"Error loading classes: {e}")
            return jsonify({'error': str(e)}), 500

    return app

if __name__ == '__main__':
    args = parse_args()
    logger.info("="*60)
    logger.info("HADIR Live Attendance System")
    logger.info("="*60)
    logger.info(f"Camera source: {args.camera}")
    logger.info(f"Server: http://{args.host}:{args.port}")
    logger.info("="*60)
    
    app = create_app(args.camera)
    logger.info("Starting Flask server...")
    app.run(host=args.host, port=args.port, debug=False, threaded=True)
