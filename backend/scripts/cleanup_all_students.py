"""
Student Cleanup and Re-registration Script

This script safely deletes all student data and prepares for clean re-registration.
It removes:
1. Student entries from database.json
2. Upload directories for each student
3. Processed face data
4. Removes students from classes
5. Deletes the trained classifier

Use this before re-registering students with better quality images.
"""

import os
import json
import shutil
from pathlib import Path

# Paths
BACKEND_DIR = Path(__file__).parent.parent
STORAGE_DIR = BACKEND_DIR / "storage"
DATABASE_FILE = STORAGE_DIR / "data" / "database.json"
CLASSES_FILE = STORAGE_DIR / "data" / "classes.json"
UPLOADS_DIR = STORAGE_DIR / "uploads" / "students"
PROCESSED_DIR = BACKEND_DIR / "processed_faces"
CLASSIFIER_DIR = STORAGE_DIR / "classifiers"
CLASSIFIER_FILE = CLASSIFIER_DIR / "face_classifier.pkl"

def backup_data():
    """Create backup of current data"""
    print("\n" + "="*60)
    print("STEP 1: CREATING BACKUPS")
    print("="*60)
    
    backup_dir = STORAGE_DIR / "backups"
    backup_dir.mkdir(exist_ok=True)
    
    from datetime import datetime
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # Backup database
    if DATABASE_FILE.exists():
        backup_db = backup_dir / f"database_{timestamp}.json"
        shutil.copy2(DATABASE_FILE, backup_db)
        print(f"✓ Database backed up to: {backup_db}")
    
    # Backup classes
    if CLASSES_FILE.exists():
        backup_classes = backup_dir / f"classes_{timestamp}.json"
        shutil.copy2(CLASSES_FILE, backup_classes)
        print(f"✓ Classes backed up to: {backup_classes}")
    
    # Backup classifier
    if CLASSIFIER_FILE.exists():
        backup_classifier = backup_dir / f"face_classifier_{timestamp}.pkl"
        shutil.copy2(CLASSIFIER_FILE, backup_classifier)
        print(f"✓ Classifier backed up to: {backup_classifier}")

def load_database():
    """Load current database"""
    if DATABASE_FILE.exists():
        with open(DATABASE_FILE, 'r') as f:
            return json.load(f)
    return {}

def load_classes():
    """Load current classes"""
    if CLASSES_FILE.exists():
        with open(CLASSES_FILE, 'r') as f:
            return json.load(f)
    return {}

def delete_student_data(student_ids=None):
    """
    Delete student data
    
    Args:
        student_ids: List of specific student IDs to delete, or None for all students
    """
    print("\n" + "="*60)
    print("STEP 2: DELETING STUDENT DATA")
    print("="*60)
    
    # Load current data
    database = load_database()
    
    # Determine which students to delete
    if student_ids is None:
        students_to_delete = list(database.keys())
        print(f"Deleting ALL {len(students_to_delete)} students")
    else:
        students_to_delete = [sid for sid in student_ids if sid in database]
        print(f"Deleting {len(students_to_delete)} specified students")
    
    if not students_to_delete:
        print("⚠️  No students to delete")
        return
    
    deleted_count = 0
    
    for student_id in students_to_delete:
        print(f"\n  Deleting {student_id}...")
        
        # 1. Delete upload directory
        upload_dir = UPLOADS_DIR / student_id
        if upload_dir.exists():
            shutil.rmtree(upload_dir)
            print(f"    ✓ Deleted uploads: {upload_dir}")
        
        # 2. Delete processed faces directory
        processed_dir = PROCESSED_DIR / student_id
        if processed_dir.exists():
            shutil.rmtree(processed_dir)
            print(f"    ✓ Deleted processed: {processed_dir}")
        
        # 3. Remove from database
        if student_id in database:
            del database[student_id]
            print(f"    ✓ Removed from database")
        
        deleted_count += 1
    
    # Save updated database
    with open(DATABASE_FILE, 'w') as f:
        json.dump(database, f, indent=2)
    
    print(f"\n✓ Deleted {deleted_count} students from database")

def clean_classes(student_ids=None):
    """Remove students from classes"""
    print("\n" + "="*60)
    print("STEP 3: CLEANING CLASS ENROLLMENTS")
    print("="*60)
    
    classes = load_classes()
    
    if student_ids is None:
        # Remove all students from all classes
        for class_id, class_data in classes.items():
            if 'student_ids' in class_data:
                removed_count = len(class_data['student_ids'])
                class_data['student_ids'] = []
                print(f"  {class_id}: Removed {removed_count} students")
    else:
        # Remove specific students from classes
        for class_id, class_data in classes.items():
            if 'student_ids' in class_data:
                original_count = len(class_data['student_ids'])
                class_data['student_ids'] = [
                    sid for sid in class_data['student_ids'] 
                    if sid not in student_ids
                ]
                removed_count = original_count - len(class_data['student_ids'])
                if removed_count > 0:
                    print(f"  {class_id}: Removed {removed_count} students")
    
    # Save updated classes
    with open(CLASSES_FILE, 'w') as f:
        json.dump(classes, f, indent=2)
    
    print("✓ Class enrollments updated")

def delete_classifier():
    """Delete trained classifier"""
    print("\n" + "="*60)
    print("STEP 4: DELETING CLASSIFIER")
    print("="*60)
    
    if CLASSIFIER_FILE.exists():
        os.remove(CLASSIFIER_FILE)
        print(f"✓ Deleted classifier: {CLASSIFIER_FILE}")
    else:
        print("⚠️  No classifier file found")

def cleanup_temp_files():
    """Clean up temporary files"""
    print("\n" + "="*60)
    print("STEP 5: CLEANING TEMPORARY FILES")
    print("="*60)
    
    # Clean HADIR_web temp and debug faces
    hadir_web = BACKEND_DIR.parent / "HADIR_web"
    
    temp_faces = hadir_web / "temp_faces"
    if temp_faces.exists():
        for file in temp_faces.glob("*.jpg"):
            file.unlink()
        print(f"✓ Cleaned temp_faces: {temp_faces}")
    
    debug_faces = hadir_web / "debug_faces"
    if debug_faces.exists():
        for file in debug_faces.glob("*.jpg"):
            file.unlink()
        print(f"✓ Cleaned debug_faces: {debug_faces}")

def main():
    """Main cleanup function"""
    print("\n" + "="*80)
    print("STUDENT DATA CLEANUP SCRIPT")
    print("="*80)
    print("\nThis script will DELETE all student data and prepare for re-registration.")
    print("\nWhat will be deleted:")
    print("  1. All student entries from database.json")
    print("  2. All upload directories (images)")
    print("  3. All processed face data")
    print("  4. All class enrollments")
    print("  5. Trained classifier")
    print("  6. Temporary face images")
    
    # Show current students
    database = load_database()
    print(f"\nCurrent students in database: {len(database)}")
    for student_id in database.keys():
        print(f"  - {student_id}")
    
    # Confirm
    print("\n" + "="*80)
    response = input("\nAre you sure you want to DELETE ALL student data? (yes/no): ")
    
    if response.lower() != 'yes':
        print("\n❌ Operation cancelled")
        return
    
    # Execute cleanup
    try:
        backup_data()
        delete_student_data()  # None = delete all students
        clean_classes()
        delete_classifier()
        cleanup_temp_files()
        
        print("\n" + "="*80)
        print("✅ CLEANUP COMPLETE!")
        print("="*80)
        print("\nAll student data has been deleted.")
        print("You can now re-register students with better quality images.")
        print("\nRECOMMENDATIONS for re-registration:")
        print("  - Use 7-10 images per student (not just 5)")
        print("  - Vary angles: front, 45° left, 45° right")
        print("  - Vary lighting: bright, normal, dim")
        print("  - Vary expressions: neutral, smile")
        print("  - Vary distances: close-up, medium")
        print("  - Ensure good lighting and clear face visibility")
        print("\nBackups saved in: backend/storage/backups/")
        
    except Exception as e:
        print(f"\n❌ Error during cleanup: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
