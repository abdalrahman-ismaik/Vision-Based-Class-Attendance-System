"""
enroll.py
---------

Script to build a face gallery from a directory of enrolment images.  It
scans the specified directory for subfolders, where each subfolder's
name is taken as the label (e.g. student name or ID) and contains one
or more face photographs.  Faces are detected in each image using
``FaceDetector`` and passed through the user‑defined ``embed_face``
function to compute embeddings.  All embeddings and their corresponding
labels are saved to a ``.npz`` file for later matching.

Usage::

    python enroll.py --images_dir /path/to/enroll_images --output gallery.npz

Each subdirectory of ``images_dir`` should contain images in formats
recognised by OpenCV (e.g. JPG, PNG).  Images that do not contain a
detectable face will be skipped.  If multiple faces are detected in a
single image, only the largest one is used.

Running this script does not require a GPU or any deep learning
frameworks beyond those used in your face embedding implementation.
"""

from __future__ import annotations

import os
import argparse
from pathlib import Path
from typing import List

import cv2
import numpy as np

# Add the project root to the Python path so imports work when this
# script is executed directly (not as a module).  When running as
# ``python -m attendance_demo.gallery.enroll`` this block has no effect.
import sys
sys.path.append(str(Path(__file__).resolve().parents[1]))  # noqa: E402

from attendance_demo.detector import FaceDetector  # type: ignore  # noqa: E402
from attendance_demo.custom_embedder import embed_face  # type: ignore  # noqa: E402


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Enroll faces into the gallery.")
    parser.add_argument(
        '--images_dir',
        type=str,
        required=True,
        help='Path to the directory containing subfolders of enrolment images.',
    )
    parser.add_argument(
        '--output',
        type=str,
        default='gallery.npz',
        help='Filename for the output gallery (npz) file.',
    )
    parser.add_argument(
        '--min_faces',
        type=int,
        default=1,
        help='Minimum number of detected faces required per person to include in the gallery.',
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    images_dir = Path(args.images_dir)
    output_path = Path(args.output)

    if not images_dir.is_dir():
        raise ValueError(f"Images directory does not exist: {images_dir}")

    detector = FaceDetector()
    embeddings: List[np.ndarray] = []
    labels: List[str] = []

    # Traverse subdirectories; each directory name is the label
    for subdir in sorted(images_dir.iterdir()):
        if not subdir.is_dir():
            continue
        label = subdir.name
        print(f"Enrolling from {label}...")
        faces_embedded = 0
        # Process each image in the subfolder
        for img_path in sorted(subdir.iterdir()):
            if not img_path.is_file():
                continue
            img = cv2.imread(str(img_path))
            if img is None:
                print(f"  Warning: Could not read {img_path}; skipping.")
                continue
            boxes = detector.detect(img)
            if not boxes:
                print(f"  No face detected in {img_path}; skipping.")
                continue
            # Use the largest face (by area) in case of multiple detections
            x, y, w, h = max(boxes, key=lambda b: b[2] * b[3])
            face = img[y : y + h, x : x + w]
            embedding = embed_face(face)
            embeddings.append(embedding.astype(np.float32))
            labels.append(label)
            faces_embedded += 1
        if faces_embedded < args.min_faces:
            print(f"Warning: {label} has only {faces_embedded} valid faces; not enough to include.")
    if not embeddings:
        raise RuntimeError("No faces enrolled; cannot create gallery.")
    # Convert to arrays and save
    embeddings_arr = np.vstack(embeddings).astype(np.float32)
    labels_arr = np.array(labels, dtype=object)
    np.savez(output_path, embeddings=embeddings_arr, labels=labels_arr)
    print(f"Gallery saved to {output_path} with {len(labels)} entries.")


if __name__ == '__main__':
    main()