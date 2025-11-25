import sys
import os

# Suppress TensorFlow logs and oneDNN messages
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'  # 0=all, 1=no info, 2=no info/warn, 3=no error

# Add project root to Python path to allow 'backend' imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import logging

# Configure logging structure
class CustomFormatter(logging.Formatter):
    """Custom formatter with colors"""
    grey = "\x1b[38;20m"
    blue = "\x1b[34;20m"
    yellow = "\x1b[33;20m"
    red = "\x1b[31;20m"
    bold_red = "\x1b[31;1m"
    reset = "\x1b[0m"
    # Simplified format: [Time] Level: Message
    format_str = "[%(asctime)s] %(levelname)s: %(message)s"

    FORMATS = {
        logging.DEBUG: grey + format_str + reset,
        logging.INFO: blue + format_str + reset,
        logging.WARNING: yellow + format_str + reset,
        logging.ERROR: red + format_str + reset,
        logging.CRITICAL: bold_red + format_str + reset
    }

    def format(self, record):
        log_fmt = self.FORMATS.get(record.levelno)
        formatter = logging.Formatter(log_fmt, datefmt='%H:%M:%S')
        return formatter.format(record)

# Setup root logger
root_logger = logging.getLogger()
root_logger.setLevel(logging.INFO)

# Remove existing handlers
for handler in root_logger.handlers[:]:
    root_logger.removeHandler(handler)

# Add console handler with custom formatter
console_handler = logging.StreamHandler()
console_handler.setFormatter(CustomFormatter())
root_logger.addHandler(console_handler)

# Suppress noisy loggers
logging.getLogger('werkzeug').setLevel(logging.INFO)  # Enable request logs (IPs)
logging.getLogger('tensorflow').setLevel(logging.ERROR)
logging.getLogger('absl').setLevel(logging.ERROR)

from flask import Flask
from flask_cors import CORS

from backend.config import get_config, ensure_directories, HOST, PORT, DEBUG
from backend.api import api
from backend.services.manager import get_pipeline

# Import namespaces to register them
from backend.api.namespaces.health import ns_health
from backend.api.namespaces.students import ns_students
from backend.api.namespaces.classes import ns_classes
from backend.api.namespaces.attendance import ns_attendance

logger = logging.getLogger(__name__)

def create_app():
    """Create and configure the Flask application."""
    # Ensure storage directories exist
    ensure_directories()
    
    app = Flask(__name__)
    
    # Load configuration
    app.config.update(get_config())
    
    # Configure CORS
    CORS(app, resources={r"/api/*": {"origins": "*"}})
    
    # Initialize API
    api.init_app(app)
    
    # Register namespaces
    api.add_namespace(ns_health)
    api.add_namespace(ns_students)
    api.add_namespace(ns_classes)
    api.add_namespace(ns_attendance)
    
    # Initialize pipeline in background
    try:
        get_pipeline()
    except Exception as e:
        logger.warning(f"Could not initialize face processing pipeline on startup: {e}")
    
    return app

app = create_app()

if __name__ == '__main__':
    app.run(host=HOST, port=PORT, debug=DEBUG)
