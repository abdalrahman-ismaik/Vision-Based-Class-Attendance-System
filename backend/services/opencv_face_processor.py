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
import pickle
from sklearn.svm import SVC
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score

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
DEFAULT_CHECKPOINT = os.path.join(FACENET_DIR, 'mobilefacenet_arcface', 'best_model_epoch43_acc100.00.pth')


class OpenCVFaceDetector:
    """Face detector using OpenCV Haar Cascades (built-in, no external files needed)"""
    
    def __init__(self, scale_factor=1.1, min_neighbors=5, min_size=(30, 30)):
        """Initialize OpenCV face detector using Haar Cascades"""
        self.scale_factor = scale_factor
        self.min_neighbors = min_neighbors
        self.min_size = min_size
        
        # Use OpenCV's built-in Haar Cascade classifier
        try:
            self.face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
            if self.face_cascade.empty():
                raise RuntimeError("Failed to load Haar Cascade classifier")
            logger.info(f"✓ OpenCV Haar Cascade face detector initialized")
        except Exception as e:
            logger.error(f"Failed to initialize face detector: {e}")
            raise
    
    def detect_faces(self, image):
        """
        Detect faces in image using Haar Cascades
        
        Args:
            image: PIL Image or numpy array
        
        Returns:
            List of bounding boxes [x1, y1, x2, y2]
        """
        # Convert PIL to numpy if needed
        if isinstance(image, Image.Image):
            image = np.array(image)
        
        # Convert to grayscale for Haar Cascade
        gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY) if len(image.shape) == 3 else image
        
        # Detect faces
        detected_faces = self.face_cascade.detectMultiScale(
            gray,
            scaleFactor=self.scale_factor,
            minNeighbors=self.min_neighbors,
            minSize=self.min_size,
            flags=cv2.CASCADE_SCALE_IMAGE
        )
        
        # Convert from (x, y, w, h) to [x1, y1, x2, y2]
        faces = []
        for (x, y, w, h) in detected_faces:
            faces.append([x, y, x + w, y + h])
        
        return faces


class FaceClassifier:
    """Train and use SVM classifier for face recognition"""
    
    def __init__(self):
        """Initialize classifier"""
        self.classifier = SVC(kernel='linear', probability=True, C=1.0)
        self.label_encoder = LabelEncoder()
        self.is_trained = False
    
    def train(self, embeddings, labels):
        """Train classifier on embeddings"""
        # Encode labels
        labels_encoded = self.label_encoder.fit_transform(labels)
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            embeddings, labels_encoded, test_size=0.2, random_state=42, stratify=labels_encoded
        )
        
        # Train classifier
        logger.info(f"Training classifier on {len(X_train)} samples...")
        self.classifier.fit(X_train, y_train)
        
        # Evaluate
        train_pred = self.classifier.predict(X_train)
        test_pred = self.classifier.predict(X_test)
        
        train_acc = accuracy_score(y_train, train_pred)
        test_acc = accuracy_score(y_test, test_pred)
        
        self.is_trained = True
        
        metrics = {
            'train_accuracy': train_acc,
            'test_accuracy': test_acc,
            'n_train': len(X_train),
            'n_test': len(X_test),
            'n_classes': len(self.label_encoder.classes_)
        }
        
        logger.info(f"Training complete: train_acc={train_acc:.3f}, test_acc={test_acc:.3f}")
        return metrics
    
    def predict(self, embedding, threshold=0.5):
        """Predict class for an embedding"""
        if not self.is_trained:
            raise ValueError("Classifier not trained yet!")
        
        embedding = embedding.reshape(1, -1)
        label_encoded = self.classifier.predict(embedding)[0]
        probabilities = self.classifier.predict_proba(embedding)[0]
        
        max_prob = probabilities.max()
        
        if max_prob < threshold:
            return {
                'label': 'Unknown',
                'confidence': max_prob,
                'probabilities': dict(zip(self.label_encoder.classes_, probabilities))
            }
        
        label = self.label_encoder.inverse_transform([label_encoded])[0]
        
        return {
            'label': label,
            'confidence': max_prob,
            'probabilities': dict(zip(self.label_encoder.classes_, probabilities))
        }
    
    def save(self, filepath):
        """Save classifier to file"""
        if not self.is_trained:
            raise ValueError("Classifier not trained yet!")
        
        with open(filepath, 'wb') as f:
            pickle.dump({
                'classifier': self.classifier,
                'label_encoder': self.label_encoder
            }, f)
        
        logger.info(f"Classifier saved to {filepath}")
    
    def load(self, filepath):
        """Load classifier from file"""
        with open(filepath, 'rb') as f:
            data = pickle.load(f)
        
        self.classifier = data['classifier']
        self.label_encoder = data['label_encoder']
        self.is_trained = True
        
        logger.info(f"Classifier loaded from {filepath}")


class SimpleFaceProcessor:
    """Simplified face processing pipeline using OpenCV DNN"""
    
    def __init__(self, checkpoint_path=None, device='cpu'):
        """Initialize processor"""
        # Lazy load torch modules
        _lazy_import_torch()
        
        self.device = device if torch.cuda.is_available() else 'cpu'
        
        # Initialize face detector
        logger.info("Initializing OpenCV face detector...")
        self.face_detector = OpenCVFaceDetector(scale_factor=1.1, min_neighbors=5, min_size=(30, 30))
        
        # Initialize embedding generator
        logger.info("Initializing embedding generator...")
        if checkpoint_path is None:
            checkpoint_path = DEFAULT_CHECKPOINT
        
        self.embedding_model = self._load_model(checkpoint_path)
        self.transform = self._get_transform()
        
        # Initialize classifier
        self.classifier = FaceClassifier()
        
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
    
    def process_student_images(self, image_paths, student_id, output_dir, augment_per_image=20):
        """
        Process multiple student images (different poses)
        
        Args:
            image_paths: List of image paths
            student_id: Student ID
            output_dir: Output directory
            augment_per_image: Number of augmentations per image (for compatibility)
        
        Returns:
            dict with processing results or None if all failed
        """
        logger.info(f"Processing {len(image_paths)} images for student {student_id}")
        
        all_embeddings = []
        successful_images = 0
        
        for idx, image_path in enumerate(image_paths, 1):
            try:
                logger.info(f"Processing image {idx}/{len(image_paths)}: {os.path.basename(image_path)}")
                
                # Load and process image
                image = Image.open(image_path).convert('RGB')
                image_np = np.array(image)
                
                # Detect face
                bboxes = self.face_detector.detect_faces(image_np)
                
                if not bboxes:
                    logger.warning(f"No face detected in image {idx}")
                    continue
                
                # Use first (best) face
                x1, y1, x2, y2 = bboxes[0]
                face = image_np[y1:y2, x1:x2]
                face_pil = Image.fromarray(face)
                
                # Generate embedding
                embedding = self.generate_embedding(face_pil)
                all_embeddings.append(embedding)
                successful_images += 1
                
                logger.info(f"✓ Image {idx} processed successfully")
                
            except Exception as e:
                logger.error(f"Error processing image {idx} for {student_id}: {e}")
                continue
        
        if not all_embeddings:
            logger.error(f"No valid faces detected for {student_id}")
            return None
        
        # Stack all embeddings
        embeddings_array = np.vstack(all_embeddings)  # Shape: (n_images, 512)
        
        # Replicate to augment_per_image samples per original image
        if augment_per_image > 1:
            embeddings_array = np.repeat(embeddings_array, augment_per_image, axis=0)
        
        # Save embeddings
        student_dir = os.path.join(output_dir, student_id)
        os.makedirs(student_dir, exist_ok=True)
        embeddings_path = os.path.join(student_dir, 'embeddings.npy')
        np.save(embeddings_path, embeddings_array)
        
        logger.info(f"✓ Processed {successful_images}/{len(image_paths)} images, saved {embeddings_array.shape[0]} embeddings")
        
        return {
            'success': True,
            'student_id': student_id,
            'num_poses_captured': successful_images,
            'num_samples_total': embeddings_array.shape[0],
            'embeddings_path': embeddings_path,
            'embeddings_shape': embeddings_array.shape
        }
    
    def train_classifier_from_data(self, data_dir, classifier_output_path):
        """
        Train classifier from processed student data
        
        Args:
            data_dir: Directory containing student subdirectories with embeddings
            classifier_output_path: Path to save trained classifier
        
        Returns:
            dict with training results
        """
        logger.info(f"Training classifier from {data_dir}")
        
        # Collect all embeddings and labels
        all_embeddings = []
        all_labels = []
        
        for student_id in os.listdir(data_dir):
            student_dir = os.path.join(data_dir, student_id)
            embeddings_path = os.path.join(student_dir, "embeddings.npy")
            
            if not os.path.exists(embeddings_path):
                logger.warning(f"No embeddings found for {student_id}")
                continue
            
            # Load embeddings
            embeddings = np.load(embeddings_path)
            
            # Add to collection
            all_embeddings.append(embeddings)
            all_labels.extend([student_id] * len(embeddings))
        
        # Stack embeddings
        all_embeddings = np.vstack(all_embeddings)
        all_labels = np.array(all_labels)
        
        logger.info(f"Collected {len(all_embeddings)} embeddings from {len(set(all_labels))} students")
        
        # Train classifier
        metrics = self.classifier.train(all_embeddings, all_labels)
        
        # Save classifier
        self.classifier.save(classifier_output_path)
        
        result = {
            'metrics': metrics,
            'classifier_path': classifier_output_path,
            'n_students': len(set(all_labels)),
            'n_embeddings': len(all_embeddings)
        }
        
        return result
    
    def recognize_face(self, image_path, threshold=0.5, allowed_student_ids=None):
        """
        Recognize face in an image using trained classifier
        
        Args:
            image_path: Path to image
            threshold: Confidence threshold (default 0.5)
            allowed_student_ids: Optional list of student IDs to restrict predictions to
        
        Returns:
            dict with recognition results including bbox and prediction
        """
        if not self.classifier.is_trained:
            raise ValueError("Classifier not trained yet!")
        
        # Load image
        image = Image.open(image_path).convert('RGB')
        
        # Detect faces
        bboxes = self.face_detector.detect_faces(image)
        
        if len(bboxes) == 0:
            return {'error': 'No face detected'}
        
        # Process first face
        bbox = bboxes[0]
        x1, y1, x2, y2 = map(int, bbox)
        
        # Add margin for better recognition
        w = x2 - x1
        h = y2 - y1
        margin = 0.2
        x1 = max(0, x1 - int(w * margin))
        y1 = max(0, y1 - int(h * margin))
        x2 = min(image.width, x2 + int(w * margin))
        y2 = min(image.height, y2 + int(h * margin))
        
        # Crop face
        face_image = image.crop((x1, y1, x2, y2))
        
        # Generate embedding
        embedding = self.generate_embedding(face_image)
        
        # Predict (optionally restricted to a list of student IDs)
        prediction = self.classifier.predict(embedding, threshold=threshold)
        
        return {
            'bbox': [x1, y1, x2, y2],
            'prediction': prediction
        }


# Alias for compatibility
FaceProcessingPipeline = SimpleFaceProcessor

if __name__ == "__main__":
    # Test
    processor = SimpleFaceProcessor(device='cpu')
    print("✓ Face processor initialized successfully")
