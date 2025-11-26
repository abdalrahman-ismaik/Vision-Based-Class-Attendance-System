"""
face_tracker.py
---------------
Simple face tracking system using IoU-based tracking to maintain labels across frames.
Tracks faces and assigns persistent IDs (face1, face2, etc.)
"""

import numpy as np
from typing import Dict, Tuple, List


class FaceTracker:
    """Track faces across frames and maintain labels"""
    
    def __init__(self, iou_threshold=0.3, max_disappeared=10):
        """
        Args:
            iou_threshold: Minimum IoU to match face between frames
            max_disappeared: Frames before removing disappeared face
        """
        self.next_id = 0
        self.faces: Dict[int, Dict] = {}  # {face_id: {bbox, label, confidence, disappeared}}
        self.iou_threshold = iou_threshold
        self.max_disappeared = max_disappeared
    
    def _calculate_iou(self, box1: Tuple[int, int, int, int], 
                      box2: Tuple[int, int, int, int]) -> float:
        """Calculate Intersection over Union between two bounding boxes"""
        x1, y1, w1, h1 = box1
        x2, y2, w2, h2 = box2
        
        # Convert to (x1, y1, x2, y2) format
        box1_x2, box1_y2 = x1 + w1, y1 + h1
        box2_x2, box2_y2 = x2 + w2, y2 + h2
        
        # Calculate intersection
        inter_x1 = max(x1, x2)
        inter_y1 = max(y1, y2)
        inter_x2 = min(box1_x2, box2_x2)
        inter_y2 = min(box1_y2, box2_y2)
        
        if inter_x2 <= inter_x1 or inter_y2 <= inter_y1:
            return 0.0
        
        inter_area = (inter_x2 - inter_x1) * (inter_y2 - inter_y1)
        box1_area = w1 * h1
        box2_area = w2 * h2
        union_area = box1_area + box2_area - inter_area
        
        return inter_area / union_area if union_area > 0 else 0.0
    
    def update(self, detected_faces: List[Tuple[int, int, int, int]]) -> Dict[int, Dict]:
        """
        Update tracker with new detections
        
        Args:
            detected_faces: List of (x, y, w, h) bounding boxes
        
        Returns:
            Dict mapping face_id to {bbox, label, is_new}
        """
        # Mark all existing faces as potentially disappeared
        for face_id in self.faces:
            self.faces[face_id]['disappeared'] += 1
        
        # Match detected faces to existing tracked faces
        matched = set()
        results = {}
        
        for det_bbox in detected_faces:
            best_match_id = None
            best_iou = self.iou_threshold
            
            # Find best matching existing face
            for face_id, face_data in self.faces.items():
                if face_id in matched:
                    continue
                
                iou = self._calculate_iou(det_bbox, face_data['bbox'])
                if iou > best_iou:
                    best_iou = iou
                    best_match_id = face_id
            
            if best_match_id is not None:
                # Update existing face
                self.faces[best_match_id]['bbox'] = det_bbox
                self.faces[best_match_id]['disappeared'] = 0
                matched.add(best_match_id)
                results[best_match_id] = {
                    'bbox': det_bbox,
                    'label': self.faces[best_match_id]['label'],
                    'confidence': self.faces[best_match_id].get('confidence', 0.0),
                    'student_id': self.faces[best_match_id].get('student_id', ''),
                    'is_new': False
                }
            else:
                # New face detected - assign ID and label
                new_id = self.next_id
                self.next_id += 1
                label = f"face{new_id + 1}"  # face1, face2, face3, etc.
                self.faces[new_id] = {
                    'bbox': det_bbox,
                    'label': label,
                    'confidence': 0.0,
                    'disappeared': 0
                }
                results[new_id] = {
                    'bbox': det_bbox,
                    'label': label,
                    'confidence': 0.0,
                    'is_new': True
                }
        
        # Remove faces that disappeared
        to_remove = [face_id for face_id, face_data in self.faces.items()
                     if face_data['disappeared'] > self.max_disappeared]
        for face_id in to_remove:
            del self.faces[face_id]
        
        return results

    def set_label(self, face_id: int, label: str, confidence: float = 0.0, student_id: str = None):
        """Update label/confidence/student_id for a tracked face."""
        if face_id in self.faces:
            self.faces[face_id]['label'] = label
            self.faces[face_id]['confidence'] = confidence
            if student_id is not None:
                self.faces[face_id]['student_id'] = student_id

