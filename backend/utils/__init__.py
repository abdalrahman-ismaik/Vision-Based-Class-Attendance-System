"""
Utility Functions
Contains helper functions and common utilities used across the application.
"""
from .database import DatabaseManager
from .file_handler import (
    allowed_file,
    validate_image,
    save_student_images,
    get_student_image_paths,
    delete_student_images,
    ALLOWED_EXTENSIONS
)

__all__ = [
    'DatabaseManager',
    'allowed_file',
    'validate_image',
    'save_student_images',
    'get_student_image_paths',
    'delete_student_images',
    'ALLOWED_EXTENSIONS'
]
