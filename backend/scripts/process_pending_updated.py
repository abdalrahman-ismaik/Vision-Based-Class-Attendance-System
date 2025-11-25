#!/usr/bin/env python3
"""
Process Pending Students - Updated for Windows
Run this to process all students with 'pending' status
"""

import sys
import os
import json
from datetime import datetime

# Get absolute paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
FACENET_DIR = os.path.join(PROJECT_ROOT, 'FaceNet')

# Add to path
sys.path.insert(0, SCRIPT_DIR)
sys.path.insert(0, FACENET_DIR)
sys.path.insert(0, os.path.join(PROJECT_ROOT, 'services'))

from face_processing_pipeline import FaceProcessingPipeline

# Paths
STORAGE_DIR = os.path.join(PROJECT_ROOT, 'storage')
DATABASE_FILE = os.path.join(STORAGE_DIR, 'data', 'database.json')
PROCESSED_FACES_DIR = os.path.join(STORAGE_DIR, 'processed')
CHECKPOINT_PATH = os.path.join(STORAGE_DIR, 'models', 'mobilefacenet.pth')

def load_database():
    """Load database"""
    if not os.path.exists(DATABASE_FILE):
        return {}
    with open(DATABASE_FILE, 'r') as f:
        return json.load(f)

def save_database(data):
    """Save database"""
    with open(DATABASE_FILE, 'w') as f:
        json.dump(data, f, indent=2)

def process_pending_students():
    """Process all students with pending status"""
    print("=" * 70)
    print("PROCESSING PENDING STUDENTS")
    print("=" * 70)
    
    # Load database
    print("\n1. Loading database...")
    database = load_database()
    print(f"   Found {len(database)} students in database")
    
    # Find pending students
    pending = [sid for sid, data in database.items() 
               if data.get('processing_status') == 'pending']
    
    if not pending:
        print("   No pending students found!")
        return
    
    print(f"   Found {len(pending)} pending students: {pending}")
    
    # Initialize pipeline
    print("\n2. Initializing pipeline...")
    print(f"   Checkpoint: {CHECKPOINT_PATH}")
    print(f"   Checkpoint exists: {os.path.exists(CHECKPOINT_PATH)}")
    
    try:
        pipeline = FaceProcessingPipeline(
            checkpoint_path=CHECKPOINT_PATH, 
            device='cpu'
        )
        print("   ✓ Pipeline initialized successfully")
    except Exception as e:
        print(f"   ✗ Failed to initialize pipeline: {e}")
        import traceback
        traceback.print_exc()
        return
    
    # Process each student
    print(f"\n3. Processing {len(pending)} students...")
    for i, student_id in enumerate(pending, 1):
        print(f"\n   [{i}/{len(pending)}] Processing {student_id}...")
        
        student = database[student_id]
        image_path = student.get('image_path')
        
        # Convert to absolute path if relative
        if image_path and not os.path.isabs(image_path):
            image_path = os.path.join(SCRIPT_DIR, image_path)
        
        if not image_path or not os.path.exists(image_path):
            print(f"      ✗ Image not found: {image_path}")
            database[student_id]['processing_status'] = 'failed'
            database[student_id]['processing_error'] = 'Image file not found'
            save_database(database)
            continue
        
        print(f"      Image: {image_path}")
        
        try:
            # Process
            result = pipeline.process_student_image(
                image_path=image_path,
                student_id=student_id,
                output_dir=PROCESSED_FACES_DIR,
                num_augmentations=20
            )
            
            if result:
                # Update database
                database[student_id]['processing_status'] = 'completed'
                database[student_id]['processed_at'] = datetime.now().isoformat()
                database[student_id]['num_augmentations'] = result.get('num_augmentations', 0)
                database[student_id]['embeddings_path'] = result.get('embeddings_path', '')
                database[student_id]['face_count'] = result.get('num_augmentations', 0)
                save_database(database)
                
                print(f"      ✓ Success! Generated {result.get('num_augmentations', 0)} augmentations")
                print(f"      Embeddings: {result.get('embeddings_shape', 'N/A')}")
            else:
                database[student_id]['processing_status'] = 'failed'
                database[student_id]['processing_error'] = 'No face detected'
                save_database(database)
                
                print(f"      ✗ Failed: No face detected")
                
        except Exception as e:
            print(f"      ✗ Error: {e}")
            import traceback
            traceback.print_exc()
            
            database[student_id]['processing_status'] = 'failed'
            database[student_id]['processing_error'] = str(e)
            save_database(database)
    
    print("\n" + "=" * 70)
    print("PROCESSING COMPLETE")
    print("=" * 70)
    
    # Summary
    database = load_database()
    completed = sum(1 for d in database.values() if d.get('processing_status') == 'completed')
    failed = sum(1 for d in database.values() if d.get('processing_status') == 'failed')
    pending = sum(1 for d in database.values() if d.get('processing_status') == 'pending')
    
    print(f"\nSummary:")
    print(f"  Completed: {completed}")
    print(f"  Failed: {failed}")
    print(f"  Pending: {pending}")
    
    if completed > 0:
        print(f"\n✓ Successfully processed {completed} student(s)")
        print(f"  Embeddings saved to: {PROCESSED_FACES_DIR}")

if __name__ == "__main__":
    process_pending_students()
