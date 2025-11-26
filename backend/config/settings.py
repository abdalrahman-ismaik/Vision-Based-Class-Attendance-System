import os

# Base directory
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Security
SECRET_KEY = os.environ.get('SECRET_KEY', 'your-secret-key-change-in-production')
DEBUG = os.environ.get('FLASK_DEBUG', '1') == '1'

# Server
HOST = os.environ.get('HOST', '0.0.0.0')
PORT = int(os.environ.get('PORT', 5000))

# Storage paths
STORAGE_DIR = os.path.join(BASE_DIR, 'storage')
UPLOAD_FOLDER = os.path.join(STORAGE_DIR, 'uploads')
STUDENT_DATA_FOLDER = os.path.join(UPLOAD_FOLDER, 'students')
PROCESSED_FACES_FOLDER = os.path.join(STORAGE_DIR, 'processed')
CLASSIFIERS_FOLDER = os.path.join(STORAGE_DIR, 'classifiers')
DATA_DIR = os.path.join(STORAGE_DIR, 'data')

# Database files
DATABASE_FILE = os.path.join(DATA_DIR, 'database.json')
CLASSES_FILE = os.path.join(DATA_DIR, 'classes.json')

# Allowed extensions
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'bmp'}

def ensure_directories():
    """Ensure all necessary directories exist."""
    dirs = [
        STORAGE_DIR,
        UPLOAD_FOLDER,
        STUDENT_DATA_FOLDER,
        PROCESSED_FACES_FOLDER,
        CLASSIFIERS_FOLDER,
        DATA_DIR
    ]
    for d in dirs:
        os.makedirs(d, exist_ok=True)

def get_config():
    """Return configuration dictionary."""
    return {
        'SECRET_KEY': SECRET_KEY,
        'DEBUG': DEBUG,
        'UPLOAD_FOLDER': UPLOAD_FOLDER,
        'MAX_CONTENT_LENGTH': None
    }
