import threading
import logging
import os
from backend.services.face_processing_pipeline import FaceProcessingPipeline
from backend.config.settings import STORAGE_DIR

logger = logging.getLogger(__name__)

# Initialize face processing pipeline (lazy loading)
_pipeline = None
_pipeline_lock = threading.Lock()

def get_pipeline():
    """Get or initialize face processing pipeline with auto-loading classifier"""
    global _pipeline
    if _pipeline is None:
        with _pipeline_lock:
            if _pipeline is None:
                try:
                    logger.info("Initializing face processing pipeline...")
                    _pipeline = FaceProcessingPipeline()
                    
                    # Try multiple possible classifier locations
                    classifier_paths = [
                        os.path.join(STORAGE_DIR, "models", "face_classifier.pkl"),
                        os.path.join(STORAGE_DIR, "classifiers", "face_classifier.pkl"),
                        os.path.join(STORAGE_DIR, "models", "classifier.pkl")
                    ]
                    
                    classifier_loaded = False
                    for classifier_path in classifier_paths:
                        if os.path.exists(classifier_path):
                            try:
                                logger.info(f"Loading classifier from {classifier_path}")
                                _pipeline.classifier.load(classifier_path)
                                logger.info(f"✓ Classifier loaded successfully with {len(_pipeline.classifier.student_ids)} students")
                                logger.info(f"  Students in classifier: {', '.join(_pipeline.classifier.student_ids)}")
                                classifier_loaded = True
                                break
                            except Exception as load_error:
                                logger.warning(f"Failed to load classifier from {classifier_path}: {load_error}")
                                continue
                    
                    if not classifier_loaded:
                        logger.warning("No classifier loaded - tried all possible locations:")
                        for path in classifier_paths:
                            logger.warning(f"  - {path} {'(exists)' if os.path.exists(path) else '(not found)'}")
                        logger.info("You need to train the classifier before recognition will work")
                    
                    logger.info("Face processing pipeline initialized successfully")
                except Exception as e:
                    logger.error(f"Failed to initialize pipeline: {e}")
                    _pipeline = None
    return _pipeline


def retrain_classifier():
    """
    Retrain the classifier from existing processed embeddings.
    Call this after registering new students or updating student data.
    
    Returns:
        dict with training results or None if failed
    """
    pipeline = get_pipeline()
    if pipeline is None:
        logger.error("Cannot retrain: pipeline not initialized")
        return None
    
    try:
        processed_dir = os.path.join(STORAGE_DIR, "processed")
        # Use models directory (matches settings.py CLASSIFIERS_FOLDER)
        classifier_path = os.path.join(STORAGE_DIR, "models", "face_classifier.pkl")
        
        if not os.path.exists(processed_dir):
            logger.error(f"Processed directory not found: {processed_dir}")
            return None
        
        # Count students with embeddings
        student_dirs = [d for d in os.listdir(processed_dir) 
                       if os.path.isdir(os.path.join(processed_dir, d)) 
                       and os.path.exists(os.path.join(processed_dir, d, "embeddings.npy"))]
        
        if len(student_dirs) < 2:
            logger.error(f"Need at least 2 students with embeddings to train. Found: {len(student_dirs)}")
            return None
        
        logger.info(f"Retraining classifier with {len(student_dirs)} students...")
        result = pipeline.train_classifier_from_data(processed_dir, classifier_path)
        logger.info(f"✓ Classifier retrained successfully")
        
        return result
        
    except Exception as e:
        logger.error(f"Failed to retrain classifier: {e}", exc_info=True)
        return None
