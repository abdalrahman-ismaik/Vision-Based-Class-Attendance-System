"""
Test Script for Face Processing Pipeline
Demonstrates the complete workflow
"""

import sys
import os
import time
import requests
from pathlib import Path

# Configuration
BASE_URL = "http://localhost:5000/api"
STUDENTS_DATA = [
    {
        "student_id": "TEST001",
        "name": "Test Student One",
        "email": "test1@example.com",
        "image_path": "../backend/uploads/students/100064807/100064807_20251008_210933.jpg"
    },
]


def test_student_registration():
    """Test student registration with image upload"""
    print("\n" + "="*70)
    print("TEST 1: STUDENT REGISTRATION")
    print("="*70)
    
    for student in STUDENTS_DATA:
        print(f"\nRegistering: {student['name']} ({student['student_id']})")
        
        # Check if image exists
        if not os.path.exists(student['image_path']):
            print(f"  ❌ Image not found: {student['image_path']}")
            continue
        
        # Prepare form data
        with open(student['image_path'], 'rb') as img_file:
            files = {'image': img_file}
            data = {
                'student_id': student['student_id'],
                'name': student['name'],
                'email': student['email']
            }
            
            # Send request
            response = requests.post(f"{BASE_URL}/students/", files=files, data=data)
        
        if response.status_code == 201:
            print(f"  ✓ Registration successful!")
            result = response.json()
            print(f"  Status: {result['student']['processing_status']}")
        else:
            print(f"  ❌ Registration failed: {response.status_code}")
            print(f"  {response.json()}")


def test_processing_status():
    """Check processing status for all students"""
    print("\n" + "="*70)
    print("TEST 2: CHECK PROCESSING STATUS")
    print("="*70)
    
    print("\nWaiting for face processing to complete...")
    print("(This may take 5-10 seconds per student)")
    
    max_wait = 60  # Maximum 60 seconds
    start_time = time.time()
    
    while time.time() - start_time < max_wait:
        all_completed = True
        
        for student in STUDENTS_DATA:
            response = requests.get(f"{BASE_URL}/students/{student['student_id']}")
            
            if response.status_code == 200:
                data = response.json()
                status = data.get('processing_status', 'unknown')
                
                if status == 'pending':
                    all_completed = False
                    print(f"  {student['student_id']}: {status} ⏳")
                elif status == 'completed':
                    print(f"  {student['student_id']}: {status} ✓")
                    if 'num_augmentations' in data:
                        print(f"    Augmentations: {data['num_augmentations']}")
                elif status == 'failed':
                    print(f"  {student['student_id']}: {status} ❌")
                    if 'processing_error' in data:
                        print(f"    Error: {data['processing_error']}")
        
        if all_completed:
            print("\n✓ All students processed!")
            break
        
        time.sleep(2)
    
    if not all_completed:
        print("\n⚠️  Timeout: Not all students processed yet")


def test_classifier_training():
    """Test classifier training"""
    print("\n" + "="*70)
    print("TEST 3: TRAIN CLASSIFIER")
    print("="*70)
    
    print("\nTraining classifier...")
    response = requests.post(f"{BASE_URL}/students/train-classifier")
    
    if response.status_code == 200:
        result = response.json()
        print("✓ Classifier trained successfully!")
        print(f"\nMetadata:")
        metadata = result['metadata']
        print(f"  Students: {metadata['n_students']}")
        print(f"  Embeddings: {metadata['n_embeddings']}")
        print(f"  Train Accuracy: {metadata['train_accuracy']:.2%}")
        print(f"  Test Accuracy: {metadata['test_accuracy']:.2%}")
        print(f"  Trained at: {metadata['trained_at']}")
    else:
        print(f"❌ Training failed: {response.status_code}")
        print(response.json())


def test_face_recognition(test_image_path=None):
    """Test face recognition"""
    print("\n" + "="*70)
    print("TEST 4: FACE RECOGNITION")
    print("="*70)
    
    # Use first student's image if no test image provided
    if test_image_path is None:
        test_image_path = STUDENTS_DATA[0]['image_path']
    
    if not os.path.exists(test_image_path):
        print(f"❌ Test image not found: {test_image_path}")
        return
    
    print(f"\nRecognizing face in: {test_image_path}")
    
    with open(test_image_path, 'rb') as img_file:
        files = {'image': img_file}
        response = requests.post(f"{BASE_URL}/students/recognize", files=files)
    
    if response.status_code == 200:
        result = response.json()
        print("✓ Recognition successful!")
        print(f"\nResults:")
        print(f"  Recognized: {result['recognized']}")
        print(f"  Student ID: {result['student_id']}")
        print(f"  Confidence: {result['confidence']:.2%}")
        print(f"  Bounding Box: {result['bbox']}")
        
        if result['student_info']:
            print(f"\nStudent Info:")
            print(f"  Name: {result['student_info']['name']}")
            print(f"  Email: {result['student_info']['email']}")
    else:
        print(f"❌ Recognition failed: {response.status_code}")
        print(response.json())


def test_list_students():
    """Test listing all students"""
    print("\n" + "="*70)
    print("TEST 5: LIST ALL STUDENTS")
    print("="*70)
    
    response = requests.get(f"{BASE_URL}/students/")
    
    if response.status_code == 200:
        result = response.json()
        print(f"\nTotal students: {result['count']}")
        
        for student in result['students']:
            print(f"\n  Student ID: {student['student_id']}")
            print(f"  Name: {student['name']}")
            print(f"  Processing Status: {student.get('processing_status', 'N/A')}")
            if 'num_augmentations' in student:
                print(f"  Augmentations: {student['num_augmentations']}")
    else:
        print(f"❌ Failed to list students: {response.status_code}")


def test_api_health():
    """Test API health check"""
    print("\n" + "="*70)
    print("API HEALTH CHECK")
    print("="*70)
    
    try:
        response = requests.get(f"{BASE_URL}/health/status", timeout=5)
        if response.status_code == 200:
            print("✓ API is running!")
            print(response.json())
            return True
        else:
            print(f"❌ API returned status {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to API. Is the server running?")
        print("   Start with: python app.py")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False


def run_all_tests():
    """Run all tests in sequence"""
    print("\n" + "="*70)
    print("FACE PROCESSING PIPELINE - FULL TEST SUITE")
    print("="*70)
    
    # Check API health
    if not test_api_health():
        print("\n⚠️  API is not running. Please start the server first.")
        print("   Run: python app.py")
        return
    
    # Run tests
    test_student_registration()
    time.sleep(2)  # Give processing a moment to start
    test_processing_status()
    test_classifier_training()
    test_face_recognition()
    test_list_students()
    
    print("\n" + "="*70)
    print("ALL TESTS COMPLETED!")
    print("="*70)


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Test Face Processing Pipeline")
    parser.add_argument('--test', choices=['all', 'health', 'register', 'status', 'train', 'recognize', 'list'],
                       default='all', help='Which test to run')
    parser.add_argument('--image', type=str, help='Path to test image for recognition')
    
    args = parser.parse_args()
    
    if args.test == 'all':
        run_all_tests()
    elif args.test == 'health':
        test_api_health()
    elif args.test == 'register':
        test_student_registration()
    elif args.test == 'status':
        test_processing_status()
    elif args.test == 'train':
        test_classifier_training()
    elif args.test == 'recognize':
        test_face_recognition(args.image)
    elif args.test == 'list':
        test_list_students()
