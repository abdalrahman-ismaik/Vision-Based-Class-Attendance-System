"""
Configuration Module
Contains application configuration and settings.
"""

import os
from pathlib import Path

# Base paths
BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / 'data'
STORAGE_DIR = BASE_DIR / 'storage'
UPLOADS_DIR = STORAGE_DIR / 'uploads'
PROCESSED_DIR = STORAGE_DIR / 'processed_faces'
CLASSIFIERS_DIR = STORAGE_DIR / 'classifiers'

# Database files
DATABASE_FILE = DATA_DIR / 'database.json'
CLASSES_FILE = DATA_DIR / 'classes.json'

# Ensure directories exist
DATA_DIR.mkdir(exist_ok=True)
STORAGE_DIR.mkdir(exist_ok=True)
UPLOADS_DIR.mkdir(exist_ok=True)
PROCESSED_DIR.mkdir(exist_ok=True)
CLASSIFIERS_DIR.mkdir(exist_ok=True)

class Config:
    """Application configuration"""
    SECRET_KEY = os.getenv('SECRET_KEY', 'your-secret-key-change-in-production')
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB max file size
    
    # File paths
    DATABASE_PATH = str(DATABASE_FILE)
    CLASSES_PATH = str(CLASSES_FILE)
    UPLOAD_FOLDER = str(UPLOADS_DIR)
    PROCESSED_FOLDER = str(PROCESSED_DIR)
    CLASSIFIERS_FOLDER = str(CLASSIFIERS_DIR)
    
    # Model paths (adjust as needed)
    FACENET_MODEL_PATH = '../FaceNet/mobilefacenet_arcface/best_model_epoch43_acc100.00.pth'
    
    # Face processing settings
    MIN_FACE_SIZE = 20
    CONFIDENCE_THRESHOLD = 0.7
    SIMILARITY_THRESHOLD = 0.6
