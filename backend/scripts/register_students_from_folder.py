#!/usr/bin/env python3
"""Batch register students whose images already exist under uploads/students."""

import argparse
import json
import logging
import os
import sys
import uuid
from datetime import datetime
from typing import Dict, List, Optional

# Ensure backend directory is on the path so we can import the pipeline
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BACKEND_ROOT = os.path.dirname(SCRIPT_DIR)
if BACKEND_ROOT not in sys.path:
    sys.path.insert(0, BACKEND_ROOT)

from services.face_processing_pipeline import FaceProcessingPipeline  # noqa: E402

DATABASE_FILE = os.path.join(BACKEND_ROOT, 'database.json')
DEFAULT_UPLOADS_DIR = os.path.join(BACKEND_ROOT, 'uploads', 'students')
PROCESSED_DIR = os.path.join(BACKEND_ROOT, 'processed_faces')
CLASSIFIER_DIR = os.path.join(BACKEND_ROOT, 'classifiers')
CLASSIFIER_PATH = os.path.join(CLASSIFIER_DIR, 'classifier.pkl')

ALLOWED_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.bmp'}

logging.basicConfig(level=logging.INFO, format='[%(levelname)s] %(message)s')
logger = logging.getLogger(__name__)


def load_json(path: str) -> Dict:
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as handle:
            try:
                return json.load(handle)
            except json.JSONDecodeError:
                logger.warning("Database file %s is corrupted. Starting with empty data.", path)
                return {}
    return {}


def save_json(path: str, data: Dict) -> None:
    with open(path, 'w', encoding='utf-8') as handle:
        json.dump(data, handle, indent=2)


def load_metadata(path: Optional[str]) -> Dict:
    if not path:
        return {}
    expanded = os.path.abspath(path)
    if not os.path.exists(expanded):
        logger.warning("Metadata file %s not found. Proceeding without it.", expanded)
        return {}
    with open(expanded, 'r', encoding='utf-8') as handle:
        return json.load(handle)


def collect_image_paths(folder: str) -> List[str]:
    images = []
    for entry in sorted(os.listdir(folder)):
        full_path = os.path.join(folder, entry)
        if os.path.isfile(full_path) and os.path.splitext(entry)[1].lower() in ALLOWED_EXTENSIONS:
            images.append(full_path)
    return images


def infer_profile(student_id: str, metadata: Dict, email_domain: Optional[str]) -> Dict:
    info = metadata.get(student_id, {})
    name = info.get('name') or info.get('full_name') or f"Student {student_id}"
    email = info.get('email')
    if not email and email_domain:
        email = f"{student_id}@{email_domain}"
    profile = {
        'name': name,
        'email': email or '',
        'department': info.get('department', info.get('dept', '')),
        'year': info.get('year')
    }
    return profile


def register_student(student_id: str, image_paths: List[str], profile: Dict, pipeline: FaceProcessingPipeline,
                     database: Dict, force: bool) -> bool:
    if student_id in database and not force:
        logger.info("Skipping %s (already registered)", student_id)
        return False

    record = {
        'uuid': str(uuid.uuid4()),
        'student_id': student_id,
        'name': profile['name'],
        'email': profile['email'],
        'department': profile['department'],
        'year': profile['year'],
        'image_paths': image_paths,
        'num_poses': len(image_paths),
        'registered_at': datetime.now().isoformat(),
        'processing_status': 'processing'
    }
    database[student_id] = record
    save_json(DATABASE_FILE, database)
    logger.info("Processing %s (%d images)", student_id, len(image_paths))

    try:
        result = pipeline.process_student_images(
            image_paths=image_paths,
            student_id=student_id,
            output_dir=PROCESSED_DIR,
            augment_per_image=20
        )
    except Exception as exc:
        logger.error("Processing failed for %s: %s", student_id, exc)
        record['processing_status'] = 'failed'
        record['processing_error'] = str(exc)
        save_json(DATABASE_FILE, database)
        return False

    if not result:
        record['processing_status'] = 'failed'
        record['processing_error'] = 'No valid faces detected'
        save_json(DATABASE_FILE, database)
        return False

    record.update({
        'processing_status': 'completed',
        'processed_at': datetime.now().isoformat(),
        'num_poses_captured': result.get('num_poses_captured'),
        'num_samples_total': result.get('num_samples_total'),
        'embeddings_path': result.get('embeddings_path')
    })
    save_json(DATABASE_FILE, database)
    logger.info("✓ %s registered and processed", student_id)
    return True


def train_classifier(pipeline: FaceProcessingPipeline) -> None:
    os.makedirs(CLASSIFIER_DIR, exist_ok=True)
    try:
        train_result = pipeline.train_classifier_from_data(
            data_dir=PROCESSED_DIR,
            classifier_output_path=CLASSIFIER_PATH
        )
        metrics = train_result.get('metrics', {})
        accuracy = metrics.get('average_test_accuracy')
        logger.info("Classifier trained on %d students. Avg accuracy: %s",
                    metrics.get('n_students', train_result.get('n_students')), f"{accuracy:.3f}" if accuracy else 'N/A')
    except ValueError as exc:
        logger.warning("Classifier training skipped: %s", exc)
    except Exception as exc:
        logger.error("Classifier training failed: %s", exc)


def resolve_folder(folder_arg: Optional[str]) -> str:
    if not folder_arg:
        return DEFAULT_UPLOADS_DIR
    folder = folder_arg
    if not os.path.isabs(folder):
        folder = os.path.join(BACKEND_ROOT, folder)
    return os.path.abspath(folder)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Register every student folder found under uploads/students")
    parser.add_argument('--folder', help='Folder that contains per-student subdirectories', default=None)
    parser.add_argument('--metadata', help='Optional JSON file with per-student metadata', default=None)
    parser.add_argument('--email-domain', help='Domain to append when metadata omits email', default='ku.ac.ae')
    parser.add_argument('--force', action='store_true', help='Reprocess students that already exist in database')
    parser.add_argument('--limit', type=int, help='Process only the first N students', default=None)
    parser.add_argument('--no-train', action='store_true', help='Skip classifier retraining after registration')
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    target_folder = resolve_folder(args.folder)
    if not os.path.exists(target_folder):
        logger.error("Folder %s does not exist", target_folder)
        sys.exit(1)

    os.makedirs(PROCESSED_DIR, exist_ok=True)

    metadata = load_metadata(args.metadata)
    database = load_json(DATABASE_FILE)
    student_dirs = [d for d in sorted(os.listdir(target_folder))
                    if os.path.isdir(os.path.join(target_folder, d))]

    if args.limit is not None:
        student_dirs = student_dirs[:args.limit]

    if not student_dirs:
        logger.warning("No student directories found in %s", target_folder)
        return

    logger.info("Discovered %d student folder(s)", len(student_dirs))
    pipeline = FaceProcessingPipeline()

    registered_count = 0
    for student_id in student_dirs:
        student_folder = os.path.join(target_folder, student_id)
        images = collect_image_paths(student_folder)
        if not images:
            logger.warning("Skipping %s (no images found)", student_id)
            continue

        profile = infer_profile(student_id, metadata, args.email_domain)
        success = register_student(student_id, images, profile, pipeline, database, args.force)
        if success:
            registered_count += 1

    logger.info("Registration completed. %d student(s) processed.", registered_count)

    if registered_count > 0 and not args.no_train:
        train_classifier(pipeline)
    elif registered_count == 0:
        logger.info("No new students were registered. Skipping classifier training.")


if __name__ == '__main__':
    main()
