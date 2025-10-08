"""
Quality Assessor Service
Evaluates frame quality using sharpness, brightness, and blur detection
"""

import cv2
import numpy as np
from typing import Dict
import logging

logger = logging.getLogger(__name__)

class QualityAssessor:
    """Assess frame quality using multiple metrics"""
    
    def __init__(self, 
                 min_sharpness: float = 100.0,
                 min_brightness: float = 50.0,
                 max_brightness: float = 200.0):
        """
        Initialize quality assessor
        
        Args:
            min_sharpness: Minimum acceptable sharpness (Laplacian variance)
            min_brightness: Minimum acceptable brightness
            max_brightness: Maximum acceptable brightness
        """
        self.min_sharpness = min_sharpness
        self.min_brightness = min_brightness
        self.max_brightness = max_brightness
    
    def assess_quality(self, frame: np.ndarray) -> Dict[str, float]:
        """
        Assess frame quality across multiple metrics
        
        Args:
            frame: Input frame as numpy array
            
        Returns:
            Dictionary with quality metrics and overall score
        """
        try:
            # Convert to grayscale for some metrics
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            
            # Calculate individual metrics
            sharpness = self._calculate_sharpness(gray)
            brightness = self._calculate_brightness(gray)
            contrast = self._calculate_contrast(gray)
            blur_score = self._calculate_blur_score(gray)
            
            # Calculate overall quality score (0-1)
            quality_score = self._calculate_overall_quality(
                sharpness, brightness, contrast, blur_score
            )
            
            return {
                'sharpness': sharpness,
                'brightness': brightness,
                'contrast': contrast,
                'blur_score': blur_score,
                'quality_score': quality_score,
                'passes_threshold': quality_score >= 0.6  # Adjustable threshold
            }
            
        except Exception as e:
            logger.error(f"Error assessing frame quality: {str(e)}")
            return {
                'sharpness': 0.0,
                'brightness': 0.0,
                'contrast': 0.0,
                'blur_score': 0.0,
                'quality_score': 0.0,
                'passes_threshold': False
            }
    
    def _calculate_sharpness(self, gray_frame: np.ndarray) -> float:
        """Calculate sharpness using Laplacian variance"""
        laplacian = cv2.Laplacian(gray_frame, cv2.CV_64F)
        return laplacian.var()
    
    def _calculate_brightness(self, gray_frame: np.ndarray) -> float:
        """Calculate average brightness"""
        return np.mean(gray_frame)
    
    def _calculate_contrast(self, gray_frame: np.ndarray) -> float:
        """Calculate contrast using standard deviation"""
        return np.std(gray_frame)
    
    def _calculate_blur_score(self, gray_frame: np.ndarray) -> float:
        """
        Calculate blur score using focus measure
        Higher score = less blur
        """
        # Sobel edge detection for focus measure
        sobelx = cv2.Sobel(gray_frame, cv2.CV_64F, 1, 0, ksize=3)
        sobely = cv2.Sobel(gray_frame, cv2.CV_64F, 0, 1, ksize=3)
        
        # Calculate gradient magnitude
        gradient_magnitude = np.sqrt(sobelx**2 + sobely**2)
        return np.mean(gradient_magnitude)
    
    def _calculate_overall_quality(self, sharpness: float, brightness: float, 
                                 contrast: float, blur_score: float) -> float:
        """
        Calculate overall quality score (0-1) based on individual metrics
        
        Uses normalized and weighted combination of metrics
        """
        # Normalize sharpness (typical range: 0-1000+)
        norm_sharpness = min(sharpness / 500.0, 1.0)
        
        # Normalize brightness (0-255 range, ideal around 100-150)
        if brightness < self.min_brightness:
            norm_brightness = brightness / self.min_brightness
        elif brightness > self.max_brightness:
            norm_brightness = (255 - brightness) / (255 - self.max_brightness)
        else:
            norm_brightness = 1.0
        
        # Normalize contrast (typical range: 0-100+)
        norm_contrast = min(contrast / 50.0, 1.0)
        
        # Normalize blur score (typical range: 0-100+)
        norm_blur = min(blur_score / 50.0, 1.0)
        
        # Weighted combination (adjust weights based on importance)
        quality_score = (
            0.3 * norm_sharpness +
            0.2 * norm_brightness +
            0.2 * norm_contrast +
            0.3 * norm_blur
        )
        
        return min(quality_score, 1.0)
    
    def filter_quality_frames(self, frames_with_quality: list, 
                            quality_threshold: float = 0.6) -> list:
        """
        Filter frames that meet quality threshold
        
        Args:
            frames_with_quality: List of (frame, timestamp, quality_dict) tuples
            quality_threshold: Minimum quality score to keep frame
            
        Returns:
            Filtered list of frames meeting quality requirements
        """
        filtered_frames = []
        
        for frame, timestamp, quality in frames_with_quality:
            if quality['quality_score'] >= quality_threshold:
                filtered_frames.append((frame, timestamp, quality))
        
        logger.info(f"Quality filter: {len(filtered_frames)}/{len(frames_with_quality)} "
                   f"frames passed threshold {quality_threshold}")
        
        return filtered_frames