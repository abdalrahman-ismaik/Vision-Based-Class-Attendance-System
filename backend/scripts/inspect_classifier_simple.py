"""Simple classifier inspection script"""
import pickle
import numpy as np
import os
import sys

classifier_path = r"C:\Users\4bais\Vision-Based-Class-Attendance-System\backend\storage\classifiers\face_classifier.pkl"

print("\n" + "="*80)
print("CLASSIFIER INSPECTION")
print("="*80)

if not os.path.exists(classifier_path):
    print(f"\n❌ File not found: {classifier_path}")
    sys.exit(1)

print(f"\n✓ Loading: {classifier_path}")
with open(classifier_path, 'rb') as f:
    data = pickle.load(f)

print(f"\nKeys in file: {list(data.keys())}")

classifier = data['classifier']
print(f"\n📊 CLASSIFIER INFO:")
print(f"  - Trained: {classifier.is_trained}")
print(f"  - Students: {classifier.student_ids}")
print(f"  - Number of classifiers: {len(classifier.classifiers)}")
print(f"  - Mean embeddings available: {len(classifier.mean_embeddings)}")

print(f"\n📐 MEAN EMBEDDINGS:")
for student_id in classifier.student_ids:
    if student_id in classifier.mean_embeddings:
        emb = classifier.mean_embeddings[student_id]
        norm = np.linalg.norm(emb)
        print(f"  {student_id}:")
        print(f"    Shape: {emb.shape}, Norm: {norm:.6f}")
        print(f"    Range: [{emb.min():.4f}, {emb.max():.4f}]")
        print(f"    Mean: {emb.mean():.4f}, Std: {emb.std():.4f}")

print(f"\n🔍 PAIRWISE COSINE SIMILARITIES:")
student_ids = list(classifier.mean_embeddings.keys())
print(f"\n{'Student':<15}", end='')
for sid in student_ids:
    print(f"{sid:<15}", end='')
print()
print("-" * (15 * (len(student_ids) + 1)))

high_similarities = []
for i, sid1 in enumerate(student_ids):
    print(f"{sid1:<15}", end='')
    emb1 = classifier.mean_embeddings[sid1]
    
    for j, sid2 in enumerate(student_ids):
        emb2 = classifier.mean_embeddings[sid2]
        cosine_sim = np.dot(emb1, emb2)
        
        print(f"{cosine_sim:.4f}         ", end='')
        
        if i != j and cosine_sim > 0.70:
            high_similarities.append((sid1, sid2, cosine_sim))
    print()

if high_similarities:
    print("\n⚠️ HIGH SIMILARITY PAIRS (> 0.70):")
    for sid1, sid2, sim in sorted(high_similarities, key=lambda x: -x[2]):
        margin = 1.0 - sim
        print(f"  {sid1} <-> {sid2}: Similarity={sim:.4f}, Margin={margin:.4f}")
        if margin < 0.03:
            print(f"    ❌ CRITICAL: Margin < 0.03 (current MIN_MARGIN threshold)")
        elif margin < 0.05:
            print(f"    ⚠️  WARNING: Margin < 0.05 (may cause ambiguous matches)")
else:
    print("\n✓ No high similarity pairs found")

print(f"\n🔧 SVM PARAMETERS:")
for student_id in classifier.student_ids:
    svm = classifier.classifiers[student_id]
    print(f"  {student_id}:")
    print(f"    Kernel: {svm.kernel}, C: {svm.C}, Gamma: {svm.gamma}")
    print(f"    Support vectors: {len(svm.support_vectors_)}")
    if hasattr(svm, 'n_support_'):
        print(f"    Per class: {svm.n_support_}")

# Focus on CS101 students
cs101_students = ['100064685', '100098104']
available_cs101 = [sid for sid in cs101_students if sid in classifier.student_ids]

if available_cs101:
    print(f"\n🎯 CS101 STUDENT ANALYSIS:")
    print(f"   Students: {available_cs101}")
    
    if len(available_cs101) == 2:
        sid1, sid2 = available_cs101
        emb1 = classifier.mean_embeddings[sid1]
        emb2 = classifier.mean_embeddings[sid2]
        cosine_sim = np.dot(emb1, emb2)
        margin = 1.0 - cosine_sim
        
        print(f"\n   Similarity between {sid1} and {sid2}:")
        print(f"     Cosine: {cosine_sim:.4f}")
        print(f"     Margin: {margin:.4f}")
        
        if margin < 0.03:
            print(f"     ❌ CRITICAL: These students are TOO SIMILAR!")
            print(f"        The margin ({margin:.4f}) is below MIN_MARGIN (0.03)")
            print(f"        This explains why they're being confused!")
        elif margin < 0.05:
            print(f"     ⚠️  WARNING: Students very similar, margin barely acceptable")
        else:
            print(f"     ✓ Margin is acceptable")
        
        # Calculate embedding distance
        euclidean_dist = np.linalg.norm(emb1 - emb2)
        print(f"     Euclidean distance: {euclidean_dist:.4f}")

print("\n" + "="*80)
print("KEY FINDINGS:")
print("="*80)

if high_similarities:
    print(f"\n⚠️ Found {len(high_similarities)} highly similar student pairs")
    print("\nROOT CAUSE:")
    print("  The students' mean embeddings are too close in the feature space.")
    print("  This happens when:")
    print("  1. Students actually look very similar")
    print("  2. Training images are too uniform (same angle/lighting)")
    print("  3. Augmentation creates similar patterns across students")
    print("  4. Insufficient original diverse images per student")
    
    print("\nSOLUTIONS:")
    print("  1. Re-register students with MORE DIVERSE images:")
    print("     - 7-10 DIFFERENT images per student")
    print("     - Different angles: front, left 45°, right 45°")
    print("     - Different lighting: bright, normal, dim")
    print("     - Different expressions: neutral, smile")
    print("     - Different distances: close-up, medium")
    print("  2. Reduce augmentation per image (20 → 5)")
    print("     - Focus on quality over quantity")
    print("     - More diverse originals > many augmentations")
    print("  3. Use stricter threshold: COSINE_THRESHOLD 0.60 → 0.65")
    print("  4. Check mean embedding calculation (should use originals only)")
else:
    print("\n✓ Students are well-separated in feature space")
    print("  Issue may be in real-time preprocessing or face extraction")

print("\n" + "="*80)
