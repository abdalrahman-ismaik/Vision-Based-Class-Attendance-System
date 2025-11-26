"""
Script to cleanup all students and re-register from uploads folder
"""

import os
import sys
import json
import shutil
import time
from pathlib import Path

# Add backend to path
backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
project_root = os.path.dirname(backend_dir)
sys.path.insert(0, project_root)

from backend.services.face_processing_pipeline import FaceProcessingPipeline
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Paths
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STORAGE_DIR = os.path.join(BASE_DIR, 'storage')
DATA_DIR = os.path.join(STORAGE_DIR, 'data')
UPLOADS_DIR = os.path.join(STORAGE_DIR, 'uploads', 'students')
PROCESSED_DIR = os.path.join(STORAGE_DIR, 'processed')
CLASSIFIERS_DIR = os.path.join(STORAGE_DIR, 'classifiers')
DATABASE_FILE = os.path.join(DATA_DIR, 'database.json')

# Student names (you can update these)
STUDENT_NAMES = {
    '100063102': 'Student 100063102',
    '100064692': 'Student 100064692',
    '100064807': 'Student 100064807',
    '100064881': 'Student 100064881'
}

def cleanup_all():
    """Clean up database, processed faces, and classifiers"""
    logger.info("="*60)
    logger.info("CLEANUP PHASE")
    logger.info("="*60)
    
    # Clean database
    if os.path.exists(DATABASE_FILE):
        logger.info(f"Clearing database: {DATABASE_FILE}")
        with open(DATABASE_FILE, 'w') as f:
            json.dump({}, f, indent=2)
    else:
        os.makedirs(DATA_DIR, exist_ok=True)
        with open(DATABASE_FILE, 'w') as f:
            json.dump({}, f, indent=2)
    
    # Clean processed faces
    if os.path.exists(PROCESSED_DIR):
        logger.info(f"Removing processed faces: {PROCESSED_DIR}")
        shutil.rmtree(PROCESSED_DIR)
    os.makedirs(PROCESSED_DIR, exist_ok=True)
    
    # Clean classifiers
    if os.path.exists(CLASSIFIERS_DIR):
        logger.info(f"Removing classifiers: {CLASSIFIERS_DIR}")
        shutil.rmtree(CLASSIFIERS_DIR)
    os.makedirs(CLASSIFIERS_DIR, exist_ok=True)
    
    logger.info("✓ Cleanup complete\n")

def load_database():
    """Load database"""
    if os.path.exists(DATABASE_FILE):
        with open(DATABASE_FILE, 'r') as f:
            return json.load(f)
    return {}

def save_database(data):
    """Save database"""
    os.makedirs(DATA_DIR, exist_ok=True)
    with open(DATABASE_FILE, 'w') as f:
        json.dump(data, f, indent=2)

def process_student(pipeline, student_id, image_paths):
    """Process a single student"""
    logger.info(f"\n{'='*60}")
    logger.info(f"PROCESSING STUDENT: {student_id}")
    logger.info(f"{'='*60}")
    logger.info(f"Images found: {len(image_paths)}")
    
    # Create student record
    from datetime import datetime
    student_data = {
        'student_id': student_id,
        'name': STUDENT_NAMES.get(student_id, f'Student {student_id}'),
        'email': f'{student_id}@university.edu',
        'department': 'Computer Science',
        'year': 3,
        'image_paths': image_paths,
        'num_poses': len(image_paths),
        'registered_at': datetime.now().isoformat(),
        'processing_status': 'processing'
    }
    
    # Save to database
    db = load_database()
    db[student_id] = student_data
    save_database(db)
    logger.info(f"✓ Student record created in database")
    
    # Process images
    try:
        result = pipeline.process_student_images(
            image_paths=image_paths,
            student_id=student_id,
            output_dir=PROCESSED_DIR,
            augment_per_image=20
        )
        
        if result:
            # Update database
            db = load_database()
            db[student_id]['processing_status'] = 'completed'
            db[student_id]['processed_at'] = datetime.now().isoformat()
            db[student_id]['num_poses_captured'] = result['num_poses_captured']
            db[student_id]['num_samples_total'] = result['num_samples_total']
            db[student_id]['embeddings_path'] = result['embeddings_path']
            save_database(db)
            
            logger.info(f"✓ Processing complete: {result['num_samples_total']} samples from {result['num_poses_captured']} poses")
            return True
        else:
            db = load_database()
            db[student_id]['processing_status'] = 'failed'
            db[student_id]['processing_error'] = 'No face detected'
            save_database(db)
            logger.error(f"✗ Processing failed: No face detected")
            return False
            
    except Exception as e:
        logger.error(f"✗ Error processing student: {e}", exc_info=True)
        db = load_database()
        db[student_id]['processing_status'] = 'failed'
        db[student_id]['processing_error'] = str(e)
        save_database(db)
        return False

def train_classifier(pipeline):
    """Train the classifier"""
    logger.info(f"\n{'='*60}")
    logger.info("TRAINING CLASSIFIER")
    logger.info(f"{'='*60}")
    
    classifier_path = os.path.join(CLASSIFIERS_DIR, 'classifier.pkl')
    
    try:
        result = pipeline.train_classifier_from_data(
            data_dir=PROCESSED_DIR,
            classifier_output_path=classifier_path
        )
        
        logger.info(f"✓ Classifier trained successfully")
        logger.info(f"  Students: {result['n_students']}")
        logger.info(f"  Total embeddings: {result['n_embeddings']}")
        logger.info(f"  Average test accuracy: {result['metrics']['average_test_accuracy']:.3f}")
        logger.info(f"  Average test F1: {result['metrics']['average_test_f1']:.3f}")
        
        # Save metadata
        from datetime import datetime
        metadata = {
            'trained_at': datetime.now().isoformat(),
            'n_students': result['n_students'],
            'n_embeddings': result['n_embeddings'],
            'average_test_accuracy': result['metrics']['average_test_accuracy'],
            'average_test_f1': result['metrics']['average_test_f1'],
            'per_student_metrics': result['metrics']['per_student_metrics'],
            'classifier_path': classifier_path,
            'classifier_type': 'binary_per_student'
        }
        
        metadata_path = os.path.join(CLASSIFIERS_DIR, 'classifier_metadata.json')
        with open(metadata_path, 'w') as f:
            json.dump(metadata, f, indent=2)
        
        logger.info(f"✓ Metadata saved to {metadata_path}")
        return True
        
    except Exception as e:
        logger.error(f"✗ Classifier training failed: {e}", exc_info=True)
        return False

def main():
    """Main execution"""
    logger.info("\n" + "="*60)
    logger.info("STUDENT RE-REGISTRATION AND TRAINING PIPELINE")
    logger.info("="*60 + "\n")
    
    # Step 1: Cleanup
    cleanup_all()
    
    # Step 2: Initialize pipeline
    logger.info("="*60)
    logger.info("INITIALIZING PIPELINE")
    logger.info("="*60)
    pipeline = FaceProcessingPipeline()
    logger.info("✓ Pipeline initialized\n")
    
    # Step 3: Find and process students
    logger.info("="*60)
    logger.info("SCANNING FOR STUDENTS")
    logger.info("="*60)
    
    if not os.path.exists(UPLOADS_DIR):
        logger.error(f"Uploads directory not found: {UPLOADS_DIR}")
        return
    
    student_dirs = [d for d in os.listdir(UPLOADS_DIR) 
                   if os.path.isdir(os.path.join(UPLOADS_DIR, d))]
    
    logger.info(f"Found {len(student_dirs)} students: {student_dirs}\n")
    
    processed_count = 0
    for student_id in sorted(student_dirs):
        student_dir = os.path.join(UPLOADS_DIR, student_id)
        
        # Get all image files
        image_files = [f for f in os.listdir(student_dir) 
                      if f.lower().endswith(('.jpg', '.jpeg', '.png', '.bmp'))]
        
        if not image_files:
            logger.warning(f"No images found for {student_id}")
            continue
        
        image_paths = [os.path.join(student_dir, f) for f in sorted(image_files)]
        
        # Process student
        if process_student(pipeline, student_id, image_paths):
            processed_count += 1
        
        time.sleep(1)  # Brief pause between students
    
    logger.info(f"\n{'='*60}")
    logger.info(f"PROCESSING SUMMARY")
    logger.info(f"{'='*60}")
    logger.info(f"Successfully processed: {processed_count}/{len(student_dirs)} students\n")
    
    # Step 4: Train classifier
    if processed_count >= 2:
        if train_classifier(pipeline):
            logger.info("\n" + "="*60)
            logger.info("✓ ALL OPERATIONS COMPLETED SUCCESSFULLY")
            logger.info("="*60)
        else:
            logger.error("\n" + "="*60)
            logger.error("✗ CLASSIFIER TRAINING FAILED")
            logger.error("="*60)
    else:
        logger.warning(f"\nNeed at least 2 students to train classifier (processed: {processed_count})")

if __name__ == "__main__":
    main()
