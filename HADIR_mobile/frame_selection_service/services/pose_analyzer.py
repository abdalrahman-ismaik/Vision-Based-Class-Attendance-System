"""
Pose Analyzer Service
Analyzes head pose and body pose using YOLOv7-Pose for multi-person 2D pose estimation
"""

import cv2
import numpy as np
import torch
import os
from typing import Dict, Tuple, Optional, List
import logging
import math
from .yolov7_utils import YOLOv7Utils

logger = logging.getLogger(__name__)

class PoseAnalyzer:
    """Analyze head pose and body pose using YOLOv7-Pose"""
    
    def __init__(self, model_path: Optional[str] = None, input_size: Tuple[int, int] = (960, 960), 
                 conf_threshold: float = 0.25, iou_threshold: float = 0.45):
        """
        Initialize YOLOv7-Pose model
        
        Args:
            model_path: Path to YOLOv7-Pose model file (yolov7-w6-pose.pt)
            input_size: Model input resolution (default 960p letterbox)
            conf_threshold: Confidence threshold for detections
            iou_threshold: IoU threshold for NMS
        """
        self.input_size = input_size
        self.conf_threshold = conf_threshold
        self.iou_threshold = iou_threshold
        
        # Device selection (GPU with CPU fallback)
        self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        logger.info(f"Using device: {self.device}")
        
        # Initialize YOLOv7 utilities
        self.utils = YOLOv7Utils()
        
        # Load model
        self.model = self._load_model(model_path)
        
        if self.model is None:
            logger.warning("YOLOv7-Pose model not loaded. Using fallback OpenCV detection.")
            self._init_fallback_detection()
    
    def _load_model(self, model_path: Optional[str] = None) -> Optional[torch.nn.Module]:
        """Load YOLOv7-Pose model with GPU/CPU fallback"""
        try:
            # Try different model paths
            possible_paths = [
                model_path,
                'models/yolov7-w6-pose.pt', 
                'yolov7-w6-pose.pt',
                '../models/yolov7-w6-pose.pt'
            ]
            
            model_file = None
            for path in possible_paths:
                if path and os.path.exists(path):
                    model_file = path
                    break
            
            if model_file is None:
                logger.info("YOLOv7-Pose model file not found locally. Using simplified pose estimation.")
                # Don't try to download automatically, use fallback instead
                return None
            
            # Load the model
            logger.info(f"Loading YOLOv7-Pose model from {model_file}")
            model = torch.load(model_file, map_location=self.device)
            
            if isinstance(model, dict):
                model = model['model']
            
            model.to(self.device)
            model.eval()
            
            logger.info("YOLOv7-Pose model loaded successfully")
            return model
            
        except Exception as e:
            logger.error(f"Error loading YOLOv7-Pose model: {str(e)}")
            return None
    
    def _init_fallback_detection(self):
        """Initialize OpenCV face detection as fallback"""
        try:
            self.face_cascade = cv2.CascadeClassifier(
                cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
            )
            self.eye_cascade = cv2.CascadeClassifier(
                cv2.data.haarcascades + 'haarcascade_eye.xml'
            )
            self.profile_cascade = cv2.CascadeClassifier(
                cv2.data.haarcascades + 'haarcascade_profileface.xml'
            )
            logger.info("Fallback OpenCV detection initialized")
        except Exception as e:
            logger.error(f"Error initializing fallback detection: {str(e)}")
    
    def analyze_pose(self, frame: np.ndarray) -> Dict[str, any]:
        """
        Analyze pose for the given frame using YOLOv7-Pose
        
        Args:
            frame: Input frame as numpy array (BGR format)
            
        Returns:
            Dictionary with pose analysis results
        """
        try:
            if self.model is not None:
                # Use YOLOv7-Pose detection
                return self._analyze_pose_yolov7(frame)
            else:
                # Fallback to OpenCV detection
                logger.debug("Using fallback OpenCV detection")
                return self._analyze_pose_fallback(frame)
                
        except Exception as e:
            logger.error(f"Error analyzing pose: {str(e)}")
            return {
                'head_pose': {'yaw': 0, 'pitch': 0, 'roll': 0, 'confidence': 0},
                'body_pose': {'landmarks': [], 'confidence': 0, 'keypoints': []},
                'pose_coverage': {'frontal': 0, 'left_profile': 0, 'right_profile': 0},
                'pose_score': 0.0
            }
    
    def _analyze_pose_yolov7(self, frame: np.ndarray) -> Dict[str, any]:
        """Analyze pose using YOLOv7-Pose model"""
        # Preprocess image
        img_tensor, ratio, pad = self.utils.preprocess_image(frame, self.input_size)
        img_tensor = img_tensor.to(self.device)
        
        # Run inference
        with torch.no_grad():
            # Handle different model types
            if hasattr(self.model, 'predict'):  # Ultralytics format
                results = self.model.predict(frame, conf=self.conf_threshold, verbose=False)
                if results and len(results) > 0:
                    keypoints = results[0].keypoints
                    if keypoints is not None:
                        return self._process_ultralytics_results(keypoints)
            else:  # YOLOv7 format
                pred = self.model(img_tensor)[0]
                pred = self.utils.non_max_suppression_kpt(
                    pred, self.conf_threshold, self.iou_threshold, 
                    nc=1, nkpt=17
                )[0]
                
                if pred.numel() > 0:
                    # Scale keypoints back to original image
                    kpts = pred[:, 6:].view(-1, 17, 3)  # Reshape to [N, 17, 3]
                    kpts = self.utils.scale_keypoints(
                        kpts, frame.shape[:2], self.input_size, ratio, pad
                    )
                    
                    return self._process_yolov7_results(kpts, pred, frame.shape[:2])
        
        # No detections found
        return {
            'head_pose': {'yaw': 0, 'pitch': 0, 'roll': 0, 'confidence': 0},
            'body_pose': {'landmarks': [], 'confidence': 0, 'keypoints': []},
            'pose_coverage': {'frontal': 0, 'left_profile': 0, 'right_profile': 0},
            'pose_score': 0.0
        }
    
    def _process_yolov7_results(self, keypoints: torch.Tensor, detections: torch.Tensor, img_shape: Tuple[int, int] = (640, 640)) -> Dict[str, any]:
        """Process YOLOv7-Pose detection results"""
        if keypoints.numel() == 0:
            return self._empty_pose_result()
        
        # Use the detection with highest confidence
        best_detection_idx = torch.argmax(detections[:, 4])
        best_keypoints = keypoints[best_detection_idx].cpu().numpy()
        
        # Extract head pose angles from COCO keypoints
        head_pose = self.utils.extract_pose_angles(best_keypoints)
        
        # Convert keypoints to landmarks format
        landmarks = []
        h, w = img_shape
        for i, (x, y, conf) in enumerate(best_keypoints):
            landmarks.append({
                'x': float(x) / w,  # Normalize to [0, 1]
                'y': float(y) / h,  # Normalize to [0, 1]
                'z': 0.0,  # YOLOv7-Pose doesn't provide Z coordinate
                'visibility': float(conf),
                'keypoint_id': i,
                'keypoint_name': self.utils.COCO_KEYPOINTS[i] if i < len(self.utils.COCO_KEYPOINTS) else f'kpt_{i}'
            })
        
        body_pose = {
            'landmarks': landmarks,
            'confidence': float(torch.mean(keypoints[best_detection_idx][:, 2])),
            'keypoints': best_keypoints.tolist(),
            'detection_confidence': float(detections[best_detection_idx, 4])
        }
        
        # Calculate pose coverage
        pose_coverage = self._calculate_pose_coverage(head_pose, body_pose)
        
        return {
            'head_pose': head_pose,
            'body_pose': body_pose,
            'pose_coverage': pose_coverage,
            'pose_score': self._calculate_pose_score(head_pose, body_pose)
        }
    
    def _process_ultralytics_results(self, keypoints) -> Dict[str, any]:
        """Process Ultralytics YOLO results"""
        if keypoints is None or keypoints.data.numel() == 0:
            return self._empty_pose_result()
        
        # Get keypoints data [N, 17, 3]
        kpts_data = keypoints.data[0].cpu().numpy()  # Take first detection
        
        # Extract head pose angles
        head_pose = self.utils.extract_pose_angles(kpts_data)
        
        # Convert to landmarks format
        landmarks = []
        for i, (x, y, conf) in enumerate(kpts_data):
            landmarks.append({
                'x': float(x) / 640,  # Normalize to [0, 1] - adjust based on image size
                'y': float(y) / 640,
                'z': 0.0,
                'visibility': float(conf),
                'keypoint_id': i,
                'keypoint_name': self.utils.COCO_KEYPOINTS[i] if i < len(self.utils.COCO_KEYPOINTS) else f'kpt_{i}'
            })
        
        body_pose = {
            'landmarks': landmarks,
            'confidence': float(np.mean(kpts_data[:, 2])),
            'keypoints': kpts_data.tolist()
        }
        
        pose_coverage = self._calculate_pose_coverage(head_pose, body_pose)
        
        return {
            'head_pose': head_pose,
            'body_pose': body_pose,
            'pose_coverage': pose_coverage,
            'pose_score': self._calculate_pose_score(head_pose, body_pose)
        }
    
    def _empty_pose_result(self) -> Dict[str, any]:
        """Return empty pose result"""
        return {
            'head_pose': {'yaw': 0, 'pitch': 0, 'roll': 0, 'confidence': 0},
            'body_pose': {'landmarks': [], 'confidence': 0, 'keypoints': []},
            'pose_coverage': {'frontal': 0, 'left_profile': 0, 'right_profile': 0},
            'pose_score': 0.0
        }
    
    def _analyze_pose_fallback(self, frame: np.ndarray) -> Dict[str, any]:
        """Fallback pose analysis using OpenCV face detection"""
        gray_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        
        # Analyze head pose using OpenCV
        head_pose = self._analyze_head_pose_opencv(gray_frame, frame)
        
        # Simplified body pose
        body_pose = self._analyze_body_pose_simple(head_pose)
        
        # Calculate pose coverage
        pose_coverage = self._calculate_pose_coverage(head_pose, body_pose)
        
        return {
            'head_pose': head_pose,
            'body_pose': body_pose,
            'pose_coverage': pose_coverage,
            'pose_score': self._calculate_pose_score(head_pose, body_pose)
        }
    
    def _analyze_head_pose_opencv(self, gray_frame: np.ndarray, color_frame: np.ndarray) -> Dict[str, float]:
        """Fallback head pose analysis using OpenCV face detection"""
        
        # Detect frontal faces
        frontal_faces = self.face_cascade.detectMultiScale(gray_frame, 1.1, 4)
        
        # Detect profile faces
        profile_faces = self.profile_cascade.detectMultiScale(gray_frame, 1.1, 4)
        
        if len(frontal_faces) == 0 and len(profile_faces) == 0:
            return {'yaw': 0, 'pitch': 0, 'roll': 0, 'confidence': 0}
        
        # Use the largest detected face
        if len(frontal_faces) > 0:
            # Frontal face detected
            face = max(frontal_faces, key=lambda f: f[2] * f[3])  # Largest by area
            x, y, w, h = face
            
            # Extract face region for detailed analysis
            face_roi = gray_frame[y:y+h, x:x+w]
            
            # Detect eyes within face region
            eyes = self.eye_cascade.detectMultiScale(face_roi, 1.1, 4)
            
            # Calculate pose based on face geometry
            yaw, pitch, roll, confidence = self._calculate_pose_from_frontal_face(
                face, eyes, gray_frame.shape
            )
            
        else:
            # Only profile face detected
            face = max(profile_faces, key=lambda f: f[2] * f[3])
            yaw, pitch, roll, confidence = self._calculate_pose_from_profile_face(
                face, gray_frame.shape
            )
        
        return {
            'yaw': yaw,
            'pitch': pitch,
            'roll': roll,
            'confidence': confidence
        }
    
    def _analyze_body_pose_simple(self, head_pose: Dict[str, float]) -> Dict[str, any]:
        """Simplified body pose based on head pose (fallback method)"""
        
        # Simplified body pose estimation based on head orientation
        confidence = head_pose.get('confidence', 0)
        
        # Generate simplified body landmarks based on head pose
        landmarks = []
        if confidence > 0.3:
            # Add basic shoulder/neck landmarks estimation
            landmarks = [
                {'x': 0.5, 'y': 0.3, 'z': 0, 'visibility': 0.8, 'keypoint_id': 17, 'keypoint_name': 'neck'},
                {'x': 0.4, 'y': 0.4, 'z': 0, 'visibility': 0.7, 'keypoint_id': 5, 'keypoint_name': 'left_shoulder'},
                {'x': 0.6, 'y': 0.4, 'z': 0, 'visibility': 0.7, 'keypoint_id': 6, 'keypoint_name': 'right_shoulder'},
            ]
        
        return {
            'landmarks': landmarks,
            'confidence': confidence * 0.8,  # Lower confidence for simplified estimation
            'keypoints': []
        }
    
    def _calculate_pose_from_frontal_face(self, face_rect, eyes, frame_shape) -> Tuple[float, float, float, float]:
        """Calculate pose angles from frontal face detection"""
        x, y, w, h = face_rect
        frame_h, frame_w = frame_shape
        
        # Calculate yaw based on face position in frame
        face_center_x = x + w // 2
        frame_center_x = frame_w // 2
        
        # Normalized position (-1 to 1)
        normalized_x = (face_center_x - frame_center_x) / (frame_w // 2)
        yaw = normalized_x * 30  # Scale to roughly -30 to +30 degrees
        
        # Calculate pitch based on face position vertically
        face_center_y = y + h // 2
        frame_center_y = frame_h // 2
        normalized_y = (face_center_y - frame_center_y) / (frame_h // 2)
        pitch = -normalized_y * 20  # Negative because y increases downward
        
        # Calculate roll based on eye positions if eyes detected
        roll = 0
        if len(eyes) >= 2:
            # Sort eyes by x position
            eyes_sorted = sorted(eyes, key=lambda e: e[0])
            if len(eyes_sorted) >= 2:
                left_eye = eyes_sorted[0]
                right_eye = eyes_sorted[1]
                
                # Calculate roll angle
                dy = right_eye[1] - left_eye[1]
                dx = right_eye[0] - left_eye[0]
                if dx != 0:
                    roll = math.atan2(dy, dx) * (180 / math.pi)
                    roll = max(-30, min(30, roll))
        
        # Confidence based on face size and detection quality
        face_area = w * h
        total_area = frame_w * frame_h
        confidence = min(0.9, (face_area / total_area) * 10)  # Higher confidence for larger faces
        
        return yaw, pitch, roll, confidence
    
    def _calculate_pose_from_profile_face(self, face_rect, frame_shape) -> Tuple[float, float, float, float]:
        """Calculate pose angles from profile face detection"""
        x, y, w, h = face_rect
        frame_h, frame_w = frame_shape
        
        # Profile face indicates significant yaw
        face_center_x = x + w // 2
        frame_center_x = frame_w // 2
        
        # Determine left or right profile based on position
        if face_center_x < frame_center_x:
            yaw = -60  # Left profile
        else:
            yaw = 60   # Right profile
        
        # Calculate pitch from vertical position
        face_center_y = y + h // 2
        frame_center_y = frame_h // 2
        normalized_y = (face_center_y - frame_center_y) / (frame_h // 2)
        pitch = -normalized_y * 15  # Less pitch variation in profile
        
        roll = 0  # Difficult to determine from profile
        
        # Lower confidence for profile detection
        face_area = w * h
        total_area = frame_w * frame_h
        confidence = min(0.7, (face_area / total_area) * 8)
        
        return yaw, pitch, roll, confidence
    

    
    def _calculate_pose_coverage(self, head_pose: Dict, body_pose: Dict) -> Dict[str, float]:
        """Calculate pose coverage metrics"""
        yaw = head_pose.get('yaw', 0)
        
        # Define pose categories based on yaw angle
        frontal_score = max(0, 1 - abs(yaw) / 30)  # Full frontal at 0°
        left_profile_score = max(0, (yaw - 20) / 50) if yaw > 20 else 0  # Left profile
        right_profile_score = max(0, (-yaw - 20) / 50) if yaw < -20 else 0  # Right profile
        
        return {
            'frontal': frontal_score,
            'left_profile': left_profile_score,
            'right_profile': right_profile_score
        }
    
    def _calculate_pose_score(self, head_pose: Dict, body_pose: Dict) -> float:
        """Calculate overall pose quality score"""
        head_confidence = head_pose.get('confidence', 0)
        body_confidence = body_pose.get('confidence', 0)
        
        # Combine confidences with weights
        pose_score = 0.7 * head_confidence + 0.3 * body_confidence
        
        return pose_score
    
    def check_pose_coverage_requirements(self, frames_with_poses: list, 
                                       requirements: Dict[str, float]) -> Dict[str, bool]:
        """
        Check if frame set meets pose coverage requirements
        
        Args:
            frames_with_poses: List of (frame, timestamp, pose_data) tuples
            requirements: Dict with required coverage for each pose type
            
        Returns:
            Dict indicating which requirements are met
        """
        coverage_counts = {'frontal': 0, 'left_profile': 0, 'right_profile': 0}
        
        for frame, timestamp, pose_data in frames_with_poses:
            pose_coverage = pose_data.get('pose_coverage', {})
            
            # Count frames that significantly contribute to each pose type
            if pose_coverage.get('frontal', 0) > 0.5:
                coverage_counts['frontal'] += 1
            if pose_coverage.get('left_profile', 0) > 0.5:
                coverage_counts['left_profile'] += 1
            if pose_coverage.get('right_profile', 0) > 0.5:
                coverage_counts['right_profile'] += 1
        
        # Check if requirements are met
        requirements_met = {}
        for pose_type, required_count in requirements.items():
            requirements_met[pose_type] = coverage_counts.get(pose_type, 0) >= required_count
        
        logger.info(f"Pose coverage: {coverage_counts}, Requirements met: {requirements_met}")
        
        return requirements_met