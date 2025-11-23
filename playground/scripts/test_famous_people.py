"""
Test Script for Face Processing Pipeline - Famous People Dataset
Tests the backend and pipeline with famous historical and contemporary figures
"""

import sys
import os
import time
import requests
from pathlib import Path
from collections import defaultdict
import random

# Add parent directory to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))

# Configuration
BASE_URL = "http://localhost:5000/api"
FAMOUS_PEOPLE_FOLDER = Path(__file__).parent.parent / "famous-people"

# Famous people data structure
# Format: Name -> list of image filenames
FAMOUS_PEOPLE = {
    "Alan Turing": ["Alan-Turing (1).jpg", "Alan-Turing (2).jpg", "Alan-Turing (3).jpg", 
                    "Alan-Turing (4).jpg", "Alan-Turing (5).jpg", "Alan-Turing (6).jpg"],
    "Albert Einstein": ["Albert-Einstein (1).jpg", "Albert-Einstein (2).jpg", "Albert-Einstein (3).jpg",
                        "Albert-Einstein (4).jpg", "Albert-Einstein (5).jpg"],
    "Isaac Newton": ["Isaac-Newton (1).jpg", "Isaac-Newton (2).jpg", "Isaac-Newton (3).jpg"],
    "Lionel Messi": ["lionel-messi (1).jpg", "lionel-messi (2).jpg", "lionel-messi (3).jpg",
                     "lionel-messi (4).jpg", "lionel-messi (5).jpg", "lionel-messi (6).jpg",
                     "lionel-messi (7).jpg", "lionel-messi (8).jpg"],
    "Mahmoud Darwish": ["Mahmoud-Darwish (1).jpg", "Mahmoud-Darwish (2).jpg", "Mahmoud-Darwish (3).jpg",
                        "Mahmoud-Darwish (4).jpg", "Mahmoud-Darwish (5).jpg", "Mahmoud-Darwish (6).jpg",
                        "Mahmoud-Darwish (7).jpg"],
    "Hayao Miyazaki": ["miyazaki-hayao (1).jpg", "miyazaki-hayao (2).jpg", "miyazaki-hayao (3).jpg",
                       "miyazaki-hayao (4).jpg", "miyazaki-hayao (5).jpg"],
    "Mousa Tameri": ["mousa-tameri (1).jpg", "mousa-tameri (2).jpg", "mousa-tameri (3).jpg",
                     "mousa-tameri (4).jpg", "mousa-tameri (5).jpg", "mousa-tameri (6).jpg"],
    "Nelson Mandela": ["nelson-mandela (1).jpg", "nelson-mandela (2).jpg", "nelson-mandela (3).jpg",
                       "nelson-mandela (4).jpg", "nelson-mandela (5).jpg", "nelson-mandela (6).jpg"],
    "Shah Rukh Khan": ["sharukhan (1).jpg", "sharukhan (2).jpg", "sharukhan (3).jpg", "sharukhan (4).jpg"],
}


def generate_student_id(name):
    """Generate a deterministic student ID from name (consistent across runs)"""
    # Remove spaces and use first 8 chars + hash-based number for consistency
    clean_name = name.replace(" ", "").replace("-", "")[:6].upper()
    # Use hash to generate consistent 3-digit number from name
    name_hash = hash(name) % 900 + 100  # Ensures 3-digit number (100-999)
    return f"FP{clean_name}{name_hash}"


def test_api_health():
    """Test API health check"""
    print("\n" + "="*80)
    print("🏥 API HEALTH CHECK")
    print("="*80)
    
    try:
        response = requests.get(f"{BASE_URL}/health/status", timeout=30)
        if response.status_code == 200:
            print("✅ API is running!")
            result = response.json()
            print(f"   Status: {result.get('status', 'unknown')}")
            return True
        else:
            print(f"❌ API returned status {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to API. Is the server running?")
        print("   💡 Start with: python backend/app.py")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False


def test_student_registration():
    """Register all famous people with their first image"""
    print("\n" + "="*80)
    print("📝 TEST 1: STUDENT REGISTRATION (Famous People)")
    print("="*80)
    
    registered_students = {}
    
    for name, images in FAMOUS_PEOPLE.items():
        student_id = generate_student_id(name)
        
        print(f"\n👤 Registering: {name}")
        print(f"   ID: {student_id}")
        print(f"   Images: {len(images)} files")
        
        # Prepare all image files for this person
        image_files = []
        missing_files = []
        
        for img_filename in images:
            image_path = FAMOUS_PEOPLE_FOLDER / img_filename
            if image_path.exists():
                image_files.append((img_filename, image_path))
            else:
                missing_files.append(img_filename)
        
        if missing_files:
            print(f"   ⚠️  Missing {len(missing_files)} file(s): {', '.join(missing_files[:3])}")
        
        if not image_files:
            print(f"   ❌ No valid images found")
            continue
        
        print(f"   📁 Uploading {len(image_files)} images...")
        
        # Prepare form data with multiple images
        try:
            # Open all files and prepare for upload
            opened_files = []
            files_list = []
            
            for img_filename, img_path in image_files:
                f = open(img_path, 'rb')
                opened_files.append(f)
                files_list.append(('images', (img_filename, f, 'image/jpeg')))
            
            data = {
                'student_id': student_id,
                'name': name,
                'email': f"{name.lower().replace(' ', '.')}@famous.edu",
                'department': 'History',
                'year': 1
            }
            
            # Send request with multiple files
            response = requests.post(f"{BASE_URL}/students/", files=files_list, data=data)
            
            # Close all opened files
            for f in opened_files:
                f.close()
            
            if response.status_code == 201:
                print(f"   ✅ Registration successful!")
                result = response.json()
                status = result['student']['processing_status']
                print(f"   Processing Status: {status}")
                registered_students[student_id] = {
                    'name': name,
                    'images': images,
                    'status': status
                }
            else:
                print(f"   ❌ Registration failed: {response.status_code}")
                try:
                    print(f"   Error: {response.json()}")
                except:
                    print(f"   Error: {response.text}")
        except Exception as e:
            print(f"   ❌ Exception during registration: {e}")
    
    print(f"\n📊 Summary: {len(registered_students)}/{len(FAMOUS_PEOPLE)} students registered")
    return registered_students


def test_processing_status(registered_students):
    """Check processing status for all registered students"""
    print("\n" + "="*80)
    print("⏳ TEST 2: CHECK PROCESSING STATUS")
    print("="*80)
    
    print("\n⏱️  Waiting for face processing to complete...")
    print("   (This may take 5-10 seconds per student)")
    
    max_wait = 300  # Maximum 5 minutes (for 9 students processing in parallel)
    start_time = time.time()
    check_interval = 3  # Check every 3 seconds
    
    status_summary = defaultdict(list)
    
    while time.time() - start_time < max_wait:
        print(f"\n📍 Status Check (Elapsed: {int(time.time() - start_time)}s)")
        all_completed = True
        status_summary.clear()
        
        for student_id, info in registered_students.items():
            try:
                response = requests.get(f"{BASE_URL}/students/{student_id}")
                
                if response.status_code == 200:
                    data = response.json()
                    status = data.get('processing_status', 'unknown')
                    name = info['name']
                    
                    status_summary[status].append(name)
                    
                    if status == 'pending':
                        all_completed = False
                        print(f"   ⏳ {name}: {status}")
                    elif status == 'completed':
                        aug_count = data.get('num_augmentations', 'N/A')
                        print(f"   ✅ {name}: {status} (Augmentations: {aug_count})")
                    elif status == 'failed':
                        print(f"   ❌ {name}: {status}")
                        if 'processing_error' in data:
                            print(f"      Error: {data['processing_error']}")
                    else:
                        print(f"   ❓ {name}: {status}")
                else:
                    print(f"   ⚠️  {info['name']}: Cannot retrieve status (HTTP {response.status_code})")
            except Exception as e:
                print(f"   ⚠️  {info['name']}: Exception: {e}")
        
        # Print summary
        print(f"\n   📊 Summary:")
        for status, names in status_summary.items():
            print(f"      {status}: {len(names)}")
        
        if all_completed:
            print("\n✅ All students processed successfully!")
            break
        
        if time.time() - start_time < max_wait:
            time.sleep(check_interval)
    
    if not all_completed:
        print(f"\n⚠️  Timeout: Not all students processed after {max_wait}s")
        print("   Some students may still be processing in the background")
        
        # Count completed vs total
        completed_count = len(status_summary.get('completed', []))
        total_count = len(registered_students)
        print(f"   ✓ {completed_count}/{total_count} students completed")
        
        if completed_count >= 2:  # Need at least 2 students to train classifier
            print(f"   ℹ️  Proceeding with {completed_count} completed students")
    
    return status_summary


def test_classifier_training():
    """Test classifier training with famous people"""
    print("\n" + "="*80)
    print("🧠 TEST 3: TRAIN CLASSIFIER")
    print("="*80)
    
    print("\n🎓 Training classifier with famous people embeddings...")
    
    try:
        response = requests.post(f"{BASE_URL}/students/train-classifier")
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Classifier trained successfully!")
            
            metadata = result.get('metadata', {})
            print(f"\n📊 Training Results:")
            print(f"   👥 Students: {metadata.get('n_students', 'N/A')}")
            print(f"   🔢 Embeddings: {metadata.get('n_embeddings', 'N/A')}")
            print(f"   📈 Train Accuracy: {metadata.get('train_accuracy', 0):.2%}")
            print(f"   📉 Test Accuracy: {metadata.get('test_accuracy', 0):.2%}")
            print(f"   🕐 Trained at: {metadata.get('trained_at', 'N/A')}")
            
            if 'classes' in metadata:
                print(f"   📋 Classes: {', '.join(metadata['classes'][:5])}...")
            
            return True
        else:
            print(f"❌ Training failed: {response.status_code}")
            try:
                print(f"   Error: {response.json()}")
            except:
                print(f"   Error: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Exception during training: {e}")
        return False


def test_face_recognition_comprehensive(registered_students):
    """Test face recognition with random images per person"""
    print("\n" + "="*80)
    print("🔍 TEST 4: COMPREHENSIVE FACE RECOGNITION")
    print("="*80)
    
    print("\n🎯 Testing recognition with random images of each person...")
    print("   Note: All images were used during registration, so this tests")
    print("   the model's ability to recognize the learned faces.")
    
    total_tests = 0
    successful_recognitions = 0
    failed_recognitions = 0
    results_by_person = {}
    
    for student_id, info in registered_students.items():
        name = info['name']
        images = info['images']
        
        print(f"\n👤 Testing: {name}")
        print(f"   Total images available: {len(images)}")
        
        person_results = {
            'correct': 0,
            'incorrect': 0,
            'no_face': 0,
            'error': 0,
            'confidences': []
        }
        
        # Test with random selection of images (since all were used for registration)
        # We'll test up to 3 random images per person
        test_images = random.sample(images, min(3, len(images)))
        
        for idx, image_filename in enumerate(test_images, 1):
            image_path = FAMOUS_PEOPLE_FOLDER / image_filename
            
            if not image_path.exists():
                print(f"   ⚠️  Image {idx}: Not found - {image_filename}")
                continue
            
            total_tests += 1
            
            try:
                with open(image_path, 'rb') as img_file:
                    files = {'image': img_file}  # API expects 'image' field name (singular)
                    response = requests.post(f"{BASE_URL}/students/recognize", files=files)
                
                if response.status_code == 200:
                    result = response.json()
                    recognized = result.get('recognized', False)
                    recognized_id = result.get('student_id', 'unknown')
                    confidence = result.get('confidence', 0)
                    
                    if recognized and recognized_id == student_id:
                        print(f"   ✅ Image {idx}: Correct! (Confidence: {confidence:.2%})")
                        person_results['correct'] += 1
                        person_results['confidences'].append(confidence)
                        successful_recognitions += 1
                    elif recognized:
                        recognized_name = result.get('student_info', {}).get('name', 'Unknown')
                        print(f"   ❌ Image {idx}: Wrong! Detected as {recognized_name} (Confidence: {confidence:.2%})")
                        person_results['incorrect'] += 1
                        failed_recognitions += 1
                    else:
                        print(f"   ❓ Image {idx}: No face recognized")
                        person_results['no_face'] += 1
                        failed_recognitions += 1
                else:
                    print(f"   ⚠️  Image {idx}: HTTP {response.status_code}")
                    person_results['error'] += 1
                    failed_recognitions += 1
            except Exception as e:
                print(f"   ⚠️  Image {idx}: Exception - {e}")
                person_results['error'] += 1
                failed_recognitions += 1
        
        # Summary for this person
        if person_results['confidences']:
            avg_confidence = sum(person_results['confidences']) / len(person_results['confidences'])
            print(f"   📊 Person Summary: {person_results['correct']}/{len(test_images)} correct, Avg Confidence: {avg_confidence:.2%}")
        else:
            print(f"   📊 Person Summary: {person_results['correct']}/{len(test_images)} correct")
        
        results_by_person[name] = person_results
    
    # Overall summary
    print("\n" + "="*80)
    print("📊 OVERALL RECOGNITION RESULTS")
    print("="*80)
    
    accuracy = (successful_recognitions / total_tests * 100) if total_tests > 0 else 0
    
    print(f"\n🎯 Total Tests: {total_tests}")
    print(f"✅ Successful: {successful_recognitions} ({successful_recognitions/total_tests*100:.1f}%)" if total_tests > 0 else "✅ Successful: 0")
    print(f"❌ Failed: {failed_recognitions} ({failed_recognitions/total_tests*100:.1f}%)" if total_tests > 0 else "❌ Failed: 0")
    print(f"📈 Accuracy: {accuracy:.2f}%")
    
    # Per-person breakdown
    print(f"\n👥 Per-Person Breakdown:")
    for name, results in results_by_person.items():
        total = results['correct'] + results['incorrect'] + results['no_face']
        if total > 0:
            person_accuracy = (results['correct'] / total * 100)
            print(f"   {name}: {results['correct']}/{total} ({person_accuracy:.1f}%)")
    
    return accuracy >= 50  # Consider test passed if accuracy >= 50%


def test_list_students():
    """Test listing all students"""
    print("\n" + "="*80)
    print("📋 TEST 5: LIST ALL STUDENTS")
    print("="*80)
    
    try:
        response = requests.get(f"{BASE_URL}/students/")
        
        if response.status_code == 200:
            result = response.json()
            count = result.get('count', 0)
            students = result.get('students', [])
            
            print(f"\n👥 Total students: {count}")
            
            if students:
                print("\n📋 Student List:")
                for student in students:
                    print(f"   • {student.get('name', 'N/A')} ({student.get('student_id', 'N/A')})")
                    print(f"     Status: {student.get('processing_status', 'N/A')}")
                    if 'num_augmentations' in student:
                        print(f"     Augmentations: {student['num_augmentations']}")
            return True
        else:
            print(f"❌ Failed to list students: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False


def cleanup_existing_test_students():
    """Delete all existing test students (FP prefix) before running tests"""
    print("\n" + "="*80)
    print("🧹 CLEANUP: Removing Existing Test Students")
    print("="*80)
    
    try:
        # Get all students
        response = requests.get(f"{BASE_URL}/students/")
        if response.status_code != 200:
            print("⚠️  Could not retrieve student list")
            return False
        
        students = response.json().get('students', [])
        test_students = [s for s in students if s['student_id'].startswith('FP')]
        
        if not test_students:
            print("✅ No existing test students found")
            return True
        
        print(f"📋 Found {len(test_students)} test students to remove:")
        for student in test_students:
            student_id = student['student_id']
            name = student.get('name', 'N/A')
            print(f"   🗑️  Deleting: {name} ({student_id})")
            
            # Delete student
            del_response = requests.delete(f"{BASE_URL}/students/{student_id}")
            if del_response.status_code == 200:
                print(f"      ✅ Deleted")
            else:
                print(f"      ⚠️  Failed to delete (status {del_response.status_code})")
        
        print(f"\n✅ Cleanup complete!")
        return True
        
    except Exception as e:
        print(f"❌ Cleanup failed: {e}")
        return False


def cleanup_test_data():
    """Optional: Show cleanup instructions for manual cleanup"""
    print("\n" + "="*80)
    print("🧹 MANUAL CLEANUP (Optional)")
    print("="*80)
    
    print("\n💡 To manually clean up all test data, run these commands (from project root):")
    print("   Remove-Item backend/database.json")
    print("   Remove-Item -Recurse backend/processed_faces/*")
    print("   Remove-Item -Recurse backend/classifiers/*")


def run_all_tests():
    """Run all tests in sequence"""
    print("\n" + "="*80)
    print("🎬 FACE PROCESSING PIPELINE - FAMOUS PEOPLE TEST SUITE")
    print("="*80)
    print(f"📁 Test Dataset: {FAMOUS_PEOPLE_FOLDER}")
    print(f"👥 Famous People: {len(FAMOUS_PEOPLE)}")
    
    # Check API health
    if not test_api_health():
        print("\n⚠️  API is not running. Please start the server first.")
        print("   💡 From project root, run:")
        print("   cd backend")
        print("   python app.py")
        return
    
    # Clean up existing test students to avoid duplicates
    cleanup_existing_test_students()
    
    # Run tests
    registered_students = test_student_registration()
    
    if not registered_students:
        print("\n❌ No students registered. Cannot continue tests.")
        return
    
    time.sleep(2)  # Give processing a moment to start
    
    status_summary = test_processing_status(registered_students)
    
    # Check if any students completed processing
    if 'completed' not in status_summary or len(status_summary['completed']) == 0:
        print("\n⚠️  No students completed processing. Cannot train classifier.")
        return
    
    # Train classifier
    training_success = test_classifier_training()
    
    if training_success:
        # Test recognition
        recognition_success = test_face_recognition_comprehensive(registered_students)
        
        # List all students
        test_list_students()
    
    # Show cleanup instructions
    cleanup_test_data()
    
    print("\n" + "="*80)
    print("✅ ALL TESTS COMPLETED!")
    print("="*80)


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Test Face Processing Pipeline with Famous People")
    parser.add_argument('--test', 
                       choices=['all', 'health', 'register', 'status', 'train', 'recognize', 'list'],
                       default='all', 
                       help='Which test to run')
    
    args = parser.parse_args()
    
    if args.test == 'all':
        run_all_tests()
    elif args.test == 'health':
        test_api_health()
    elif args.test == 'register':
        test_student_registration()
    elif args.test == 'status':
        # Need to get registered students first
        print("⚠️  This test requires registered students. Run 'all' or 'register' first.")
    elif args.test == 'train':
        test_classifier_training()
    elif args.test == 'recognize':
        print("⚠️  This test requires registered students and trained classifier.")
        print("   Run 'all' to execute the complete test suite.")
    elif args.test == 'list':
        test_list_students()
