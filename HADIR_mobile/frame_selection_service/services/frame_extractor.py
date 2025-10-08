"""
Frame Extractor Service
Handles efficient video frame extraction using OpenCV
"""

import cv2
import numpy as np
import tempfile
import os
from typing import List, Tuple
import logging

logger = logging.getLogger(__name__)

class FrameExtractor:
    """Extract frames from video files with efficient processing"""
    
    def __init__(self, max_frames: int = 300):
        """
        Initialize frame extractor
        
        Args:
            max_frames: Maximum number of frames to extract to prevent memory issues
        """
        self.max_frames = max_frames
    
    def extract_frames(self, video_path: str, sample_rate: int = 1) -> List[Tuple[np.ndarray, float]]:
        """
        Extract frames from video file
        
        Args:
            video_path: Path to video file
            sample_rate: Extract every nth frame (1 = all frames)
            
        Returns:
            List of tuples (frame_array, timestamp)
        """
        frames = []
        
        try:
            cap = cv2.VideoCapture(video_path)
            
            if not cap.isOpened():
                raise ValueError(f"Cannot open video file: {video_path}")
            
            fps = cap.get(cv2.CAP_PROP_FPS)
            frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            
            logger.info(f"Processing video: {fps} FPS, {frame_count} frames")
            
            # Calculate sampling to stay within max_frames limit
            if frame_count > self.max_frames:
                sample_rate = max(sample_rate, frame_count // self.max_frames)
                logger.info(f"Adjusting sample rate to {sample_rate} to limit frames")
            
            frame_idx = 0
            while True:
                ret, frame = cap.read()
                if not ret:
                    break
                
                # Sample frames at specified rate
                if frame_idx % sample_rate == 0:
                    timestamp = frame_idx / fps
                    frames.append((frame, timestamp))
                
                frame_idx += 1
                
                # Safety limit
                if len(frames) >= self.max_frames:
                    logger.warning(f"Reached maximum frame limit: {self.max_frames}")
                    break
            
            cap.release()
            logger.info(f"Extracted {len(frames)} frames from video")
            
        except Exception as e:
            logger.error(f"Error extracting frames: {str(e)}")
            raise
        
        return frames
    
    def save_temp_video(self, video_data: bytes) -> str:
        """
        Save uploaded video data to temporary file
        
        Args:
            video_data: Raw video bytes
            
        Returns:
            Path to temporary video file
        """
        temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.mp4')
        temp_file.write(video_data)
        temp_file.close()
        
        return temp_file.name
    
    def cleanup_temp_file(self, file_path: str):
        """Clean up temporary file"""
        try:
            if os.path.exists(file_path):
                os.unlink(file_path)
                logger.info(f"Cleaned up temporary file: {file_path}")
        except Exception as e:
            logger.warning(f"Failed to cleanup temp file {file_path}: {str(e)}")