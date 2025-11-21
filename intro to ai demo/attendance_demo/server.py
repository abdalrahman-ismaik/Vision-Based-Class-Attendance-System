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


def create_app(video_source: str) -> Flask:
    app = Flask(__name__, template_folder='templates')
    # Initialize face detector and tracker
    detector = FaceDetector()
    tracker = FaceTracker(iou_threshold=0.3, max_disappeared=10)
    cap = open_video_source(video_source)

    def gen_frames() -> Generator[bytes, None, None]:
        frame_count = 0
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
            
            frame_count += 1
            
            # Optimization: Resize frame for faster detection
            # Detect on a smaller image (e.g., 320px width)
            height, width = frame.shape[:2]
            scale_factor = 0.5  # Downscale to 50%
            small_frame = cv2.resize(frame, None, fx=scale_factor, fy=scale_factor)
            
            # Detect faces on small frame
            small_faces = detector.detect(small_frame)
            
            # Scale bounding boxes back up
            faces = []
            for (x, y, w, h) in small_faces:
                faces.append((
                    int(x / scale_factor),
                    int(y / scale_factor),
                    int(w / scale_factor),
                    int(h / scale_factor)
                ))
            
            # Update tracker
            tracked_faces = tracker.update(faces)
            
            # Draw bounding boxes and labels for tracked faces
            for face_id, face_data in tracked_faces.items():
                x, y, w, h = face_data['bbox']
                label = face_data['label']
                
                # Color: green for tracked faces
                color = (0, 255, 0)
                
                # Draw bounding box
                cv2.rectangle(frame, (x, y), (x + w, y + h), color, 2)
                
                # Draw label background
                text = label
                (text_w, text_h), _ = cv2.getTextSize(text, cv2.FONT_HERSHEY_SIMPLEX, 0.6, 2)
                cv2.rectangle(frame, (x, y - text_h - 10), (x + text_w, y), color, -1)
                
                # Draw label text
                cv2.putText(frame, text, (x, y - 5), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
            
            # Encode as JPEG
            ret, buffer = cv2.imencode('.jpg', frame)
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