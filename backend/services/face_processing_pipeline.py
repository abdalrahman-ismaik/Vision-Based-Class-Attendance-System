"""
Face Processing Pipeline
Handles image augmentation, face detection, embedding generation, and classifier training
"""

import os
import sys
import cv2
import torch
import numpy as np
from PIL import Image, ImageEnhance, ImageOps
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
# Path to FaceNet model
DEFAULT_CHECKPOINT = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'storage', 'models', 'mobilefacenet.pth')


class FaceDetector:
    """Face detector using RetinaFace"""
    
    def __init__(self, threshold=0.8):
        """Initialize face detector"""
        try:
            # Try importing from FaceNet utils
            sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'FaceNet'))
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
            # Convert PIL Image (RGB) to numpy array (BGR) for RetinaFace
            image = np.array(image)
            image = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)
        
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
            checkpoint_path = DEFAULT_CHECKPOINT
        
        if not os.path.exists(checkpoint_path):
            # Fallback to original location if not found in storage
            original_path = os.path.join(os.path.dirname(__file__), '..', '..', 'FaceNet', 'mobilefacenet_arcface', 'best_model_epoch43_acc100.00.pth')
            if os.path.exists(original_path):
                checkpoint_path = original_path
                logger.warning(f"Model not found in storage, using fallback: {checkpoint_path}")
            else:
                logger.error(f"Model not found at {checkpoint_path} or {original_path}")

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
        self.mean_embeddings = {}  # Store mean embeddings for cosine similarity fallback
    
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
            
            # Store mean embedding for this student (for cosine similarity fallback)
            # CRITICAL FIX: Calculate mean ONLY from original embeddings (first one per augmentation batch)
            # Assuming augmentations are generated in batches, use only first embedding of each batch
            student_mask = binary_labels == 1
            student_embeddings = embeddings[student_mask]
            
            # For augmented data: if we have exactly 100 embeddings (5 images * 20 augmentations)
            # Take every 20th embedding (the original non-augmented ones)
            n_student_embeddings = len(student_embeddings)
            if n_student_embeddings % 20 == 0:
                # We have augmented data, extract originals
                num_originals = n_student_embeddings // 20
                original_indices = [i * 20 for i in range(num_originals)]
                original_embeddings = student_embeddings[original_indices]
                logger.info(f"    Using {len(original_embeddings)} original embeddings for mean (from {n_student_embeddings} total)")
            else:
                # No augmentation or different ratio, use all
                original_embeddings = student_embeddings
                logger.info(f"    Using all {len(original_embeddings)} embeddings for mean")
            
            # Calculate and normalize mean embedding
            self.mean_embeddings[student_id] = np.mean(original_embeddings, axis=0)
            self.mean_embeddings[student_id] /= np.linalg.norm(self.mean_embeddings[student_id])
            
            # Count positive and negative samples
            n_positive = np.sum(binary_labels == 1)
            n_negative = np.sum(binary_labels == 0)
            
            logger.info(f"    Positive samples: {n_positive}, Negative samples: {n_negative}")
            
            # CRITICAL FIX: Balance the dataset by undersampling negatives
            # Too many negatives causes SVM probability calibration issues
            MAX_NEGATIVE_RATIO = 5  # At most 5x negative samples compared to positive
            
            if n_negative > n_positive * MAX_NEGATIVE_RATIO:
                # Undersample negatives
                negative_indices = np.where(binary_labels == 0)[0]
                positive_indices = np.where(binary_labels == 1)[0]
                
                # Randomly select subset of negatives
                target_negatives = n_positive * MAX_NEGATIVE_RATIO
                selected_negative_indices = np.random.choice(
                    negative_indices, 
                    size=target_negatives, 
                    replace=False
                )
                
                # Combine indices
                selected_indices = np.concatenate([positive_indices, selected_negative_indices])
                np.random.shuffle(selected_indices)
                
                # Create balanced dataset
                embeddings_balanced = embeddings[selected_indices]
                labels_balanced = binary_labels[selected_indices]
                
                logger.info(f"    Undersampled negatives: {n_negative} -> {target_negatives}")
                n_negative = target_negatives
            else:
                embeddings_balanced = embeddings
                labels_balanced = binary_labels
            
            # Handle class imbalance with adjusted weights
            weight_positive = len(labels_balanced) / (2 * n_positive)
            weight_negative = len(labels_balanced) / (2 * n_negative)
            class_weights = {1: weight_positive, 0: weight_negative}
            
            # Split data
            X_train, X_test, y_train, y_test = train_test_split(
                embeddings_balanced, labels_balanced, 
                test_size=0.2, 
                random_state=42,
                stratify=labels_balanced  # Maintain class balance in splits
            )
            
            # Train binary SVM classifier with class weights
            # IMPROVEMENT: Increase C for better margin and use RBF kernel for non-linear boundaries
            classifier = SVC(
                kernel='rbf',  # RBF kernel can capture non-linear patterns better
                probability=True, 
                C=10.0,  # Higher C for stricter classification
                gamma='scale',  # Automatic gamma scaling
                class_weight=class_weights
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
        
        logger.info(f"  [Classifier] Starting prediction...")
        logger.info(f"  [Classifier]   Embedding shape: {embedding.shape}")
        logger.info(f"  [Classifier]   Threshold: {threshold}")
        logger.info(f"  [Classifier]   Allowed students: {allowed_student_ids}")
        logger.info(f"  [Classifier]   Total trained classifiers: {len(self.classifiers)}")
        
        embedding = embedding.reshape(1, -1)
        
        # Determine which classifiers to consult
        if allowed_student_ids is None:
            iter_classifiers = self.classifiers.items()
            logger.info(f"  [Classifier]   Using all {len(self.classifiers)} classifiers")
        else:
            # Filter to allowed students and ignore missing ones
            iter_classifiers = [
                (sid, self.classifiers[sid])
                for sid in allowed_student_ids if sid in self.classifiers
            ]
            logger.info(f"  [Classifier]   Using {len(iter_classifiers)} classifiers (from {len(allowed_student_ids)} allowed)")
            missing = [sid for sid in allowed_student_ids if sid not in self.classifiers]
            if missing:
                logger.warning(f"  [Classifier]   Missing classifiers for: {missing}")

        # Get predictions from the selected classifiers
        predictions = {}
        decision_scores = {}  # Store decision function values for debugging
        cosine_similarities = {}  # Store cosine similarities for comparison
        
        for student_id, classifier in iter_classifiers:
            # Get decision function value (distance from hyperplane)
            decision_value = classifier.decision_function(embedding)[0]
            decision_scores[student_id] = float(decision_value)
            
            # Predict probability for positive class (this student)
            proba = classifier.predict_proba(embedding)[0]
            positive_proba = proba[1] if len(proba) > 1 else proba[0]

            predictions[student_id] = float(positive_proba)
            
            # Also calculate cosine similarity with mean embedding
            if student_id in self.mean_embeddings:
                cosine_sim = np.dot(embedding.flatten(), self.mean_embeddings[student_id])
                cosine_similarities[student_id] = float(cosine_sim)
            
            logger.debug(f"  [Classifier]     {student_id}: prob={positive_proba:.4f}, decision={decision_value:.4f}, cosine={cosine_similarities.get(student_id, 0):.4f}")
        
        logger.info(f"  [Classifier]   Got predictions for {len(predictions)} students")
        logger.info(f"  [Classifier]   Decision function values: {decision_scores}")
        logger.info(f"  [Classifier]   Cosine similarities: {cosine_similarities}")
        
        if len(predictions) == 0:
            # No classifiers available in the allowed set
            logger.warning(f"  [Classifier] ✗ No classifiers available")
            return {
                'label': 'Unknown',
                'confidence': 0.0,
                'all_predictions': predictions,
                'threshold_used': threshold
            }

        # Find student with highest confidence
        best_student_svm = max(predictions, key=predictions.get)
        best_confidence_svm = predictions[best_student_svm]
        
        # Also check cosine similarity
        best_student_cosine = max(cosine_similarities, key=cosine_similarities.get) if cosine_similarities else None
        best_similarity = cosine_similarities.get(best_student_cosine, 0) if best_student_cosine else 0
        
        logger.info(f"  [Classifier]   Best SVM match: {best_student_svm} with confidence {best_confidence_svm:.4f}")
        if best_student_cosine:
            logger.info(f"  [Classifier]   Best cosine match: {best_student_cosine} with similarity {best_similarity:.4f}")
        
        # Use cosine similarity as fallback if SVM confidence is low but cosine similarity is high
        # Typical good cosine similarity threshold is 0.5-0.6 (higher = more strict)
        COSINE_THRESHOLD = 0.60
        MIN_MARGIN = 0.03  # Minimum difference between best and second-best match (lowered from 0.05)
        
        # Check margin: best match should be significantly better than second-best
        if len(cosine_similarities) >= 2:
            sorted_sims = sorted(cosine_similarities.items(), key=lambda x: x[1], reverse=True)
            best_sim_value = sorted_sims[0][1]
            second_best_sim_value = sorted_sims[1][1]
            margin = best_sim_value - second_best_sim_value
            logger.info(f"  [Classifier]   Cosine similarity margin: {margin:.4f} (best: {best_sim_value:.4f}, second: {second_best_sim_value:.4f})")
        else:
            margin = 1.0  # Only one student, no ambiguity
        
        # NEW LOGIC: Use SVM result first, confirm with cosine similarity
        # Get cosine similarity for the best SVM prediction
        svm_student_cosine = cosine_similarities.get(best_student_svm, 0.0)
        logger.info(f"  [Classifier]   Best SVM student ({best_student_svm}) cosine similarity: {svm_student_cosine:.4f}")
        
        # 1. Check if SVM prediction is confirmed by cosine similarity
        if svm_student_cosine >= COSINE_THRESHOLD and margin >= MIN_MARGIN:
            # SVM prediction has good cosine similarity and margin - ACCEPT
            logger.info(f"  [Classifier] ✓ SVM prediction confirmed by cosine (SVM conf={best_confidence_svm:.4f}, cosine={svm_student_cosine:.4f} >= {COSINE_THRESHOLD}, margin={margin:.4f})")
            return {
                'label': best_student_svm,
                'confidence': svm_student_cosine,  # Use cosine as confidence
                'all_predictions': predictions,
                'cosine_similarities': cosine_similarities,
                'method': 'svm_confirmed_by_cosine',
                'svm_confidence': best_confidence_svm,
                'margin': margin,
                'threshold_used': COSINE_THRESHOLD
            }
        elif svm_student_cosine >= COSINE_THRESHOLD and margin < MIN_MARGIN:
            # SVM prediction has good cosine but margin too small - AMBIGUOUS
            logger.warning(f"  [Classifier] ✗ Cosine similarity margin too small ({margin:.4f} < {MIN_MARGIN}), ambiguous match")
            return {
                'label': 'Unknown',
                'confidence': svm_student_cosine,
                'all_predictions': predictions,
                'cosine_similarities': cosine_similarities,
                'reason': 'ambiguous_match',
                'margin': margin,
                'threshold_used': COSINE_THRESHOLD
            }
        else:
            # SVM prediction NOT confirmed by cosine - check if best cosine match is different
            logger.warning(f"  [Classifier] ✗ SVM prediction ({best_student_svm}) cosine {svm_student_cosine:.4f} below threshold {COSINE_THRESHOLD}")
            
            if best_student_cosine != best_student_svm and best_similarity >= COSINE_THRESHOLD and margin >= MIN_MARGIN:
                # Best cosine match is different from SVM and meets criteria - use it as fallback
                logger.info(f"  [Classifier] → Using best cosine match ({best_student_cosine}) as fallback (SVM picked wrong student)")
                return {
                    'label': best_student_cosine,
                    'confidence': best_similarity,
                    'all_predictions': predictions,
                    'cosine_similarities': cosine_similarities,
                    'method': 'cosine_fallback',
                    'svm_confidence': predictions.get(best_student_cosine, 0.0),
                    'margin': margin,
                    'threshold_used': COSINE_THRESHOLD
                }
            else:
                # No student meets criteria - REJECT
                logger.warning(f"  [Classifier] ✗ No student meets threshold (best SVM cosine={svm_student_cosine:.4f}, best cosine={best_similarity:.4f})")
                return {
                    'label': 'Unknown',
                    'confidence': best_confidence_svm,
                    'all_predictions': predictions,
                    'cosine_similarities': cosine_similarities,
                    'threshold_used': COSINE_THRESHOLD
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
                'student_ids': self.student_ids,
                'mean_embeddings': self.mean_embeddings
            }, f)
        
        logger.info(f"Classifiers saved to {filepath} (with mean embeddings)")
    
    def load(self, filepath):
        """Load classifiers from file"""
        with open(filepath, 'rb') as f:
            data = pickle.load(f)
        
        self.classifiers = data['classifiers']
        self.student_ids = data['student_ids']
        # Load mean_embeddings if available (for backward compatibility)
        self.mean_embeddings = data.get('mean_embeddings', {})
        self.is_trained = True
        
        logger.info(f"Loaded {len(self.classifiers)} classifiers from {filepath}")
        if self.mean_embeddings:
            logger.info(f"  ✓ Loaded mean embeddings for {len(self.mean_embeddings)} students")
        else:
            logger.warning(f"  ⚠ No mean embeddings found - cosine similarity fallback disabled")


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
        image = Image.open(image_path)
        
        # Fix orientation based on EXIF
        try:
            image = ImageOps.exif_transpose(image)
        except Exception as e:
            logger.warning(f"Could not apply EXIF transpose: {e}")
            
        image = image.convert('RGB')
        
        # Detect faces
        bboxes = self.face_detector.detect_faces(image)
        
        # If no faces detected, try rotating
        if len(bboxes) == 0:
            logger.info(f"No face detected in initial orientation, trying rotations...")
            for angle in [90, 180, 270]:
                rotated_image = image.rotate(-angle, expand=True)
                bboxes = self.face_detector.detect_faces(rotated_image)
                if len(bboxes) > 0:
                    logger.info(f"Face detected after rotating {angle} degrees")
                    image = rotated_image
                    break
        
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
                logger.info(f"Step 1/3: Loading and detecting face in image {idx}/{len(image_paths)}")
                # Load image
                image = Image.open(image_path)
                
                # Fix orientation based on EXIF
                try:
                    image = ImageOps.exif_transpose(image)
                except Exception as e:
                    logger.warning(f"Could not apply EXIF transpose: {e}")
                
                image = image.convert('RGB')
                
                # Detect faces
                bboxes = self.face_detector.detect_faces(image)
                
                # If no faces detected, try rotating
                if len(bboxes) == 0:
                    logger.info(f"No face detected in initial orientation for image {idx}, trying rotations...")
                    for angle in [90, 180, 270]:
                        rotated_image = image.rotate(-angle, expand=True) # Rotate clockwise
                        bboxes = self.face_detector.detect_faces(rotated_image)
                        if len(bboxes) > 0:
                            logger.info(f"Face detected after rotating {angle} degrees")
                            image = rotated_image
                            break
                
                if len(bboxes) == 0:
                    logger.warning(f"No face detected in image {idx} for {student_id} (tried all orientations)")
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
                
                logger.info(f"Step 2/3: Generating {augment_per_image} augmentations for image {idx}")
                # Apply augmentation if requested
                if augment_per_image > 0:
                    # Generate augmentations for this pose
                    augmented_images = self.augmentor.generate_augmentations(
                        face_image, num_augmentations=augment_per_image
                    )
                else:
                    # Just use the original face without augmentation
                    augmented_images = [face_image]
                
                logger.info(f"Step 3/3: Generating embeddings for {len(augmented_images)} variations of image {idx}")
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
        
        logger.info(f"=== Starting face recognition for: {image_path} ===")
        logger.info(f"  Threshold: {threshold}")
        logger.info(f"  Allowed students: {allowed_student_ids}")
        
        # Load image
        image = Image.open(image_path)
        logger.info(f"  Image loaded: size={image.size}, mode={image.mode}")
        
        # Fix orientation based on EXIF
        try:
            image = ImageOps.exif_transpose(image)
        except Exception as e:
            logger.warning(f"Could not apply EXIF transpose: {e}")
            
        image = image.convert('RGB')
        
        # Detect faces
        logger.info(f"  Detecting faces in image...")
        bboxes = self.face_detector.detect_faces(image)
        logger.info(f"  Detected {len(bboxes)} face(s)")
        
        # If no faces detected, try rotating
        if len(bboxes) == 0:
            logger.warning(f"  No faces detected, trying rotation...")
            for angle in [90, 180, 270]:
                rotated_image = image.rotate(-angle, expand=True)
                bboxes = self.face_detector.detect_faces(rotated_image)
                if len(bboxes) > 0:
                    logger.info(f"  Found face after {angle}° rotation")
                    image = rotated_image
                    break
        
        if len(bboxes) == 0:
            logger.error(f"  ✗ No face detected in image after all attempts")
            return {'error': 'No face detected'}
        
        # Process first face
        bbox = bboxes[0]
        x1, y1, x2, y2 = map(int, bbox)
        logger.info(f"  Using first face: bbox=({x1}, {y1}, {x2}, {y2})")
        
        # Add margin
        w = x2 - x1
        h = y2 - y1
        margin = 0.2
        x1 = max(0, x1 - int(w * margin))
        y1 = max(0, y1 - int(h * margin))
        x2 = min(image.width, x2 + int(w * margin))
        y2 = min(image.height, y2 + int(h * margin))
        logger.info(f"  Face bbox with margin: ({x1}, {y1}, {x2}, {y2})")
        
        # Crop face
        face_image = image.crop((x1, y1, x2, y2))
        logger.info(f"  Cropped face: size={face_image.size}")
        
        # Generate embedding
        logger.info(f"  Generating face embedding...")
        embedding = self.embedding_generator.generate_embedding(face_image)
        logger.info(f"  Embedding generated: shape={embedding.shape}, dtype={embedding.dtype}")
        logger.info(f"  Embedding stats: min={embedding.min():.4f}, max={embedding.max():.4f}, mean={embedding.mean():.4f}")
        
        # Predict (optionally restricted to a list of student IDs)
        logger.info(f"  Running classifier prediction...")
        prediction = self.classifier.predict(embedding, threshold=threshold, allowed_student_ids=allowed_student_ids)
        logger.info(f"  Prediction result: {prediction}")
        logger.info(f"=== Face recognition complete ===")
        
        return {
            'bbox': [x1, y1, x2, y2],
            'prediction': prediction
        }
    
    def recognize_face_from_crop(self, face_crop_path, threshold=0.5, allowed_student_ids=None):
        """
        Recognize face from an already-cropped face image (skips face detection)
        
        Args:
            face_crop_path: Path to cropped face image
            threshold: Confidence threshold
            allowed_student_ids: Optional list of student IDs to restrict recognition to
        
        Returns:
            dict with recognition results
        """
        if not self.classifier.is_trained:
            raise ValueError("Classifier not trained yet!")
        
        logger.info(f"=== Starting face recognition from crop: {face_crop_path} ===")
        logger.info(f"  Threshold: {threshold}")
        logger.info(f"  Allowed students: {allowed_student_ids}")
        
        # Load image
        image = Image.open(face_crop_path)
        logger.info(f"  Image loaded: size={image.size}, mode={image.mode}")
        
        # Fix orientation based on EXIF
        try:
            image = ImageOps.exif_transpose(image)
        except Exception as e:
            logger.warning(f"Could not apply EXIF transpose: {e}")
            
        image = image.convert('RGB')
        logger.info(f"  Image converted to RGB: size={image.size}")
        
        # Generate embedding directly (skip face detection since already cropped)
        logger.info(f"  Generating face embedding from crop...")
        embedding = self.embedding_generator.generate_embedding(image)
        logger.info(f"  Embedding generated: shape={embedding.shape}, dtype={embedding.dtype}")
        logger.info(f"  Embedding stats: min={embedding.min():.4f}, max={embedding.max():.4f}, mean={embedding.mean():.4f}")
        
        # Predict (optionally restricted to a list of student IDs)
        logger.info(f"  Running classifier prediction...")
        prediction = self.classifier.predict(embedding, threshold=threshold, allowed_student_ids=allowed_student_ids)
        logger.info(f"  Prediction result: {prediction}")
        logger.info(f"=== Face recognition complete ===")
        
        return {
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
