"""
Test script for registering a student with multiple images via the API.
"""
import requests
import os
from pathlib import Path

# API endpoint
API_URL = "http://127.0.0.1:5000/api/students/"

# Student data
student_data = {
    'student_id': '100064701',
    'name': 'Isaac Newton',
    'email': 'isaac@example.com',
    'department': 'Physics',
    'year': 4
}

# Image files to upload (modify these paths to match your actual image locations)
image_folder = Path(r"C:\Users\4bais\Downloads")  # Change this to your image folder
image_files = [
    "Albert_Einstein_ (1).jpg",
    "Albert_Einstein_ (2).jpg",
    "Albert_Einstein_ (3).jpg",
    "Albert_Einstein_ (4).jpg",
    "Albert_Einstein_ (5).jpg"
]

def register_student():
    """Register a student with multiple images."""
    print(f"Registering student: {student_data['name']} ({student_data['student_id']})")
    print(f"Looking for images in: {image_folder}")
    
    # Prepare files for upload
    files = []
    for img_file in image_files:
        img_path = image_folder / img_file
        if img_path.exists():
            print(f"  ✓ Found: {img_file}")
            files.append(('images', (img_file, open(img_path, 'rb'), 'image/jpeg')))
        else:
            print(f"  ✗ Not found: {img_file}")
    
    if not files:
        print("\n❌ No images found! Please update the image_folder path in the script.")
        return
    
    print(f"\nUploading {len(files)} images...")
    
    try:
        # Send POST request
        response = requests.post(API_URL, files=files, data=student_data)
        
        # Close file handles
        for _, (_, file_handle, _) in files:
            file_handle.close()
        
        # Print response
        print(f"\nStatus Code: {response.status_code}")
        print(f"Response: {response.json()}")
        
        if response.status_code == 201:
            print("\n✅ Student registered successfully!")
        else:
            print(f"\n❌ Registration failed: {response.json().get('error', 'Unknown error')}")
            
    except requests.exceptions.ConnectionError:
        print("\n❌ Could not connect to the API. Make sure the backend is running on http://127.0.0.1:5000")
    except Exception as e:
        print(f"\n❌ Error: {e}")
        # Close file handles in case of error
        for _, (_, file_handle, _) in files:
            try:
                file_handle.close()
            except:
                pass

if __name__ == "__main__":
    register_student()
