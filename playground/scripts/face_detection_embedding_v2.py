"""
Face Detection and Embedding Generation Script
Uses FaceNet MobileFaceNet model with RetinaFace detector
SIMPLIFIED VERSION - No alignment, proper preprocessing
"""

import sys
import os
import torch
import numpy as np
from PIL import Image
from torchvision import transforms
import matplotlib.pyplot as plt

# Add FaceNet directory to path
sys.path.append('../FaceNet')

from networks.models_facenet import MobileFaceNet
from utils.utils import RetinaFacePyPIAdapter


# ============= CONFIGURATION =============
# These values are from FaceNet/generate_embeddings.py
FACENET_MEAN = [0.31928780674934387, 0.2873991131782532, 0.25779902935028076]
FACENET_STD = [0.19799138605594635, 0.20757903158664703, 0.21088403463363647]


def get_facenet_transform(crop_size=(112, 112), grayscale=False):
    """
    Get the exact preprocessing transform used in FaceNet training.
    This ensures embeddings are consistent.
    """
    tr_list = []
    if grayscale:
        tr_list.append(transforms.Grayscale(num_output_channels=3))
    
    tr_list.extend([
        transforms.Resize(crop_size),
        transforms.ToTensor(),
        transforms.Normalize(mean=FACENET_MEAN, std=FACENET_STD)
    ])
    
    return transforms.Compose(tr_list)


def load_facenet_model(checkpoint_path, device='cuda'):
    """
    Load pretrained MobileFaceNet model.
    
    Args:
        checkpoint_path: Path to .pth file
        device: 'cuda' or 'cpu'
    
    Returns:
        model: MobileFaceNet in eval mode
    """
    model = MobileFaceNet(embedding_size=512)
    
    # Load checkpoint
    checkpoint = torch.load(checkpoint_path, map_location=device)
    
    # Handle different checkpoint formats
    if 'model_state_dict' in checkpoint:
        model.load_state_dict(checkpoint['model_state_dict'])
    else:
        model.load_state_dict(checkpoint)
    
    model.to(device)
    model.eval()
    
    print(f"✓ Loaded FaceNet model from: {checkpoint_path}")
    return model


def detect_and_embed_faces(image_path, model, face_detector, transform, device='cuda', margin=0.2):
    """
    Detect faces and generate embeddings.
    
    Args:
        image_path: Path to image
        model: Loaded MobileFaceNet model
        face_detector: RetinaFace detector
        transform: torchvision transform
        device: 'cuda' or 'cpu'
        margin: Margin around detected face (0.2 = 20%)
    
    Returns:
        List of dicts with face info and embeddings
    """
    # Load image
    image = Image.open(image_path).convert('RGB')
    img_array = np.array(image)
    
    # Detect faces
    bboxes = face_detector.detect_faces(img_array)
    
    if len(bboxes) == 0:
        print("⚠️  No faces detected!")
        return []
    
    print(f"✓ Detected {len(bboxes)} face(s)")
    
    # Process each face
    face_data = []
    
    for i, bbox in enumerate(bboxes):
        x1, y1, x2, y2 = map(int, bbox)
        
        # Add margin
        w = x2 - x1
        h = y2 - y1
        margin_w = int(w * margin)
        margin_h = int(h * margin)
        
        x1_margin = max(0, x1 - margin_w)
        y1_margin = max(0, y1 - margin_h)
        x2_margin = min(image.width, x2 + margin_w)
        y2_margin = min(image.height, y2 + margin_h)
        
        # Crop face
        face_crop = image.crop((x1_margin, y1_margin, x2_margin, y2_margin))
        
        # Apply FaceNet preprocessing
        face_tensor = transform(face_crop).unsqueeze(0).to(device)
        
        # Generate embedding
        with torch.no_grad():
            embedding = model(face_tensor)
            # L2 normalize (important for cosine similarity!)
            embedding = embedding / torch.norm(embedding, p=2, dim=1, keepdim=True)
            embedding = embedding.cpu().numpy().flatten()
        
        face_data.append({
            'face_id': i + 1,
            'bbox': [x1, y1, x2, y2],
            'bbox_margin': [x1_margin, y1_margin, x2_margin, y2_margin],
            'image': np.array(face_crop),
            'embedding': embedding,
            'embedding_norm': np.linalg.norm(embedding)
        })
    
    return face_data


def compute_cosine_similarity(emb1, emb2):
    """
    Compute cosine similarity between two embeddings.
    Assumes embeddings are already L2-normalized.
    """
    return np.dot(emb1, emb2)


def compare_faces(face_embeddings, threshold=0.5):
    """
    Compare all pairs of faces and print similarity matrix.
    
    Args:
        face_embeddings: List of face data dicts from detect_and_embed_faces
        threshold: Similarity threshold for same person
    """
    n_faces = len(face_embeddings)
    
    if n_faces < 2:
        print("Need at least 2 faces to compare!")
        return
    
    print("\n" + "="*60)
    print("FACE SIMILARITY MATRIX")
    print("="*60)
    
    # Create similarity matrix
    sim_matrix = np.zeros((n_faces, n_faces))
    
    for i in range(n_faces):
        for j in range(n_faces):
            if i == j:
                sim_matrix[i, j] = 1.0
            else:
                sim = compute_cosine_similarity(
                    face_embeddings[i]['embedding'],
                    face_embeddings[j]['embedding']
                )
                sim_matrix[i, j] = sim
    
    # Print matrix
    print("\n     ", end="")
    for j in range(n_faces):
        print(f"Face{j+1:2d} ", end="")
    print()
    print("     " + "-" * (7 * n_faces))
    
    for i in range(n_faces):
        print(f"Face{i+1:2d} |", end="")
        for j in range(n_faces):
            sim = sim_matrix[i, j]
            print(f" {sim:5.3f} ", end="")
        print()
    
    # Print pairwise comparisons
    print("\n" + "="*60)
    print("PAIRWISE COMPARISONS")
    print("="*60)
    
    for i in range(n_faces):
        for j in range(i + 1, n_faces):
            sim = sim_matrix[i, j]
            verdict = "✓ SAME PERSON" if sim >= threshold else "✗ DIFFERENT"
            print(f"Face {i+1} vs Face {j+1}: {sim:.4f} → {verdict}")
    
    print("\n" + "="*60)
    print(f"Threshold: {threshold}")
    print("="*60 + "\n")
    
    return sim_matrix


def compare_two_images(image1_path, image2_path, model, face_detector, transform, device='cuda', threshold=0.5, margin=0.2, visualize=True):
    """
    Compare two images to see if they contain the same person.
    
    Args:
        image1_path: Path to first image
        image2_path: Path to second image
        model: Loaded MobileFaceNet model
        face_detector: RetinaFace detector
        transform: torchvision transform
        device: 'cuda' or 'cpu'
        threshold: Similarity threshold for same person (default: 0.5)
        margin: Margin around detected face
        visualize: Whether to show side-by-side comparison
    
    Returns:
        dict with comparison results
    """
    print("\n" + "="*70)
    print("COMPARING TWO IMAGES")
    print("="*70)
    print(f"Image 1: {os.path.basename(image1_path)}")
    print(f"Image 2: {os.path.basename(image2_path)}")
    print("="*70 + "\n")
    
    # Process both images
    faces1 = detect_and_embed_faces(image1_path, model, face_detector, transform, device, margin)
    faces2 = detect_and_embed_faces(image2_path, model, face_detector, transform, device, margin)
    
    if len(faces1) == 0 or len(faces2) == 0:
        print("❌ Could not detect faces in one or both images!")
        return None
    
    # Take the first (or largest) face from each image
    face1 = faces1[0]  # You could select by size if multiple faces
    face2 = faces2[0]
    
    # Compute similarity
    similarity = compute_cosine_similarity(face1['embedding'], face2['embedding'])
    
    # Determine verdict
    if similarity >= 0.6:
        verdict = "✓ SAME PERSON (High Confidence)"
        color = "green"
    elif similarity >= threshold:
        verdict = "? POSSIBLY SAME (Medium Confidence)"
        color = "orange"
    else:
        verdict = "✗ DIFFERENT PEOPLE (High Confidence)"
        color = "red"
    
    # Print results
    print("\n" + "="*70)
    print("COMPARISON RESULTS")
    print("="*70)
    print(f"Cosine Similarity: {similarity:.4f}")
    print(f"Threshold: {threshold:.4f}")
    print(f"Verdict: {verdict}")
    print("="*70 + "\n")
    
    # Visualize if requested
    if visualize:
        fig, axes = plt.subplots(1, 2, figsize=(12, 6))
        
        # Image 1
        axes[0].imshow(face1['image'])
        axes[0].axis('off')
        axes[0].set_title(f"Image 1\n{os.path.basename(image1_path)}", fontsize=12, weight='bold')
        
        # Image 2
        axes[1].imshow(face2['image'])
        axes[1].axis('off')
        axes[1].set_title(f"Image 2\n{os.path.basename(image2_path)}", fontsize=12, weight='bold')
        
        # Add similarity info at the top
        fig.suptitle(
            f"Similarity: {similarity:.4f} → {verdict}",
            fontsize=14,
            weight='bold',
            color=color
        )
        
        plt.tight_layout()
        plt.show()
    
    return {
        'similarity': similarity,
        'threshold': threshold,
        'verdict': verdict,
        'same_person': similarity >= threshold,
        'face1': face1,
        'face2': face2
    }


def visualize_faces(face_embeddings, image_path, output_dir="output"):
    """
    Visualize detected faces with bounding boxes and save individual crops.
    """
    os.makedirs(output_dir, exist_ok=True)
    
    # Original image with bboxes
    image = Image.open(image_path).convert('RGB')
    
    fig, ax = plt.subplots(1, 1, figsize=(12, 8))
    ax.imshow(image)
    ax.axis('off')
    
    for face_data in face_embeddings:
        x1, y1, x2, y2 = face_data['bbox']
        rect = plt.Rectangle(
            (x1, y1), x2 - x1, y2 - y1,
            fill=False, edgecolor='lime', linewidth=2
        )
        ax.add_patch(rect)
        ax.text(
            x1, y1 - 10,
            f"Face {face_data['face_id']}",
            color='lime', fontsize=12, weight='bold',
            bbox=dict(boxstyle='round,pad=0.3', facecolor='black', alpha=0.7)
        )
    
    base_name = os.path.splitext(os.path.basename(image_path))[0]
    detection_path = os.path.join(output_dir, f'{base_name}_detections.png')
    plt.savefig(detection_path, dpi=150, bbox_inches='tight')
    plt.close()
    print(f"✓ Saved detections: {detection_path}")
    
    # Save individual face crops
    for face_data in face_embeddings:
        face_id = face_data['face_id']
        face_img = face_data['image']
        
        plt.figure(figsize=(4, 4))
        plt.imshow(face_img)
        plt.axis('off')
        plt.title(f"Face {face_id}", fontsize=12, weight='bold')
        
        crop_path = os.path.join(output_dir, f'{base_name}_face_{face_id}.png')
        plt.savefig(crop_path, dpi=150, bbox_inches='tight')
        plt.close()
        print(f"✓ Saved face crop: {crop_path}")


def main():
    """
    Main function to run the face detection and embedding pipeline.
    """
    # Configuration
    CHECKPOINT_PATH = "../FaceNet/mobilefacenet_arcface/best_model_epoch43_acc100.00.pth"
    IMAGE_PATH = "test_image.jpg"  # Change this to your image
    DEVICE = 'cuda' if torch.cuda.is_available() else 'cpu'
    THRESHOLD = 0.5  # Similarity threshold for same person
    
    # For comparing two images
    IMAGE1_PATH = "./jf1.png"  # Change these to your images
    IMAGE2_PATH = "./p2.png"
    COMPARE_MODE = True  # Set to True to compare two images instead
    
    print("="*60)
    print("FACENET EMBEDDING EXTRACTION")
    print("="*60)
    print(f"Device: {DEVICE}")
    print(f"Checkpoint: {CHECKPOINT_PATH}")
    if COMPARE_MODE:
        print(f"Mode: Compare two images")
        print(f"Image 1: {IMAGE1_PATH}")
        print(f"Image 2: {IMAGE2_PATH}")
    else:
        print(f"Mode: Single image analysis")
        print(f"Image: {IMAGE_PATH}")
    print("="*60 + "\n")
    
    # Load model
    model = load_facenet_model(CHECKPOINT_PATH, device=DEVICE)
    
    # Create face detector
    face_detector = RetinaFacePyPIAdapter(threshold=0.9)
    
    # Get FaceNet preprocessing transform
    transform = get_facenet_transform(crop_size=(112, 112), grayscale=False)
    
    if COMPARE_MODE:
        # Compare two images mode
        result = compare_two_images(
            image1_path=IMAGE1_PATH,
            image2_path=IMAGE2_PATH,
            model=model,
            face_detector=face_detector,
            transform=transform,
            device=DEVICE,
            threshold=THRESHOLD,
            margin=0.2,
            visualize=True
        )
        
        if result:
            print(f"\n✓ Comparison complete!")
            print(f"   Same person: {result['same_person']}")
            print(f"   Similarity: {result['similarity']:.4f}")
    else:
        # Single image analysis mode
        # Detect and embed faces
        face_embeddings = detect_and_embed_faces(
            image_path=IMAGE_PATH,
            model=model,
            face_detector=face_detector,
            transform=transform,
            device=DEVICE,
            margin=0.2
        )
        
        if not face_embeddings:
            print("No faces detected. Exiting.")
            return
        
        # Print embedding info
        print("\n" + "="*60)
        print("EMBEDDING DIAGNOSTICS")
        print("="*60)
        for face_data in face_embeddings:
            print(f"Face {face_data['face_id']}:")
            print(f"  Embedding shape: {face_data['embedding'].shape}")
            print(f"  L2 norm: {face_data['embedding_norm']:.6f}")
            print(f"  Mean: {face_data['embedding'].mean():.6f}")
            print(f"  Std: {face_data['embedding'].std():.6f}")
        print("="*60 + "\n")
        
        # Compare faces if multiple detected
        if len(face_embeddings) >= 2:
            compare_faces(face_embeddings, threshold=THRESHOLD)
        
        # Visualize results
        visualize_faces(face_embeddings, IMAGE_PATH, output_dir="output")
    
    print("\n✓ Done!")


if __name__ == "__main__":
    main()
