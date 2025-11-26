"""
Test script to verify face_processing_pipeline imports correctly
"""
import sys
import os

# Add backend directory to path
backend_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
sys.path.insert(0, backend_dir)

print("=" * 60)
print("TESTING FACE PROCESSING PIPELINE IMPORT")
print("=" * 60)

try:
    print("\n1. Testing direct import from services.face_processing_pipeline...")
    from services.face_processing_pipeline import FaceProcessingPipeline
    print("   ✓ Direct import successful")
except Exception as e:
    print(f"   ✗ Direct import failed: {e}")
    sys.exit(1)

try:
    print("\n2. Testing import from services module...")
    from services import FaceProcessingPipeline as FPP
    print("   ✓ Module import successful")
except Exception as e:
    print(f"   ✗ Module import failed: {e}")
    sys.exit(1)

try:
    print("\n3. Checking class methods...")
    methods = ['process_student_images', 'train_classifier_from_data', 'recognize_face']
    for method in methods:
        if hasattr(FaceProcessingPipeline, method):
            print(f"   ✓ Method '{method}' exists")
        else:
            print(f"   ✗ Method '{method}' missing")
except Exception as e:
    print(f"   ✗ Method check failed: {e}")

try:
    print("\n4. Testing pipeline initialization...")
    pipeline = FaceProcessingPipeline(device='cpu')
    print("   ✓ Pipeline initialized successfully")
    
    print("\n5. Checking pipeline components...")
    if hasattr(pipeline, 'face_detector'):
        print("   ✓ face_detector component exists")
    if hasattr(pipeline, 'embedding_generator'):
        print("   ✓ embedding_generator component exists")
    if hasattr(pipeline, 'classifier'):
        print("   ✓ classifier component exists")
    
except Exception as e:
    print(f"   ✗ Initialization failed: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

print("\n" + "=" * 60)
print("✓ ALL TESTS PASSED - FaceProcessingPipeline is working!")
print("=" * 60)
