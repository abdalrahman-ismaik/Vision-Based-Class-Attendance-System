"""
app.py
------

Flask web application for HADIR_web live attendance monitoring.
Provides real-time video streaming with face detection and recognition.

Features:
- Real-time video feed with MJPEG streaming
- Face detection and recognition
- Green boxes for registered students
- Red boxes for unknown faces
- Integration with backend recognition API

Usage:
    python app.py --camera 0 --backend http://127.0.0.1:5000/api/attendance/class
"""

import os
import logging
import argparse
import requests
from flask import Flask, render_template, Response, request, jsonify
from flask_cors import CORS
from realtime_recognition import RealtimeRecognitionSystem

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Parse command line arguments
def parse_args():
    parser = argparse.ArgumentParser(description='HADIR_web Live Attendance Server')
    parser.add_argument(
        '--camera',
        type=str,
        default='0',
        help='Camera index (e.g., 0) or video file path (default: 0)'
    )
    parser.add_argument(
        '--backend',
        type=str,
        default='http://127.0.0.1:5000/api/attendance/class',
        help='Backend recognition API URL (default: http://127.0.0.1:5000/api/attendance/class)'
    )
    parser.add_argument(
        '--host',
        type=str,
        default='127.0.0.1',
        help='Host to bind the server to (default: 127.0.0.1)'
    )
    parser.add_argument(
        '--port',
        type=int,
        default=5001,
        help='Port to bind the server to (default: 5001)'
    )
    parser.add_argument(
        '--debug',
        action='store_true',
        help='Enable debug mode'
    )
    parser.add_argument(
        '--class-id',
        type=str,
        default=None,
        help='Class identifier to send with attendance submissions'
    )
    parser.add_argument(
        '--threshold',
        type=float,
        default=None,
        help='Optional confidence threshold forwarded to the backend (0-1)'
    )
    return parser.parse_args()


# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Global recognition system instance
recognition_system = None


def create_app(camera_source, backend_url, class_id=None, recognition_threshold=None):
    """Create and configure the Flask application."""
    global recognition_system
    
    try:
        logger.info("Initializing HADIR_web...")
        logger.info(f"Camera source: {camera_source}")
        logger.info(f"Backend API: {backend_url}")
        
        # Convert camera source to int if it's a digit
        if isinstance(camera_source, str) and camera_source.isdigit():
            camera_source = int(camera_source)
        
        # Initialize recognition system
        recognition_system = RealtimeRecognitionSystem(
            camera_source=camera_source,
            backend_url=backend_url,
            class_id=class_id,
            recognition_threshold=recognition_threshold
        )
        
        logger.info("✓ HADIR_web initialized successfully")
        
    except Exception as e:
        logger.error(f"Failed to initialize HADIR_web: {e}")
        raise
    
    return app


@app.route('/')
def index():
    """Render main dashboard page."""
    backend_base = recognition_system.backend_url.rsplit('/', 2)[0] if recognition_system else 'http://127.0.0.1:5000'
    class_id = recognition_system.class_id if recognition_system else ''
    return render_template('index.html', backend_url=backend_base, class_id=class_id)


@app.route('/video_feed')
def video_feed():
    """
    Video streaming route.
    Returns MJPEG stream with real-time face detection and recognition.
    """
    if recognition_system is None:
        return "Recognition system not initialized", 500
    
    return Response(
        recognition_system.generate_frames(),
        mimetype='multipart/x-mixed-replace; boundary=frame'
    )


@app.route('/health')
def health():
    """Health check endpoint."""
    return {
        'status': 'ok',
        'service': 'HADIR_web',
        'camera_active': recognition_system is not None,
        'backend_url': recognition_system.backend_url if recognition_system else None,
        'class_id': recognition_system.class_id if recognition_system else None
    }


@app.route('/config/class', methods=['GET', 'POST'])
def configure_class():
    """Get or update the active class identifier used for recognition submissions."""
    if recognition_system is None:
        return jsonify({'error': 'Recognition system not initialized'}), 503

    if request.method == 'GET':
        return {'class_id': recognition_system.class_id}

    payload = request.get_json(silent=True) or {}
    new_class_id = payload.get('class_id', '').strip()

    if not new_class_id:
        return jsonify({'error': 'class_id is required'}), 400

    recognition_system.set_class_id(new_class_id)
    logger.info(f"Class ID updated via UI -> {new_class_id}")
    return {'class_id': recognition_system.class_id}


@app.route('/api/class/roster')
def get_class_roster():
    """Get the roster of students in the current class."""
    if recognition_system is None:
        return jsonify({'error': 'Recognition system not initialized'}), 503
    
    if not recognition_system.class_id:
        return jsonify({'error': 'Class ID not set'}), 400
    
    try:
        # Fetch roster from backend
        backend_base = recognition_system.backend_url.rsplit('/', 2)[0]
        response = requests.get(
            f"{backend_base}/api/classes/{recognition_system.class_id}/students",
            timeout=10
        )
        
        if response.status_code == 404:
            return jsonify({'error': 'Class not found or no students enrolled'}), 404
        
        response.raise_for_status()
        data = response.json()
        
        return jsonify({
            'class_id': data.get('class_id'),
            'class_name': data.get('class_name'),
            'students': data.get('students', [])
        })
        
    except requests.RequestException as e:
        logger.error(f"Failed to fetch class roster: {e}")
        return jsonify({'error': 'Failed to fetch class roster'}), 500


@app.route('/api/attendance/recognized')
def get_recognized_students():
    """Get list of students recognized in the current session."""
    if recognition_system is None:
        return jsonify({'error': 'Recognition system not initialized'}), 503
    
    return jsonify({
        'recognized_students': [
            {
                'student_id': student_id,
                'name': details['name'],
                'confidence': details['confidence'],
                'timestamp': details['timestamp']
            }
            for student_id, details in recognition_system.recognized_students.items()
        ]
    })


@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors."""
    return {'error': 'Endpoint not found'}, 404


@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors."""
    logger.error(f"Internal server error: {error}")
    return {'error': 'Internal server error'}, 500


def main():
    """Main entry point."""
    args = parse_args()
    
    try:
        # Create app with configuration
        create_app(
            camera_source=args.camera,
            backend_url=args.backend,
            class_id=args.class_id,
                recognition_threshold=args.threshold
        )
        
        # Print startup info
        print("\n" + "="*60)
        print("  🎓 HADIR Live Attendance System")
        print("="*60)
        print(f"\n  📹 Camera: {args.camera}")
        print(f"  🔗 Backend API: {args.backend}")
        if args.class_id:
            print(f"  🏫 Class ID: {args.class_id}")
        else:
            print("  ⚠️ Class ID not provided. Set it from the web dashboard before recording attendance.")
        print(f"  🌐 Server: http://{args.host}:{args.port}")
        print(f"\n  Open http://{args.host}:{args.port} in your browser")
        print("\n  Press Ctrl+C to stop the server")
        print("="*60 + "\n")
        
        # Run Flask app
        app.run(
            host=args.host,
            port=args.port,
            debug=args.debug,
            threaded=True
        )
        
    except KeyboardInterrupt:
        logger.info("\nShutting down...")
        if recognition_system:
            recognition_system.release()
        logger.info("Server stopped")
        
    except Exception as e:
        logger.error(f"Failed to start server: {e}")
        
        # Add helpful hint for WSL2/Linux users
        if "Failed to open camera" in str(e):
            print("\n" + "!"*60)
            print("  [ERROR] Could not open camera.")
            if os.name != 'nt':
                print("  [TIP] On WSL2/Linux, direct webcam access (index 0) requires USBIPD.")
            
            if "http" in str(args.camera):
                print("  [TIP] For IP Cameras, ensure the URL includes the video stream endpoint.")
                print("        Common endpoints: /video, /video?x.mjpeg, /mjpegfeed")
                print(f"        Try: {args.camera}/video")
            else:
                print("  [TIP] Alternatively, use an IP Webcam app on your phone:")
                print("        python app.py --camera http://192.168.1.x:8080/video")
            print("!"*60 + "\n")

        if recognition_system:
            recognition_system.release()
        raise


if __name__ == '__main__':
    main()
