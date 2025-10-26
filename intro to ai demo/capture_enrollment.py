"""
capture_enrollment.py
---------------------
Capture enrollment photos from webcam and save them to enrollment folders.
"""

import cv2
import os
from pathlib import Path

def capture_photos():
    # Create enrollment directory if it doesn't exist
    enroll_dir = Path("enroll_images")
    enroll_dir.mkdir(exist_ok=True)
    
    print("Capture Enrollment Photos")
    print("=" * 50)
    print("This will help you capture photos for enrollment.")
    print()
    
    # Get student name
    student_name = input("Enter student name (e.g., student1, John, etc.): ").strip()
    if not student_name:
        print("Error: Student name cannot be empty!")
        return
    
    student_dir = enroll_dir / student_name
    student_dir.mkdir(exist_ok=True)
    
    # Count existing photos
    existing_photos = len(list(student_dir.glob("*.jpg")))
    
    print(f"\nStudent: {student_name}")
    print(f"Photos will be saved to: {student_dir}")
    print(f"Existing photos: {existing_photos}")
    print()
    
    # Initialize webcam
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("Error: Could not open webcam!")
        return
    
    print("Instructions:")
    print("  - Press SPACE to capture a photo")
    print("  - Press 'q' to quit")
    print("  - A window will show the camera feed")
    print()
    
    photo_count = existing_photos
    frame_skip = 0
    
    while True:
        ret, frame = cap.read()
        if not ret:
            print("Error: Failed to read from webcam!")
            break
        
        # Mirror the frame for better UX
        frame = cv2.flip(frame, 1)
        
        # Display photo count
        cv2.putText(frame, f"Photos captured: {photo_count}", 
                   (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
        cv2.putText(frame, "Press SPACE to capture, 'q' to quit", 
                   (10, frame.shape[0] - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
        
        cv2.imshow('Capture Enrollment Photos', frame)
        
        key = cv2.waitKey(1) & 0xFF
        
        if key == ord(' '):  # Space bar to capture
            photo_filename = student_dir / f"{student_name}_{photo_count:03d}.jpg"
            cv2.imwrite(str(photo_filename), frame)
            photo_count += 1
            print(f"✓ Captured photo: {photo_filename.name} (Total: {photo_count})")
            
            # Show a flash effect
            cv2.rectangle(frame, (0, 0), (frame.shape[1], frame.shape[0]), (255, 255, 255), -1)
            cv2.imshow('Capture Enrollment Photos', frame)
            cv2.waitKey(100)
            
        elif key == ord('q'):
            break
    
    cap.release()
    cv2.destroyAllWindows()
    
    print(f"\n✓ Captured {photo_count - existing_photos} new photos for {student_name}")
    print(f"Total photos in gallery: {photo_count}")
    print("\nNext step: Run enrollment to create the gallery:")
    print("  python -m attendance_demo.gallery.enroll --images_dir enroll_images --output attendance_demo/gallery.npz")

if __name__ == "__main__":
    capture_photos()
