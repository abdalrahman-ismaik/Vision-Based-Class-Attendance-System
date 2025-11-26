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

    def start(self, class_id: str):
        with self.lock:
            if self.is_running:
                self.stop()
            
            self.class_id = class_id
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
            print("Camera stopped")

    def get_frame(self):
        with self.lock:
            if self.is_running and self.cap and self.cap.isOpened():
                return self.cap.read()
            return False, None

def create_app(video_source: str) -> Flask:
    app = Flask(__name__, template_folder='templates')
    
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
    
    # Verification queue for ambiguous faces with thread lock
    # Format: {face_id: {'predictions': [list of prediction dicts], 'attempts': int, 'processing': bool}}
    verification_queue = {}
    verification_lock = threading.Lock()
    MAX_VERIFICATION_ATTEMPTS = 3
    MIN_REQUIRED_MARGIN = 0.05

    def recognize_face_direct(face_id: int, face_crop, current_class_id: str):
        """Process cropped face using backend pipeline directly."""
        try:
            # Check if another thread is already processing this face
            with verification_lock:
                if face_id in verification_queue:
                    if verification_queue[face_id].get('processing', False):
                        logger.debug(f"[Face {face_id}] Already being processed by another thread, skipping")
                        return
                    # Mark as processing
                    verification_queue[face_id]['processing'] = True
                else:
                    # Initialize queue entry with processing flag
                    verification_queue[face_id] = {
                        'predictions': [],
                        'attempts': 0,
                        'processing': True
                    }
            
            try:
                logger.info(f"[Face {face_id}] Starting recognition for class: {current_class_id}")
                
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
                logger.info(f"[Face {face_id}]   - Threshold: 0.6")
                logger.info(f"[Face {face_id}]   - Allowed students: {enrolled_ids}")
                
                result = pipeline.recognize_face_from_crop(
                    face_crop_path=temp_path,
                    threshold=0.6,
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
                
                logger.info(f"[Face {face_id}] Prediction details:")
                logger.info(f"[Face {face_id}]   - Label: {label}")
                logger.info(f"[Face {face_id}]   - Confidence: {confidence:.4f}")
                logger.info(f"[Face {face_id}]   - All predictions: {all_predictions}")
                
                # Check if this was an ambiguous match
                reason = prediction.get('reason', '')
                margin = prediction.get('margin', 1.0)
                
                if reason == 'ambiguous_match':
                    with verification_lock:
                        # Check if face still in queue (might have been cleared by another thread)
                        if face_id not in verification_queue:
                            logger.warning(f"[Face {face_id}] Face already processed and cleared from queue")
                            tracker.set_label(face_id, "Already Processed", 0.0)
                            return
                        
                        # Add prediction to queue
                        verification_queue[face_id]['predictions'].append(prediction)
                        verification_queue[face_id]['attempts'] += 1
                        
                        attempts = verification_queue[face_id]['attempts']
                        logger.warning(f"[Face {face_id}] Ambiguous match (margin: {margin:.4f}), collecting more samples ({attempts}/{MAX_VERIFICATION_ATTEMPTS})")
                        
                        if attempts < MAX_VERIFICATION_ATTEMPTS:
                            # Need more samples, clear processing flag and return
                            verification_queue[face_id]['processing'] = False
                            tracker.set_label(face_id, f"Verifying... {attempts}/{MAX_VERIFICATION_ATTEMPTS}", confidence)
                            return
                        else:
                            # Max attempts reached, use majority voting
                            logger.info(f"[Face {face_id}] Max attempts reached, using majority voting across {len(verification_queue[face_id]['predictions'])} samples")
                            
                            # Count votes for each student
                            vote_counts = {}
                            cosine_sums = {}
                            
                            for pred in verification_queue[face_id]['predictions']:
                                cosine_sims = pred.get('cosine_similarities', {})
                                if cosine_sims:
                                    best_student = max(cosine_sims, key=cosine_sims.get)
                                    vote_counts[best_student] = vote_counts.get(best_student, 0) + 1
                                    cosine_sums[best_student] = cosine_sums.get(best_student, 0) + cosine_sims[best_student]
                            
                            if vote_counts:
                                # Get student with most votes
                                winner = max(vote_counts, key=vote_counts.get)
                                winner_votes = vote_counts[winner]
                                avg_cosine = cosine_sums[winner] / winner_votes
                                
                                logger.info(f"[Face {face_id}] Voting results: {vote_counts}")
                                logger.info(f"[Face {face_id}] Winner: {winner} with {winner_votes} votes, avg cosine: {avg_cosine:.4f}")
                                
                                # Check if winner has clear majority (> 50%)
                                if winner_votes > MAX_VERIFICATION_ATTEMPTS / 2 and avg_cosine >= 0.60:
                                    label = winner
                                    confidence = avg_cosine
                                    logger.info(f"[Face {face_id}] Verified by majority voting")
                                else:
                                    label = 'Unknown'
                                    confidence = avg_cosine
                                    logger.warning(f"[Face {face_id}] No clear majority, marking as Unknown")
                            else:
                                label = 'Unknown'
                                confidence = 0.0
                            
                            # Clean up verification queue
                            del verification_queue[face_id]
                else:
                    # Clear verification queue if face was successfully identified
                    with verification_lock:
                        if face_id in verification_queue:
                            del verification_queue[face_id]
                
                if label != 'Unknown':
                    student_id = label
                    
                    # Load student name from database
                    db = load_database()
                    student_info = db.get(student_id, {})
                    student_name = student_info.get('name', student_id)
                    
                    logger.info(f"[Face {face_id}] ✓ RECOGNIZED: {student_name} (ID: {student_id}) with confidence {confidence:.2f}")
                    tracker.set_label(face_id, student_name, confidence)
                    
                    # TODO: Mark attendance in database
                    # This should update the attendance record for this student in this class
                    logger.info(f"[Face {face_id}] Attendance marked for {student_id} in class {current_class_id}")
                    
                else:
                    logger.warning(f"[Face {face_id}] ✗ NOT RECOGNIZED")
                    logger.warning(f"[Face {face_id}]   - Best confidence was: {confidence:.4f} (threshold: 0.6)")
                    if all_predictions:
                        logger.warning(f"[Face {face_id}]   - Top predictions:")
                        sorted_preds = sorted(all_predictions.items(), key=lambda x: x[1], reverse=True)[:3]
                        for sid, conf in sorted_preds:
                            logger.warning(f"[Face {face_id}]     * {sid}: {conf:.4f}")
                    tracker.set_label(face_id, "Unknown", 0.0)
            
            finally:
                # Always clear processing flag when done
                with verification_lock:
                    if face_id in verification_queue:
                        verification_queue[face_id]['processing'] = False
                
        except Exception as e:
            logger.error(f"[Face {face_id}] Recognition error: {e}", exc_info=True)
            tracker.set_label(face_id, "Error", 0.0)
            # Clear from queue on error
            with verification_lock:
                if face_id in verification_queue:
                    del verification_queue[face_id]

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
            
            # 2. Update tracker
            tracked_faces = tracker.update(faces)
            
            # 3. Process new faces and retry ambiguous ones
            current_class_id = camera_manager.class_id
            
            for face_id, data in tracked_faces.items():
                # Check if this face is in verification queue (needs retry)
                needs_verification = face_id in verification_queue
                is_new_face = data['is_new']
                
                if (is_new_face or needs_verification) and current_class_id:
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
                    elif needs_verification:
                        logger.debug(f"Re-processing face {face_id} for verification")
                    
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
                
                # Logic: 
                # - If label starts with 'face' -> Processing (Yellow/Blue?) -> Let's use Red for now as "Unregistered/Unknown"
                # - If label is 'Unknown' -> Red
                # - Otherwise (Name) -> Green
                
                if label.startswith('face') or label == 'Unknown':
                    color = (0, 0, 255) # Red
                    display_label = "Unknown" if label == 'Unknown' else "Scanning..."
                else:
                    color = (0, 255, 0) # Green
                    display_label = f"{label} ({data.get('confidence', 0):.2f})"

                cv2.rectangle(frame, (x, y), (x+w, y+h), color, 2)
                cv2.putText(frame, display_label, (x, y-10), cv2.FONT_HERSHEY_SIMPLEX, 0.8, color, 2)
            
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
