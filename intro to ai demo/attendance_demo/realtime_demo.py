"""
realtime_demo.py
-----------------

Launch a real‑time class attendance demo with face tracking.
Tracks faces across frames and assigns persistent labels (face1, face2, etc.)

Usage::

    python realtime_demo.py --video_source 0 --display

Arguments:

* ``--video_source``: Camera index (int) or path to a video file or
  network stream.  Defaults to ``0`` (the first webcam).
* ``--display``: If specified, show the annotated video in a window.
* ``--save``: Path to save the annotated video; if omitted, no file is
  written.

Press ``q`` in the display window to quit the demo.
"""

from __future__ import annotations

import cv2
import numpy as np
import argparse
import os
from pathlib import Path
from typing import Tuple

from attendance_demo.detector import FaceDetector
from attendance_demo.face_tracker import FaceTracker


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run the real‑time attendance demo with face tracking.")
    parser.add_argument(
        '--video_source',
        type=str,
        default='0',
        help='Video source (camera index or file/stream path).  Defaults to 0.',
    )
    parser.add_argument(
        '--display',
        action='store_true',
        help='Display the annotated video in a window.',
    )
    parser.add_argument(
        '--save',
        type=str,
        default='',
        help='Optional path to save the annotated video (e.g. output.mp4).',
    )
    return parser.parse_args()


def open_video_source(src: str) -> cv2.VideoCapture:
    """Open a video capture from a camera index or file/stream path."""
    # If the source is a digit, interpret as camera index
    if src.isdigit():
        cap = cv2.VideoCapture(int(src))
    else:
        cap = cv2.VideoCapture(src)
    if not cap.isOpened():
        raise IOError(f"Failed to open video source {src}")
    return cap


def main() -> None:
    args = parse_args()

    # Initialize face detector and tracker
    detector = FaceDetector()
    tracker = FaceTracker(iou_threshold=0.3, max_disappeared=10)
    
    print("✓ Face detector initialized")
    print("✓ Face tracker initialized")
    print("\nStarting live face tracking...")
    print("Press 'q' to quit\n")

    # Open the video source
    cap = open_video_source(args.video_source)

    # Prepare video writer if saving
    writer = None
    if args.save:
        fourcc = cv2.VideoWriter_fourcc(*'mp4v')
        fps = cap.get(cv2.CAP_PROP_FPS) or 25.0
        width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        writer = cv2.VideoWriter(args.save, fourcc, fps, (width, height))
        print(f"Saving annotated video to {args.save} at {fps:.2f} FPS")

    frame_count = 0
    while True:
        ret, frame = cap.read()
        if not ret or frame is None:
            break
        frame_count += 1

        # Detect faces on this frame
        faces = detector.detect(frame)
        
        # Update tracker with detected faces
        tracked_faces = tracker.update(faces)
        
        # Draw bounding boxes and labels for tracked faces
        for face_id, face_data in tracked_faces.items():
            x, y, w, h = face_data['bbox']
            label = face_data['label']
            is_new = face_data.get('is_new', False)
            
            # Color: green for tracked faces
            color = (0, 255, 0)
            
            # Draw bounding box
            cv2.rectangle(frame, (x, y), (x + w, y + h), color, 2)
            
            # Draw label background
            text = label
            (text_w, text_h), _ = cv2.getTextSize(text, cv2.FONT_HERSHEY_SIMPLEX, 0.6, 2)
            cv2.rectangle(frame, (x, y - text_h - 10), (x + text_w, y), color, -1)
            
            # Draw label text
            cv2.putText(frame, text, (x, y - 5), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
            
            # Print to console when new face appears
            if is_new:
                print(f"  [NEW] {label} detected at frame {frame_count}")

        # Display the frame
        if args.display:
            cv2.imshow('Face Tracking Demo', frame)
            # Exit on 'q'
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
        # Save the frame
        if writer is not None:
            writer.write(frame)

    cap.release()
    if writer is not None:
        writer.release()
    if args.display:
        cv2.destroyAllWindows()
    print(f"\nProcessed {frame_count} frames.")


if __name__ == '__main__':
    main()