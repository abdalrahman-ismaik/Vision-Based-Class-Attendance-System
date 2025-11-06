"""
Face Processing Pipeline
Handles image augmentation, face detection, embedding generation, and classifier training
"""

import os
import sys
import cv2
import torch
import numpy as np
from PIL import Image, ImageEnhance
import pickle
from datetime import datetime
from sklearn.svm import SVC
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
import logging

# Add FaceNet directory to path - use absolute path
BACKEND_DIR = os.path.dirname(os.path.abspath(__file__))
FACENET_DIR = os.path.join(os.path.dirname(BACKEND_DIR), 'FaceNet')
if FACENET_DIR not in sys.path:
    sys.path.insert(0, FACENET_DIR)

from networks.models_facenet import MobileFaceNet
from torchvision import transforms

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# ============= CONSTANTS =============
FACENET_MEAN = [0.31928780674934387, 0.2873991131782532, 0.25779902935028076]
FACENET_STD = [0.19799138605594635, 0.20757903158664703, 0.21088403463363647]
DEFAULT_CHECKPOINT = '../FaceNet/mobilefacenet_arcface/best_model_epoch43_acc100.00.pth'


class FaceDetector:
    """Face detector using RetinaFace"""
    
    def __init__(self, threshold=0.9):
        """Initialize face detector"""
        try:
            # Try importing from FaceNet utils
            sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../FaceNet'))
            from utils.utils import RetinaFacePyPIAdapter
            self.detector = RetinaFacePyPIAdapter(threshold=threshold)
            logger.info(f"✓ Face detector initialized with threshold={threshold}")
        except Exception as e:
            logger.error(f"Failed to initialize face detector: {e}")
            raise
    
    def detect_faces(self, image):
        """
        Detect faces in image
        
        Args:
            image: PIL Image or numpy array
        
        Returns:
            List of bounding boxes [x1, y1, x2, y2]
        """
        if isinstance(image, Image.Image):
            image = np.array(image)
        
        return self.detector.detect_faces(image)


class ImageAugmentor:
    """Image augmentation for face images"""
    
    @staticmethod
    def zoom_in(image, zoom_factor=1.2):
        """Zoom into center of image"""
        width, height = image.size
        new_width = int(width / zoom_factor)
        new_height = int(height / zoom_factor)
        
        left = (width - new_width) // 2
        top = (height - new_height) // 2
        right = left + new_width
        bottom = top + new_height
        
        cropped = image.crop((left, top, right, bottom))
        return cropped.resize((width, height), Image.LANCZOS)
    
    @staticmethod
    def zoom_out(image, zoom_factor=0.8):
        """Zoom out by adding padding"""
        width, height = image.size
        new_width = int(width * zoom_factor)
        new_height = int(height * zoom_factor)
        
        # Resize image
        resized = image.resize((new_width, new_height), Image.LANCZOS)
        
        # Create new image with padding
        new_image = Image.new('RGB', (width, height), (128, 128, 128))
        paste_x = (width - new_width) // 2
        paste_y = (height - new_height) // 2
        new_image.paste(resized, (paste_x, paste_y))
        
        return new_image
    
    @staticmethod
    def adjust_brightness(image, factor):
        """Adjust brightness. factor > 1.0 brightens, < 1.0 dims"""
        enhancer = ImageEnhance.Brightness(image)
        return enhancer.enhance(factor)
    
    @staticmethod
    def adjust_contrast(image, factor):
        """Adjust contrast"""
        enhancer = ImageEnhance.Contrast(image)
        return enhancer.enhance(factor)
    
    @staticmethod
    def horizontal_flip(image):
        """Flip image horizontally"""
        return image.transpose(Image.FLIP_LEFT_RIGHT)
    
    @staticmethod
    def rotate(image, angle):
        """Rotate image by angle (degrees)"""
        return image.rotate(angle, fillcolor=(128, 128, 128))
    
    @staticmethod
    def add_gaussian_noise(image, mean=0, sigma=10):
        """Add gaussian noise to image"""
        img_array = np.array(image, dtype=np.float32)
        noise = np.random.normal(mean, sigma, img_array.shape)
        noisy_img = np.clip(img_array + noise, 0, 255).astype(np.uint8)
        return Image.fromarray(noisy_img)
    
    @classmethod
    def generate_augmentations(cls, image, num_augmentations=20):
        """
        Generate multiple augmentations of an image
        
        Args:
            image: PIL Image
            num_augmentations: Number of augmentations to generate
        
        Returns:
            List of augmented PIL Images
        """
        augmentations = [image]  # Original image
        
        # Define augmentation strategies
        strategies = [
            # Zoom variations
            lambda img: cls.zoom_in(img, 1.15),
            lambda img: cls.zoom_in(img, 1.3),
            lambda img: cls.zoom_out(img, 0.85),
            
            # Brightness variations
            lambda img: cls.adjust_brightness(img, 0.6),   # Dim
            lambda img: cls.adjust_brightness(img, 0.8),
            lambda img: cls.adjust_brightness(img, 1.2),   # Bright
            lambda img: cls.adjust_brightness(img, 1.4),
            
            # Contrast variations
            lambda img: cls.adjust_contrast(img, 0.8),
            lambda img: cls.adjust_contrast(img, 1.2),
            
            # Rotation
            lambda img: cls.rotate(img, -10),
            lambda img: cls.rotate(img, 10),
            lambda img: cls.rotate(img, -5),
            lambda img: cls.rotate(img, 5),
            
            # Noise
            lambda img: cls.add_gaussian_noise(img, sigma=5),
            lambda img: cls.add_gaussian_noise(img, sigma=15),
            
            # Combinations
            lambda img: cls.adjust_brightness(cls.zoom_in(img, 1.2), 0.8),
            lambda img: cls.adjust_brightness(cls.zoom_out(img, 0.85), 1.2),
            lambda img: cls.adjust_contrast(cls.rotate(img, 5), 1.1),
            lambda img: cls.add_gaussian_noise(cls.adjust_brightness(img, 0.9), sigma=8),
        ]
        
        # Generate augmentations
        for i, strategy in enumerate(strategies):
            if i >= num_augmentations:
                break
            try:
                aug_img = strategy(image)
                augmentations.append(aug_img)
            except Exception as e:
                logger.warning(f"Augmentation {i} failed: {e}")
        
        logger.info(f"Generated {len(augmentations)} augmentations")
        return augmentations


class EmbeddingGenerator:
    """Generate face embeddings using FaceNet"""
    
    def __init__(self, checkpoint_path=None, device='cuda'):
        """
        Initialize embedding generator
        
        Args:
            checkpoint_path: Path to FaceNet checkpoint
            device: 'cuda' or 'cpu'
        """
        self.device = device if torch.cuda.is_available() else 'cpu'
        
        if checkpoint_path is None:
            checkpoint_path = os.path.join(
                os.path.dirname(__file__),
                DEFAULT_CHECKPOINT
            )
        
        self.model = self._load_model(checkpoint_path)
        self.transform = self._get_transform()
        logger.info(f"Embedding generator initialized on {self.device}")
    
    def _load_model(self, checkpoint_path):
        """Load FaceNet model"""
        model = MobileFaceNet(embedding_size=512)
        
        checkpoint = torch.load(checkpoint_path, map_location=self.device)
        
        if 'model_state_dict' in checkpoint:
            model.load_state_dict(checkpoint['model_state_dict'])
        else:
            model.load_state_dict(checkpoint)
        
        model.to(self.device)
        model.eval()
        
        logger.info(f"Loaded FaceNet model from {checkpoint_path}")
        return model
    
    def _get_transform(self):
        """Get preprocessing transform"""
        return transforms.Compose([
            transforms.Resize((112, 112)),
            transforms.ToTensor(),
            transforms.Normalize(mean=FACENET_MEAN, std=FACENET_STD)
        ])
    
    def generate_embedding(self, face_image):
        """
        Generate embedding for a face image
        
        Args:
            face_image: PIL Image of face
        
        Returns:
            numpy array of shape (512,)
        """
        # Preprocess
        face_tensor = self.transform(face_image).unsqueeze(0).to(self.device)
        
        # Generate embedding
        with torch.no_grad():
            embedding = self.model(face_tensor)
            # L2 normalize
            embedding = embedding / torch.norm(embedding, p=2, dim=1, keepdim=True)
            embedding = embedding.cpu().numpy().flatten()
        
        return embedding


class FaceClassifier:
    """Train and use SVM classifier for face recognition"""
    
    def __init__(self):
        """Initialize classifier"""
        self.classifier = SVC(kernel='linear', probability=True, C=1.0)
        self.label_encoder = LabelEncoder()
        self.is_trained = False
    
    def train(self, embeddings, labels):
        """
        Train classifier on embeddings
        
        Args:
            embeddings: numpy array of shape (n_samples, embedding_dim)
            labels: numpy array of shape (n_samples,) - class labels
        
        Returns:
            dict with training metrics
        """
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
        """
        Predict class for an embedding
        
        Args:
            embedding: numpy array of shape (embedding_dim,)
            threshold: Minimum probability threshold
        
        Returns:
            dict with prediction results
        """
        if not self.is_trained:
            raise ValueError("Classifier not trained yet!")
        
        # Predict
        embedding = embedding.reshape(1, -1)
        label_encoded = self.classifier.predict(embedding)[0]
        probabilities = self.classifier.predict_proba(embedding)[0]
        
        max_prob = probabilities.max()
        
        # Check threshold
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


class FaceProcessingPipeline:
    """Complete pipeline for face processing"""
    
    def __init__(self, checkpoint_path=None, device='cuda'):
        """Initialize pipeline components"""
        self.face_detector = FaceDetector(threshold=0.9)
        self.augmentor = ImageAugmentor()
        self.embedding_generator = EmbeddingGenerator(checkpoint_path, device)
        self.classifier = FaceClassifier()
        
        logger.info("Face processing pipeline initialized")
    
    def process_student_image(self, image_path, student_id, output_dir, num_augmentations=20):
        """
        Process a single student image:
        1. Detect face
        2. Generate augmentations
        3. Extract embeddings for all augmentations
        
        Args:
            image_path: Path to student image
            student_id: Student identifier
            output_dir: Directory to save augmented images and embeddings
            num_augmentations: Number of augmentations to generate
        
        Returns:
            dict with processing results
        """
        logger.info(f"Processing image for student {student_id}")
        
        # Load image
        image = Image.open(image_path).convert('RGB')
        
        # Detect faces
        bboxes = self.face_detector.detect_faces(image)
        
        if len(bboxes) == 0:
            logger.warning(f"No face detected in {image_path}")
            return None
        
        # Take first/largest face
        bbox = bboxes[0]
        x1, y1, x2, y2 = map(int, bbox)
        
        # Add margin
        w = x2 - x1
        h = y2 - y1
        margin = 0.2
        margin_w = int(w * margin)
        margin_h = int(h * margin)
        
        x1 = max(0, x1 - margin_w)
        y1 = max(0, y1 - margin_h)
        x2 = min(image.width, x2 + margin_w)
        y2 = min(image.height, y2 + margin_h)
        
        # Crop face
        face_image = image.crop((x1, y1, x2, y2))
        
        # Generate augmentations
        augmented_images = self.augmentor.generate_augmentations(
            face_image, num_augmentations=num_augmentations
        )
        
        # Create output directory
        student_aug_dir = os.path.join(output_dir, student_id)
        os.makedirs(student_aug_dir, exist_ok=True)
        
        # Save augmented images and generate embeddings
        embeddings = []
        for i, aug_img in enumerate(augmented_images):
            # Save augmented image
            aug_path = os.path.join(student_aug_dir, f"aug_{i:03d}.jpg")
            aug_img.save(aug_path)
            
            # Generate embedding
            embedding = self.embedding_generator.generate_embedding(aug_img)
            embeddings.append(embedding)
        
        # Stack embeddings
        embeddings = np.array(embeddings)
        
        # Save embeddings
        embeddings_path = os.path.join(student_aug_dir, "embeddings.npy")
        np.save(embeddings_path, embeddings)
        
        result = {
            'student_id': student_id,
            'num_augmentations': len(augmented_images),
            'embeddings_shape': embeddings.shape,
            'output_dir': student_aug_dir,
            'embeddings_path': embeddings_path
        }
        
        logger.info(f"Processed {student_id}: {len(augmented_images)} augmentations, embeddings saved")
        return result
    
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
    
    def recognize_face(self, image_path, threshold=0.5):
        """
        Recognize face in an image using trained classifier
        
        Args:
            image_path: Path to image
            threshold: Confidence threshold
        
        Returns:
            dict with recognition results
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
        
        # Add margin
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
        embedding = self.embedding_generator.generate_embedding(face_image)
        
        # Predict
        prediction = self.classifier.predict(embedding, threshold=threshold)
        
        return {
            'bbox': [x1, y1, x2, y2],
            'prediction': prediction
        }


def main():
    """Example usage"""
    # Initialize pipeline
    pipeline = FaceProcessingPipeline()
    
    # Process a student image
    result = pipeline.process_student_image(
        image_path="../backend/uploads/students/100064807/100064807_20251008_210933.jpg",
        student_id="100064807",
        output_dir="../backend/processed_faces",
        num_augmentations=20
    )
    
    print(f"Processing result: {result}")


if __name__ == "__main__":
    main()
