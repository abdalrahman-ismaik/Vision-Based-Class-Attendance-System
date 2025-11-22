"""
Services Module
Contains business logic and processing services including face recognition and attendance processing.
"""

from .face_processing_pipeline import FaceProcessingPipeline
from .opencv_face_processor import OpenCVFaceProcessor

__all__ = ['FaceProcessingPipeline', 'OpenCVFaceProcessor']
