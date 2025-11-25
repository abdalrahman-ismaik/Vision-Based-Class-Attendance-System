import os
import requests
import argparse
import mimetypes

# Configuration
API_URL = "http://localhost:5000/api/students"
DEFAULT_IMAGE_FOLDER = r"C:\Users\4bais\OneDrive\Pictures\Camera Roll"

def register_student(student_id, name, image_folder, email=None, department=None, year=None):
    """
    Registers a student by uploading images from a folder to the backend API.
    """
    print(f"Preparing to register student: {name} ({student_id})")
    print(f"Source folder: {image_folder}")

    if not os.path.exists(image_folder):
        print(f"Error: Folder not found: {image_folder}")
        return

    # Collect image files
    files_to_upload = []
    valid_extensions = {'.jpg', '.jpeg', '.png', '.bmp'}
    
    # We need to keep file objects open until the request is sent
    opened_files = []

    try:
        for filename in os.listdir(image_folder):
            ext = os.path.splitext(filename)[1].lower()
            if ext in valid_extensions:
                file_path = os.path.join(image_folder, filename)
                mime_type = mimetypes.guess_type(file_path)[0] or 'application/octet-stream'
                
                f = open(file_path, 'rb')
                opened_files.append(f)
                
                # Append to files list for requests
                # Format: ('key', ('filename', file_object, 'content_type'))
                files_to_upload.append(('images', (filename, f, mime_type)))
                print(f"Found image: {filename}")

        if not files_to_upload:
            print("No valid images found in the specified folder.")
            return

        print(f"Uploading {len(files_to_upload)} images...")

        # Prepare form data
        data = {
            'student_id': student_id,
            'name': name
        }
        if email: data['email'] = email
        if department: data['department'] = department
        if year: data['year'] = year

        # Send POST request
        try:
            response = requests.post(API_URL, data=data, files=files_to_upload)
            
            if response.status_code == 201:
                print("\nSUCCESS: Student registered successfully!")
                print("Response:", response.json())
            else:
                print(f"\nFAILED: Server returned status code {response.status_code}")
                try:
                    print("Error details:", response.json())
                except:
                    print("Response text:", response.text)

        except requests.exceptions.ConnectionError:
            print(f"\nERROR: Could not connect to the backend at {API_URL}")
            print("Please ensure the backend server is running (python backend/app.py).")
        except Exception as e:
            print(f"\nERROR: An unexpected error occurred: {e}")

    finally:
        # Close all opened files
        for f in opened_files:
            f.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Register a student using images from a folder.")
    parser.add_argument("--id", help="Student ID")
    parser.add_argument("--name", help="Student Name")
    parser.add_argument("--folder", default=DEFAULT_IMAGE_FOLDER, help="Folder containing student images")
    parser.add_argument("--email", help="Student Email")
    parser.add_argument("--dept", help="Department")
    parser.add_argument("--year", type=int, help="Academic Year")

    args = parser.parse_args()

    # Interactive mode if arguments are missing
    student_id = args.id
    if not student_id:
        student_id = input("Enter Student ID: ").strip()
    
    name = args.name
    if not name:
        name = input("Enter Student Name: ").strip()

    if not student_id or not name:
        print("Error: Student ID and Name are required.")
    else:
        register_student(student_id, name, args.folder, args.email, args.dept, args.year)
