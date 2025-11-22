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

# Add FaceNet directory to path
# Navigate from backend/services/ to FaceNet/
facenet_path = os.path.join(os.path.dirname(__file__), '..', '..', 'FaceNet')
sys.path.insert(0, facenet_path)

from networks.models_facenet import MobileFaceNet
from torchvision import transforms

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# ============= CONSTANTS =============
FACENET_MEAN = [0.31928780674934387, 0.2873991131782532, 0.25779902935028076]
FACENET_STD = [0.19799138605594635, 0.20757903158664703, 0.21088403463363647]
# Path from backend/services/ to FaceNet/mobilefacenet_arcface/
DEFAULT_CHECKPOINT = '../../FaceNet/mobilefacenet_arcface/best_model_epoch43_acc100.00.pth'


class FaceDetector:
    """Face detector using OpenCV Haar Cascades (avoids Keras compatibility issues)"""
    
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
            model.load_state_dict(checkpoint['model_state_dict'], strict=False)
        else:
            model.load_state_dict(checkpoint, strict=False)
        
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
    """Train and use binary classifiers for face recognition - one per student"""
    
    def __init__(self):
        """Initialize classifier storage"""
        self.classifiers = {}  # Dict of {student_id: classifier}
        self.student_ids = []
        self.is_trained = False
    
    def train(self, embeddings, labels):
        """
        Train binary classifier for each student
        
        Args:
            embeddings: numpy array of shape (n_samples, embedding_dim)
            labels: numpy array of shape (n_samples,) - student IDs
        
        Returns:
            dict with training metrics
        """
        unique_labels = np.unique(labels)
        self.student_ids = list(unique_labels)
        
        if len(unique_labels) < 2:
            raise ValueError("Need at least 2 students to train classifiers")
        
        logger.info(f"Training binary classifiers for {len(unique_labels)} students...")
        
        metrics = {
            'n_students': len(unique_labels),
            'n_embeddings': len(embeddings),
            'per_student_metrics': {}
        }
        
        # Train one binary classifier per student
        for student_id in unique_labels:
            logger.info(f"  Training classifier for {student_id}...")
            
            # Create binary labels: 1 for this student, 0 for others
            binary_labels = (labels == student_id).astype(int)
            
            # Count positive and negative samples
            n_positive = np.sum(binary_labels == 1)
            n_negative = np.sum(binary_labels == 0)
            
            logger.info(f"    Positive samples: {n_positive}, Negative samples: {n_negative}")
            
            # Handle class imbalance by adjusting weights
            # Calculate class weights inversely proportional to class frequencies
            weight_positive = len(binary_labels) / (2 * n_positive)
            weight_negative = len(binary_labels) / (2 * n_negative)
            class_weights = {1: weight_positive, 0: weight_negative}
            
            # Split data
            X_train, X_test, y_train, y_test = train_test_split(
                embeddings, binary_labels, 
                test_size=0.2, 
                random_state=42,
                stratify=binary_labels  # Maintain class balance in splits
            )
            
            # Train binary SVM classifier with class weights
            classifier = SVC(
                kernel='linear', 
                probability=True, 
                C=1.0,
                class_weight=class_weights  # Handle imbalance
            )
            classifier.fit(X_train, y_train)
            
            # Evaluate
            train_pred = classifier.predict(X_train)
            test_pred = classifier.predict(X_test)
            
            train_acc = accuracy_score(y_train, train_pred)
            test_acc = accuracy_score(y_test, test_pred)
            
            # Calculate precision, recall, F1 for the positive class
            from sklearn.metrics import precision_recall_fscore_support
            test_prec, test_rec, test_f1, _ = precision_recall_fscore_support(
                y_test, test_pred, pos_label=1, average='binary', zero_division=0
            )
            
            # Store classifier
            self.classifiers[student_id] = classifier
            
            metrics['per_student_metrics'][student_id] = {
                'train_accuracy': float(train_acc),
                'test_accuracy': float(test_acc),
                'test_precision': float(test_prec),
                'test_recall': float(test_rec),
                'test_f1': float(test_f1),
                'n_positive': int(n_positive),
                'n_negative': int(n_negative),
                'n_train': len(X_train),
                'n_test': len(X_test),
                'class_weight_positive': float(weight_positive),
                'class_weight_negative': float(weight_negative)
            }
            
            logger.info(f"    Train acc: {train_acc:.3f}, Test acc: {test_acc:.3f}, "
                       f"Precision: {test_prec:.3f}, Recall: {test_rec:.3f}, F1: {test_f1:.3f}")
        
        self.is_trained = True
        
        # Calculate average metrics
        avg_test_acc = np.mean([m['test_accuracy'] for m in metrics['per_student_metrics'].values()])
        avg_test_f1 = np.mean([m['test_f1'] for m in metrics['per_student_metrics'].values()])
        
        metrics['average_test_accuracy'] = float(avg_test_acc)
        metrics['average_test_f1'] = float(avg_test_f1)
        
        logger.info(f"Training complete: avg_test_acc={avg_test_acc:.3f}, avg_f1={avg_test_f1:.3f}")
        return metrics
    
    def predict(self, embedding, threshold=0.5, allowed_student_ids=None):
        """
        Predict using all binary classifiers and return best match
        
        Args:
            embedding: numpy array of shape (embedding_dim,)
            threshold: Minimum probability threshold for positive prediction
        
        Returns:
            dict with prediction results
        """
        if not self.is_trained:
            raise ValueError("Classifiers not trained yet!")
        
        embedding = embedding.reshape(1, -1)
        
        # Determine which classifiers to consult
        if allowed_student_ids is None:
            iter_classifiers = self.classifiers.items()
        else:
            # Filter to allowed students and ignore missing ones
            iter_classifiers = (
                (sid, self.classifiers[sid])
                for sid in allowed_student_ids if sid in self.classifiers
            )

        # Get predictions from the selected classifiers
        predictions = {}
        for student_id, classifier in iter_classifiers:
            # Predict probability for positive class (this student)
            proba = classifier.predict_proba(embedding)[0]
            positive_proba = proba[1] if len(proba) > 1 else proba[0]

            predictions[student_id] = float(positive_proba)
        
        if len(predictions) == 0:
            # No classifiers available in the allowed set
            return {
                'label': 'Unknown',
                'confidence': 0.0,
                'all_predictions': predictions,
                'threshold_used': threshold
            }

        # Find student with highest confidence
        best_student = max(predictions, key=predictions.get)
        best_confidence = predictions[best_student]
        
        # Check if confidence exceeds threshold
        if best_confidence < threshold:
            return {
                'label': 'Unknown',
                'confidence': best_confidence,
                'all_predictions': predictions,
                'threshold_used': threshold
            }
        
        return {
            'label': best_student,
            'confidence': best_confidence,
            'all_predictions': predictions,
            'threshold_used': threshold
        }
    
    def predict_student(self, embedding, student_id, threshold=0.5):
        """
        Predict if embedding matches a specific student
        
        Args:
            embedding: numpy array of shape (embedding_dim,)
            student_id: Student ID to check
            threshold: Minimum probability threshold
        
        Returns:
            dict with prediction results
        """
        if not self.is_trained:
            raise ValueError("Classifiers not trained yet!")
        
        if student_id not in self.classifiers:
            raise ValueError(f"No classifier found for student {student_id}")
        
        embedding = embedding.reshape(1, -1)
        classifier = self.classifiers[student_id]
        
        # Predict probability for positive class
        proba = classifier.predict_proba(embedding)[0]
        positive_proba = proba[1] if len(proba) > 1 else proba[0]
        
        is_match = positive_proba >= threshold
        
        return {
            'student_id': student_id,
            'is_match': bool(is_match),
            'confidence': float(positive_proba),
            'threshold_used': threshold
        }
    
    def save(self, filepath):
        """Save all classifiers to file"""
        if not self.is_trained:
            raise ValueError("Classifiers not trained yet!")
        
        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        
        with open(filepath, 'wb') as f:
            pickle.dump({
                'classifiers': self.classifiers,
                'student_ids': self.student_ids
            }, f)
        
        logger.info(f"Classifiers saved to {filepath}")
    
    def load(self, filepath):
        """Load classifiers from file"""
        with open(filepath, 'rb') as f:
            data = pickle.load(f)
        
        self.classifiers = data['classifiers']
        self.student_ids = data['student_ids']
        self.is_trained = True
        
        logger.info(f"Loaded {len(self.classifiers)} classifiers from {filepath}")


class FaceProcessingPipeline:
    """Complete pipeline for face processing"""
    
    def __init__(self, checkpoint_path=None, device='cuda'):
        """Initialize pipeline components"""
        self.face_detector = FaceDetector()  # OpenCV Haar Cascade (no threshold parameter)
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
    
    def process_student_images(self, image_paths, student_id, output_dir, augment_per_image=20):
        """
        Process multiple student images (different poses):
        1. Detect face in each image
        2. Generate augmentations for each pose
        3. Extract embeddings for all augmented images
        
        Args:
            image_paths: List of paths to student images (different poses)
            student_id: Student identifier
            output_dir: Directory to save processed images and embeddings
            augment_per_image: Number of augmentations per pose (0 = no augmentation)
        
        Returns:
            dict with processing results or None if no faces detected
        """
        logger.info(f"Processing {len(image_paths)} images for student {student_id}")
        
        # Create output directory
        student_dir = os.path.join(output_dir, student_id)
        os.makedirs(student_dir, exist_ok=True)
        
        embeddings = []
        processed_count = 0
        
        # Process each pose
        for idx, image_path in enumerate(image_paths, 1):
            try:
                # Load image
                image = Image.open(image_path).convert('RGB')
                
                # Detect faces
                bboxes = self.face_detector.detect_faces(image)
                
                if len(bboxes) == 0:
                    logger.warning(f"No face detected in image {idx} for {student_id}")
                    continue
                
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
                
                # Apply augmentation if requested
                if augment_per_image > 0:
                    # Generate augmentations for this pose
                    augmented_images = self.augmentor.generate_augmentations(
                        face_image, num_augmentations=augment_per_image
                    )
                else:
                    # Just use the original face without augmentation
                    augmented_images = [face_image]
                
                # Process each augmented version
                for aug_idx, aug_img in enumerate(augmented_images):
                    # Resize to standard size (112x112 for MobileFaceNet)
                    aug_img_resized = aug_img.resize((112, 112), Image.LANCZOS)
                    
                    # Save processed face
                    face_path = os.path.join(student_dir, f"pose{idx}_aug{aug_idx}.jpg")
                    aug_img_resized.save(face_path)
                    
                    # Generate embedding
                    embedding = self.embedding_generator.generate_embedding(aug_img_resized)
                    embeddings.append(embedding)
                    processed_count += 1
                
                logger.info(f"Processed image {idx}/{len(image_paths)} for {student_id} "
                           f"({len(augmented_images)} variations)")
                
            except Exception as e:
                logger.error(f"Error processing image {idx} for {student_id}: {e}")
                continue
        
        # Check if we got enough valid faces
        if processed_count == 0:
            logger.error(f"No valid faces detected for {student_id}")
            return None
        
        # Calculate expected samples
        expected_samples = len(image_paths) * (augment_per_image if augment_per_image > 0 else 1)
        if processed_count < expected_samples * 0.5:  # Less than 50% of expected
            logger.warning(f"Only {processed_count}/{expected_samples} samples generated for {student_id}")
        
        # Stack embeddings
        embeddings = np.array(embeddings)
        
        # Save embeddings
        embeddings_path = os.path.join(student_dir, "embeddings.npy")
        np.save(embeddings_path, embeddings)
        
        result = {
            'student_id': student_id,
            'num_poses_captured': len([p for p in image_paths if os.path.exists(p)]),
            'num_samples_total': processed_count,
            'embeddings_shape': embeddings.shape,
            'output_dir': student_dir,
            'embeddings_path': embeddings_path,
            'augmentation_per_pose': augment_per_image
        }
        
        logger.info(f"Processed {student_id}: {processed_count} total samples from {len(image_paths)} poses, embeddings saved")
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
    
    def recognize_face(self, image_path, threshold=0.5, allowed_student_ids=None):
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
        
    # Predict (optionally restricted to a list of student IDs)
        prediction = self.classifier.predict(embedding, threshold=threshold, allowed_student_ids=allowed_student_ids)
        
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
