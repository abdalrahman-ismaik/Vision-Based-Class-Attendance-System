"""
detector.py
------------

This module contains a face detector using OpenCV's YuNet (FaceDetectorYN).
YuNet is a lightweight, fast, and accurate face detector that runs efficiently on CPU.

Each bounding box is a tuple ``(x, y, w, h)`` in pixel coordinates relative to the input image.
"""

from __future__ import annotations

import cv2
import numpy as np
import os
from typing import List, Tuple
import logging

logger = logging.getLogger(__name__)


class FaceDetector:
    """Detect faces in an image using OpenCV YuNet."""

    def __init__(self, model_path: str = "face_detection_yunet_2023mar.onnx", 
                 score_threshold: float = 0.6,
                 nms_threshold: float = 0.3,
                 top_k: int = 5000) -> None:
        """Initialize the face detector.

        Parameters
        ----------
        model_path : str
            Path to the .onnx model file.
        score_threshold : float
            Filter out faces with confidence < score_threshold.
        nms_threshold : float
            Suppress bounding boxes with IoU > nms_threshold.
        top_k : int
            Keep top_k bounding boxes before NMS.
        """
        # Locate model file relative to this script if just filename is given
        if not os.path.isabs(model_path):
            current_dir = os.path.dirname(os.path.abspath(__file__))
            model_path = os.path.join(current_dir, model_path)
            
        if not os.path.exists(model_path):
            raise FileNotFoundError(
                f"YuNet model not found at {model_path}. \n"
                "Please download it from: https://github.com/opencv/opencv_zoo/raw/main/models/face_detection_yunet/face_detection_yunet_2023mar.onnx"
            )
            
        self.detector = cv2.FaceDetectorYN.create(
            model=model_path,
            config="",
            input_size=(320, 320), # Initial size, will be updated per frame
            score_threshold=score_threshold,
            nms_threshold=nms_threshold,
            top_k=top_k
        )
        logger.info(f"Face detector initialized with YuNet (threshold={score_threshold})")

    def detect(self, image: np.ndarray) -> List[Tuple[int, int, int, int]]:
        """Run face detection on the provided image.

        Parameters
        ----------
        image : np.ndarray
            A colour image in BGR format (as read by ``cv2.VideoCapture``).

        Returns
        -------
        List[Tuple[int, int, int, int]]
            A list of bounding boxes, where each box is ``(x, y, w, h)``.
        """
        h, w, _ = image.shape
        
        # Update input size for the current frame
        self.detector.setInputSize((w, h))
        
        # Run detection
        # results is a tuple: (conf, faces)
        _, faces = self.detector.detect(image)
        
        bboxes = []
        if faces is not None:
            for face in faces:
                # YuNet returns [x, y, w, h, x_re, y_re, x_le, y_le, x_nt, y_nt, x_rcm, y_rcm, x_lcm, y_lcm, score]
                # We just need the bounding box
                x, y, w, h = face[:4].astype(int)
                
                # Ensure coordinates are within image bounds
                x = max(0, x)
                y = max(0, y)
                w = min(w, image.shape[1] - x)
                h = min(h, image.shape[0] - y)
                
                if w > 0 and h > 0:
                    bboxes.append((x, y, w, h))
        
        return bboxes
