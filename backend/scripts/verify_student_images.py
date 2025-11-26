"""
Verify Student Images Database Integrity
=========================================

This script checks each student in the database and verifies:
1. That the student has images assigned
2. That the image files actually exist
3. That the images in the processed_faces folder match the student
4. That the image filenames contain the correct student ID

Usage:
    python backend/scripts/verify_student_images.py
    python backend/scripts/verify_student_images.py --fix-mismatches
"""

import os
import sys
import json
import argparse
from pathlib import Path
from PIL import Image

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from database.core import load_database, save_database
from config.settings import STUDENT_DATA_FOLDER, PROCESSED_FACES_FOLDER

def verify_student_images(fix_mismatches=False):
    """
    Verify that each student has correct images assigned.
    
    Args:
        fix_mismatches: If True, remove mismatched images from database
    """
    database = load_database()
    
    print("="*80)
    print("STUDENT IMAGE VERIFICATION REPORT")
    print("="*80)
    print(f"Total students in database: {len(database)}")
    print()
    
    issues_found = []
    students_checked = 0
    total_images_checked = 0
    
    for student_id, student_data in database.items():
        students_checked += 1
        student_name = student_data.get('name', 'Unknown')
        image_paths = student_data.get('image_paths', [])
        
        print(f"\n[{students_checked}] Student: {student_name} (ID: {student_id})")
        print(f"    Database record claims {len(image_paths)} images")
        
        if not image_paths:
            print(f"    ⚠ WARNING: No images assigned to this student!")
            issues_found.append({
                'student_id': student_id,
                'student_name': student_name,
                'issue': 'no_images',
                'details': 'No images in database record'
            })
            continue
        
        valid_images = []
        invalid_images = []
        mismatched_images = []
        missing_images = []
        
        for img_path in image_paths:
            total_images_checked += 1
            
            # Check if file exists
            if not os.path.exists(img_path):
                print(f"    ✗ MISSING: {img_path}")
                missing_images.append(img_path)
                issues_found.append({
                    'student_id': student_id,
                    'student_name': student_name,
                    'issue': 'missing_file',
                    'details': f'File not found: {img_path}'
                })
                continue
            
            # Check if filename contains the correct student ID
            filename = os.path.basename(img_path)
            parent_dir = os.path.basename(os.path.dirname(img_path))
            
            # Images should be in a directory named after student ID
            if parent_dir != student_id:
                print(f"    ✗ MISMATCH: Image in wrong directory")
                print(f"       Expected: .../{student_id}/...")
                print(f"       Got:      .../{parent_dir}/{filename}")
                mismatched_images.append(img_path)
                issues_found.append({
                    'student_id': student_id,
                    'student_name': student_name,
                    'issue': 'directory_mismatch',
                    'details': f'Image in {parent_dir}/ instead of {student_id}/'
                })
                continue
            
            # Try to open image to verify it's valid
            try:
                with Image.open(img_path) as img:
                    width, height = img.size
                    print(f"    ✓ Valid: {filename} ({width}x{height})")
                    valid_images.append(img_path)
            except Exception as e:
                print(f"    ✗ CORRUPT: {filename} - {e}")
                invalid_images.append(img_path)
                issues_found.append({
                    'student_id': student_id,
                    'student_name': student_name,
                    'issue': 'corrupt_file',
                    'details': f'Cannot open image: {img_path}'
                })
        
        # Check processed faces folder
        processed_dir = os.path.join(PROCESSED_FACES_FOLDER, student_id)
        if os.path.exists(processed_dir):
            processed_files = [f for f in os.listdir(processed_dir) if f.endswith(('.jpg', '.png'))]
            embeddings_file = os.path.join(processed_dir, 'embeddings.npy')
            has_embeddings = os.path.exists(embeddings_file)
            
            print(f"    ℹ Processed faces: {len(processed_files)} files")
            if has_embeddings:
                print(f"    ℹ Embeddings file: EXISTS")
            else:
                print(f"    ⚠ Embeddings file: MISSING")
                issues_found.append({
                    'student_id': student_id,
                    'student_name': student_name,
                    'issue': 'missing_embeddings',
                    'details': 'No embeddings.npy file found'
                })
        else:
            print(f"    ⚠ Processed faces directory: NOT FOUND")
            issues_found.append({
                'student_id': student_id,
                'student_name': student_name,
                'issue': 'no_processed_dir',
                'details': f'Directory not found: {processed_dir}'
            })
        
        # Summary for this student
        print(f"    Summary: {len(valid_images)} valid, {len(missing_images)} missing, "
              f"{len(mismatched_images)} mismatched, {len(invalid_images)} corrupt")
        
        # Fix mismatches if requested
        if fix_mismatches and (mismatched_images or invalid_images or missing_images):
            print(f"    🔧 Fixing: Removing problematic images from database...")
            student_data['image_paths'] = valid_images
            student_data['num_poses'] = len(valid_images)
    
    # Save fixed database if requested
    if fix_mismatches:
        save_database(database)
        print("\n✓ Database updated with corrections")
    
    # Print summary
    print("\n" + "="*80)
    print("VERIFICATION SUMMARY")
    print("="*80)
    print(f"Students checked: {students_checked}")
    print(f"Total images checked: {total_images_checked}")
    print(f"Issues found: {len(issues_found)}")
    print()
    
    # Group issues by type
    issue_types = {}
    for issue in issues_found:
        issue_type = issue['issue']
        if issue_type not in issue_types:
            issue_types[issue_type] = []
        issue_types[issue_type].append(issue)
    
    if issue_types:
        print("Issues breakdown:")
        for issue_type, issues in issue_types.items():
            print(f"  • {issue_type}: {len(issues)} occurrences")
        print()
        
        # Show detailed issues
        print("Detailed issues:")
        for issue in issues_found:
            print(f"  • {issue['student_name']} ({issue['student_id']})")
            print(f"    Type: {issue['issue']}")
            print(f"    Details: {issue['details']}")
            print()
    else:
        print("✓ No issues found! All student images are correctly assigned.")
    
    print("="*80)
    
    return issues_found

def check_orphaned_images():
    """Check for images in processed_faces that don't belong to any student."""
    print("\n" + "="*80)
    print("CHECKING FOR ORPHANED IMAGES")
    print("="*80)
    
    database = load_database()
    registered_student_ids = set(database.keys())
    
    if not os.path.exists(PROCESSED_FACES_FOLDER):
        print(f"Processed faces folder not found: {PROCESSED_FACES_FOLDER}")
        return
    
    orphaned_dirs = []
    
    for student_dir in os.listdir(PROCESSED_FACES_FOLDER):
        dir_path = os.path.join(PROCESSED_FACES_FOLDER, student_dir)
        
        if not os.path.isdir(dir_path):
            continue
        
        if student_dir not in registered_student_ids:
            file_count = len([f for f in os.listdir(dir_path) if os.path.isfile(os.path.join(dir_path, f))])
            print(f"⚠ ORPHANED: {student_dir}/ ({file_count} files)")
            print(f"   This directory has no corresponding student in database")
            orphaned_dirs.append(student_dir)
    
    if not orphaned_dirs:
        print("✓ No orphaned directories found")
    else:
        print(f"\nFound {len(orphaned_dirs)} orphaned directories")
        print("These directories can be safely deleted or may indicate data inconsistency")
    
    print("="*80)
    
    return orphaned_dirs

def main():
    parser = argparse.ArgumentParser(description='Verify student image database integrity')
    parser.add_argument('--fix-mismatches', action='store_true',
                       help='Remove mismatched/invalid images from database')
    parser.add_argument('--check-orphaned', action='store_true',
                       help='Also check for orphaned image directories')
    
    args = parser.parse_args()
    
    # Run verification
    issues = verify_student_images(fix_mismatches=args.fix_mismatches)
    
    # Check for orphaned images if requested
    if args.check_orphaned:
        orphaned = check_orphaned_images()
    
    # Exit with error code if issues found
    if issues:
        sys.exit(1)
    else:
        sys.exit(0)

if __name__ == '__main__':
    main()
