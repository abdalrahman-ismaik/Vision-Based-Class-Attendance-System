import os
import logging
from datetime import datetime
from PIL import Image
from backend.config.settings import ALLOWED_EXTENSIONS, STUDENT_DATA_FOLDER

logger = logging.getLogger(__name__)

def allowed_file(filename):
    """Check if the uploaded file has an allowed extension."""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def validate_image(file):
    """Validate the uploaded image file."""
    if not file:
        return False, "No file provided"
    
    if file.filename == '':
        return False, "No file selected"
    
    if not allowed_file(file.filename):
        return False, f"Invalid file type. Allowed types: {', '.join(ALLOWED_EXTENSIONS)}"
    
    return True, "Valid"

def save_student_images(files, student_id):
    """Save multiple student face images to the uploads folder."""
    # Create student-specific folder
    student_folder = os.path.join(STUDENT_DATA_FOLDER, student_id)
    os.makedirs(student_folder, exist_ok=True)
    
    saved_paths = []
    errors = []
    
    for idx, file in enumerate(files, 1):
        # Generate unique filename
        try:
            ext = file.filename.rsplit('.', 1)[1].lower()
        except IndexError:
            ext = 'jpg' # Default fallback
            
        filename = f"{student_id}_pose{idx}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.{ext}"
        filepath = os.path.join(student_folder, filename)
        
        # Save the file
        try:
            file.save(filepath)
            
            # Validate it's a valid image
            img = Image.open(filepath)
            img.verify()
            logger.info(f"Image {idx} saved successfully: {filepath}")
            saved_paths.append(filepath)
            
            # Re-open to ensure it's not closed if we need to use it later? 
            # verify() closes the file, but we are just saving paths here.
            
        except Exception as e:
            if os.path.exists(filepath):
                os.remove(filepath)
            logger.error(f"Invalid image file {idx}: {e}")
            errors.append(f"Image {idx}: {str(e)}")
    
    if len(saved_paths) == 0:
        return None, "No valid images could be saved: " + "; ".join(errors)
    
    return saved_paths, None
