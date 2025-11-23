"""
Test script for multi-image student registration endpoint
Tests the new endpoint that accepts 5 images in one call
"""

import requests
import os
from pathlib import Path

# Configuration
BASE_URL = "http://localhost:5000"
REGISTER_URL = f"{BASE_URL}/api/students/register"

# Test student data
TEST_STUDENT = {
    "student_id": "TEST123456",
    "name": "Test Student",
    "email": "test.student@university.edu",
    "department": "Computer Science",
    "year": 3
}

def test_registration_with_5_images():
    """Test student registration with 5 images"""
    
    print("=" * 60)
    print("Testing Multi-Image Student Registration")
    print("=" * 60)
    
    # Find test images (use existing student images for testing)
    backend_dir = Path(__file__).parent.parent
    uploads_dir = backend_dir / "storage" / "uploads" / "students"
    
    # Get first available student's images
    test_images = []
    for student_folder in uploads_dir.iterdir():
        if student_folder.is_dir():
            images = list(student_folder.glob("*.jpg"))
            if len(images) >= 1:
                # Use the same image 5 times for testing
                # In real scenario, mobile app provides 5 different poses
                test_images = images[:1] * 5
                break
    
    if len(test_images) < 5:
        print("❌ Error: Could not find test images")
        print(f"   Please add at least one image to {uploads_dir}")
        return False
    
    print(f"\n📸 Using test images: {test_images[0].name}")
    print(f"   (Same image used 5 times for testing purposes)")
    
    # Prepare files for upload
    files = {
        f'image_{i}': (f'test_pose{i}.jpg', open(test_images[i-1], 'rb'), 'image/jpeg')
        for i in range(1, 6)
    }
    
    # Prepare form data
    data = TEST_STUDENT.copy()
    
    print(f"\n📤 Sending registration request...")
    print(f"   Student ID: {data['student_id']}")
    print(f"   Name: {data['name']}")
    print(f"   Images: 5")
    
    try:
        # Send request
        response = requests.post(
            REGISTER_URL,
            data=data,
            files=files,
            timeout=30
        )
        
        # Close file handles
        for file_tuple in files.values():
            file_tuple[1].close()
        
        print(f"\n📥 Response Status: {response.status_code}")
        
        if response.status_code == 201:
            result = response.json()
            print("\n✅ Registration Successful!")
            print(f"   Success: {result.get('success')}")
            print(f"   Message: {result.get('message')}")
            print(f"   Images Received: {result.get('images_received')}")
            
            student = result.get('student', {})
            print(f"\n👤 Student Details:")
            print(f"   UUID: {student.get('uuid')}")
            print(f"   Student ID: {student.get('student_id')}")
            print(f"   Name: {student.get('name')}")
            print(f"   Images: {student.get('num_images')}")
            print(f"   Status: {student.get('processing_status')}")
            
            print(f"\n📁 Image Paths:")
            for i, path in enumerate(student.get('image_paths', []), 1):
                print(f"   {i}. {Path(path).name}")
            
            return True
            
        elif response.status_code == 409:
            print("\n⚠️  Student Already Exists")
            print(f"   {response.json()}")
            return False
            
        else:
            print(f"\n❌ Registration Failed")
            print(f"   Status: {response.status_code}")
            print(f"   Response: {response.json()}")
            return False
            
    except requests.exceptions.ConnectionError:
        print("\n❌ Connection Error")
        print("   Make sure the backend server is running:")
        print("   python app.py")
        return False
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        return False


def test_missing_images():
    """Test validation - missing images"""
    
    print("\n" + "=" * 60)
    print("Testing Validation: Missing Images")
    print("=" * 60)
    
    data = {
        "student_id": "TEST_MISSING",
        "name": "Test Missing Images"
    }
    
    # Only send 3 images instead of 5
    backend_dir = Path(__file__).parent.parent
    uploads_dir = backend_dir / "storage" / "uploads" / "students"
    
    test_image = None
    for student_folder in uploads_dir.iterdir():
        if student_folder.is_dir():
            images = list(student_folder.glob("*.jpg"))
            if len(images) >= 1:
                test_image = images[0]
                break
    
    if not test_image:
        print("⚠️  Skipping test - no test images available")
        return
    
    files = {
        f'image_{i}': (f'test_pose{i}.jpg', open(test_image, 'rb'), 'image/jpeg')
        for i in range(1, 4)  # Only 3 images
    }
    
    try:
        response = requests.post(REGISTER_URL, data=data, files=files, timeout=10)
        
        # Close file handles
        for file_tuple in files.values():
            file_tuple[1].close()
        
        if response.status_code == 400:
            error = response.json().get('error', '')
            if 'Missing image_' in error:
                print("✅ Validation Working: Correctly rejected missing images")
                print(f"   Error: {error}")
            else:
                print(f"⚠️  Unexpected error: {error}")
        else:
            print(f"⚠️  Expected 400 status, got {response.status_code}")
            
    except Exception as e:
        print(f"❌ Error: {e}")


def test_health_check():
    """Test if backend is running"""
    
    print("\n" + "=" * 60)
    print("Testing Health Check")
    print("=" * 60)
    
    try:
        response = requests.get(f"{BASE_URL}/api/health/status", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Backend is running")
            print(f"   Status: {data.get('status')}")
            print(f"   Version: {data.get('version')}")
            print(f"   Pipeline: {data.get('pipeline_status')}")
            return True
        else:
            print(f"⚠️  Unexpected response: {response.status_code}")
            return False
    except:
        print("❌ Backend is not running")
        print("   Start it with: python app.py")
        return False


if __name__ == "__main__":
    print("\n🧪 Multi-Image Registration Test Suite\n")
    
    # First check if backend is running
    if not test_health_check():
        print("\n❌ Cannot run tests - backend is not available")
        exit(1)
    
    # Test successful registration
    success = test_registration_with_5_images()
    
    # Test validation
    test_missing_images()
    
    print("\n" + "=" * 60)
    if success:
        print("✅ Main test passed!")
    else:
        print("❌ Main test failed")
    print("=" * 60)
    print()
