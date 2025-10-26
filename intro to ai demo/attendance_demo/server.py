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
from attendance_demo.custom_embedder import embed_face
from attendance_demo.gallery_utils import load_gallery, match_embedding


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run the attendance demo web server.")
    parser.add_argument(
        '--gallery',
        type=str,
        default=str(Path(__file__).resolve().parents[0] / 'gallery.npz'),
        help='Path to the gallery npz file created by enroll.py.',
    )
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
    if src.isdigit():
        cap = cv2.VideoCapture(int(src))
    else:
        cap = cv2.VideoCapture(src)
    if not cap.isOpened():
        raise IOError(f"Failed to open video source {src}")
    return cap


def create_app(gallery_path: Path, video_source: str) -> Flask:
    app = Flask(__name__, template_folder='templates')
    # Load gallery once at startup
    embeddings, labels = load_gallery(str(gallery_path))
    detector = FaceDetector()
    cap = open_video_source(video_source)

    def gen_frames() -> Generator[bytes, None, None]:
        while True:
            success, frame = cap.read()
            if not success or frame is None:
                break
            # Detect faces and annotate
            faces = detector.detect(frame)
            for (x, y, w, h) in faces:
                pad = int(0.1 * max(w, h))
                x0 = max(x - pad, 0)
                y0 = max(y - pad, 0)
                x1 = min(x + w + pad, frame.shape[1])
                y1 = min(y + h + pad, frame.shape[0])
                face_crop = frame[y0:y1, x0:x1]
                embedding = embed_face(face_crop)
                label, score = match_embedding(embedding, embeddings, labels)
                # Draw bounding box and label
                cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 255, 0), 2)
                text = label if label != 'unknown' else 'Unknown'
                cv2.putText(frame, text, (x, y - 5), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)
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
    gallery_path = Path(args.gallery)
    if not gallery_path.exists():
        raise FileNotFoundError(f"Gallery file does not exist: {gallery_path}")
    app = create_app(gallery_path, args.video_source)
    print(f"Starting server on {args.host}:{args.port}")
    app.run(host=args.host, port=args.port, threaded=True)


if __name__ == '__main__':
    main()