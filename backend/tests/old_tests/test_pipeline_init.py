"""Test pipeline initialization to see actual error."""
import sys
import os

# Add backend to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

try:
    print("Importing FaceProcessingPipeline...")
    from services.face_processing_pipeline import FaceProcessingPipeline
    print("✓ Import successful")
    
    print("\nInitializing pipeline...")
    pipeline = FaceProcessingPipeline(device='cpu')
    print("✓ Pipeline initialized successfully!")
    
except Exception as e:
    print(f"\n✗ Error: {type(e).__name__}: {e}")
    import traceback
    traceback.print_exc()
