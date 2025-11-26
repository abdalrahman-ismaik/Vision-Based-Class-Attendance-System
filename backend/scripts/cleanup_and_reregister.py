"""
Script to cleanup student data and prepare for re-registration
Run this before re-registering students to ensure clean slate
"""

import os
import sys
import json
import shutil
from pathlib import Path

# Add parent directory to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def cleanup_student_data(student_ids=None):
    """
    Clean up all student data including:
    - Uploads folder
    - Processed embeddings
    - Classifier file
    - Database entries
    
    Args:
        student_ids: List of student IDs to delete, or None to delete all
    """
    base_dir = Path(__file__).parent.parent
    
    # Paths
    uploads_dir = base_dir / 'storage' / 'uploads' / 'students'
    processed_dir = base_dir / 'storage' / 'processed'
    classifier_path = base_dir / 'storage' / 'classifiers' / 'face_classifier.pkl'
    database_path = base_dir / 'storage' / 'data' / 'students.json'
    
    print("=" * 60)
    print("STUDENT DATA CLEANUP")
    print("=" * 60)
    
    # 1. Clean uploads
    if uploads_dir.exists():
        if student_ids is None:
            print(f"\n[1/4] Removing ALL student uploads from {uploads_dir}")
            for student_dir in uploads_dir.iterdir():
                if student_dir.is_dir():
                    print(f"  - Removing {student_dir.name}")
                    shutil.rmtree(student_dir)
        else:
            print(f"\n[1/4] Removing selected student uploads")
            for student_id in student_ids:
                student_dir = uploads_dir / student_id
                if student_dir.exists():
                    print(f"  - Removing {student_id}")
                    shutil.rmtree(student_dir)
                else:
                    print(f"  - {student_id} not found in uploads")
    
    # 2. Clean processed embeddings
    if processed_dir.exists():
        if student_ids is None:
            print(f"\n[2/4] Removing ALL processed embeddings from {processed_dir}")
            for student_dir in processed_dir.iterdir():
                if student_dir.is_dir():
                    print(f"  - Removing {student_dir.name}")
                    shutil.rmtree(student_dir)
        else:
            print(f"\n[2/4] Removing selected processed embeddings")
            for student_id in student_ids:
                student_dir = processed_dir / student_id
                if student_dir.exists():
                    print(f"  - Removing {student_id}")
                    shutil.rmtree(student_dir)
                else:
                    print(f"  - {student_id} not found in processed")
    
    # 3. Remove classifier (will need retraining)
    print(f"\n[3/4] Removing classifier")
    if classifier_path.exists():
        os.remove(classifier_path)
        print(f"  ✓ Removed {classifier_path}")
    else:
        print(f"  - Classifier not found")
    
    # 4. Clean database
    print(f"\n[4/4] Updating database")
    if database_path.exists():
        with open(database_path, 'r') as f:
            db = json.load(f)
        
        if student_ids is None:
            print(f"  - Removing ALL students from database")
            db = {}
        else:
            for student_id in student_ids:
                if student_id in db:
                    print(f"  - Removing {student_id} from database")
                    del db[student_id]
                else:
                    print(f"  - {student_id} not found in database")
        
        with open(database_path, 'w') as f:
            json.dump(db, f, indent=2)
        print(f"  ✓ Database updated")
    else:
        print(f"  - Database not found")
    
    print("\n" + "=" * 60)
    print("✓ CLEANUP COMPLETE")
    print("=" * 60)
    print("\nNext steps:")
    print("1. Register students with high-quality images (3-5 images per student)")
    print("2. Use good lighting and clear face visibility")
    print("3. Train classifier: POST http://127.0.0.1:5000/api/students/train-classifier")
    print("4. Test recognition to verify accuracy")


def list_registered_students():
    """List all currently registered students"""
    base_dir = Path(__file__).parent.parent
    database_path = base_dir / 'storage' / 'data' / 'students.json'
    
    if not database_path.exists():
        print("No students registered")
        return []
    
    with open(database_path, 'r') as f:
        db = json.load(f)
    
    print("\n" + "=" * 60)
    print("REGISTERED STUDENTS")
    print("=" * 60)
    
    for student_id, info in db.items():
        name = info.get('name', 'N/A')
        images = info.get('image_paths', [])
        print(f"\n{student_id}: {name}")
        print(f"  Images: {len(images)}")
        if images:
            for img in images:
                print(f"    - {Path(img).name}")
    
    print("\n" + "=" * 60)
    return list(db.keys())


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Cleanup student data before re-registration')
    parser.add_argument('--list', action='store_true', help='List all registered students')
    parser.add_argument('--students', nargs='+', help='Student IDs to remove (space-separated). Omit to remove ALL students.')
    parser.add_argument('--all', action='store_true', help='Remove ALL students (same as omitting --students)')
    
    args = parser.parse_args()
    
    if args.list:
        list_registered_students()
    elif args.all or args.students is None:
        confirm = input("\n⚠️  WARNING: This will remove ALL students. Continue? (yes/no): ")
        if confirm.lower() == 'yes':
            cleanup_student_data(None)
        else:
            print("Cancelled")
    elif args.students:
        print(f"\nWill remove students: {', '.join(args.students)}")
        confirm = input("Continue? (yes/no): ")
        if confirm.lower() == 'yes':
            cleanup_student_data(args.students)
        else:
            print("Cancelled")
    else:
        parser.print_help()
