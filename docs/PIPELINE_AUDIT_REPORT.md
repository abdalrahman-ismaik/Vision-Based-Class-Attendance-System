# Face Recognition Pipeline Audit Report

**Date**: November 26, 2025  
**Issue**: Different students being misidentified as the same person  
**Students Affected**: 100064685 (Osmam) and 100098104 (Agga) in CS101

---

## Executive Summary

After comprehensive code review, I've identified **5 critical weak points** in the pipeline that could cause different students to be misidentified as the same person:

1. **❌ CRITICAL**: Mean embedding calculation uses augmented data
2. **⚠️ HIGH**: Class imbalance and undersampling in SVM training
3. **⚠️ HIGH**: No face alignment/normalization in real-time recognition
4. **⚠️ MEDIUM**: Margin threshold too lenient (0.03 vs required ~0.05+)
5. **⚠️ MEDIUM**: Augmentation may create similar patterns across students

---

## 1. CRITICAL ISSUE: Mean Embedding Calculation

### Location
`backend/services/face_processing_pipeline.py`, lines 326-345

### Current Code
```python
# CRITICAL FIX: Calculate mean ONLY from original embeddings (first one per augmentation batch)
student_embeddings = embeddings[student_mask]

# For augmented data: if we have exactly 100 embeddings (5 images * 20 augmentations)
n_student_embeddings = len(student_embeddings)
if n_student_embeddings % 20 == 0:
    # We have augmented data, extract originals
    num_originals = n_student_embeddings // 20
    original_indices = [i * 20 for i in range(num_originals)]
    original_embeddings = student_embeddings[original_indices]
```

### Problem
**ASSUMPTION VIOLATION**: The code assumes augmented images are stored in batches of 20, with the original being the first in each batch. However:

1. **Order Not Guaranteed**: The `generate_augmentations()` method returns `[original] + augmentations`, but after processing multiple images, the order in the final embedding array depends on how `process_student_image()` is called
2. **Modulo Check Too Strict**: If a student has 3 images instead of 5, you get 60 embeddings (3×20), but the pattern still applies
3. **Edge Case**: If registration fails on some images, you might have 80 embeddings (4 successful × 20), and picking every 20th element won't get all originals

### Impact
- **Mean embeddings may include augmented data**, which can:
  - Shift the "center" of a student's feature space
  - Create artificially similar mean embeddings across students
  - Reduce inter-student separation margins

### Evidence from Your Logs
Your margins are consistently 0.01-0.04, which suggests students' mean embeddings are **TOO CLOSE**.

---

## 2. HIGH ISSUE: Class Imbalance & Undersampling

### Location
`backend/services/face_processing_pipeline.py`, lines 349-381

### Current Code
```python
MAX_NEGATIVE_RATIO = 5  # At most 5x negative samples compared to positive

if n_negative > n_positive * MAX_NEGATIVE_RATIO:
    # Undersample negatives
    selected_negative_indices = np.random.choice(
        negative_indices, 
        size=target_negatives, 
        replace=False
    )
```

### Problem
**Random undersampling loses information**:

1. **Loss of Diverse Negatives**: With 12 students, each binary classifier has 11 students' worth of negative samples. Random selection may miss important boundary cases
2. **Unstable Decision Boundaries**: Different runs produce different negative samples → different decision boundaries
3. **Probability Calibration Issues**: SVM probability estimates become unreliable with imbalanced calibration sets

### Current Stats (12 students, 100 embeddings each)
- Positive samples: 100 (one student)
- Negative samples: 1100 (11 other students)
- After undersampling: 100 positive vs 500 negative (5:1 ratio)
- **Lost 600 negative samples** (54.5% of negative data)

### Impact
- SVM may **not learn to distinguish similar-looking students** if their embeddings aren't in the undersampled negative set
- Decision boundaries become **less robust**

### Better Approach
Use **class weights** without undersampling, or use **stratified undersampling** to ensure all students are represented in negatives.

---

## 3. HIGH ISSUE: No Face Alignment in Real-Time

### Location
`HADIR_web/app.py`, lines 207-209  
`backend/services/face_processing_pipeline.py`, lines 1096-1115

### Current Code (Real-Time)
```python
# Save temp image for processing
cv2.imwrite(temp_path, face_crop)

# Recognize using pipeline
result = pipeline.recognize_face_from_crop(
    face_crop_path=temp_path,
    threshold=0.6,
    allowed_student_ids=enrolled_ids
)
```

### Current Code (Recognition)
```python
def recognize_face_from_crop(self, face_crop_path, threshold=0.5, allowed_student_ids=None):
    # Load image
    image = Image.open(face_crop_path)
    image = image.convert('RGB')
    
    # Generate embedding directly (skip face detection since already cropped)
    embedding = self.embedding_generator.generate_embedding(image)
```

### Problem
**NO ALIGNMENT OR PREPROCESSING**:

1. **Training Pipeline**:
   - Detects face with RetinaFace
   - Adds 20% margin
   - Crops face
   - Augments
   - Resizes to 112×112
   - Normalizes with FACENET_MEAN/STD

2. **Real-Time Pipeline**:
   - Gets face crop from YuNet
   - **Directly converts to PIL**
   - **No alignment to eye positions**
   - **No margin adjustment**
   - **Different face detector** (YuNet vs RetinaFace)
   - Resizes to 112×112
   - Normalizes with same FACENET_MEAN/STD

### Impact
**PREPROCESSING MISMATCH**:
- Training faces have **consistent alignment and margins**
- Real-time faces have **variable alignment and cropping**
- This creates a **domain shift** → embeddings from real-time images don't match training embeddings well

### Evidence
Face 1 in your logs was 81×84 pixels - **very small**, likely poorly aligned.

---

## 4. MEDIUM ISSUE: Margin Threshold Too Lenient

### Location
`backend/services/face_processing_pipeline.py`, line 534

### Current Code
```python
MIN_MARGIN = 0.03  # Minimum difference between best and second-best match (lowered from 0.05)
```

### Analysis

| Margin | Meaning | Interpretation |
|--------|---------|----------------|
| 1.0 - 0.71 = 0.29 | 29% difference | Clearly different students |
| 1.0 - 0.75 = 0.25 | 25% difference | Well-separated |
| 1.0 - 0.80 = 0.20 | 20% difference | Good separation |
| 1.0 - 0.90 = 0.10 | 10% difference | Moderate similarity |
| 1.0 - 0.95 = 0.05 | 5% difference | **High similarity** |
| 1.0 - 0.97 = 0.03 | **3% difference** | **Very high similarity** |
| 1.0 - 0.99 = 0.01 | **1% difference** | **Extremely similar** |

### Your Logs Show
```
Face 0: margins = 0.0153, 0.0288, 0.0378
Face 1: margins = 0.0153, 0.0103, 0.0103
```

**All margins < 0.04** → Students are **EXTREMELY SIMILAR** in embedding space!

### Problem
MIN_MARGIN = 0.03 means you accept predictions where:
- Best match cosine = 0.97
- 2nd best cosine = 0.94
- Margin = 0.03

This is **BARELY distinguishable** - essentially saying "I'm only 3% more confident in student A than student B".

### Impact
**Accepts ambiguous matches that should be rejected**, leading to misidentification.

---

## 5. MEDIUM ISSUE: Augmentation Strategy

### Location
`backend/services/face_processing_pipeline.py`, lines 141-191

### Current Strategy
- **20 augmentations** per original image
- Includes: zoom, brightness, contrast, rotation, noise, combinations
- For 5 original images → 100 total embeddings per student

### Problem
**Too much synthetic data**:

1. **Data Distribution Shift**: 95% of training data is synthetic, only 5% is real
2. **Augmentation Patterns**: All students get same augmentation patterns → may create similar artifacts
3. **Overfitting to Augmentations**: SVM learns augmentation patterns, not just face features
4. **Reduced Diversity**: 5 real poses × 20 variants < 20 diverse real poses

### Better Approach
- **Fewer augmentations** (5-10 per image)
- **More diverse original images** (7-10 different poses, lighting, expressions)
- Focus on capturing **natural variation** rather than synthetic variation

---

## Root Cause Analysis

Based on the audit, here's what's happening:

```
1. Students registered with 5 similar images (same angle, lighting)
   ↓
2. Each image augmented 20x → 100 embeddings per student
   ↓
3. Mean embedding calculated (possibly incorrectly including augmented data)
   ↓
4. Mean embeddings of similar students end up VERY CLOSE (margin 0.01-0.04)
   ↓
5. SVM trained with random undersampling → may miss key distinctions
   ↓
6. Real-time: Face detected with YuNet (different from RetinaFace training)
   ↓
7. Face crop saved WITHOUT alignment
   ↓
8. Embedding generated from misaligned face → doesn't match training distribution
   ↓
9. Classifier sees TWO slightly different versions of similar-looking students
   ↓
10. Both match student 100064685 because:
    - Mean embeddings are too close (margin < 0.03)
    - Preprocessing mismatch adds noise
    - MIN_MARGIN=0.03 is too lenient
```

---

## Recommended Fixes (Priority Order)

### 1. **IMMEDIATE: Fix Mean Embedding Calculation** ⚠️ CRITICAL

**Current Problem**: Assumes embeddings are ordered in batches of 20.

**Solution**: Tag embeddings during generation to identify originals.

```python
def process_student_image(self, image_paths, student_id, output_dir, augment_per_image=20):
    embeddings = []
    is_original = []  # NEW: Track which embeddings are originals
    
    for idx, image_path in enumerate(image_paths, 1):
        # ... face detection code ...
        
        if augment_per_image > 0:
            augmented_images = self.augmentor.generate_augmentations(
                face_image, num_augmentations=augment_per_image
            )
        else:
            augmented_images = [face_image]
        
        for aug_idx, aug_img in enumerate(augmented_images):
            # ... embedding generation ...
            embeddings.append(embedding)
            is_original.append(aug_idx == 0)  # First is original
    
    return {
        'student_id': student_id,
        'n_embeddings': len(embeddings),
        'embeddings': np.array(embeddings),
        'is_original': np.array(is_original)  # NEW
    }
```

Then in training:

```python
# Calculate mean ONLY from original embeddings
student_mask = binary_labels == 1
original_mask = is_original[student_mask]
original_embeddings = embeddings[student_mask][original_mask]
self.mean_embeddings[student_id] = np.mean(original_embeddings, axis=0)
self.mean_embeddings[student_id] /= np.linalg.norm(self.mean_embeddings[student_id])
```

### 2. **IMMEDIATE: Add Face Alignment to Real-Time** ⚠️ CRITICAL

**Solution**: Align real-time faces the same way as training.

```python
def recognize_face_from_crop(self, face_crop_path, threshold=0.5, allowed_student_ids=None):
    # Load image
    image = Image.open(face_crop_path)
    image = image.convert('RGB')
    
    # NEW: Apply same preprocessing as training
    # 1. Ensure minimum margin (if crop is tight)
    # 2. Resize to standard size FIRST
    # 3. Apply center crop if needed
    
    # Option A: Simple resize (quick fix)
    image = image.resize((112, 112), Image.LANCZOS)
    
    # Option B: Better - detect landmarks and align
    # (requires landmark detection in YuNet or RetinaFace)
    
    # Generate embedding
    embedding = self.embedding_generator.generate_embedding(image)
    ...
```

**Better Long-Term**: Use RetinaFace for real-time detection too (instead of YuNet) to ensure consistency.

### 3. **HIGH PRIORITY: Re-Register Students with Diverse Images** 🔄

**Goal**: Increase inter-student separation by capturing natural variation.

**Registration Protocol**:
```
For each student:
  1. Capture 7-10 images (NOT 5)
  2. Vary angles:
     - 3 frontal (direct, slight left, slight right)
     - 2 profile (45° left, 45° right)
     - 2 different distances (close, medium)
  3. Vary lighting:
     - Bright (well-lit)
     - Normal (classroom lighting)
     - Dim (backlit)
  4. Vary expression:
     - Neutral
     - Slight smile
  5. Use FEWER augmentations:
     - 5-10 per image (not 20)
     - Focus on realistic variations
```

**Expected Outcome**: Mean embeddings will be more representative and better separated (margin > 0.05).

### 4. **MEDIUM PRIORITY: Improve SVM Training** 🔧

**Option A**: Remove undersampling, use class weights only:

```python
# Calculate class weights
weight_positive = len(labels_balanced) / (2 * n_positive)
weight_negative = len(labels_balanced) / (2 * n_negative)
class_weights = {1: weight_positive, 0: weight_negative}

# Train WITHOUT undersampling
classifier = SVC(
    kernel='rbf',
    probability=True,
    C=10.0,
    gamma='scale',
    class_weight=class_weights
)
classifier.fit(embeddings, binary_labels)  # Use full dataset
```

**Option B**: Stratified undersampling:

```python
from imblearn.under_sampling import RandomUnderSampler

# Ensure all 11 other students are represented in negatives
# by sampling proportionally from each student
rus = RandomUnderSampler(
    sampling_strategy={0: n_positive * MAX_NEGATIVE_RATIO, 1: n_positive},
    random_state=42
)
embeddings_resampled, labels_resampled = rus.fit_resample(embeddings, binary_labels)
```

### 5. **MEDIUM PRIORITY: Increase Margin Threshold** 📊

**Change**:
```python
MIN_MARGIN = 0.05  # Back to original (from 0.03)
```

**Reasoning**: 0.03 (3% difference) is too lenient for similar-looking students. 0.05 (5% difference) provides better confidence.

**Even Better**: Dynamic margin based on overall similarity:
```python
if best_sim_value > 0.90:  # Very high similarity
    MIN_MARGIN = 0.08  # Require 8% difference
elif best_sim_value > 0.85:
    MIN_MARGIN = 0.06  # Require 6% difference
else:
    MIN_MARGIN = 0.05  # Standard 5% difference
```

### 6. **LOW PRIORITY: Add Embedding Quality Checks** ✅

**During Training**:
```python
# After calculating mean embeddings, check pairwise similarities
def check_student_separation(mean_embeddings, min_margin=0.05):
    warnings = []
    for sid1 in mean_embeddings:
        for sid2 in mean_embeddings:
            if sid1 >= sid2:
                continue
            sim = np.dot(mean_embeddings[sid1], mean_embeddings[sid2])
            margin = 1.0 - sim
            if margin < min_margin:
                warnings.append(f"Students {sid1} and {sid2} are very similar (margin: {margin:.4f})")
    
    if warnings:
        logger.warning("TRAINING WARNING: Some students have low separation:")
        for w in warnings:
            logger.warning(f"  {w}")
        logger.warning("  Consider re-registering these students with more diverse images.")
    
    return warnings
```

**During Real-Time**:
```python
# Check embedding quality
def check_embedding_quality(embedding):
    norm = np.linalg.norm(embedding)
    if abs(norm - 1.0) > 0.1:
        logger.warning(f"Embedding norm ({norm:.4f}) deviates from 1.0 - may be low quality")
        return False
    return True
```

---

## Testing & Validation Plan

### Phase 1: Immediate Diagnosis
1. ✅ Run `inspect_classifier_simple.py` to check current mean embedding similarities
2. ✅ Verify CS101 students 100064685 and 100098104 have margin < 0.05
3. ✅ Check if other student pairs also have low margins

### Phase 2: Quick Fixes (Test Individually)
1. **Test A**: Increase MIN_MARGIN to 0.05
   - Expected: More rejections, fewer false positives
   - Run real-time test, check if both faces still identified as same student

2. **Test B**: Add simple resize to real-time (112×112 before embedding)
   - Expected: More consistent embeddings
   - Compare embedding stats from real-time vs training

3. **Test C**: Use COSINE_THRESHOLD = 0.65 (stricter)
   - Expected: Fewer matches, higher accuracy on matches
   - Check if correct students still get matched

### Phase 3: Re-Training (Full Fix)
1. **Re-register CS101 students** with new protocol (7-10 diverse images)
2. **Fix mean embedding calculation** with `is_original` tracking
3. **Reduce augmentations** to 5-10 per image
4. **Retrain classifier** with new data
5. **Validate**:
   - Check mean embedding similarities (should have margin > 0.05)
   - Test real-time recognition
   - Verify different students are correctly distinguished

### Phase 4: Long-Term Improvements
1. Switch to RetinaFace for real-time detection (consistency with training)
2. Add landmark-based face alignment
3. Implement quality checks during registration
4. Add confidence-based temporal tracking (verify identity over multiple frames)

---

## Expected Outcomes

### After Immediate Fixes (1-2):
- **Reduced false positives** (fewer misidentifications)
- **May increase false negatives** (some correct students not recognized)
- **Verification queue usage** will increase (more ambiguous matches)

### After Re-Training (3):
- **Higher margins** between students (0.05-0.15 instead of 0.01-0.04)
- **Better separation** in feature space
- **More confident predictions** (fewer ambiguous matches)
- **Higher accuracy** for both known and unknown faces

### After Full Pipeline Fix (4):
- **Consistent preprocessing** across training and real-time
- **Robust recognition** even with pose/lighting variations
- **Lower verification queue usage** (direct recognition more accurate)

---

## Conclusion

The misidentification issue is caused by a **combination of factors**:

1. **Primary**: Students' mean embeddings are too close (margin 0.01-0.04 < 0.03)
2. **Secondary**: Preprocessing mismatch between training and real-time
3. **Contributing**: Lenient margin threshold (0.03), heavy augmentation (20x)

**Immediate Actions**:
1. Fix mean embedding calculation (ensure only originals used)
2. Add proper face preprocessing to real-time pipeline
3. Re-register students with diverse images

**Expected Timeline**:
- Quick fixes (margin threshold): 5 minutes
- Re-registration of 2 students: 10 minutes
- Full retraining: 5-10 minutes
- Testing: 15 minutes
- **Total: ~40 minutes to resolution**

The pipeline is **fundamentally sound**, but needs **data quality improvements** and **preprocessing consistency** to work correctly for similar-looking students.
