"""
detector.py
------------

This module contains a simple face detector using OpenCV's Haar cascade.
It wraps the cascade classifier in a class that exposes a single method
``detect`` returning bounding boxes for all detected faces in a given
image.  Each bounding box is a tuple ``(x, y, w, h)`` in pixel
coordinates relative to the input image.

The Haar cascade is not state‑of‑the‑art but is included with OpenCV and
requires no additional downloads.  For improved detection accuracy you
could replace this with a more modern detector such as RetinaFace,
MediaPipe Face Detection, or YOLOv8‑face.
"""

from __future__ import annotations

import cv2
from typing import List, Tuple


class FaceDetector:
    """Detect faces in an image using a Haar cascade classifier."""

    def __init__(self, scale_factor: float = 1.1, min_neighbors: int = 5, min_size: Tuple[int, int] = (30, 30)) -> None:
        """Initialise the face detector.

        Parameters
        ----------
        scale_factor : float, optional
            Parameter specifying how much the image size is reduced at
            each image scale.  See OpenCV's ``detectMultiScale`` for
            details.  Lower values yield more accurate but slower
            detection.
        min_neighbors : int, optional
            Parameter specifying how many neighbours each candidate
            rectangle should have to retain it.  Higher values reduce
            false positives.
        min_size : tuple of int, optional
            Minimum possible object size.  Objects smaller than this are
            ignored.
        """
        cascade_path = cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
        self.classifier = cv2.CascadeClassifier(cascade_path)
        if self.classifier.empty():
            raise IOError(f"Failed to load Haar cascade from {cascade_path}")
        self.scale_factor = scale_factor
        self.min_neighbors = min_neighbors
        self.min_size = min_size

    def detect(self, image) -> List[Tuple[int, int, int, int]]:
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
        # Convert to grayscale as Haar cascades work on single channel images
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        faces = self.classifier.detectMultiScale(
            gray,
            scaleFactor=self.scale_factor,
            minNeighbors=self.min_neighbors,
            minSize=self.min_size,
            flags=cv2.CASCADE_SCALE_IMAGE,
        )
        # Convert to Python list of tuples for consistency
        return [(int(x), int(y), int(w), int(h)) for (x, y, w, h) in faces]