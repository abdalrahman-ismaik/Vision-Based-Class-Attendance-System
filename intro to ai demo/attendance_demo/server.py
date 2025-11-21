"""
server.py
---------

Flask application for streaming the annotated video from the real‑time
attendance system over HTTP.  When you navigate to the root URL (``/``)
the browser will display a web page containing a live MJPEG stream of
the video annotated with bounding boxes and names.

This server is optional; you can also run the demo directly via
``realtime_demo.py``.  The web interface may be convenient for
demonstrating the system on devices without access to the desktop or
when you wish to embed the stream into another application.

Usage::

    python server.py --gallery attendance_demo/gallery.npz --video_source 0 --host 0.0.0.0 --port 5000

Point your web browser at ``http://<host>:<port>/`` to view the stream.
"""

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Generator

import cv2
import os
import threading
import requests
from flask import Flask, render_template, Response

from attendance_demo.detector import FaceDetector
from attendance_demo.face_tracker import FaceTracker


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run the attendance demo web server with face tracking.")
    parser.add_argument(
        '--video_source',
        type=str,
        default='0',
        help='Video source (camera index or file/stream path).  Defaults to 0.',
    )
    parser.add_argument(
        '--host',
        type=str,
        default='127.0.0.1',
        help='Host interface to bind the web server to.',
    )
    parser.add_argument(
        '--port',
        type=int,
        default=5000,
        help='Port number to bind the web server to.',
    )
    return parser.parse_args()


def open_video_source(src: str) -> cv2.VideoCapture:
    """Open a video capture from a camera index or file/stream path."""
    print(f"Attempting to open video source: {src}")
    if src.isdigit():
        cap = cv2.VideoCapture(int(src), cv2.CAP_DSHOW) # Use DirectShow on Windows for faster opening
        if not cap.isOpened():
             # Fallback to default backend
             print(f"Failed to open with CAP_DSHOW, trying default backend...")
             cap = cv2.VideoCapture(int(src))
    else:
        cap = cv2.VideoCapture(src)
    
    if not cap.isOpened():
        raise IOError(f"Failed to open video source {src}")
    
    # Try to set resolution to something standard
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
    
    print(f"Successfully opened video source: {src}")
    return cap


BACKEND_RECOGNITION_URL = os.environ.get('BACKEND_RECOGNITION_URL', 'http://127.0.0.1:5001/api/students/recognize')


def create_app(video_source: str) -> Flask:
    app = Flask(__name__, template_folder='templates')
    # Initialize face detector and tracker
    detector = FaceDetector()
    tracker = FaceTracker(iou_threshold=0.3, max_disappeared=10)
    cap = open_video_source(video_source)

    def recognize_face_async(face_id: int, face_crop):
        """Send cropped face to backend recognizer in background."""
        try:
            _, buf = cv2.imencode('.jpg', face_crop)
            files = {'image': ('face.jpg', buf.tobytes(), 'image/jpeg')}
            resp = requests.post(BACKEND_RECOGNITION_URL, files=files, timeout=10)
            resp.raise_for_status()
            data = resp.json()

            if data.get('recognized') and data.get('student_id') not in (None, 'Unknown'):
                label = data.get('student_id', 'Unknown')
                confidence = data.get('confidence', 0.0)
            else:
                label = 'Unknown'
                confidence = data.get('confidence', 0.0)
        except Exception as exc:
            print(f"[Backend recognize] Error: {exc}")
            label = 'Unknown'
            confidence = 0.0

        tracker.set_label(face_id, label, confidence)

    def gen_frames() -> Generator[bytes, None, None]:
        frame_count = 0
        detection_interval = 3  # run detector every N frames
        last_faces = []  # cache last detected faces between detection frames
        stream_scale = 0.75  # downscale output stream to reduce bandwidth/encoding cost
        while True:
            success, frame = cap.read()
            if not success or frame is None:
                # Try to reconnect to camera if stream is lost
                print("Lost connection to camera, trying to reconnect...")
                cap.release()
                if video_source.isdigit():
                    cap.open(int(video_source), cv2.CAP_DSHOW)
                else:
                    cap.open(video_source)
                
                if not cap.isOpened():
                    print("Failed to reconnect to camera.")
                    break
                continue
            
            # Flip frame horizontally for a mirror effect (fixes inverted view)
            frame = cv2.flip(frame, 1)
            
            frame_count += 1
            
            # Optimization: run detection on downscaled frame, and only every N frames
            height, width = frame.shape[:2]
            detect_scale = 0.5  # Downscale to 50% for detection

            if frame_count % detection_interval == 0 or not last_faces:
                small_frame = cv2.resize(frame, None, fx=detect_scale, fy=detect_scale)
                small_faces = detector.detect(small_frame)

                # Scale bounding boxes back up
                faces = []
                for (x, y, w, h) in small_faces:
                    faces.append((
                        int(x / detect_scale),
                        int(y / detect_scale),
                        int(w / detect_scale),
                        int(h / detect_scale)
                    ))

                last_faces = faces
            else:
                faces = last_faces
            
            # Update tracker
            tracked_faces = tracker.update(faces)
            
            # Draw bounding boxes and labels for tracked faces
            for face_id, face_data in tracked_faces.items():
                x, y, w, h = face_data['bbox']
                label = face_data['label']
                confidence = face_data.get('confidence', 0.0)
                is_new = face_data.get('is_new', False)

                if is_new:
                    # Extract slightly padded face crop for backend recognition
                    pad = int(0.15 * max(w, h))
                    x0 = max(x - pad, 0)
                    y0 = max(y - pad, 0)
                    x1 = min(x + w + pad, frame.shape[1])
                    y1 = min(y + h + pad, frame.shape[0])
                    face_crop = frame[y0:y1, x0:x1].copy()

                    tracker.set_label(face_id, 'Processing...', 0.0)
                    threading.Thread(
                        target=recognize_face_async,
                        args=(face_id, face_crop),
                        daemon=True
                    ).start()
                    label = 'Processing...'
                    confidence = 0.0
                
                # Color: green for tracked faces
                color = (0, 255, 0)
                
                # Draw bounding box
                cv2.rectangle(frame, (x, y), (x + w, y + h), color, 2)
                
                # Draw label background
                if label and label != 'Unknown':
                    text = f"{label} ({confidence:.2f})"
                else:
                    text = label or 'Unknown'
                (text_w, text_h), _ = cv2.getTextSize(text, cv2.FONT_HERSHEY_SIMPLEX, 0.6, 2)
                cv2.rectangle(frame, (x, y - text_h - 10), (x + text_w, y), color, -1)
                
                # Draw label text
                cv2.putText(frame, text, (x, y - 5), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
            
            # Downscale the output stream to reduce encoding/network overhead
            if 0 < stream_scale < 1.0:
                output_frame = cv2.resize(frame, None, fx=stream_scale, fy=stream_scale)
            else:
                output_frame = frame

            # Encode as JPEG with reduced quality for performance
            ret, buffer = cv2.imencode('.jpg', output_frame, [int(cv2.IMWRITE_JPEG_QUALITY), 80])
            if not ret:
                continue
            frame_bytes = buffer.tobytes()
            yield (
                b'--frame\r\n'
                b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n'
            )
    
    @app.route('/')
    def index():
        return render_template('index.html')

    @app.route('/video_feed')
    def video_feed():
        return Response(gen_frames(), mimetype='multipart/x-mixed-replace; boundary=frame')

    return app


def main() -> None:
    args = parse_args()
    app = create_app(args.video_source)
    print(f"Starting face tracking server on {args.host}:{args.port}")
    print("Open http://{}:{}/ in your browser".format(args.host, args.port))
    app.run(host=args.host, port=args.port, threaded=True)


if __name__ == '__main__':
    main()