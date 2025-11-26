"""
Script to retrain the classifier from scratch using all processed embeddings
"""

import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.manager import get_pipeline, retrain_classifier
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)

def main():
    """Retrain classifier from all processed embeddings"""
    logger.info("=" * 80)
    logger.info("RETRAINING CLASSIFIER FROM SCRATCH")
    logger.info("=" * 80)
    
    # Get pipeline
    pipeline = get_pipeline()
    if pipeline is None:
        logger.error("Failed to initialize pipeline")
        return False
    
    # Retrain classifier
    result = retrain_classifier()
    
    if result is None:
        logger.error("Failed to retrain classifier")
        return False
    
    logger.info("=" * 80)
    logger.info("TRAINING COMPLETE!")
    logger.info("=" * 80)
    logger.info(f"Number of students: {result.get('n_students')}")
    logger.info(f"Number of embeddings: {result.get('n_embeddings')}")
    
    metrics = result.get('metrics', {})
    logger.info(f"Average test accuracy: {metrics.get('average_test_accuracy', 0):.3f}")
    logger.info(f"Average test F1: {metrics.get('average_test_f1', 0):.3f}")
    
    logger.info("\nPer-student metrics:")
    for student_id, student_metrics in metrics.get('per_student_metrics', {}).items():
        logger.info(f"  {student_id}:")
        logger.info(f"    Test accuracy: {student_metrics.get('test_accuracy', 0):.3f}")
        logger.info(f"    Test F1: {student_metrics.get('test_f1', 0):.3f}")
        logger.info(f"    Positive samples: {student_metrics.get('n_positive', 0)}")
        logger.info(f"    Negative samples: {student_metrics.get('n_negative', 0)}")
    
    logger.info("=" * 80)
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
