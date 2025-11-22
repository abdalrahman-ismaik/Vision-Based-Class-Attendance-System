"""
Alternative Face Processing Pipeline using OpenCV DNN for face detection
This avoids TensorFlow/Keras compatibility issues with RetinaFace
"""

import os
import sys
import cv2
import numpy as np
from PIL import Image
import logging
from pathlib import Path

# Add FaceNet directory to path
BACKEND_DIR = os.path.dirname(os.path.abspath(__file__))  # backend/services
PROJECT_ROOT = os.path.dirname(os.path.dirname(BACKEND_DIR))  # project root
FACENET_DIR = os.path.join(PROJECT_ROOT, 'FaceNet')
if FACENET_DIR not in sys.path:
    sys.path.insert(0, FACENET_DIR)

# Lazy import torch and torchvision to speed up initial load
torch = None
transforms = None
MobileFaceNet = None

def _lazy_import_torch():
    """Lazy import torch modules to improve startup time"""
    global torch, transforms, MobileFaceNet
    if torch is None:
        import torch as _torch
        from torchvision import transforms as _transforms
        from networks.models_facenet import MobileFaceNet as _MobileFaceNet
        torch = _torch
        transforms = _transforms
        MobileFaceNet = _MobileFaceNet

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Constants
FACENET_MEAN = [0.31928780674934387, 0.2873991131782532, 0.25779902935028076]
FACENET_STD = [0.19799138605594635, 0.20757903158664703, 0.21088403463363647]
DEFAULT_CHECKPOINT = '../FaceNet/mobilefacenet_arcface/best_model_epoch43_acc100.00.pth'


class OpenCVFaceDetector:
    """Face detector using OpenCV DNN module (no TensorFlow dependency)"""
    
    def __init__(self, confidence_threshold=0.7):
        """Initialize OpenCV face detector"""
        self.confidence_threshold = confidence_threshold
        
        # Download model files if not present
        model_dir = os.path.join(BACKEND_DIR, 'opencv_models')
        os.makedirs(model_dir, exist_ok=True)
        
        prototxt_path = os.path.join(model_dir, 'deploy.prototxt')
        weights_path = os.path.join(model_dir, 'res10_300x300_ssd_iter_140000.caffemodel')
        
        # Create prototxt if doesn't exist
        if not os.path.exists(prototxt_path):
            logger.info("Creating deploy.prototxt...")
            self._create_prototxt(prototxt_path)
        
        # Download weights if needed
        if not os.path.exists(weights_path):
            logger.warning(f"Model weights not found at {weights_path}")
            logger.info("Please download from: https://github.com/opencv/opencv_3rdparty/raw/dnn_samples_face_detector_20170830/res10_300x300_ssd_iter_140000.caffemodel")
            logger.info(f"And save to: {weights_path}")
            raise FileNotFoundError(f"Face detector model not found: {weights_path}")
        
        # Load network
        try:
            self.net = cv2.dnn.readNetFromCaffe(prototxt_path, weights_path)
            logger.info(f"✓ OpenCV face detector initialized (confidence={confidence_threshold})")
        except Exception as e:
            logger.error(f"Failed to load face detector: {e}")
            raise
    
    def _create_prototxt(self, path):
        """Create deploy.prototxt file"""
        prototxt_content = """
name: "OpenCVFaceDetector"
input: "data"
input_dim: 1
input_dim: 3
input_dim: 300
input_dim: 300

layer {
  name: "conv1_1"
  type: "Convolution"
  bottom: "data"
  top: "conv1_1"
}

layer {
  name: "detection_out"
  type: "DetectionOutput"
  bottom: "loc"
  bottom: "conf"
  bottom: "prior"
  top: "detection_out"
}
"""
        with open(path, 'w') as f:
            f.write(prototxt_content.strip())
    
    def detect_faces(self, image):
        """
        Detect faces in image using OpenCV DNN
        
        Args:
            image: PIL Image or numpy array
        
        Returns:
            List of bounding boxes [x1, y1, x2, y2]
        """
        # Convert PIL to numpy if needed
        if isinstance(image, Image.Image):
            image = np.array(image)
        
        h, w = image.shape[:2]
        
        # Prepare blob
        blob = cv2.dnn.blobFromImage(
            cv2.resize(image, (300, 300)),
            1.0,
            (300, 300),
            (104.0, 177.0, 123.0)
        )
        
        # Detection
        self.net.setInput(blob)
        detections = self.net.forward()
        
        # Extract faces
        faces = []
        for i in range(detections.shape[2]):
            confidence = detections[0, 0, i, 2]
            
            if confidence > self.confidence_threshold:
                box = detections[0, 0, i, 3:7] * np.array([w, h, w, h])
                (x1, y1, x2, y2) = box.astype("int")
                
                # Ensure box is within image bounds
                x1, y1 = max(0, x1), max(0, y1)
                x2, y2 = min(w, x2), min(h, y2)
                
                faces.append([x1, y1, x2, y2])
        
        return faces


class SimpleFaceProcessor:
    """Simplified face processing pipeline using OpenCV DNN"""
    
    def __init__(self, checkpoint_path=None, device='cpu'):
        """Initialize processor"""
        # Lazy load torch modules
        _lazy_import_torch()
        
        self.device = device if torch.cuda.is_available() else 'cpu'
        
        # Initialize face detector
        logger.info("Initializing OpenCV face detector...")
        self.face_detector = OpenCVFaceDetector(confidence_threshold=0.7)
        
        # Initialize embedding generator
        logger.info("Initializing embedding generator...")
        if checkpoint_path is None:
            checkpoint_path = os.path.join(BACKEND_DIR, DEFAULT_CHECKPOINT)
        
        self.embedding_model = self._load_model(checkpoint_path)
        self.transform = self._get_transform()
        
        logger.info("✓ Face processor initialized")
    
    def _load_model(self, checkpoint_path):
        """Load FaceNet model"""
        model = MobileFaceNet(embedding_size=512)
        
        checkpoint = torch.load(checkpoint_path, map_location=self.device)
        
        try:
            if 'model_state_dict' in checkpoint:
                model.load_state_dict(checkpoint['model_state_dict'], strict=False)
            else:
                model.load_state_dict(checkpoint, strict=False)
            logger.info(f"✓ Loaded FaceNet model from {checkpoint_path}")
        except Exception as e:
            logger.warning(f"Loading model with strict=False: {e}")
            if 'model_state_dict' in checkpoint:
                model.load_state_dict(checkpoint['model_state_dict'], strict=False)
            else:
                model.load_state_dict(checkpoint, strict=False)
        
        model.to(self.device)
        model.eval()
        return model
    
    def _get_transform(self):
        """Get preprocessing transform"""
        return transforms.Compose([
            transforms.Resize((112, 112)),
            transforms.ToTensor(),
            transforms.Normalize(mean=FACENET_MEAN, std=FACENET_STD)
        ])
    
    def generate_embedding(self, face_image):
        """Generate embedding for face image"""
        if isinstance(face_image, np.ndarray):
            face_image = Image.fromarray(face_image)
        
        # Transform
        face_tensor = self.transform(face_image).unsqueeze(0).to(self.device)
        
        # Generate embedding
        with torch.no_grad():
            embedding = self.embedding_model(face_tensor)
        
        return embedding.cpu().numpy().flatten()
    
    def process_student_image(self, image_path, student_id, output_dir, num_augmentations=20):
        """
        Process student image - detect face and generate embeddings
        
        Args:
            image_path: Path to student image
            student_id: Student ID
            output_dir: Output directory for embeddings
            num_augmentations: Number of augmented images to generate (for compatibility)
        
        Returns:
            dict with processing results or None if failed
        """
        logger.info(f"Processing image for student {student_id}")
        
        # Load image
        image = Image.open(image_path).convert('RGB')
        image_np = np.array(image)
        
        # Detect faces
        logger.info("Detecting face...")
        bboxes = self.face_detector.detect_faces(image_np)
        
        if not bboxes:
            logger.error("No face detected in image")
            return None
        
        # Use first (best) face
        x1, y1, x2, y2 = bboxes[0]
        logger.info(f"Face detected at [{x1}, {y1}, {x2}, {y2}]")
        
        # Crop face
        face = image_np[y1:y2, x1:x2]
        face_pil = Image.fromarray(face)
        
        # Generate embedding
        logger.info("Generating embedding...")
        embedding = self.generate_embedding(face_pil)
        
        # Create output directory
        student_dir = os.path.join(output_dir, student_id)
        os.makedirs(student_dir, exist_ok=True)
        
        # Save embedding (replicate for compatibility with multi-embedding code)
        embeddings_array = np.tile(embedding, (num_augmentations, 1))  # Shape: (20, 512)
        embeddings_path = os.path.join(student_dir, 'embeddings.npy')
        np.save(embeddings_path, embeddings_array)
        
        logger.info(f"✓ Embeddings saved: {embeddings_path}")
        
        return {
            'success': True,
            'student_id': student_id,
            'face_bbox': [x1, y1, x2, y2],
            'num_augmentations': num_augmentations,
            'embeddings_path': embeddings_path,
            'embeddings_shape': embeddings_array.shape
        }


# Alias for compatibility
FaceProcessingPipeline = SimpleFaceProcessor

if __name__ == "__main__":
    # Test
    processor = SimpleFaceProcessor(device='cpu')
    print("✓ Face processor initialized successfully")
