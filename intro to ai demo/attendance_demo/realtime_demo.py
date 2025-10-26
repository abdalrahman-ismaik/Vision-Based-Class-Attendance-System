"""
realtime_demo.py
-----------------

Launch a real‑time class attendance demo using the components provided
in this package.  This script captures video from a camera or file,
detects faces, computes embeddings using your model (via
``custom_embedder.embed_face``), matches them against a precomputed
gallery, and overlays bounding boxes and names on the video frames.

Usage::

    python realtime_demo.py --gallery attendance_demo/gallery.npz --video_source 0

Arguments:

* ``--gallery``: Path to the gallery ``.npz`` file produced by
  ``enroll.py``.  Defaults to ``attendance_demo/gallery.npz``.
* ``--video_source``: Camera index (int) or path to a video file or
  network stream.  Defaults to ``0`` (the first webcam).
* ``--display``: If specified, show the annotated video in a window.
* ``--save``: Path to save the annotated video; if omitted, no file is
  written.

Press ``q`` in the display window to quit the demo.

Note: Face detection runs on every frame.  For higher performance you
can modify the code to detect less frequently or incorporate a
tracking algorithm.  See the comments in the code for guidance.
"""

from __future__ import annotations

import cv2
import numpy as np
import argparse
import os
from pathlib import Path
from typing import Tuple

from attendance_demo.detector import FaceDetector
from attendance_demo.custom_embedder import embed_face
from attendance_demo.gallery_utils import load_gallery, match_embedding


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run the real‑time attendance demo.")
    parser.add_argument(
        '--gallery',
        type=str,
        default=str(Path(__file__).resolve().parents[0] / 'gallery.npz'),
        help='Path to the gallery npz file created by enroll.py.',
    )
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
    gallery_path = Path(args.gallery)
    if not gallery_path.exists():
        raise FileNotFoundError(f"Gallery file does not exist: {gallery_path}")
    gallery_embeddings, gallery_labels = load_gallery(str(gallery_path))
    print(f"Loaded gallery with {len(gallery_labels)} entries from {gallery_path}")

    # Load face detector
    detector = FaceDetector()

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
        # Iterate through faces and classify
        for (x, y, w, h) in faces:
            # Expand the bounding box slightly to capture full face context
            pad = int(0.1 * max(w, h))
            x0 = max(x - pad, 0)
            y0 = max(y - pad, 0)
            x1 = min(x + w + pad, frame.shape[1])
            y1 = min(y + h + pad, frame.shape[0])
            face_crop = frame[y0:y1, x0:x1]
            embedding = embed_face(face_crop)
            label, score = match_embedding(embedding, gallery_embeddings, gallery_labels)
            # Draw bounding box and label
            cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 255, 0), 2)
            text = f"{label}" if label != 'unknown' else 'Unknown'
            cv2.putText(frame, text, (x, y - 5), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)

        # Display the frame
        if args.display:
            cv2.imshow('Attendance Demo', frame)
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
    print(f"Processed {frame_count} frames.")


if __name__ == '__main__':
    main()