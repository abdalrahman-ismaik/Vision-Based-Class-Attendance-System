"""
Test script for FaceNet facial recognition system functionality.
This script demonstrates:
- Model loading (MobileFaceNet backbone with ArcFace/CosFace head)
- Face detection using RetinaFace
- Embedding extraction
- Face recognition
"""

import os
import sys
import torch
import numpy as np
from PIL import Image
import matplotlib.pyplot as plt
import cv2

# Add FaceNet directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'FaceNet'))

from networks.models_facenet import MobileFaceNet, Arcface, CosFace
from utils.utils import RetinaFacePyPIAdapter

def test_model_loading():
    """Test loading MobileFaceNet backbone and classifier heads."""
    print("\n" + "="*60)
    print("TEST 1: Model Loading")
    print("="*60)
    
    embedding_size = 512
    num_classes = 10  # Example number of classes
    
    # Test MobileFaceNet backbone
    print("\n1. Loading MobileFaceNet backbone...")
    backbone = MobileFaceNet(embedding_size=embedding_size)
    
    # Count parameters
    total_params = sum(p.numel() for p in backbone.parameters())
    trainable_params = sum(p.numel() for p in backbone.parameters() if p.requires_grad)
    
    print(f"   ✓ Backbone loaded successfully")
    print(f"   - Total parameters: {total_params:,}")
    print(f"   - Trainable parameters: {trainable_params:,}")
    
    # Test with dummy input
    dummy_input = torch.randn(2, 3, 112, 112)
    embeddings = backbone(dummy_input)
    print(f"   - Input shape: {dummy_input.shape}")
    print(f"   - Output embedding shape: {embeddings.shape}")
    print(f"   - Embedding dimension: {embeddings.shape[1]}")
    
    # Test ArcFace head
    print("\n2. Loading ArcFace classifier head...")
    arcface_head = Arcface(embedding_size=embedding_size, classnum=num_classes, s=32.0, m=0.4)
    print(f"   ✓ ArcFace head loaded successfully")
    print(f"   - Number of classes: {num_classes}")
    print(f"   - Scale (s): 32.0, Margin (m): 0.4")
    
    # Test forward pass
    labels = torch.tensor([1, 5])
    output = arcface_head(embeddings, labels)
    print(f"   - Output shape: {output.shape}")
    
    # Test CosFace head
    print("\n3. Loading CosFace classifier head...")
    cosface_head = CosFace(embedding_size=embedding_size, classnum=num_classes, s=30.0, m=0.4)
    print(f"   ✓ CosFace head loaded successfully")
    print(f"   - Number of classes: {num_classes}")
    print(f"   - Scale (s): 30.0, Margin (m): 0.4")
    
    output_cos = cosface_head(embeddings, labels)
    print(f"   - Output shape: {output_cos.shape}")
    
    print("\n✓ All models loaded successfully!")
    return backbone, arcface_head, cosface_head


def test_face_detection():
    """Test face detection with RetinaFace."""
    print("\n" + "="*60)
    print("TEST 2: Face Detection")
    print("="*60)
    
    try:
        print("\n1. Loading RetinaFace detector...")
        detector = RetinaFacePyPIAdapter(threshold=0.5)
        print("   ✓ RetinaFace detector loaded successfully")
        
        # Create a synthetic test image
        print("\n2. Creating test image...")
        test_img = np.random.randint(0, 255, (480, 640, 3), dtype=np.uint8)
        print(f"   - Image shape: {test_img.shape}")
        
        # Test detection (will likely not find faces in random noise, but tests the pipeline)
        print("\n3. Testing face detection...")
        bboxes = detector.detect_faces(test_img)
        print(f"   ✓ Detection completed")
        print(f"   - Detected {len(bboxes)} faces")
        
        if len(bboxes) > 0:
            print("   - Bounding boxes:")
            for i, bbox in enumerate(bboxes):
                print(f"     Face {i+1}: {bbox}")
        
        return detector
        
    except ImportError as e:
        print(f"   ⚠ Warning: Could not load RetinaFace detector")
        print(f"   Error: {e}")
        print(f"   Install with: pip install retina-face")
        return None


def test_embedding_extraction(backbone):
    """Test embedding extraction from images."""
    print("\n" + "="*60)
    print("TEST 3: Embedding Extraction")
    print("="*60)
    
    # Create synthetic face images
    print("\n1. Creating test face images...")
    batch_size = 4
    test_images = torch.randn(batch_size, 3, 112, 112)
    print(f"   - Batch size: {batch_size}")
    print(f"   - Image size: 112x112")
    
    # Extract embeddings
    print("\n2. Extracting embeddings...")
    backbone.eval()
    with torch.no_grad():
        embeddings = backbone(test_images)
    
    print(f"   ✓ Embeddings extracted successfully")
    print(f"   - Embedding shape: {embeddings.shape}")
    print(f"   - Embedding dimension: {embeddings.shape[1]}")
    
    # Verify L2 normalization
    norms = torch.norm(embeddings, p=2, dim=1)
    print(f"\n3. Verifying L2 normalization...")
    print(f"   - L2 norms: {norms.numpy()}")
    print(f"   - All norms ≈ 1.0: {torch.allclose(norms, torch.ones_like(norms), atol=1e-5)}")
    
    return embeddings


def test_similarity_computation(embeddings):
    """Test cosine similarity computation between embeddings."""
    print("\n" + "="*60)
    print("TEST 4: Similarity Computation")
    print("="*60)
    
    # Compute cosine similarity matrix
    print("\n1. Computing pairwise cosine similarities...")
    similarity_matrix = torch.mm(embeddings, embeddings.t())
    
    print(f"   ✓ Similarity matrix computed")
    print(f"   - Matrix shape: {similarity_matrix.shape}")
    
    # Display similarity matrix
    print("\n2. Similarity matrix (embeddings × embeddings^T):")
    print(f"{similarity_matrix.numpy()}")
    
    # Find most similar pairs
    print("\n3. Analyzing similarities...")
    n = embeddings.shape[0]
    for i in range(n):
        for j in range(i+1, n):
            sim = similarity_matrix[i, j].item()
            print(f"   - Similarity(Face {i}, Face {j}): {sim:.4f}")
    
    # Diagonal should be 1.0 (self-similarity)
    diagonal = torch.diag(similarity_matrix)
    print(f"\n4. Self-similarities (should be 1.0):")
    print(f"   {diagonal.numpy()}")
    
    return similarity_matrix


def test_pretrained_weights():
    """Test loading pretrained weights if available."""
    print("\n" + "="*60)
    print("TEST 5: Pretrained Weights")
    print("="*60)
    
    pretrained_path = os.path.join(
        os.path.dirname(__file__), 
        '..', 
        'FaceNet', 
        'mobile_weights', 
        'model_mobilefacenet.pth'
    )
    
    print(f"\n1. Checking for pretrained weights...")
    print(f"   Path: {pretrained_path}")
    
    if os.path.exists(pretrained_path):
        print(f"   ✓ Pretrained weights found!")
        
        # Load weights
        print(f"\n2. Loading pretrained weights...")
        backbone = MobileFaceNet(embedding_size=512)
        state_dict = torch.load(pretrained_path, map_location='cpu')
        backbone.load_state_dict(state_dict, strict=False)
        print(f"   ✓ Weights loaded successfully")
        
        # Test inference
        print(f"\n3. Testing pretrained model inference...")
        test_input = torch.randn(1, 3, 112, 112)
        backbone.eval()
        with torch.no_grad():
            embedding = backbone(test_input)
        print(f"   ✓ Inference successful")
        print(f"   - Output shape: {embedding.shape}")
        
        return True
    else:
        print(f"   ⚠ Pretrained weights not found")
        print(f"   This is okay for testing the model architecture")
        return False


def test_fine_tuned_models():
    """Check for fine-tuned model checkpoints."""
    print("\n" + "="*60)
    print("TEST 6: Fine-tuned Models")
    print("="*60)
    
    checkpoint_dir = os.path.join(
        os.path.dirname(__file__), 
        '..', 
        'FaceNet', 
        'mobilefacenet_arcface'
    )
    
    print(f"\n1. Checking for fine-tuned models...")
    print(f"   Directory: {checkpoint_dir}")
    
    if os.path.exists(checkpoint_dir):
        print(f"   ✓ Checkpoint directory found!")
        
        # List checkpoint files
        checkpoint_files = [f for f in os.listdir(checkpoint_dir) if f.endswith('.pth')]
        print(f"\n2. Available checkpoints:")
        for ckpt in checkpoint_files:
            file_path = os.path.join(checkpoint_dir, ckpt)
            file_size = os.path.getsize(file_path) / (1024 * 1024)  # MB
            print(f"   - {ckpt} ({file_size:.2f} MB)")
        
        return len(checkpoint_files) > 0
    else:
        print(f"   ⚠ No fine-tuned models found")
        print(f"   Train a model using fine_tune_main.py to create checkpoints")
        return False


def test_data_structure():
    """Test data directory structure."""
    print("\n" + "="*60)
    print("TEST 7: Data Structure")
    print("="*60)
    
    data_dir = os.path.join(
        os.path.dirname(__file__), 
        '..', 
        'FaceNet', 
        'data'
    )
    
    print(f"\n1. Checking data directory...")
    print(f"   Path: {data_dir}")
    
    if os.path.exists(data_dir):
        print(f"   ✓ Data directory exists")
        
        # List class folders
        classes = [d for d in os.listdir(data_dir) if os.path.isdir(os.path.join(data_dir, d))]
        print(f"\n2. Found {len(classes)} classes:")
        
        total_images = 0
        for cls in sorted(classes)[:10]:  # Show first 10
            cls_path = os.path.join(data_dir, cls)
            images = [f for f in os.listdir(cls_path) 
                     if f.lower().endswith(('.jpg', '.jpeg', '.png', '.bmp'))]
            total_images += len(images)
            print(f"   - {cls}: {len(images)} images")
        
        if len(classes) > 10:
            print(f"   ... and {len(classes) - 10} more classes")
        
        print(f"\n   Total images (shown): {total_images}")
        
        return True
    else:
        print(f"   ⚠ Data directory not found")
        print(f"   Create a 'data' folder with class subfolders containing face images")
        return False


def run_all_tests():
    """Run all test functions."""
    print("\n" + "="*70)
    print(" FACENET FUNCTIONALITY TEST SUITE")
    print("="*70)
    print("\nThis script tests the FaceNet facial recognition system components:")
    print("- Model architecture (MobileFaceNet, ArcFace, CosFace)")
    print("- Face detection (RetinaFace)")
    print("- Embedding extraction")
    print("- Similarity computation")
    print("- Pretrained weights")
    print("- Data structure")
    
    results = {}
    
    # Test 1: Model Loading
    try:
        backbone, arcface_head, cosface_head = test_model_loading()
        results['model_loading'] = True
    except Exception as e:
        print(f"\n✗ Test failed: {e}")
        results['model_loading'] = False
        return results
    
    # Test 2: Face Detection
    try:
        detector = test_face_detection()
        results['face_detection'] = detector is not None
    except Exception as e:
        print(f"\n✗ Test failed: {e}")
        results['face_detection'] = False
    
    # Test 3: Embedding Extraction
    try:
        embeddings = test_embedding_extraction(backbone)
        results['embedding_extraction'] = True
    except Exception as e:
        print(f"\n✗ Test failed: {e}")
        results['embedding_extraction'] = False
        embeddings = None
    
    # Test 4: Similarity Computation
    if embeddings is not None:
        try:
            test_similarity_computation(embeddings)
            results['similarity_computation'] = True
        except Exception as e:
            print(f"\n✗ Test failed: {e}")
            results['similarity_computation'] = False
    
    # Test 5: Pretrained Weights
    try:
        results['pretrained_weights'] = test_pretrained_weights()
    except Exception as e:
        print(f"\n✗ Test failed: {e}")
        results['pretrained_weights'] = False
    
    # Test 6: Fine-tuned Models
    try:
        results['fine_tuned_models'] = test_fine_tuned_models()
    except Exception as e:
        print(f"\n✗ Test failed: {e}")
        results['fine_tuned_models'] = False
    
    # Test 7: Data Structure
    try:
        results['data_structure'] = test_data_structure()
    except Exception as e:
        print(f"\n✗ Test failed: {e}")
        results['data_structure'] = False
    
    # Summary
    print("\n" + "="*70)
    print(" TEST SUMMARY")
    print("="*70)
    
    passed = sum(results.values())
    total = len(results)
    
    for test_name, result in results.items():
        status = "✓ PASS" if result else "✗ FAIL"
        print(f"{status} - {test_name.replace('_', ' ').title()}")
    
    print(f"\nTotal: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 All tests passed! FaceNet system is ready to use.")
    else:
        print("\n⚠ Some tests failed. Check the output above for details.")
    
    print("\n" + "="*70)
    
    return results


def test_camera_face_recognition():
    """Test real-time face recognition using laptop camera."""
    print("\n" + "="*70)
    print(" REAL-TIME CAMERA FACE RECOGNITION TEST")
    print("="*70)
    
    # Load model
    print("\n1. Loading model...")
    device = 'cuda' if torch.cuda.is_available() else 'cpu'
    
    # Try to load pretrained or fine-tuned model
    model_path = None
    
    # Check for best fine-tuned model
    checkpoint_dir = os.path.join(os.path.dirname(__file__), '..', 'FaceNet', 'mobilefacenet_arcface')
    if os.path.exists(checkpoint_dir):
        checkpoints = sorted([f for f in os.listdir(checkpoint_dir) if f.endswith('.pth')])
        if checkpoints:
            model_path = os.path.join(checkpoint_dir, checkpoints[-1])  # Use best model
            print(f"   Using fine-tuned model: {checkpoints[-1]}")
    
    # Fall back to pretrained model
    if model_path is None:
        model_path = os.path.join(os.path.dirname(__file__), '..', 'FaceNet', 'mobile_weights', 'model_mobilefacenet.pth')
        if os.path.exists(model_path):
            print(f"   Using pretrained model: model_mobilefacenet.pth")
        else:
            print("   ⚠ No model weights found! Using random initialization.")
            model_path = None
    
    # Load backbone
    backbone = MobileFaceNet(embedding_size=512).to(device)
    if model_path and os.path.exists(model_path):
        try:
            state_dict = torch.load(model_path, map_location=device)
            backbone.load_state_dict(state_dict, strict=False)
            print(f"   ✓ Model loaded successfully")
        except Exception as e:
            print(f"   ⚠ Warning: Could not load weights: {e}")
    
    backbone.eval()
    
    # Load face detector
    print("\n2. Loading face detector...")
    try:
        detector = RetinaFacePyPIAdapter(threshold=0.5)
        print(f"   ✓ RetinaFace detector loaded")
    except ImportError:
        print(f"   ⚠ RetinaFace not available. Install with: pip install retina-face")
        return False
    
    # Load reference embeddings (facebank) if available
    print("\n3. Loading reference embeddings (facebank)...")
    facebank_path = os.path.join(os.path.dirname(__file__), '..', 'FaceNet', 'data', 'facebank')
    names = []
    embeddings_db = None
    
    if os.path.exists(facebank_path):
        # Check for saved embeddings
        emb_file = os.path.join(facebank_path, 'embeddings.pth')
        names_file = os.path.join(facebank_path, 'names.npy')
        
        if os.path.exists(emb_file) and os.path.exists(names_file):
            embeddings_db = torch.load(emb_file, map_location=device)
            names = np.load(names_file, allow_pickle=True).tolist()
            print(f"   ✓ Loaded {len(names)} reference identities")
            for name in names:
                print(f"     - {name}")
        else:
            print(f"   ⚠ No saved embeddings found in facebank")
            print(f"   Run generate_embeddings.py to create reference embeddings")
    else:
        print(f"   ⚠ Facebank directory not found")
        print(f"   Create {facebank_path} and add reference face images")
    
    # Initialize camera
    print("\n4. Opening camera...")
    cap = cv2.VideoCapture(0)
    
    if not cap.isOpened():
        print("   ✗ Error: Could not open camera")
        return False
    
    # Set camera properties
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
    cap.set(cv2.CAP_PROP_FPS, 30)
    
    print(f"   ✓ Camera opened successfully")
    print(f"   Resolution: {int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))}x{int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))}")
    print(f"   FPS: {int(cap.get(cv2.CAP_PROP_FPS))}")
    
    print("\n" + "="*70)
    print(" STARTING REAL-TIME FACE RECOGNITION")
    print("="*70)
    print("\nControls:")
    print("  - Press 'q' to quit")
    print("  - Press 's' to save current frame")
    print("  - Press 'SPACE' to pause/resume")
    print("\nRecognition threshold: 0.5 (cosine similarity)")
    print("\n")
    
    frame_count = 0
    fps_start_time = cv2.getTickCount()
    fps = 0
    paused = False
    
    try:
        while True:
            if not paused:
                ret, frame = cap.read()
                
                if not ret:
                    print("   ✗ Error: Could not read frame")
                    break
                
                frame_count += 1
                display_frame = frame.copy()
                
                # Calculate FPS
                if frame_count % 30 == 0:
                    fps_end_time = cv2.getTickCount()
                    time_diff = (fps_end_time - fps_start_time) / cv2.getTickFrequency()
                    fps = 30 / time_diff
                    fps_start_time = cv2.getTickCount()
                
                # Detect faces
                bboxes = detector.detect_faces(frame)
                
                # Process each detected face
                for bbox in bboxes:
                    x1, y1, x2, y2 = map(int, bbox[:4])
                    
                    # Draw bounding box
                    cv2.rectangle(display_frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
                    
                    # Extract face region
                    face_crop = frame[y1:y2, x1:x2]
                    
                    if face_crop.size == 0:
                        continue
                    
                    # Resize to model input size
                    face_resized = cv2.resize(face_crop, (112, 112))
                    face_rgb = cv2.cvtColor(face_resized, cv2.COLOR_BGR2RGB)
                    
                    # Normalize
                    face_tensor = torch.from_numpy(face_rgb).float().permute(2, 0, 1).unsqueeze(0)
                    face_tensor = (face_tensor - 127.5) / 128.0
                    face_tensor = face_tensor.to(device)
                    
                    # Extract embedding
                    with torch.no_grad():
                        embedding = backbone(face_tensor)
                    
                    # Recognize face
                    label = "Unknown"
                    confidence = 0.0
                    color = (0, 0, 255)  # Red for unknown
                    
                    if embeddings_db is not None and len(names) > 0:
                        # Compute similarity with all reference embeddings
                        similarities = torch.mm(embedding, embeddings_db.t())
                        max_sim, max_idx = similarities.max(dim=1)
                        
                        max_sim = max_sim.item()
                        max_idx = max_idx.item()
                        
                        # Recognition threshold
                        threshold = 0.5
                        
                        if max_sim > threshold:
                            label = names[max_idx]
                            confidence = max_sim
                            color = (0, 255, 0)  # Green for recognized
                    
                    # Draw label
                    label_text = f"{label}"
                    if confidence > 0:
                        label_text += f" ({confidence:.2f})"
                    
                    # Background for text
                    (text_width, text_height), _ = cv2.getTextSize(label_text, cv2.FONT_HERSHEY_SIMPLEX, 0.6, 2)
                    cv2.rectangle(display_frame, (x1, y1 - text_height - 10), (x1 + text_width, y1), color, -1)
                    
                    # Text
                    cv2.putText(display_frame, label_text, (x1, y1 - 5), 
                               cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
                
                # Display info
                info_text = f"FPS: {fps:.1f} | Faces: {len(bboxes)} | Frame: {frame_count}"
                cv2.putText(display_frame, info_text, (10, 30), 
                           cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)
                
                if embeddings_db is None:
                    warning_text = "No reference embeddings loaded"
                    cv2.putText(display_frame, warning_text, (10, 60), 
                               cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 255), 2)
                
                # Show frame
                cv2.imshow('FaceNet Real-Time Recognition', display_frame)
            
            # Handle key presses
            key = cv2.waitKey(1) & 0xFF
            
            if key == ord('q'):
                print("\n   Quitting...")
                break
            elif key == ord('s'):
                filename = f"frame_{frame_count}.jpg"
                cv2.imwrite(filename, display_frame)
                print(f"   Saved frame to {filename}")
            elif key == ord(' '):
                paused = not paused
                status = "PAUSED" if paused else "RESUMED"
                print(f"   {status}")
    
    except KeyboardInterrupt:
        print("\n   Interrupted by user")
    
    finally:
        cap.release()
        cv2.destroyAllWindows()
        print("\n   ✓ Camera released and windows closed")
    
    print(f"\n   Total frames processed: {frame_count}")
    print(f"   Average FPS: {fps:.1f}")
    
    return True


if __name__ == "__main__":
    # Set device
    device = 'cuda' if torch.cuda.is_available() else 'cpu'
    print(f"\nUsing device: {device}")
    
    if device == 'cuda':
        print(f"GPU: {torch.cuda.get_device_name(0)}")
        print(f"CUDA Version: {torch.version.cuda}")
    
    # Ask user what to run
    print("\n" + "="*70)
    print(" FACENET TEST OPTIONS")
    print("="*70)
    print("\n1. Run all system tests")
    print("2. Test camera face recognition")
    print("3. Run both")
    
    choice = input("\nEnter your choice (1/2/3) [default: 1]: ").strip()
    
    if not choice:
        choice = '1'
    
    if choice == '1':
        # Run all tests
        results = run_all_tests()
        sys.exit(0 if all(results.values()) else 1)
    
    elif choice == '2':
        # Test camera
        success = test_camera_face_recognition()
        sys.exit(0 if success else 1)
    
    elif choice == '3':
        # Run both
        print("\n" + "="*70)
        print(" PART 1: SYSTEM TESTS")
        print("="*70)
        results = run_all_tests()
        
        print("\n" + "="*70)
        print(" PART 2: CAMERA TEST")
        print("="*70)
        input("\nPress Enter to start camera test...")
        
        success = test_camera_face_recognition()
        sys.exit(0 if all(results.values()) and success else 1)
    
    else:
        print("Invalid choice. Please run again and select 1, 2, or 3.")
        sys.exit(1)
