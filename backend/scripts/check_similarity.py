"""
Quick script to check cosine similarity between live embedding and stored embeddings
"""
import numpy as np
import sys
import os
from PIL import Image

sys.path.insert(0, r"C:\Users\4bais\Vision-Based-Class-Attendance-System\backend")
from services.face_processing_pipeline import FaceProcessingPipeline

# Load pipeline
pipeline = FaceProcessingPipeline()

# Load stored embeddings for 100098104
stored_emb = np.load(r"C:\Users\4bais\Vision-Based-Class-Attendance-System\backend\storage\processed\100098104\embeddings.npy")

# Load and process the debug image
debug_img_path = r"C:\Users\4bais\Vision-Based-Class-Attendance-System\HADIR_web\debug_faces\face_0_1764139497250.jpg"

# Process it the same way as recognize_face does
image = Image.open(debug_img_path).convert('RGB')
bboxes = pipeline.face_detector.detect_faces(image)

if len(bboxes) > 0:
    bbox = bboxes[0]
    x1, y1, x2, y2 = map(int, bbox)
    
    # Add margin
    w = x2 - x1
    h = y2 - y1
    margin = 0.2
    x1 = max(0, x1 - int(w * margin))
    y1 = max(0, y1 - int(h * margin))
    x2 = min(image.width, x2 + int(w * margin))
    y2 = min(image.height, y2 + int(h * margin))
    
    face_image = image.crop((x1, y1, x2, y2))
    live_emb = pipeline.embedding_generator.generate_embedding(face_image)
    
    print(f"Live embedding norm: {np.linalg.norm(live_emb):.6f}")
    print(f"Stored embedding norms: min={np.linalg.norm(stored_emb, axis=1).min():.6f}, max={np.linalg.norm(stored_emb, axis=1).max():.6f}")
    
    # Calculate cosine similarities
    similarities = np.dot(stored_emb, live_emb)  # Since both are L2-normalized, dot product = cosine similarity
    
    print(f"\nCosine similarities with stored embeddings:")
    print(f"  Min: {similarities.min():.6f}")
    print(f"  Max: {similarities.max():.6f}")
    print(f"  Mean: {similarities.mean():.6f}")
    print(f"  Median: {np.median(similarities):.6f}")
    print(f"  Top 10: {sorted(similarities, reverse=True)[:10]}")
    
    print(f"\nFor comparison, typical thresholds:")
    print(f"  >0.6: Very good match")
    print(f"  >0.5: Good match")
    print(f"  >0.4: Possible match")
    print(f"  <0.4: Probably not a match")

