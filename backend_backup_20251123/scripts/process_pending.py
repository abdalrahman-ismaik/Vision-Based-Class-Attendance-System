#!/usr/bin/env python3
"""
Process Pending Students Script
Run this to process all students with 'pending' status
This runs outside the Flask app so no threading issues
"""

import sys
import os
import json

# Add paths
sys.path.insert(0, '/home/mohamed/Code/Vision-Based-Class-Attendance-System/backend')
sys.path.insert(0, '/home/mohamed/Code/Vision-Based-Class-Attendance-System/FaceNet')

from face_processing_pipeline import FaceProcessingPipeline
from datetime import datetime

# Paths
DATABASE_FILE = '/home/mohamed/Code/Vision-Based-Class-Attendance-System/backend/database.json'
PROCESSED_FACES_DIR = '/home/mohamed/Code/Vision-Based-Class-Attendance-System/backend/processed_faces'
CHECKPOINT_PATH = '/home/mohamed/Code/Vision-Based-Class-Attendance-System/FaceNet/mobilefacenet_arcface/best_model_epoch43_acc100.00.pth'

def load_database():
    """Load database"""
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
    try:
        pipeline = FaceProcessingPipeline(checkpoint_path=CHECKPOINT_PATH, device='cpu')
        print("   ✓ Pipeline initialized")
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
        
        if not image_path or not os.path.exists(image_path):
            print(f"      ✗ Image not found: {image_path}")
            database[student_id]['processing_status'] = 'failed'
            database[student_id]['processing_error'] = 'Image file not found'
            save_database(database)
            continue
        
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
                database[student_id]['num_augmentations'] = result['num_augmentations']
                database[student_id]['embeddings_path'] = result['embeddings_path']
                save_database(database)
                
                print(f"      ✓ Success! Generated {result['num_augmentations']} augmentations")
                print(f"      Embeddings: {result['embeddings_shape']}")
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

if __name__ == "__main__":
    process_pending_students()
