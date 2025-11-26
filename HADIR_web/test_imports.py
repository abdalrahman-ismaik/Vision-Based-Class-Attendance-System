"""Test if all imports work correctly"""
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

print("Testing imports...")

try:
    print("1. Importing detector...")
    from detector import FaceDetector
    print("   ✓ detector imported")
except Exception as e:
    print(f"   ✗ Failed: {e}")

try:
    print("2. Importing face_tracker...")
    from face_tracker import FaceTracker
    print("   ✓ face_tracker imported")
except Exception as e:
    print(f"   ✗ Failed: {e}")

try:
    print("3. Importing backend.database.core...")
    from backend.database.core import load_classes, load_database
    print("   ✓ backend.database.core imported")
except Exception as e:
    print(f"   ✗ Failed: {e}")

try:
    print("4. Importing backend.services.manager...")
    from backend.services.manager import get_pipeline
    print("   ✓ backend.services.manager imported")
except Exception as e:
    print(f"   ✗ Failed: {e}")

try:
    print("5. Importing backend.config.settings...")
    from backend.config.settings import ensure_directories
    print("   ✓ backend.config.settings imported")
except Exception as e:
    print(f"   ✗ Failed: {e}")

print("\nAll imports successful! ✓")
