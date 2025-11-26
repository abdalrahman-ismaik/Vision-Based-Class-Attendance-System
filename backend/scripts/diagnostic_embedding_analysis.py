"""
Diagnostic Embedding Analysis Script

This script performs comprehensive analysis to identify why different students
are being misidentified as the same person.

It checks:
1. Embedding quality and consistency
2. Training data quality (mean embeddings per student)
3. Cosine similarity distributions
4. SVM decision boundaries and margins
5. Face image preprocessing differences
"""

import os
import sys
import pickle
import numpy as np
from PIL import Image
import cv2

# Add paths
backend_path = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, backend_path)
sys.path.insert(0, os.path.join(backend_path, '..'))

from services.face_processing_pipeline import FaceProcessingPipeline
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def load_classifier_info(classifier_path):
    """Load and inspect classifier structure"""
    print("\n" + "="*80)
    print("STEP 1: CLASSIFIER STRUCTURE ANALYSIS")
    print("="*80)
    
    with open(classifier_path, 'rb') as f:
        data = pickle.load(f)
    
    print(f"\n✓ Loaded classifier from: {classifier_path}")
    print(f"  Keys in classifier file: {list(data.keys())}")
    
    classifier = data['classifier']
    print(f"\n📊 CLASSIFIER OVERVIEW:")
    print(f"  - Is trained: {classifier.is_trained}")
    print(f"  - Number of students: {len(classifier.student_ids)}")
    print(f"  - Student IDs: {classifier.student_ids}")
    print(f"  - Number of binary classifiers: {len(classifier.classifiers)}")
    
    return classifier

def analyze_mean_embeddings(classifier):
    """Analyze the quality of mean embeddings"""
    print("\n" + "="*80)
    print("STEP 2: MEAN EMBEDDING QUALITY ANALYSIS")
    print("="*80)
    
    print(f"\n📐 Mean embeddings stored for {len(classifier.mean_embeddings)} students:")
    
    for student_id in classifier.student_ids:
        if student_id in classifier.mean_embeddings:
            mean_emb = classifier.mean_embeddings[student_id]
            norm = np.linalg.norm(mean_emb)
            print(f"  {student_id}:")
            print(f"    - Shape: {mean_emb.shape}")
            print(f"    - Norm: {norm:.6f} (should be ~1.0 for normalized)")
            print(f"    - Min: {mean_emb.min():.4f}, Max: {mean_emb.max():.4f}")
            print(f"    - Mean: {mean_emb.mean():.4f}, Std: {mean_emb.std():.4f}")
        else:
            print(f"  {student_id}: ⚠️ NO MEAN EMBEDDING FOUND")
    
    return classifier.mean_embeddings

def analyze_cosine_similarities(mean_embeddings, target_students=None):
    """Calculate pairwise cosine similarities between all students"""
    print("\n" + "="*80)
    print("STEP 3: PAIRWISE COSINE SIMILARITY ANALYSIS")
    print("="*80)
    
    student_ids = list(mean_embeddings.keys())
    
    if target_students:
        # Filter to only target students
        student_ids = [sid for sid in student_ids if sid in target_students]
    
    print(f"\n🔍 Calculating cosine similarities between {len(student_ids)} students...")
    print("\nPairwise Cosine Similarity Matrix:")
    print(f"{'Student':<15}", end='')
    for sid in student_ids:
        print(f"{sid:<15}", end='')
    print()
    print("-" * (15 * (len(student_ids) + 1)))
    
    high_similarities = []
    
    for i, sid1 in enumerate(student_ids):
        print(f"{sid1:<15}", end='')
        emb1 = mean_embeddings[sid1]
        
        for j, sid2 in enumerate(student_ids):
            emb2 = mean_embeddings[sid2]
            cosine_sim = np.dot(emb1, emb2)
            
            print(f"{cosine_sim:.4f}         ", end='')
            
            # Track high similarities (excluding self-similarity)
            if i != j and cosine_sim > 0.70:
                high_similarities.append((sid1, sid2, cosine_sim))
        print()
    
    if high_similarities:
        print("\n⚠️ HIGH SIMILARITY PAIRS (> 0.70):")
        for sid1, sid2, sim in sorted(high_similarities, key=lambda x: -x[2]):
            print(f"  {sid1} <-> {sid2}: {sim:.4f}")
            print(f"    Margin: {1.0 - sim:.4f} (should be > 0.05 ideally)")
    else:
        print("\n✓ No high similarity pairs found (all < 0.70)")
    
    return high_similarities

def analyze_svm_parameters(classifier, target_students=None):
    """Analyze SVM classifier parameters"""
    print("\n" + "="*80)
    print("STEP 4: SVM CLASSIFIER PARAMETERS")
    print("="*80)
    
    for student_id in classifier.student_ids:
        if target_students and student_id not in target_students:
            continue
            
        svm = classifier.classifiers[student_id]
        print(f"\n🔧 SVM for {student_id}:")
        print(f"  - Kernel: {svm.kernel}")
        print(f"  - C: {svm.C}")
        print(f"  - Gamma: {svm.gamma}")
        print(f"  - Number of support vectors: {len(svm.support_vectors_)}")
        print(f"  - Support vector ratio: {len(svm.support_vectors_) / len(svm.support_):.2%}")
        
        # Check class balance in training
        if hasattr(svm, 'n_support_'):
            print(f"  - Support vectors per class: {svm.n_support_}")

def test_real_images(pipeline, classifier, test_images, target_students=None):
    """Test recognition on actual face images"""
    print("\n" + "="*80)
    print("STEP 5: REAL IMAGE RECOGNITION TEST")
    print("="*80)
    
    if not test_images:
        print("\n⚠️ No test images provided")
        return
    
    results = []
    
    for img_path, expected_id in test_images:
        print(f"\n📸 Testing: {os.path.basename(img_path)}")
        print(f"   Expected: {expected_id}")
        
        try:
            # Load and preprocess image
            image = Image.open(img_path).convert('RGB')
            
            # Generate embedding
            embedding = pipeline.embedding_generator.generate_embedding(image)
            print(f"   Embedding: min={embedding.min():.4f}, max={embedding.max():.4f}, mean={embedding.mean():.4f}")
            
            # Calculate cosine similarities with all students
            print(f"   Cosine similarities:")
            cosine_sims = {}
            for student_id in classifier.student_ids:
                if student_id in classifier.mean_embeddings:
                    sim = np.dot(embedding, classifier.mean_embeddings[student_id])
                    cosine_sims[student_id] = sim
                    marker = "✓" if student_id == expected_id else " "
                    print(f"     {marker} {student_id}: {sim:.4f}")
            
            # Get SVM predictions
            print(f"   SVM predictions:")
            svm_predictions = {}
            for student_id in (target_students or classifier.student_ids):
                if student_id not in classifier.classifiers:
                    continue
                svm = classifier.classifiers[student_id]
                proba = svm.predict_proba(embedding.reshape(1, -1))[0]
                pos_proba = proba[1] if len(proba) > 1 else proba[0]
                decision_val = svm.decision_function(embedding.reshape(1, -1))[0]
                svm_predictions[student_id] = {
                    'probability': pos_proba,
                    'decision': decision_val
                }
                marker = "✓" if student_id == expected_id else " "
                print(f"     {marker} {student_id}: prob={pos_proba:.4f}, decision={decision_val:.4f}")
            
            # Use classifier prediction logic
            prediction = classifier.predict(embedding, threshold=0.5, allowed_student_ids=target_students)
            predicted_id = prediction.get('label', 'Unknown')
            confidence = prediction.get('confidence', 0.0)
            method = prediction.get('method', 'unknown')
            
            print(f"   Final prediction: {predicted_id} (confidence: {confidence:.4f}, method: {method})")
            
            correct = predicted_id == expected_id
            marker = "✅" if correct else "❌"
            print(f"   {marker} {'CORRECT' if correct else 'INCORRECT'}")
            
            results.append({
                'image': os.path.basename(img_path),
                'expected': expected_id,
                'predicted': predicted_id,
                'correct': correct,
                'confidence': confidence,
                'method': method,
                'cosine_sims': cosine_sims,
                'svm_predictions': svm_predictions
            })
            
        except Exception as e:
            print(f"   ❌ Error: {e}")
            import traceback
            traceback.print_exc()
    
    # Summary
    print("\n" + "="*80)
    print("RECOGNITION TEST SUMMARY")
    print("="*80)
    
    if results:
        correct_count = sum(1 for r in results if r['correct'])
        total_count = len(results)
        accuracy = correct_count / total_count
        
        print(f"\n📊 Accuracy: {correct_count}/{total_count} = {accuracy:.2%}")
        
        print("\n❌ Misclassifications:")
        for r in results:
            if not r['correct']:
                print(f"  - {r['image']}: Expected {r['expected']}, Got {r['predicted']}")
                print(f"    Method: {r['method']}, Confidence: {r['confidence']:.4f}")
    
    return results

def check_image_preprocessing_differences(image_path1, image_path2, pipeline):
    """Compare preprocessing of two images"""
    print("\n" + "="*80)
    print("STEP 6: IMAGE PREPROCESSING COMPARISON")
    print("="*80)
    
    print(f"\n🔬 Comparing preprocessing of two images...")
    print(f"  Image 1: {os.path.basename(image_path1)}")
    print(f"  Image 2: {os.path.basename(image_path2)}")
    
    for i, img_path in enumerate([image_path1, image_path2], 1):
        print(f"\n  Image {i} ({os.path.basename(img_path)}):")
        
        # Load original
        img_cv = cv2.imread(img_path)
        print(f"    - Original shape: {img_cv.shape}")
        print(f"    - Original dtype: {img_cv.dtype}")
        print(f"    - Original range: [{img_cv.min()}, {img_cv.max()}]")
        print(f"    - Original mean: {img_cv.mean():.2f}")
        
        # Load as PIL
        img_pil = Image.open(img_path).convert('RGB')
        print(f"    - PIL size: {img_pil.size}")
        print(f"    - PIL mode: {img_pil.mode}")
        
        # Generate embedding
        embedding = pipeline.embedding_generator.generate_embedding(img_pil)
        print(f"    - Embedding shape: {embedding.shape}")
        print(f"    - Embedding range: [{embedding.min():.4f}, {embedding.max():.4f}]")
        print(f"    - Embedding mean: {embedding.mean():.4f}")
        print(f"    - Embedding std: {embedding.std():.4f}")
        print(f"    - Embedding norm: {np.linalg.norm(embedding):.4f}")

def main():
    print("\n" + "="*80)
    print("FACE RECOGNITION DIAGNOSTIC ANALYSIS")
    print("="*80)
    
    # Paths
    classifier_path = os.path.join(backend_path, 'storage', 'classifiers', 'face_classifier.pkl')
    
    # Check if classifier exists
    if not os.path.exists(classifier_path):
        print(f"\n❌ Classifier not found at: {classifier_path}")
        return
    
    # Initialize pipeline
    print("\n🔧 Initializing pipeline...")
    pipeline = FaceProcessingPipeline()
    print("✓ Pipeline initialized")
    
    # Load classifier
    classifier = load_classifier_info(classifier_path)
    pipeline.classifier = classifier
    
    # Analyze mean embeddings
    mean_embeddings = analyze_mean_embeddings(classifier)
    
    # Focus on CS101 students if they exist
    cs101_students = ['100064685', '100098104']
    available_cs101 = [sid for sid in cs101_students if sid in classifier.student_ids]
    
    if available_cs101:
        print(f"\n🎯 Focusing analysis on CS101 students: {available_cs101}")
        target_students = available_cs101
    else:
        print(f"\n🎯 CS101 students not found, analyzing all students")
        target_students = None
    
    # Analyze cosine similarities
    high_sims = analyze_cosine_similarities(mean_embeddings, target_students)
    
    # Analyze SVM parameters
    analyze_svm_parameters(classifier, target_students)
    
    # Test with debug images if available
    debug_dir = os.path.join(backend_path, '..', 'HADIR_web', 'debug_faces')
    if os.path.exists(debug_dir):
        debug_images = [
            os.path.join(debug_dir, f) 
            for f in os.listdir(debug_dir) 
            if f.endswith(('.jpg', '.png'))
        ]
        
        if debug_images:
            print(f"\n📁 Found {len(debug_images)} debug images")
            
            # For testing, we need to know which student each image belongs to
            # Since we don't have labels, just test the first 2-4 images
            test_images = []
            for img_path in debug_images[:4]:
                # Try to infer student from filename or just mark as unknown
                # Format: face_{face_id}_{timestamp}.jpg
                test_images.append((img_path, "Unknown"))
            
            if test_images:
                results = test_real_images(pipeline, classifier, test_images, target_students)
            
            # Compare preprocessing if we have at least 2 images
            if len(debug_images) >= 2:
                check_image_preprocessing_differences(
                    debug_images[0], 
                    debug_images[1], 
                    pipeline
                )
    
    # KEY FINDINGS SUMMARY
    print("\n" + "="*80)
    print("KEY FINDINGS & RECOMMENDATIONS")
    print("="*80)
    
    print("\n🔍 ISSUE IDENTIFICATION:")
    
    if high_sims:
        print(f"\n⚠️ CRITICAL: Found {len(high_sims)} student pairs with high similarity (> 0.70)")
        print("   This indicates:")
        print("   1. Students may look very similar")
        print("   2. Training data may be insufficient or low quality")
        print("   3. Augmentation may be creating too similar embeddings")
        
        for sid1, sid2, sim in high_sims[:3]:  # Show top 3
            margin = 1.0 - sim
            print(f"\n   Example: {sid1} <-> {sid2}")
            print(f"     Similarity: {sim:.4f}")
            print(f"     Margin: {margin:.4f} ({'GOOD' if margin >= 0.05 else 'TOO SMALL'})")
    else:
        print("\n✓ Student embeddings are well-separated (all similarities < 0.70)")
    
    print("\n💡 RECOMMENDATIONS:")
    print("   1. Review training images for CS101 students")
    print("      - Are they from same person? Same lighting? Same angle?")
    print("   2. Check mean embedding calculation (should use original, not augmented)")
    print("   3. Consider increasing COSINE_THRESHOLD from 0.60 to 0.65")
    print("   4. Re-register students with more diverse images")
    print("      - Different angles (left, right, center)")
    print("      - Different lighting conditions")
    print("      - Different expressions")
    print("   5. Check if augmentation is too aggressive")
    print("      - May be creating embeddings that are too similar")
    print("   6. Consider using fewer augmentations but more original images")
    print("      - E.g., 7-10 original poses instead of 5 poses × 20 augmentations")
    
    print("\n" + "="*80)
    print("DIAGNOSTIC COMPLETE")
    print("="*80)

if __name__ == '__main__':
    main()
