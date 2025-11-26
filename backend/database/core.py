import json
import os
import logging
from backend.config.settings import DATABASE_FILE, CLASSES_FILE

logger = logging.getLogger(__name__)

def load_database():
    """Load the student database from JSON file."""
    if os.path.exists(DATABASE_FILE):
        try:
            with open(DATABASE_FILE, 'r') as f:
                return json.load(f)
        except json.JSONDecodeError:
            logger.warning("Database file is corrupted. Starting fresh.")
            return {}
    return {}


def save_database(data):
    """Save the student database to JSON file."""
    with open(DATABASE_FILE, 'w') as f:
        json.dump(data, f, indent=2)


def load_classes():
    """Load the classes database from JSON file."""
    if os.path.exists(CLASSES_FILE):
        try:
            with open(CLASSES_FILE, 'r') as f:
                return json.load(f)
        except json.JSONDecodeError:
            logger.warning("Classes file is corrupted. Starting fresh.")
            return {}
    return {}


def save_classes(data):
    """Save the classes database to JSON file."""
    with open(CLASSES_FILE, 'w') as f:
        json.dump(data, f, indent=2)
