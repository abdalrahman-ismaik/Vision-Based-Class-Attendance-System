"""
Script to check registration image quality before training
Helps identify potential issues that could cause misclassification
"""

import os
import sys
import cv2
import numpy as np
from pathlib import Path
from PIL import Image

# Add parent directory to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def check_image_quality(image_path):
    """
    Check various quality metrics for a registration image
    
    Returns:
        dict with quality scores and recommendations
    """
    issues = []
    warnings = []
    
    # Load image
    img = cv2.imread(str(image_path))
    if img is None:
        return {'error': 'Could not load image'}
    
    h, w = img.shape[:2]
    
    # 1. Resolution check
    min_resolution = 640 * 480
    if w * h < min_resolution:
        issues.append(f"Low resolution ({w}x{h}). Recommended: at least 640x480")
    elif w < 400 or h < 400:
        warnings.append(f"Small dimensions ({w}x{h}). Recommended: at least 400x400")
    
    # 2. Brightness check
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    avg_brightness = np.mean(gray)
    
    if avg_brightness < 50:
        issues.append(f"Too dark (brightness: {avg_brightness:.1f}). Recommended: 80-180")
    elif avg_brightness > 200:
        issues.append(f"Too bright (brightness: {avg_brightness:.1f}). Recommended: 80-180")
    elif avg_brightness < 70 or avg_brightness > 180:
        warnings.append(f"Brightness borderline ({avg_brightness:.1f}). Optimal: 80-180")
    
    # 3. Blur detection (Laplacian variance)
    laplacian_var = cv2.Laplacian(gray, cv2.CV_64F).var()
    
    if laplacian_var < 50:
        issues.append(f"Image too blurry (sharpness: {laplacian_var:.1f}). Recommended: > 100")
    elif laplacian_var < 100:
        warnings.append(f"Image slightly blurry (sharpness: {laplacian_var:.1f}). Recommended: > 100")
    
    # 4. Face detection
    face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
    faces = face_cascade.detectMultiScale(gray, 1.1, 4)
    
    if len(faces) == 0:
        issues.append("No face detected. Ensure face is clearly visible")
    elif len(faces) > 1:
        issues.append(f"Multiple faces detected ({len(faces)}). Use images with single person only")
    else:
        # Check face size relative to image
        x, y, fw, fh = faces[0]
        face_ratio = (fw * fh) / (w * h)
        
        if face_ratio < 0.05:
            warnings.append(f"Face too small ({face_ratio*100:.1f}% of image). Recommended: > 10%")
        elif face_ratio > 0.7:
            warnings.append(f"Face too close ({face_ratio*100:.1f}% of image). Recommended: 10-50%")
    
    # 5. Contrast check
    contrast = gray.std()
    if contrast < 30:
        warnings.append(f"Low contrast ({contrast:.1f}). Recommended: > 40")
    
    return {
        'resolution': f"{w}x{h}",
        'brightness': f"{avg_brightness:.1f}",
        'sharpness': f"{laplacian_var:.1f}",
        'contrast': f"{contrast:.1f}",
        'faces_detected': len(faces),
        'issues': issues,
        'warnings': warnings,
        'quality_score': calculate_quality_score(issues, warnings)
    }


def calculate_quality_score(issues, warnings):
    """Calculate overall quality score (0-100)"""
    score = 100
    score -= len(issues) * 25  # Each issue -25 points
    score -= len(warnings) * 10  # Each warning -10 points
    return max(0, score)


def check_student_images(student_id=None):
    """Check quality of all images for a student or all students"""
    base_dir = Path(__file__).parent.parent
    uploads_dir = base_dir / 'storage' / 'uploads' / 'students'
    
    if not uploads_dir.exists():
        print("No student uploads found")
        return
    
    print("\n" + "=" * 80)
    print("REGISTRATION IMAGE QUALITY CHECK")
    print("=" * 80)
    
    # Get student directories
    if student_id:
        student_dirs = [uploads_dir / student_id] if (uploads_dir / student_id).exists() else []
    else:
        student_dirs = [d for d in uploads_dir.iterdir() if d.is_dir()]
    
    if not student_dirs:
        print("No students found")
        return
    
    all_results = {}
    
    for student_dir in sorted(student_dirs):
        student_id = student_dir.name
        print(f"\n{'='*80}")
        print(f"Student: {student_id}")
        print(f"{'='*80}")
        
        # Find all image files
        image_files = []
        for ext in ['*.jpg', '*.jpeg', '*.png']:
            image_files.extend(student_dir.glob(ext))
        
        if not image_files:
            print("  ⚠️  No images found")
            continue
        
        print(f"Found {len(image_files)} image(s)")
        
        student_results = []
        for img_path in sorted(image_files):
            print(f"\n  📷 {img_path.name}")
            result = check_image_quality(img_path)
            student_results.append(result)
            
            if 'error' in result:
                print(f"     ❌ {result['error']}")
                continue
            
            # Print metrics
            print(f"     Resolution: {result['resolution']}")
            print(f"     Brightness: {result['brightness']}")
            print(f"     Sharpness: {result['sharpness']}")
            print(f"     Faces: {result['faces_detected']}")
            print(f"     Quality Score: {result['quality_score']}/100")
            
            # Print issues
            if result['issues']:
                print(f"     ❌ ISSUES:")
                for issue in result['issues']:
                    print(f"        - {issue}")
            
            if result['warnings']:
                print(f"     ⚠️  WARNINGS:")
                for warning in result['warnings']:
                    print(f"        - {warning}")
            
            if not result['issues'] and not result['warnings']:
                print(f"     ✅ Good quality!")
        
        all_results[student_id] = student_results
        
        # Summary for this student
        avg_score = np.mean([r['quality_score'] for r in student_results if 'quality_score' in r])
        total_issues = sum(len(r.get('issues', [])) for r in student_results)
        total_warnings = sum(len(r.get('warnings', [])) for r in student_results)
        
        print(f"\n  📊 Summary:")
        print(f"     Average Quality: {avg_score:.1f}/100")
        print(f"     Total Issues: {total_issues}")
        print(f"     Total Warnings: {total_warnings}")
        
        if avg_score < 60:
            print(f"     ⚠️  RECOMMENDATION: Consider re-capturing images with better quality")
        elif total_issues > 0:
            print(f"     ⚠️  RECOMMENDATION: Fix critical issues before training")
        else:
            print(f"     ✅ Images look good for training!")
    
    print("\n" + "=" * 80)
    print("OVERALL RECOMMENDATIONS")
    print("=" * 80)
    print("\n✅ Best Practices:")
    print("  1. Use 3-5 high-quality images per student")
    print("  2. Good lighting (natural or bright indoor)")
    print("  3. Clear face visibility (no masks, glasses, or obstructions)")
    print("  4. Neutral to slight smile expression")
    print("  5. Slight variations in angle (±15 degrees)")
    print("  6. Consistent distance from camera")
    print("  7. High resolution (at least 640x480)")
    print("\n❌ Avoid:")
    print("  - Blurry images")
    print("  - Too dark or too bright")
    print("  - Multiple people in frame")
    print("  - Extreme head angles")
    print("  - Low resolution images")
    print("=" * 80)


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Check registration image quality')
    parser.add_argument('--student', help='Check specific student ID only')
    
    args = parser.parse_args()
    
    check_student_images(args.student)
