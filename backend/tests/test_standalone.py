#!/usr/bin/env python3
"""
Standalone test script to debug face processing pipeline
Tests the pipeline directly without the Flask server
"""

import sys
import os

# Add paths
sys.path.insert(0, '/home/mohamed/Code/Vision-Based-Class-Attendance-System/backend')
sys.path.insert(0, '/home/mohamed/Code/Vision-Based-Class-Attendance-System/FaceNet')

print("=" * 70)
print("FACE PROCESSING PIPELINE - STANDALONE TEST")
print("=" * 70)

# Test imports
print("\n1. Testing imports...")
try:
    from face_processing_pipeline import FaceProcessingPipeline
    print("   ✓ face_processing_pipeline imported")
except Exception as e:
    print(f"   ✗ Failed to import face_processing_pipeline: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

# Test pipeline initialization
print("\n2. Initializing pipeline...")
try:
    checkpoint_path = "/home/mohamed/Code/Vision-Based-Class-Attendance-System/FaceNet/mobilefacenet_arcface/best_model_epoch43_acc100.00.pth"
    
    if not os.path.exists(checkpoint_path):
        print(f"   ✗ Checkpoint not found: {checkpoint_path}")
        sys.exit(1)
    
    print(f"   Checkpoint exists: {checkpoint_path}")
    
    pipeline = FaceProcessingPipeline(checkpoint_path=checkpoint_path, device='cpu')
    print("   ✓ Pipeline initialized successfully!")
    
except Exception as e:
    print(f"   ✗ Failed to initialize pipeline: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

# Test processing
print("\n3. Testing face processing...")
try:
    image_path = "./uploads/students/1000648000/1000648000_20251020_202731.jpeg"
    
    if not os.path.exists(image_path):
        print(f"   ✗ Image not found: {image_path}")
        sys.exit(1)
    
    print(f"   Processing: {image_path}")
    
    output_dir = "/home/mohamed/Code/Vision-Based-Class-Attendance-System/backend/processed_faces"
    os.makedirs(output_dir, exist_ok=True)
    
    result = pipeline.process_student_image(
        image_path=image_path,
        student_id="100064000",
        output_dir=output_dir,
        num_augmentations=20
    )
    
    if result:
        print("   ✓ Processing successful!")
        print(f"   Student ID: {result['student_id']}")
        print(f"   Augmentations: {result['num_augmentations']}")
        print(f"   Embeddings shape: {result['embeddings_shape']}")
        print(f"   Output dir: {result['output_dir']}")
        print(f"   Embeddings path: {result['embeddings_path']}")
    else:
        print("   ✗ Processing failed - no result returned")
        
except Exception as e:
    print(f"   ✗ Error during processing: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

print("\n" + "=" * 70)
print("TEST COMPLETED SUCCESSFULLY!")
print("=" * 70)
