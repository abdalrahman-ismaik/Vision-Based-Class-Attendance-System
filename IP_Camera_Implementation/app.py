"""
app.py
------

Flask web application for HADIR Live Attendance monitoring with direct backend integration.
Provides real-time video streaming with face detection and recognition.

Features:
- Real-time video feed with MJPEG streaming
- Face detection and recognition using integrated backend pipeline
- Green boxes for registered students
- Red boxes for unknown faces
- Direct integration with FaceNet + SVM classifier (no HTTP calls)
- Class-based student filtering

Usage:
    python app.py --camera 0 --class-id CS101 --threshold 0.6
    python app.py --camera http://192.168.1.10:8080/video --class-id CS101
"""

import os
import logging
import argparse
from flask import Flask, render_template, Response
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
    parser = argparse.ArgumentParser(description='HADIR Live Attendance Server with Direct Backend Integration')
    parser.add_argument(
        '--camera',
        type=str,
        default='0',
        help='Camera index (e.g., 0) or video file path (default: 0)'
    )
    parser.add_argument(
        '--class-id',
        type=str,
        default=None,
        help='Class identifier to filter enrolled students (default: None - recognize all students)'
    )
    parser.add_argument(
        '--host',
        type=str,
        default='0.0.0.0',
        help='Host to bind the server to (default: 0.0.0.0)'
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
        '--threshold',
        type=float,
        default=0.6,
        help='Confidence threshold for recognition (0-1, default: 0.6)'
    )
    parser.add_argument(
        '--cooldown',
        type=float,
        default=10.0,
        help='Minimum seconds between recognitions per student (default: 10)'
    )
    return parser.parse_args()


# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Global recognition system instance
recognition_system = None


def create_app(camera_source, class_id=None, threshold=0.6, cooldown=10.0):
    """Create and configure the Flask application."""
    global recognition_system
    
    try:
        logger.info("Initializing HADIR with Direct Backend Integration...")
        logger.info(f"Camera source: {camera_source}")
        if class_id:
            logger.info(f"Class ID: {class_id}")
        logger.info(f"Recognition threshold: {threshold}")
        
        # Convert camera source to int if it's a digit
        if isinstance(camera_source, str) and camera_source.isdigit():
            camera_source = int(camera_source)
        
        # Initialize recognition system
        recognition_system = RealtimeRecognitionSystem(
            camera_source=camera_source,
            class_id=class_id,
            attendance_threshold=threshold,
            attendance_cooldown=cooldown
        )
        
        logger.info("✓ HADIR initialized successfully")
        
    except Exception as e:
        logger.error(f"Failed to initialize HADIR: {e}")
        raise
    
    return app


@app.route('/')
def index():
    """Render main dashboard page."""
    return render_template('index.html')


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
        'service': 'HADIR Live Attendance (Direct Backend)',
        'camera_active': recognition_system is not None,
        'classifier_trained': recognition_system.pipeline.classifier.is_trained if recognition_system else False,
        'num_students': len(recognition_system.pipeline.classifier.student_ids) if recognition_system else 0,
        'class_id': recognition_system.class_id if recognition_system else None
    }


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
            class_id=args.class_id,
            threshold=args.threshold,
            cooldown=args.cooldown
        )
        
        # Print startup info
        print("\n" + "="*60)
        print("  🎓 HADIR Live Attendance System (Direct Backend)")
        print("="*60)
        print(f"\n  📹 Camera: {args.camera}")
        if args.class_id:
            print(f"  🏫 Class: {args.class_id}")
            print(f"  🎯 Threshold: {args.threshold}")
            print(f"  ⏱  Cooldown: {args.cooldown}s")
        else:
            print(f"  👥 Mode: Recognize all students (no class filter)")
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
