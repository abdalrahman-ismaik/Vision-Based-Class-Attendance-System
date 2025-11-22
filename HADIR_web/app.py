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
    python app.py --camera 0 --backend http://127.0.0.1:5000/api/students/recognize
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
        default='http://127.0.0.1:5000/api/students/recognize',
        help='Backend recognition API URL (default: http://127.0.0.1:5000/api/students/recognize)'
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
    return parser.parse_args()


# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Global recognition system instance
recognition_system = None


def create_app(camera_source, backend_url):
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
            backend_url=backend_url
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
    return render_template('index.html', backend_url=backend_base)


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
        'backend_url': recognition_system.backend_url if recognition_system else None
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
        create_app(args.camera, args.backend)
        
        # Print startup info
        print("\n" + "="*60)
        print("  🎓 HADIR Live Attendance System")
        print("="*60)
        print(f"\n  📹 Camera: {args.camera}")
        print(f"  🔗 Backend API: {args.backend}")
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
        if recognition_system:
            recognition_system.release()
        raise


if __name__ == '__main__':
    main()
