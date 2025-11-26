"""
Test script to compare embeddings between training data and live recognition
"""

import sys
import os
import numpy as np
from PIL import Image

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.face_processing_pipeline import FaceProcessingPipeline
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def main():
    """Compare embeddings"""
    
    # Initialize pipeline
    logger.info("Initializing pipeline...")
    pipeline = FaceProcessingPipeline()
    
    # Load a stored embedding for student 100098104
    processed_dir = r"C:\Users\4bais\Vision-Based-Class-Attendance-System\backend\storage\processed\100098104"
    embeddings_path = os.path.join(processed_dir, "embeddings.npy")
    
    if not os.path.exists(embeddings_path):
        logger.error(f"Embeddings file not found: {embeddings_path}")
        return
    
    # Load stored embeddings
    stored_embeddings = np.load(embeddings_path)
    logger.info(f"Loaded {len(stored_embeddings)} stored embeddings")
    logger.info(f"  Shape: {stored_embeddings.shape}")
    logger.info(f"  Mean embedding stats: min={stored_embeddings.mean(axis=0).min():.4f}, max={stored_embeddings.mean(axis=0).max():.4f}, mean={stored_embeddings.mean():.4f}")
    
    # Load the debug image from live recognition
    debug_image_path = r"C:\Users\4bais\Vision-Based-Class-Attendance-System\HADIR_web\debug_faces\face_0_1764139497250.jpg"
    
    if not os.path.exists(debug_image_path):
        logger.error(f"Debug image not found: {debug_image_path}")
        # List available debug images
        debug_dir = os.path.dirname(debug_image_path)
        if os.path.exists(debug_dir):
            files = os.listdir(debug_dir)
            logger.info(f"Available debug images: {files}")
            if files:
                debug_image_path = os.path.join(debug_dir, files[-1])  # Use latest
                logger.info(f"Using: {debug_image_path}")
            else:
                return
        else:
            return
    
    # Process the debug image through the full pipeline
    logger.info(f"\nProcessing debug image: {debug_image_path}")
    result = pipeline.recognize_face(debug_image_path, threshold=0.0)  # Set threshold to 0 to always get result
    
    if 'error' in result:
        logger.error(f"Error processing debug image: {result['error']}")
        return
    
    # Get the embedding that was just generated
    image = Image.open(debug_image_path)
    image = image.convert('RGB')
    
    # Detect and crop face
    bboxes = pipeline.face_detector.detect_faces(image)
    if len(bboxes) > 0:
        bbox = bboxes[0]
        x1, y1, x2, y2 = map(int, bbox)
        
        # Add margin (same as in recognize_face)
        w = x2 - x1
        h = y2 - y1
        margin = 0.2
        x1 = max(0, x1 - int(w * margin))
        y1 = max(0, y1 - int(h * margin))
        x2 = min(image.width, x2 + int(w * margin))
        y2 = min(image.height, y2 + int(h * margin))
        
        face_image = image.crop((x1, y1, x2, y2))
        live_embedding = pipeline.embedding_generator.generate_embedding(face_image)
        
        logger.info(f"\nLive embedding stats:")
        logger.info(f"  Shape: {live_embedding.shape}")
        logger.info(f"  Min: {live_embedding.min():.4f}, Max: {live_embedding.max():.4f}, Mean: {live_embedding.mean():.4f}")
        logger.info(f"  Norm: {np.linalg.norm(live_embedding):.4f}")
        
        # Compare with stored embeddings
        logger.info(f"\nComparing with stored embeddings:")
        
        # Calculate cosine similarities
        similarities = []
        for i, stored_emb in enumerate(stored_embeddings):
            # Cosine similarity
            similarity = np.dot(live_embedding, stored_emb) / (np.linalg.norm(live_embedding) * np.linalg.norm(stored_emb))
            similarities.append(similarity)
        
        similarities = np.array(similarities)
        logger.info(f"  Cosine similarities:")
        logger.info(f"    Min: {similarities.min():.4f}")
        logger.info(f"    Max: {similarities.max():.4f}")
        logger.info(f"    Mean: {similarities.mean():.4f}")
        logger.info(f"    Median: {np.median(similarities):.4f}")
        logger.info(f"    Top 5: {sorted(similarities, reverse=True)[:5]}")
        
        # Compare norms
        stored_norms = np.linalg.norm(stored_embeddings, axis=1)
        logger.info(f"\nStored embedding norms:")
        logger.info(f"  Min: {stored_norms.min():.4f}, Max: {stored_norms.max():.4f}, Mean: {stored_norms.mean():.4f}")
        
        # Check if embeddings are normalized
        logger.info(f"\nAre embeddings L2-normalized?")
        logger.info(f"  Live: {'Yes' if abs(np.linalg.norm(live_embedding) - 1.0) < 0.01 else 'No'}")
        logger.info(f"  Stored (mean): {'Yes' if abs(stored_norms.mean() - 1.0) < 0.01 else 'No'}")

if __name__ == "__main__":
    main()
