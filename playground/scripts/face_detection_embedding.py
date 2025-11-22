"""
Face Detection and Embedding Generation Script
Uses FaceNet MobileFaceNet model with RetinaFace detector
"""

import sys
import os
import cv2
import torch
import numpy as np
from PIL import Image
from torchvision import transforms
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle
from retinaface import RetinaFace

# Add FaceNet directory to path
sys.path.append('../FaceNet')

from networks.models_facenet import MobileFaceNet
from utils.utils import RetinaFacePyPIAdapter


SIMILARITY_THRESHOLDS = {
    'same': 0.62,
    'maybe': 0.50,
    'uncertain': 0.38,
}

ARC_FACE_TEMPLATE = np.array([
    [38.2946, 51.6963],
    [73.5318, 51.5014],
    [56.0252, 71.7366],
    [41.5493, 92.3655],
    [70.7299, 92.2041],
], dtype=np.float32)


def detect_faces_with_landmarks(image_bgr, face_detector):
    """Return list of detections with bbox, score, and optional landmarks."""
    detections = []
    raw = None
    try:
        if hasattr(face_detector, 'detector'):
            raw = face_detector.detector.detect_faces(image_bgr)
        else:
            raw = RetinaFace.detect_faces(image_bgr)
    except Exception as exc:
        print(f"⚠️  RetinaFace landmark detection failed ({exc}). Falling back to bounding boxes only.")

    threshold = getattr(face_detector, 'threshold', 0.5)

    if isinstance(raw, dict):
        for face_info in raw.values():
            score = face_info.get('score', 1.0)
            if score < threshold:
                continue
            bbox = face_info.get('facial_area')
            if not bbox:
                continue
            detections.append({
                'bbox': tuple(map(int, bbox)),
                'score': float(score),
                'landmarks': face_info.get('landmarks', {})
            })

    if not detections:
        simple_boxes = face_detector.detect_faces(image_bgr)
        for bbox in simple_boxes:
            detections.append({
                'bbox': bbox,
                'score': 1.0,
                'landmarks': {}
            })

    return detections


def crop_face_with_margin(image_bgr, bbox, margin=0.25):
    """Crop face with margin relative to bbox size."""
    h, w = image_bgr.shape[:2]
    x1, y1, x2, y2 = bbox
    width = x2 - x1
    height = y2 - y1
    if width <= 0 or height <= 0:
        return None

    margin_x = int(width * margin)
    margin_y = int(height * margin)

    x1 = max(0, x1 - margin_x)
    y1 = max(0, y1 - margin_y)
    x2 = min(w, x2 + margin_x)
    y2 = min(h, y2 + margin_y)

    return image_bgr[y1:y2, x1:x2]


def align_face_with_landmarks(image_bgr, landmarks, output_size=112):
    """Align face using five-point landmarks and ArcFace template."""
    if not landmarks:
        return None

    try:
        dst = np.array([
            [landmarks['left_eye'][0], landmarks['left_eye'][1]],
            [landmarks['right_eye'][0], landmarks['right_eye'][1]],
            [landmarks['nose'][0], landmarks['nose'][1]],
            [landmarks['mouth_left'][0], landmarks['mouth_left'][1]],
            [landmarks['mouth_right'][0], landmarks['mouth_right'][1]],
        ], dtype=np.float32)
    except KeyError:
        return None

    try:
        matrix, _ = cv2.estimateAffinePartial2D(dst, ARC_FACE_TEMPLATE, method=cv2.LMEDS)
        if matrix is None:
            return None
        aligned = cv2.warpAffine(
            image_bgr,
            matrix,
            (output_size, output_size),
            flags=cv2.INTER_LINEAR,
            borderMode=cv2.BORDER_CONSTANT,
            borderValue=0,
        )
        return aligned
    except cv2.error:
        return None


def load_model(checkpoint_path, device='cuda'):
    """Load the pre-trained FaceNet model"""
    print("Loading FaceNet model...")
    
    embedding_size = 512
    backbone = MobileFaceNet(embedding_size=embedding_size).to(device)
    
    # Load checkpoint
    checkpoint = torch.load(checkpoint_path, map_location=device)
    backbone.load_state_dict(checkpoint['model_state_dict'])
    backbone.eval()
    
    print(f"✓ Model loaded from: {checkpoint_path}")
    print(f"✓ Model trained for {checkpoint.get('epoch', 'unknown')} epochs")
    print(f"✓ Embedding dimension: {embedding_size}")
    
    return backbone


def get_preprocessing_transform():
    """Get the image preprocessing transform"""
    return transforms.Compose([
        transforms.Resize((112, 112)),
        transforms.ToTensor(),
        transforms.Normalize(
            mean=[0.31928780674934387, 0.2873991131782532, 0.25779902935028076],
            std=[0.19799138605594635, 0.20757903158664703, 0.21088403463363647]
        )
    ])


def detect_and_embed_faces(image_path, backbone, face_detector, preprocess, device='cuda', 
                           save_visualization=True, output_dir='./output'):
    """
    Detect faces in an image and generate embeddings for each face
    
    Args:
        image_path: Path to input image
        backbone: FaceNet model
        face_detector: Face detector object
        preprocess: Preprocessing transform
        device: 'cuda' or 'cpu'
        save_visualization: Whether to save visualization images
        output_dir: Directory to save outputs
    
    Returns:
        List of dictionaries containing face data and embeddings
    """
    
    if not os.path.exists(image_path):
        print(f"❌ Image not found at: {image_path}")
        return []
    
    # Create output directory
    if save_visualization:
        os.makedirs(output_dir, exist_ok=True)
    
    # Load image
    img_bgr = cv2.imread(image_path)
    img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
    
    print(f"\n✓ Image loaded: {image_path}")
    print(f"✓ Image size: {img_rgb.shape}")
    
    # Detect faces
    print("\n🔍 Detecting faces with landmarks...")
    detections = detect_faces_with_landmarks(img_bgr, face_detector)
    
    print(f"✓ Found {len(detections)} face(s)")
    
    if len(detections) == 0:
        print("⚠️  No faces detected in the image")
        return []
    
    # Store face data
    face_embeddings = []
    
    # Process each detected face
    for i, det in enumerate(detections):
        bbox = det['bbox']
        score = det.get('score', 1.0)
        landmarks = det.get('landmarks', {})
        x1, y1, x2, y2 = bbox

        # Margin crop for visualization / fallback
        face_crop_bgr = crop_face_with_margin(img_bgr, bbox, margin=0.25)
        if face_crop_bgr is None or face_crop_bgr.size == 0:
            print(f"⚠️  Skipping face {i+1}: empty crop")
            continue

        # Align face to canonical pose if landmarks available
        aligned_bgr = align_face_with_landmarks(img_bgr, landmarks, output_size=112)
        alignment_used = aligned_bgr is not None

        if not alignment_used:
            aligned_bgr = cv2.resize(face_crop_bgr, (112, 112), interpolation=cv2.INTER_AREA)

        aligned_rgb = cv2.cvtColor(aligned_bgr, cv2.COLOR_BGR2RGB)
        face_pil = Image.fromarray(aligned_rgb)
        face_tensor = preprocess(face_pil).unsqueeze(0).to(device)

        # Generate embedding
        with torch.no_grad():
            embedding = backbone(face_tensor)

        embedding = torch.nn.functional.normalize(embedding, p=2, dim=1)
        embedding_np = embedding.cpu().numpy().flatten()

        raw_crop_rgb = cv2.cvtColor(face_crop_bgr, cv2.COLOR_BGR2RGB)

        face_embeddings.append({
            'face_id': i + 1,
            'bbox': bbox,
            'score': score,
            'landmarks': landmarks,
            'embedding': embedding_np,
            'aligned_image': aligned_rgb,
            'raw_crop': raw_crop_rgb,
            'alignment_used': alignment_used
        })

        print(f"\n  Face {i+1}:")
        print(f"    - Detector score: {score:.3f}")
        print(f"    - Location: ({x1}, {y1}) to ({x2}, {y2})")
        print(f"    - Size: {x2 - x1}x{y2 - y1} pixels")
        print(f"    - Alignment: {'yes' if alignment_used else 'no (fallback resize)'}")
        print(f"    - Embedding shape: {embedding_np.shape}")
        print(f"    - Embedding sample: {embedding_np[:5]}")
    
    # Save visualizations
    if save_visualization and len(face_embeddings) > 0:
        save_face_visualizations(img_rgb, face_embeddings, image_path, output_dir)
    
    print(f"\n✅ Successfully generated embeddings for {len(face_embeddings)} face(s)")
    
    return face_embeddings


def save_face_visualizations(img_rgb, face_embeddings, original_image_path, output_dir):
    """Save visualization images showing detected faces"""
    
    base_name = os.path.splitext(os.path.basename(original_image_path))[0]
    
    # 1. Save image with bounding boxes
    fig, ax = plt.subplots(1, figsize=(10, 8))
    ax.imshow(img_rgb)
    
    for face_data in face_embeddings:
        x1, y1, x2, y2 = face_data['bbox']
        rect = Rectangle((x1, y1), x2-x1, y2-y1, 
                        linewidth=3, edgecolor='lime', facecolor='none')
        ax.add_patch(rect)
        ax.text(x1, y1-10, f"Face {face_data['face_id']}", 
               color='lime', fontsize=14, weight='bold',
               bbox=dict(boxstyle='round,pad=0.5', facecolor='black', alpha=0.8))
    
    ax.axis('off')
    ax.set_title(f'Detected {len(face_embeddings)} Face(s)', fontsize=16, weight='bold', pad=20)
    plt.tight_layout()
    
    output_path = os.path.join(output_dir, f'{base_name}_detected_faces.png')
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    print(f"\n✓ Saved detection visualization: {output_path}")
    
    # 2. Save individual face crops
    for face_data in face_embeddings:
        face_id = face_data['face_id']
        aligned_img = face_data.get('aligned_image')
        raw_crop = face_data.get('raw_crop')
        show_img = aligned_img if aligned_img is not None else raw_crop
        if show_img is None:
            print(f"! Skipping face {face_id}: no visualization image available")
            continue

        plt.figure(figsize=(4, 4))
        plt.imshow(show_img)
        plt.axis('off')
        title_suffix = 'aligned' if face_data.get('alignment_used') else 'fallback'
        plt.title(f"Face {face_id} ({title_suffix})", fontsize=12, weight='bold')

        crop_path = os.path.join(output_dir, f'{base_name}_face_{face_id}.png')
        plt.savefig(crop_path, dpi=150, bbox_inches='tight')
        plt.close()
        print(f"✓ Saved face crop: {crop_path}")
    
    # 3. Save embedding visualization for first face
    if len(face_embeddings) > 0:
        first_face_emb = face_embeddings[0]['embedding']
        plt.figure(figsize=(15, 2))
        plt.imshow(first_face_emb.reshape(1, -1), aspect='auto', cmap='viridis')
        plt.colorbar()
        plt.title('Face 1 Embedding Visualization (512 dimensions)', fontsize=12, weight='bold')
        plt.xlabel('Embedding Dimension')
        plt.yticks([])
        
        emb_path = os.path.join(output_dir, f'{base_name}_face_1_embedding_viz.png')
        plt.savefig(emb_path, dpi=150, bbox_inches='tight')
        plt.close()
        print(f"✓ Saved embedding visualization: {emb_path}")


def save_embeddings(face_embeddings, image_path, output_dir='./output'):
    """Save embeddings to .npy files"""
    
    if len(face_embeddings) == 0:
        print("No embeddings to save")
        return
    
    os.makedirs(output_dir, exist_ok=True)
    base_name = os.path.splitext(os.path.basename(image_path))[0]
    
    for face_data in face_embeddings:
        face_id = face_data['face_id']
        embedding = face_data['embedding']
        
        output_path = os.path.join(output_dir, f'{base_name}_face_{face_id}_embedding.npy')
        np.save(output_path, embedding)
        print(f"✓ Saved embedding: {output_path}")


def compare_faces(face_embeddings, output_dir='./output', save_visualization=True):
    """
    Compare similarity between detected faces using L2-normalized embeddings
    
    Similarity Thresholds (for L2-normalized embeddings):
    - > 0.50: Very likely the same person
    - 0.40-0.50: Possibly the same person
    - 0.30-0.40: Uncertain
    - < 0.30: Different people
    """
    
    if len(face_embeddings) < 2:
        print(f"\nOnly {len(face_embeddings)} face(s) detected. Need at least 2 faces to compare.")
        return None
    
    from sklearn.metrics.pairwise import cosine_similarity
    
    print("\n" + "="*50)
    print("Face Similarity Matrix")
    print("(Embeddings are L2-normalized)")
    print("="*50)
    
    # Create similarity matrix
    embeddings_matrix = np.array([f['embedding'] for f in face_embeddings])
    similarity_matrix = cosine_similarity(embeddings_matrix)
    
    # Display matrix with proper thresholds
    print("\nPairwise Similarities:")
    print("Thresholds: >0.50=SAME, 0.40-0.50=MAYBE, <0.30=DIFFERENT")
    print("-" * 50)
    
    for i in range(len(face_embeddings)):
        for j in range(len(face_embeddings)):
            if i < j:  # Only show upper triangle
                sim = similarity_matrix[i][j]
                if sim > 0.50:
                    status = "✓ SAME PERSON"
                    color = "🟢"
                elif sim > 0.40:
                    status = "❓ MAYBE SAME"
                    color = "🟡"
                elif sim > 0.30:
                    status = "❓ UNCERTAIN"
                    color = "🟠"
                else:
                    status = "✗ DIFFERENT"
                    color = "🔴"
                print(f"  {color} Face {i+1} ↔ Face {j+1}: {sim:.4f}  [{status}]")
    
    # Find most similar and most different pairs
    max_sim = -1
    min_sim = 2
    max_pair = (0, 0)
    min_pair = (0, 0)
    
    for i in range(len(face_embeddings)):
        for j in range(i+1, len(face_embeddings)):
            sim = similarity_matrix[i][j]
            if sim > max_sim:
                max_sim = sim
                max_pair = (i+1, j+1)
            if sim < min_sim:
                min_sim = sim
                min_pair = (i+1, j+1)
    
    print(f"\n📊 Summary:")
    print(f"  Most similar pair: Face {max_pair[0]} ↔ Face {max_pair[1]} ({max_sim:.4f})")
    print(f"  Most different pair: Face {min_pair[0]} ↔ Face {min_pair[1]} ({min_sim:.4f})")
    
    # Add embedding statistics
    print(f"\n📐 Embedding Statistics:")
    for i, face in enumerate(face_embeddings):
        emb = face['embedding']
        print(f"  Face {i+1}:")
        print(f"    - L2 Norm: {np.linalg.norm(emb):.6f} (should be ~1.0)")
        print(f"    - Mean: {emb.mean():.6f}")
        print(f"    - Std: {emb.std():.6f}")
    
    # Save visualization
    if save_visualization:
        save_similarity_matrix(similarity_matrix, face_embeddings, output_dir)
    
    return similarity_matrix


def diagnose_embeddings(face_embeddings):
    """
    Diagnose potential issues with embeddings
    """
    print("\n" + "="*60)
    print("🔍 Embedding Diagnostics")
    print("="*60)
    
    for i, face in enumerate(face_embeddings):
        emb = face['embedding']
        
        print(f"\nFace {i+1}:")
        print(f"  Shape: {emb.shape}")
        print(f"  L2 Norm: {np.linalg.norm(emb):.6f} {'✓' if abs(np.linalg.norm(emb) - 1.0) < 0.01 else '⚠️ Should be ~1.0'}")
        print(f"  Mean: {emb.mean():.6f}")
        print(f"  Std: {emb.std():.6f}")
        print(f"  Min: {emb.min():.6f}")
        print(f"  Max: {emb.max():.6f}")
        print(f"  Non-zero values: {np.count_nonzero(emb)}/{len(emb)}")
        print(f"  Sample values: {emb[:5]}")
    
    # Check if embeddings are too similar (potential issue)
    if len(face_embeddings) >= 2:
        from sklearn.metrics.pairwise import cosine_similarity
        embeddings_matrix = np.array([f['embedding'] for f in face_embeddings])
        avg_similarity = cosine_similarity(embeddings_matrix).mean()
        print(f"\n⚠️  Average similarity: {avg_similarity:.4f}")
        if avg_similarity > 0.8:
            print("  WARNING: Embeddings are suspiciously similar!")
            print("  This might indicate:")
            print("    - Model is not properly loaded")
            print("    - Wrong preprocessing normalization")
            print("    - Faces are too small/low quality")


def save_similarity_matrix(similarity_matrix, face_embeddings, output_dir):
    """Save a visual similarity matrix heatmap"""
    
    os.makedirs(output_dir, exist_ok=True)
    
    fig, ax = plt.subplots(figsize=(10, 8))
    im = ax.imshow(similarity_matrix, cmap='RdYlGn', vmin=0, vmax=1)
    
    # Set ticks and labels
    face_labels = [f"Face {i+1}" for i in range(len(face_embeddings))]
    ax.set_xticks(range(len(face_embeddings)))
    ax.set_yticks(range(len(face_embeddings)))
    ax.set_xticklabels(face_labels)
    ax.set_yticklabels(face_labels)
    
    # Rotate x labels
    plt.setp(ax.get_xticklabels(), rotation=45, ha="right", rotation_mode="anchor")
    
    # Add text annotations
    for i in range(len(face_embeddings)):
        for j in range(len(face_embeddings)):
            text = ax.text(j, i, f'{similarity_matrix[i][j]:.3f}',
                          ha="center", va="center", color="black", 
                          fontsize=11, weight='bold')
    
    # Add colorbar
    cbar = plt.colorbar(im, ax=ax)
    cbar.set_label('Cosine Similarity', rotation=270, labelpad=20, fontsize=12)
    
    ax.set_title('Face Similarity Matrix\n(Higher values = More similar)', 
                fontsize=14, weight='bold', pad=20)
    
    plt.tight_layout()
    output_path = os.path.join(output_dir, 'similarity_matrix.png')
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"\n✓ Saved similarity matrix: {output_path}")


def compare_two_images(image_path1, image_path2, backbone, face_detector, preprocess, 
                       device='cuda', output_dir='./output'):
    """
    Compare faces from two different images
    
    Args:
        image_path1: Path to first image
        image_path2: Path to second image
        backbone: FaceNet model
        face_detector: Face detector object
        preprocess: Preprocessing transform
        device: 'cuda' or 'cpu'
        output_dir: Directory to save outputs
    
    Returns:
        Dictionary with comparison results
    """
    
    print("\n" + "="*60)
    print("Comparing faces from two images")
    print("="*60)
    
    # Process first image
    print(f"\n📷 Processing Image 1: {image_path1}")
    faces1 = detect_and_embed_faces(
        image_path=image_path1,
        backbone=backbone,
        face_detector=face_detector,
        preprocess=preprocess,
        device=device,
        save_visualization=True,
        output_dir=output_dir
    )
    
    # Process second image
    print(f"\n📷 Processing Image 2: {image_path2}")
    faces2 = detect_and_embed_faces(
        image_path=image_path2,
        backbone=backbone,
        face_detector=face_detector,
        preprocess=preprocess,
        device=device,
        save_visualization=True,
        output_dir=output_dir
    )
    
    if len(faces1) == 0 or len(faces2) == 0:
        print("\n⚠️  Cannot compare: No faces detected in one or both images")
        return None
    
    # Compare all faces between images
    from sklearn.metrics.pairwise import cosine_similarity
    
    print("\n" + "="*60)
    print("Cross-Image Face Comparison")
    print("="*60)
    
    results = []
    
    for face1 in faces1:
        emb1 = face1['embedding'].reshape(1, -1)
        
        for face2 in faces2:
            emb2 = face2['embedding'].reshape(1, -1)
            
            similarity = cosine_similarity(emb1, emb2)[0][0]
            
            # Updated thresholds for L2-normalized embeddings
            if similarity > 0.6:
                status = "✓ SAME PERSON"
                confidence = "High"
            elif similarity > 0.50:
                status = "❓ POSSIBLY SAME"
                confidence = "Medium"
            elif similarity > 0.4:
                status = "❓ UNCERTAIN"
                confidence = "Low"
            else:
                status = "✗ DIFFERENT PERSON"
                confidence = "High"
            
            result = {
                'image1': os.path.basename(image_path1),
                'face1_id': face1['face_id'],
                'image2': os.path.basename(image_path2),
                'face2_id': face2['face_id'],
                'similarity': similarity,
                'status': status,
                'confidence': confidence
            }
            results.append(result)
            
            print(f"\nImage1 Face {face1['face_id']} ↔ Image2 Face {face2['face_id']}:")
            print(f"  Similarity: {similarity:.4f}")
            print(f"  Status: {status}")
            print(f"  Confidence: {confidence}")
    
    # Find best match
    if results:
        best_match = max(results, key=lambda x: x['similarity'])
        print(f"\n🎯 Best Match:")
        print(f"  {best_match['image1']} Face {best_match['face1_id']} ↔ "
              f"{best_match['image2']} Face {best_match['face2_id']}")
        print(f"  Similarity: {best_match['similarity']:.4f}")
        print(f"  {best_match['status']}")
    
    return results


def main():
    """Main function"""
    
    # ============ CONFIGURATION ============
    # Mode: 'single' or 'compare'
    MODE = 'compare'  # Change to 'compare' to compare two images
    
    # Single image mode
    IMAGE_PATH = "./image.png"  # Change this to your image path
    
    # Compare mode - set these if MODE = 'compare'
    IMAGE_PATH_1 = "./p2.png"
    IMAGE_PATH_2 = "./jf2.png"
    
    # Model and output settings
    CHECKPOINT_PATH = '../FaceNet/mobilefacenet_arcface/best_model_epoch43_acc100.00.pth'
    OUTPUT_DIR = './face_detection_output'
    DEVICE = 'cuda' if torch.cuda.is_available() else 'cpu'
    FACE_DETECTION_THRESHOLD = 0.5
    # ======================================
    
    print("="*60)
    print("Face Detection and Embedding Generation")
    print("="*60)
    print(f"Mode: {MODE.upper()}")
    print(f"Device: {DEVICE}")
    print(f"Output directory: {OUTPUT_DIR}")
    print("="*60)
    
    # Initialize face detector
    print("\nInitializing face detector...")
    face_detector = RetinaFacePyPIAdapter(threshold=FACE_DETECTION_THRESHOLD)
    print("✓ Face detector initialized")
    
    # Load model
    backbone = load_model(CHECKPOINT_PATH, DEVICE)
    
    # Get preprocessing transform
    preprocess = get_preprocessing_transform()
    print("✓ Preprocessing pipeline ready")
    
    # Process based on mode
    if MODE == 'compare':
        # Compare two images
        compare_two_images(
            image_path1=IMAGE_PATH_1,
            image_path2=IMAGE_PATH_2,
            backbone=backbone,
            face_detector=face_detector,
            preprocess=preprocess,
            device=DEVICE,
            output_dir=OUTPUT_DIR
        )
    else:
        # Single image mode
        print(f"\n📷 Processing Image: {IMAGE_PATH}")
        
        # Detect faces and generate embeddings
        face_embeddings = detect_and_embed_faces(
            image_path=IMAGE_PATH,
            backbone=backbone,
            face_detector=face_detector,
            preprocess=preprocess,
            device=DEVICE,
            save_visualization=True,
            output_dir=OUTPUT_DIR
        )
        
        # Save embeddings to files
        if len(face_embeddings) > 0:
            print("\n" + "="*60)
            print("Saving embeddings...")
            save_embeddings(face_embeddings, IMAGE_PATH, OUTPUT_DIR)
            
            # Run diagnostics
            diagnose_embeddings(face_embeddings)
            
            # Compare faces if multiple detected
            compare_faces(face_embeddings, OUTPUT_DIR, save_visualization=True)
    
    print("\n" + "="*60)
    print("✅ Processing complete!")
    print(f"Check output directory: {OUTPUT_DIR}")
    print("="*60)


if __name__ == "__main__":
    main()
