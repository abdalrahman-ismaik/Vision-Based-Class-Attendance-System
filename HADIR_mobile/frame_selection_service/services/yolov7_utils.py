"""
YOLOv7 Utilities for Pose Estimation
Contains utilities for YOLOv7-Pose model inference, letterbox preprocessing, and keypoint processing
"""

import torch
import cv2
import numpy as np
from typing import Tuple, List, Dict, Optional
import logging

logger = logging.getLogger(__name__)

class YOLOv7Utils:
    """Utilities for YOLOv7-Pose model inference and processing"""
    
    # COCO 17 keypoints format (different from MediaPipe's 33)
    COCO_KEYPOINTS = [
        'nose',           # 0
        'left_eye',       # 1
        'right_eye',      # 2
        'left_ear',       # 3
        'right_ear',      # 4
        'left_shoulder',  # 5
        'right_shoulder', # 6
        'left_elbow',     # 7
        'right_elbow',    # 8
        'left_wrist',     # 9
        'right_wrist',    # 10
        'left_hip',       # 11
        'right_hip',      # 12
        'left_knee',      # 13
        'right_knee',     # 14
        'left_ankle',     # 15
        'right_ankle'     # 16
    ]
    
    # Skeleton connections for visualization
    SKELETON = [
        [16, 14], [14, 12], [17, 15], [15, 13], [12, 13],
        [6, 12], [7, 13], [6, 7], [6, 8], [7, 9],
        [8, 10], [9, 11], [2, 3], [1, 2], [1, 3],
        [2, 4], [3, 5], [4, 6], [5, 7]
    ]
    
    @staticmethod
    def letterbox(img: np.ndarray, new_shape: Tuple[int, int] = (640, 640), 
                  color: Tuple[int, int, int] = (114, 114, 114), 
                  auto: bool = True, scaleFill: bool = False, 
                  scaleup: bool = True, stride: int = 32) -> Tuple[np.ndarray, float, Tuple[int, int]]:
        """
        Resize and pad image while maintaining aspect ratio (letterbox)
        
        Args:
            img: Input image
            new_shape: Target size (height, width)
            color: Padding color
            auto: Minimum rectangle
            scaleFill: Stretch to fill
            scaleup: Allow upscaling
            stride: Stride for padding
            
        Returns:
            Tuple of (processed_image, scale_ratio, padding)
        """
        shape = img.shape[:2]  # current shape [height, width]
        
        if isinstance(new_shape, int):
            new_shape = (new_shape, new_shape)
        
        # Scale ratio (new / old)
        r = min(new_shape[0] / shape[0], new_shape[1] / shape[1])
        if not scaleup:  # only scale down, do not scale up (for better val mAP)
            r = min(r, 1.0)
        
        # Compute padding
        ratio = r, r  # width, height ratios
        new_unpad = int(round(shape[1] * r)), int(round(shape[0] * r))
        dw, dh = new_shape[1] - new_unpad[0], new_shape[0] - new_unpad[1]  # wh padding
        
        if auto:  # minimum rectangle
            dw, dh = np.mod(dw, stride), np.mod(dh, stride)  # wh padding
        elif scaleFill:  # stretch
            dw, dh = 0.0, 0.0
            new_unpad = (new_shape[1], new_shape[0])
            ratio = new_shape[1] / shape[1], new_shape[0] / shape[0]  # width, height ratios
        
        dw /= 2  # divide padding into 2 sides
        dh /= 2
        
        if shape[::-1] != new_unpad:  # resize
            img = cv2.resize(img, new_unpad, interpolation=cv2.INTER_LINEAR)
        
        top, bottom = int(round(dh - 0.1)), int(round(dh + 0.1))
        left, right = int(round(dw - 0.1)), int(round(dw + 0.1))
        img = cv2.copyMakeBorder(img, top, bottom, left, right, cv2.BORDER_CONSTANT, value=color)
        
        return img, ratio, (dw, dh)
    
    @staticmethod
    def preprocess_image(img: np.ndarray, input_size: Tuple[int, int] = (960, 960)) -> Tuple[torch.Tensor, float, Tuple[int, int]]:
        """
        Preprocess image for YOLOv7-Pose inference
        
        Args:
            img: Input image (BGR format)
            input_size: Model input size
            
        Returns:
            Tuple of (preprocessed_tensor, scale_ratio, padding)
        """
        # Letterbox resize
        img_resized, ratio, pad = YOLOv7Utils.letterbox(img, new_shape=input_size, auto=False)
        
        # Convert BGR to RGB
        img_rgb = cv2.cvtColor(img_resized, cv2.COLOR_BGR2RGB)
        
        # Normalize to [0, 1] and convert to tensor
        img_tensor = torch.from_numpy(img_rgb).float() / 255.0
        
        # Rearrange dimensions from HWC to CHW
        img_tensor = img_tensor.permute(2, 0, 1)
        
        # Add batch dimension
        img_tensor = img_tensor.unsqueeze(0)
        
        return img_tensor, ratio, pad
    
    @staticmethod
    def non_max_suppression_kpt(prediction: torch.Tensor, conf_thres: float = 0.25, 
                               iou_thres: float = 0.45, classes: Optional[List[int]] = None, 
                               agnostic: bool = False, multi_label: bool = False, 
                               labels: Optional[List] = None, max_det: int = 300, 
                               nc: int = 1, nkpt: int = 17) -> List[torch.Tensor]:
        """
        Non-Maximum Suppression (NMS) on inference results with keypoints
        
        Args:
            prediction: Model output tensor
            conf_thres: Confidence threshold
            iou_thres: IoU threshold for NMS
            classes: Filter by class
            agnostic: Class-agnostic NMS
            multi_label: Multiple labels per box
            labels: Label format
            max_det: Maximum detections per image
            nc: Number of classes
            nkpt: Number of keypoints
            
        Returns:
            List of detections with keypoints
        """
        if nc == 1:
            nc = prediction.shape[2] - nkpt * 3 - 5  # number of classes
        
        mi = 5 + nc + nkpt * 3  # mask start index
        xc = prediction[..., 4] > conf_thres  # candidates
        
        # Settings
        max_wh = 7680  # (pixels) maximum box width and height
        max_nms = 30000  # maximum number of boxes into torchvision.ops.nms()
        time_limit = 0.3 + 0.03 * prediction.shape[0]  # seconds to quit after
        redundant = True  # require redundant detections
        multi_label &= nc > 1  # multiple labels per box (adds 0.5ms/img)
        merge = False  # use merge-NMS
        
        output = [torch.zeros((0, 6 + nkpt * 3), device=prediction.device)] * prediction.shape[0]
        
        for xi, x in enumerate(prediction):  # image index, image inference
            x = x[xc[xi]]  # confidence
            
            # If none remain process next image
            if not x.shape[0]:
                continue
            
            # Compute conf
            x[:, 5:5 + nc] *= x[:, 4:5]  # conf = obj_conf * cls_conf
            
            # Box (center x, center y, width, height) to (x1, y1, x2, y2)
            box = YOLOv7Utils.xywh2xyxy(x[:, :4])
            kpt = x[:, 6:].view(x.shape[0], nkpt, 3)
            
            # Detections matrix nx6 (xyxy, conf, cls)
            if multi_label:
                i, j = (x[:, 5:mi] > conf_thres).nonzero(as_tuple=False).T
                x = torch.cat((box[i], x[i, j + 5, None], j[:, None].float(), kpt[i]), 1)
            else:  # best class only
                conf, j = x[:, 5:mi].max(1, keepdim=True)
                x = torch.cat((box, conf, j.float(), kpt.view(x.shape[0], nkpt * 3)), 1)[conf.view(-1) > conf_thres]
            
            # Filter by class
            if classes is not None:
                x = x[(x[:, 5:6] == torch.tensor(classes, device=x.device)).any(1)]
            
            # Check shape
            n = x.shape[0]  # number of boxes
            if not n:  # no boxes
                continue
            elif n > max_nms:  # excess boxes
                x = x[x[:, 4].argsort(descending=True)[:max_nms]]  # sort by confidence
            
            # Batched NMS
            c = x[:, 5:6] * (0 if agnostic else max_wh)  # classes
            boxes, scores = x[:, :4] + c, x[:, 4]  # boxes (offset by class), scores
            i = torch.ops.torchvision.nms(boxes, scores, iou_thres)  # NMS
            if i.shape[0] > max_det:  # limit detections
                i = i[:max_det]
            
            output[xi] = x[i]
        
        return output
    
    @staticmethod
    def xywh2xyxy(x: torch.Tensor) -> torch.Tensor:
        """Convert boxes from [x, y, w, h] to [x1, y1, x2, y2] format"""
        y = x.clone() if isinstance(x, torch.Tensor) else np.copy(x)
        y[:, 0] = x[:, 0] - x[:, 2] / 2  # top left x
        y[:, 1] = x[:, 1] - x[:, 3] / 2  # top left y
        y[:, 2] = x[:, 0] + x[:, 2] / 2  # bottom right x
        y[:, 3] = x[:, 1] + x[:, 3] / 2  # bottom right y
        return y
    
    @staticmethod
    def scale_keypoints(keypoints: torch.Tensor, img_shape: Tuple[int, int], 
                       input_shape: Tuple[int, int], ratio: Tuple[float, float], 
                       pad: Tuple[int, int]) -> torch.Tensor:
        """
        Scale keypoints back to original image coordinates
        
        Args:
            keypoints: Keypoints tensor [N, 17, 3] (x, y, confidence)
            img_shape: Original image shape (H, W)
            input_shape: Model input shape (H, W)
            ratio: Scale ratios (w_ratio, h_ratio)
            pad: Padding (dw, dh)
            
        Returns:
            Scaled keypoints tensor
        """
        if keypoints.numel() == 0:
            return keypoints
        
        # Clone to avoid modifying original
        kpts = keypoints.clone()
        
        # Scale back from input size to original size
        kpts[:, :, 0] -= pad[0]  # x padding 
        kpts[:, :, 1] -= pad[1]  # y padding
        kpts[:, :, 0] /= ratio[0]  # x ratio
        kpts[:, :, 1] /= ratio[1]  # y ratio
        
        # Clip to image bounds
        kpts[:, :, 0] = torch.clamp(kpts[:, :, 0], 0, img_shape[1])
        kpts[:, :, 1] = torch.clamp(kpts[:, :, 1], 0, img_shape[0])
        
        return kpts
    
    @staticmethod
    def extract_pose_angles(keypoints: np.ndarray) -> Dict[str, float]:
        """
        Extract head pose angles from COCO keypoints
        
        Args:
            keypoints: Keypoints array [17, 3] (x, y, confidence)
            
        Returns:
            Dictionary with yaw, pitch, roll angles
        """
        try:
            # Extract key facial keypoints
            nose = keypoints[0]  # nose
            left_eye = keypoints[1]  # left_eye  
            right_eye = keypoints[2]  # right_eye
            left_ear = keypoints[3]  # left_ear
            right_ear = keypoints[4]  # right_ear
            
            # Check if key points are visible (confidence > 0.3)
            key_points = [nose, left_eye, right_eye, left_ear, right_ear]
            visible_points = [p for p in key_points if len(p) > 2 and p[2] > 0.3]
            
            if len(visible_points) < 2:
                return {'yaw': 0.0, 'pitch': 0.0, 'roll': 0.0, 'confidence': 0.0}
            
            # Calculate yaw (left-right rotation)
            yaw = YOLOv7Utils._calculate_yaw_from_keypoints(
                nose, left_eye, right_eye, left_ear, right_ear
            )
            
            # Calculate pitch (up-down rotation)  
            pitch = YOLOv7Utils._calculate_pitch_from_keypoints(
                nose, left_eye, right_eye
            )
            
            # Calculate roll (head tilt)
            roll = YOLOv7Utils._calculate_roll_from_keypoints(
                left_eye, right_eye, left_ear, right_ear
            )
            
            # Calculate confidence based on keypoint visibility
            confidence = min(1.0, len(visible_points) / 5.0 * 
                           np.mean([p[2] for p in visible_points]))
            
            return {
                'yaw': yaw,
                'pitch': pitch, 
                'roll': roll,
                'confidence': confidence
            }
            
        except Exception as e:
            logger.warning(f"Error extracting pose angles: {str(e)}")
            return {'yaw': 0.0, 'pitch': 0.0, 'roll': 0.0, 'confidence': 0.0}
    
    @staticmethod
    def _calculate_yaw_from_keypoints(nose, left_eye, right_eye, left_ear, right_ear) -> float:
        """Calculate yaw angle from facial keypoints"""
        # Use eye and ear positions to estimate head rotation
        if left_eye[2] > 0.3 and right_eye[2] > 0.3:
            eye_center_x = (left_eye[0] + right_eye[0]) / 2
            eye_distance = abs(right_eye[0] - left_eye[0])
            
            if nose[2] > 0.3 and eye_distance > 0:
                # Nose position relative to eye center indicates yaw
                nose_offset = nose[0] - eye_center_x
                yaw_ratio = nose_offset / eye_distance
                yaw = np.arctan(yaw_ratio) * (180 / np.pi)
                return np.clip(yaw, -90, 90)
        
        # Fallback: use ear visibility for profile detection
        left_ear_visible = left_ear[2] > 0.3 if len(left_ear) > 2 else False
        right_ear_visible = right_ear[2] > 0.3 if len(right_ear) > 2 else False
        
        if left_ear_visible and not right_ear_visible:
            return -45  # Left profile
        elif right_ear_visible and not left_ear_visible:
            return 45   # Right profile
        
        return 0.0
    
    @staticmethod
    def _calculate_pitch_from_keypoints(nose, left_eye, right_eye) -> float:
        """Calculate pitch angle from facial keypoints"""
        if nose[2] > 0.3 and left_eye[2] > 0.3 and right_eye[2] > 0.3:
            eye_center_y = (left_eye[1] + right_eye[1]) / 2
            nose_eye_distance = nose[1] - eye_center_y
            
            # Estimate pitch based on nose-eye vertical relationship
            pitch = np.arctan2(nose_eye_distance, 50) * (180 / np.pi)
            return np.clip(pitch, -45, 45)
        
        return 0.0
    
    @staticmethod
    def _calculate_roll_from_keypoints(left_eye, right_eye, left_ear, right_ear) -> float:
        """Calculate roll angle from facial keypoints"""
        # Primary: use eye positions
        if left_eye[2] > 0.3 and right_eye[2] > 0.3:
            dy = right_eye[1] - left_eye[1]
            dx = right_eye[0] - left_eye[0]
            if abs(dx) > 1e-6:
                roll = np.arctan2(dy, dx) * (180 / np.pi)
                return np.clip(roll, -45, 45)
        
        # Fallback: use ear positions
        if left_ear[2] > 0.3 and right_ear[2] > 0.3:
            dy = right_ear[1] - left_ear[1]
            dx = right_ear[0] - left_ear[0]
            if abs(dx) > 1e-6:
                roll = np.arctan2(dy, dx) * (180 / np.pi)
                return np.clip(roll, -30, 30)
        
        return 0.0