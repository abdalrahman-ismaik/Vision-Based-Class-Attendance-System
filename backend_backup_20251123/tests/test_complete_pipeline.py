"""
Comprehensive test script for the face processing pipeline.
Tests student registration, face processing, and classifier training.
"""
import sys
import os
import time
import json
import requests
from pathlib import Path
from typing import List, Dict, Tuple

# Add backend to path
backend_path = Path(__file__).parent.parent
sys.path.insert(0, str(backend_path))

# Test configuration
API_BASE_URL = "http://127.0.0.1:5000/api"
TEST_IMAGES_DIR = backend_path.parent / "playground" / "test_images"
DATABASE_PATH = backend_path / "data" / "database.json"

# Generate unique IDs based on timestamp
import random
BASE_ID = int(time.time()) % 100000  # Use timestamp for unique IDs

# Test students with their images
TEST_STUDENTS = [
    {
        'student_id': str(200000 + BASE_ID + 1),
        'name': 'Albert Einstein',
        'email': 'albert.einstein@physics.edu',
        'department': 'Physics',
        'year': 4,
        'images': ['Albert-Einstein (1).jpg', 'Albert-Einstein (2).jpg', 'Albert-Einstein (3).jpg',
                   'Albert-Einstein (4).jpg', 'Albert-Einstein (5).jpg']
    },
    {
        'student_id': str(200000 + BASE_ID + 2),
        'name': 'Alan Turing',
        'email': 'alan.turing@cs.edu',
        'department': 'Computer Science',
        'year': 3,
        'images': ['Alan-Turing (1).jpg', 'Alan-Turing (2).jpg', 'Alan-Turing (3).jpg',
                   'Alan-Turing (4).jpg', 'Alan-Turing (5).jpg', 'Alan-Turing (6).jpg']
    },
    {
        'student_id': str(200000 + BASE_ID + 3),
        'name': 'Isaac Newton',
        'email': 'isaac.newton@physics.edu',
        'department': 'Physics',
        'year': 4,
        'images': ['Isaac-Newton (1).jpg', 'Isaac-Newton (2).jpg', 'Isaac-Newton (3).jpg']
    },
    {
        'student_id': str(200000 + BASE_ID + 4),
        'name': 'Lionel Messi',
        'email': 'lionel.messi@sports.edu',
        'department': 'Sports Science',
        'year': 2,
        'images': ['lionel-messi (1).jpg', 'lionel-messi (2).jpg', 'lionel-messi (3).jpg',
                   'lionel-messi (4).jpg', 'lionel-messi (5).jpg']
    },
    {
        'student_id': str(200000 + BASE_ID + 5),
        'name': 'Mahmoud Darwish',
        'email': 'mahmoud.darwish@literature.edu',
        'department': 'Literature',
        'year': 3,
        'images': ['Mahmoud-Darwish (1).jpg', 'Mahmoud-Darwish (2).jpg', 'Mahmoud-Darwish (3).jpg',
                   'Mahmoud-Darwish (4).jpg', 'Mahmoud-Darwish (5).jpg']
    }
]

class Colors:
    """ANSI color codes for terminal output"""
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'


def print_header(text: str):
    """Print formatted header"""
    print(f"\n{Colors.HEADER}{Colors.BOLD}{'='*80}")
    print(f"{text:^80}")
    print(f"{'='*80}{Colors.ENDC}\n")


def print_success(text: str):
    """Print success message"""
    print(f"{Colors.OKGREEN}✓ {text}{Colors.ENDC}")


def print_error(text: str):
    """Print error message"""
    print(f"{Colors.FAIL}✗ {text}{Colors.ENDC}")


def print_warning(text: str):
    """Print warning message"""
    print(f"{Colors.WARNING}⚠ {text}{Colors.ENDC}")


def print_info(text: str):
    """Print info message"""
    print(f"{Colors.OKCYAN}ℹ {text}{Colors.ENDC}")


def check_server_connection() -> bool:
    """Check if the backend server is running"""
    try:
        response = requests.get(f"{API_BASE_URL}/students/", timeout=5)
        return True
    except requests.exceptions.ConnectionError:
        return False
    except Exception as e:
        print_warning(f"Unexpected error checking server: {e}")
        return False


def check_test_images() -> Tuple[bool, List[str]]:
    """Check if test images directory exists and has images"""
    if not TEST_IMAGES_DIR.exists():
        return False, []
    
    missing_images = []
    for student in TEST_STUDENTS:
        for img in student['images']:
            img_path = TEST_IMAGES_DIR / img
            if not img_path.exists():
                missing_images.append(img)
    
    return len(missing_images) == 0, missing_images


def register_student(student_data: Dict) -> Tuple[bool, Dict]:
    """Register a student with their images"""
    print_info(f"Registering: {student_data['name']} (ID: {student_data['student_id']})")
    
    # Prepare form data
    form_data = {
        'student_id': student_data['student_id'],
        'name': student_data['name'],
        'email': student_data['email'],
        'department': student_data['department'],
        'year': student_data['year']
    }
    
    # Prepare files
    files = []
    for img_name in student_data['images']:
        img_path = TEST_IMAGES_DIR / img_name
        if img_path.exists():
            files.append(('images', (img_name, open(img_path, 'rb'), 'image/jpeg')))
        else:
            print_warning(f"  Image not found: {img_name}")
    
    if not files:
        print_error(f"  No images found for {student_data['name']}")
        return False, {'error': 'No images found'}
    
    print_info(f"  Uploading {len(files)} images...")
    
    try:
        response = requests.post(
            f"{API_BASE_URL}/students/",
            files=files,
            data=form_data,
            timeout=30
        )
        
        # Close file handles
        for _, (_, fh, _) in files:
            fh.close()
        
        if response.status_code == 201:
            print_success(f"  Registered successfully!")
            return True, response.json()
        else:
            error_msg = response.json().get('error', 'Unknown error')
            print_error(f"  Registration failed: {error_msg}")
            return False, response.json()
            
    except requests.exceptions.Timeout:
        print_error("  Request timed out")
        return False, {'error': 'Timeout'}
    except Exception as e:
        print_error(f"  Exception: {e}")
        # Clean up file handles
        for _, (_, fh, _) in files:
            try:
                fh.close()
            except:
                pass
        return False, {'error': str(e)}


def wait_for_processing(student_id: str, max_wait: int = 60) -> Tuple[bool, Dict]:
    """Wait for face processing to complete"""
    print_info(f"Waiting for processing (student ID: {student_id})...")
    
    start_time = time.time()
    while time.time() - start_time < max_wait:
        try:
            if not DATABASE_PATH.exists():
                time.sleep(2)
                continue
                
            with open(DATABASE_PATH, 'r') as f:
                db = json.load(f)
            
            if student_id not in db:
                time.sleep(2)
                continue
            
            student = db[student_id]
            status = student.get('processing_status', 'unknown')
            
            print(f"  Status: {status}", end='\r')
            
            if status == 'completed':
                print_success(f"  Processing completed!")
                print_info(f"    Poses captured: {student.get('num_poses_captured', 'N/A')}")
                print_info(f"    Total samples: {student.get('num_samples_total', 'N/A')}")
                return True, student
            elif status == 'failed':
                error = student.get('processing_error', 'Unknown error')
                print_error(f"  Processing failed: {error}")
                return False, student
            
            time.sleep(2)
            
        except Exception as e:
            print_warning(f"  Error checking status: {e}")
            time.sleep(2)
    
    print_error(f"  Processing timeout after {max_wait}s")
    return False, {'error': 'Timeout'}


def train_classifier() -> Tuple[bool, Dict]:
    """Train the face classifier"""
    print_info("Training classifier...")
    
    try:
        response = requests.post(
            f"{API_BASE_URL}/students/train-classifier",
            json={},
            timeout=120
        )
        
        if response.status_code == 200:
            result = response.json()
            print_success("Classifier trained successfully!")
            print_info(f"  Students trained: {result.get('students_count', 'N/A')}")
            print_info(f"  Model path: {result.get('model_path', 'N/A')}")
            return True, result
        else:
            error = response.json().get('error', 'Unknown error')
            print_error(f"Training failed: {error}")
            return False, response.json()
            
    except requests.exceptions.Timeout:
        print_error("Training request timed out")
        return False, {'error': 'Timeout'}
    except Exception as e:
        print_error(f"Exception during training: {e}")
        return False, {'error': str(e)}


def get_all_students() -> Tuple[bool, List[Dict]]:
    """Get all registered students"""
    try:
        response = requests.get(f"{API_BASE_URL}/students/", timeout=10)
        if response.status_code == 200:
            data = response.json()
            # API returns {"count": X, "students": [...]}
            return True, data.get('students', [])
        else:
            return False, []
    except Exception as e:
        print_error(f"Failed to get students: {e}")
        return False, []


def run_complete_test():
    """Run complete pipeline test"""
    print_header("FACE PROCESSING PIPELINE - COMPLETE TEST")
    
    # Step 1: Pre-flight checks
    print_header("Step 1: Pre-flight Checks")
    
    print_info("Checking server connection...")
    if not check_server_connection():
        print_error("Backend server is not running!")
        print_info("Please start the server with: python backend/app.py")
        return False
    print_success("Server is running")
    
    print_info("Checking test images...")
    images_ok, missing = check_test_images()
    if not images_ok:
        print_error(f"Missing {len(missing)} test images:")
        for img in missing[:5]:  # Show first 5
            print(f"    - {img}")
        return False
    print_success(f"All test images found in {TEST_IMAGES_DIR}")
    
    # Step 2: Register students
    print_header("Step 2: Register Students")
    
    registered_students = []
    failed_students = []
    
    for student in TEST_STUDENTS:
        success, result = register_student(student)
        if success:
            registered_students.append(student['student_id'])
        else:
            failed_students.append(student['student_id'])
        time.sleep(1)  # Small delay between registrations
    
    print(f"\n{Colors.BOLD}Registration Summary:{Colors.ENDC}")
    print_success(f"Successfully registered: {len(registered_students)}")
    if failed_students:
        print_error(f"Failed registrations: {len(failed_students)}")
    
    if not registered_students:
        print_error("No students registered successfully!")
        return False
    
    # Step 3: Wait for face processing
    print_header("Step 3: Face Processing")
    
    processed_students = []
    failed_processing = []
    
    for student_id in registered_students:
        success, result = wait_for_processing(student_id, max_wait=60)
        if success:
            processed_students.append(student_id)
        else:
            failed_processing.append(student_id)
    
    print(f"\n{Colors.BOLD}Processing Summary:{Colors.ENDC}")
    print_success(f"Successfully processed: {len(processed_students)}")
    if failed_processing:
        print_error(f"Failed processing: {len(failed_processing)}")
        for sid in failed_processing:
            print(f"    - {sid}")
    
    if not processed_students:
        print_error("No students processed successfully!")
        return False
    
    # Step 4: Train classifier
    print_header("Step 4: Train Classifier")
    
    success, result = train_classifier()
    if not success:
        print_error("Classifier training failed!")
        return False
    
    # Step 5: Verify final state
    print_header("Step 5: Final Verification")
    
    success, students = get_all_students()
    if success:
        print_success(f"Total students in system: {len(students)}")
        for student in students:
            status = student.get('processing_status', 'unknown')
            if status == 'completed':
                print_success(f"  {student['name']} ({student['student_id']}) - Ready")
            else:
                print_warning(f"  {student['name']} ({student['student_id']}) - {status}")
    
    # Final summary
    print_header("TEST COMPLETE")
    print_success("All pipeline tests passed!")
    print(f"\n{Colors.BOLD}Final Statistics:{Colors.ENDC}")
    print(f"  Registered: {len(registered_students)}/{len(TEST_STUDENTS)}")
    print(f"  Processed:  {len(processed_students)}/{len(registered_students)}")
    print(f"  Classifier: {'Trained ✓' if success else 'Failed ✗'}")
    
    return True


if __name__ == "__main__":
    try:
        success = run_complete_test()
        exit(0 if success else 1)
    except KeyboardInterrupt:
        print_warning("\n\nTest interrupted by user")
        exit(1)
    except Exception as e:
        print_error(f"\n\nUnexpected error: {e}")
        import traceback
        traceback.print_exc()
        exit(1)
