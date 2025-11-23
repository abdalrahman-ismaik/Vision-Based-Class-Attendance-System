"""Test pipeline initialization"""
import sys
import os

# Add backend to path
backend_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, backend_dir)

try:
    print("Importing SimpleFaceProcessor...")
    from services.opencv_face_processor import SimpleFaceProcessor
    print("✓ Import successful")
    
    print("\nInitializing pipeline...")
    pipeline = SimpleFaceProcessor(device='cpu')
    print("✓ Pipeline initialized successfully!")
    
    print("\nChecking methods...")
    print(f"Has recognize_face: {hasattr(pipeline, 'recognize_face')}")
    print(f"Has process_student_images: {hasattr(pipeline, 'process_student_images')}")
    print(f"Has train_classifier_from_data: {hasattr(pipeline, 'train_classifier_from_data')}")
    
except Exception as e:
    print(f"\n✗ Error: {type(e).__name__}: {e}")
    import traceback
    traceback.print_exc()
