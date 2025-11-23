"""Quick test of RetinaFace face detection"""
import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

from retinaface import RetinaFace
import cv2

# Test with a famous person image
test_image = 'playground/famous-people/lionel-messi (1).jpg'

print(f"Testing RetinaFace with: {test_image}")
print("-" * 60)

# Load image
img = cv2.imread(test_image)
if img is None:
    print(f"❌ Failed to load image: {test_image}")
    exit(1)

print(f"✓ Image loaded successfully")
print(f"  Shape: {img.shape}")
print(f"  Size: {img.shape[1]}x{img.shape[0]}")

# Detect faces
print("\nDetecting faces...")
try:
    faces = RetinaFace.detect_faces(img)
    
    if faces is None or len(faces) == 0:
        print("❌ No faces detected!")
    else:
        print(f"✓ Detected {len(faces)} face(s)")
        for face_id, face_info in faces.items():
            print(f"\n  Face {face_id}:")
            print(f"    Confidence: {face_info.get('score', 'N/A')}")
            print(f"    Bbox: {face_info.get('facial_area', 'N/A')}")
            
except Exception as e:
    print(f"❌ Error during detection: {e}")
    import traceback
    traceback.print_exc()
