"""Quick test to verify face detection is working"""

import cv2
import os
from pathlib import Path

# Test with one of the uploaded images
test_folders = Path('uploads/students').glob('FPALBERT*')
test_folder = next(test_folders, None)

if test_folder:
    images = list(test_folder.glob('*.jpg'))
    if images:
        test_image = str(images[0])
        print(f"Testing with: {test_image}")
        
        # Load image
        img = cv2.imread(test_image)
        if img is not None:
            print(f"Image loaded: {img.shape}")
            
            # Try RetinaFace
            try:
                from retinaface import RetinaFace
                print("\nTesting RetinaFace...")
                faces = RetinaFace.detect_faces(img)
                print(f"RetinaFace detected: {len(faces) if faces else 0} faces")
                print(f"Result: {faces}")
            except Exception as e:
                print(f"RetinaFace error: {e}")
                import traceback
                traceback.print_exc()
        else:
            print("Failed to load image")
    else:
        print("No images found in folder")
else:
    print("No test folder found")
