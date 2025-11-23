"""
Test script to POST images from a directory to the backend API
Tests student registration with multiple images
"""

import os
import requests
from pathlib import Path
from datetime import datetime

# Configuration
API_BASE_URL = "http://localhost:5000/api"
IMAGE_DIRECTORY = r"C:\Users\4bais\OneDrive\Pictures\Camera Roll"
SUPPORTED_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.bmp', '.gif'}

def get_image_files(directory):
    """Get all image files from the specified directory"""
    image_files = []
    path = Path(directory)
    
    if not path.exists():
        print(f"❌ Directory not found: {directory}")
        return []
    
    for file in path.iterdir():
        if file.is_file() and file.suffix.lower() in SUPPORTED_EXTENSIONS:
            image_files.append(file)
    
    return sorted(image_files)


def test_health_check():
    """Test if the API is running"""
    try:
        response = requests.get(f"{API_BASE_URL}/health/status", timeout=5)
        if response.status_code == 200:
            print("✅ API is healthy")
            print(f"   Response: {response.json()}")
            return True
        else:
            print(f"❌ API returned status code: {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ Cannot connect to API: {e}")
        return False


def upload_student_images(student_id, name, image_files, email="", department="", year=None):
    """Upload multiple images for student registration"""
    
    if not image_files:
        print(f"❌ No images provided for {student_id}")
        return False
    
    print(f"\n📤 Uploading {len(image_files)} image(s) for student: {student_id}")
    
    # Prepare form data
    data = {
        'student_id': student_id,
        'name': name,
        'email': email,
        'department': department,
    }
    
    if year:
        data['year'] = year
    
    # Prepare files for upload
    files = []
    try:
        for img_path in image_files:
            print(f"   📎 Adding: {img_path.name}")
            files.append(('images', (img_path.name, open(img_path, 'rb'), 'image/jpeg')))
        
        # Send POST request
        print(f"   🚀 Sending request to {API_BASE_URL}/students/")
        response = requests.post(
            f"{API_BASE_URL}/students/",
            data=data,
            files=files,
            timeout=30
        )
        
        # Process response
        if response.status_code == 201:
            print(f"   ✅ Student registered successfully!")
            result = response.json()
            print(f"   📋 Response: {result}")
            return True
        elif response.status_code == 409:
            print(f"   ⚠️  Student already exists")
            print(f"   Response: {response.json()}")
            return False
        else:
            print(f"   ❌ Registration failed with status code: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"   ❌ Request failed: {e}")
        return False
    finally:
        # Close all file handles
        for _, file_tuple in files:
            file_tuple[1].close()


def test_single_student_multiple_images():
    """Test uploading multiple images for one student"""
    print("\n" + "="*70)
    print("TEST 1: Single Student with Multiple Images")
    print("="*70)
    
    image_files = get_image_files(IMAGE_DIRECTORY)
    
    if not image_files:
        print("❌ No images found in directory")
        return False
    
    print(f"📁 Found {len(image_files)} image(s) in directory")
    
    # Use first 5 images (or all if less than 5)
    images_to_upload = image_files[:5]
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    success = upload_student_images(
        student_id=f"TEST_{timestamp}",
        name=f"Test Student {timestamp}",
        image_files=images_to_upload,
        email=f"test_{timestamp}@example.com",
        department="Computer Science",
        year=3
    )
    
    return success


def test_multiple_students_one_image_each():
    """Test uploading one image for multiple students"""
    print("\n" + "="*70)
    print("TEST 2: Multiple Students with One Image Each")
    print("="*70)
    
    image_files = get_image_files(IMAGE_DIRECTORY)
    
    if not image_files:
        print("❌ No images found in directory")
        return False
    
    print(f"📁 Found {len(image_files)} image(s) in directory")
    
    # Use first 3 images for 3 different students
    max_students = min(3, len(image_files))
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    results = []
    for i in range(max_students):
        success = upload_student_images(
            student_id=f"STU_{timestamp}_{i+1}",
            name=f"Student {i+1}",
            image_files=[image_files[i]],
            email=f"student{i+1}_{timestamp}@example.com",
            department="Engineering",
            year=2
        )
        results.append(success)
    
    return all(results)


def test_batch_upload_all_images():
    """Test uploading all images as different poses for one student"""
    print("\n" + "="*70)
    print("TEST 3: Batch Upload All Images for One Student")
    print("="*70)
    
    image_files = get_image_files(IMAGE_DIRECTORY)
    
    if not image_files:
        print("❌ No images found in directory")
        return False
    
    print(f"📁 Found {len(image_files)} image(s) in directory")
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    success = upload_student_images(
        student_id=f"BATCH_{timestamp}",
        name=f"Batch Test Student {timestamp}",
        image_files=image_files,  # Upload all images
        email=f"batch_{timestamp}@example.com",
        department="Information Technology",
        year=4
    )
    
    return success


def list_registered_students():
    """List all registered students"""
    print("\n" + "="*70)
    print("LISTING ALL REGISTERED STUDENTS")
    print("="*70)
    
    try:
        response = requests.get(f"{API_BASE_URL}/students/", timeout=10)
        if response.status_code == 200:
            data = response.json()
            count = data.get('count', 0)
            students = data.get('students', [])
            
            print(f"📊 Total students: {count}")
            for student in students:
                print(f"\n   👤 {student.get('name')} ({student.get('student_id')})")
                print(f"      Email: {student.get('email', 'N/A')}")
                print(f"      Department: {student.get('department', 'N/A')}")
                print(f"      Images: {student.get('num_poses', 0)} pose(s)")
                print(f"      Status: {student.get('processing_status', 'unknown')}")
            return True
        else:
            print(f"❌ Failed to list students: {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ Request failed: {e}")
        return False


def main():
    """Main test runner"""
    print("="*70)
    print("🧪 IMAGE UPLOAD TEST SCRIPT")
    print("="*70)
    print(f"📂 Image Directory: {IMAGE_DIRECTORY}")
    print(f"🌐 API Base URL: {API_BASE_URL}")
    print()
    
    # Step 1: Health check
    if not test_health_check():
        print("\n❌ API is not available. Please start the backend server first.")
        print("   Run: python backend/app.py")
        return
    
    # Check if directory exists
    if not os.path.exists(IMAGE_DIRECTORY):
        print(f"\n❌ Directory not found: {IMAGE_DIRECTORY}")
        print("   Please update IMAGE_DIRECTORY in the script.")
        return
    
    # Menu for user selection
    print("\n" + "="*70)
    print("SELECT TEST TO RUN:")
    print("="*70)
    print("1. Single student with multiple images (first 5 images)")
    print("2. Multiple students with one image each (first 3 images)")
    print("3. Batch upload all images for one student")
    print("4. List all registered students")
    print("5. Run all tests")
    print("0. Exit")
    print()
    
    choice = input("Enter your choice (0-5): ").strip()
    
    if choice == '1':
        test_single_student_multiple_images()
    elif choice == '2':
        test_multiple_students_one_image_each()
    elif choice == '3':
        test_batch_upload_all_images()
    elif choice == '4':
        list_registered_students()
    elif choice == '5':
        test_single_student_multiple_images()
        test_multiple_students_one_image_each()
        test_batch_upload_all_images()
        list_registered_students()
    elif choice == '0':
        print("👋 Exiting...")
        return
    else:
        print("❌ Invalid choice")
        return
    
    # Final summary
    print("\n" + "="*70)
    print("✅ TEST COMPLETED")
    print("="*70)
    print("\n💡 TIP: Run option 4 to see all registered students")


if __name__ == "__main__":
    main()
