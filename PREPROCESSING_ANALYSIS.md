# Preprocessing Analysis & Fix Summary

## Issue Found: SVM Probability Calibration Problem

After thorough analysis, I identified that the preprocessing between training and inference is **mostly consistent**, but there's a **classifier calibration issue**.

### Preprocessing Comparison

#### Training Pipeline:
1. Load original student image
2. **RetinaFace** face detection
3. Crop with 20% margin
4. **Generate 20 augmentations** (brightness, contrast, zoom, rotation, noise)
5. **Resize to 112x112** (LANCZOS)
6. Generate embedding via FaceNet (with internal resize 112→112, ToTensor, Normalize)
7. Store embeddings for SVM training

#### Inference Pipeline:
1. Load webcam frame
2. **RetinaFace** face detection  
3. Crop with 20% margin
4. **No augmentation** (single image)
5. **No manual resize** (passes crop directly)
6. Generate embedding via FaceNet (with internal resize to 112x112, ToTensor, Normalize)
7. SVM prediction

### Key Findings:

1. ✅ **Same face detector**: Both use RetinaFace
2. ✅ **Same margin**: Both use 20% margin around detected face
3. ✅ **Same embedding model**: Both use MobileFaceNet with identical preprocessing
4. ✅ **Same normalization**: Both embeddings are L2-normalized (norm = 1.0)
5. ⚠️ **Different augmentation**: Training uses 20 augmented versions per image, inference uses raw image
6. ⚠️ **Different resize timing**: Training pre-resizes to 112x112, inference relies on FaceNet's internal resize

### The Real Problem: SVM Probability Calibration

The SVM classifier uses **Platt scaling** to convert decision values to probabilities. With heavily imbalanced data (100 positive vs 1180 negative samples per student), Platt scaling becomes overly conservative, producing very low probabilities even for correct matches.

**Evidence from logs:**
- Best SVM probability: **0.0177** (1.77%) - Way too low!
- This happens even when the classifier has 99%+ test accuracy

### The Solution: Cosine Similarity Fallback

I've implemented a **hybrid approach**:

1. **Primary**: Use SVM probabilities with threshold 0.6
2. **Fallback**: If SVM prob < 0.6 BUT cosine similarity ≥ 0.4, use cosine similarity
3. **Reject**: If both are too low, mark as "Unknown"

**Why this works:**
- Cosine similarity directly compares embeddings without probability calibration issues
- Threshold of 0.4-0.5 is standard for face recognition (0.6+ is very good match)
- This bypasses the Platt scaling problem while maintaining accuracy

### Code Changes:

1. **Added mean embeddings storage**: Each classifier now stores the mean embedding for its student
2. **Calculate cosine similarity**: Compare live embedding with stored mean embeddings  
3. **Hybrid decision logic**: Use cosine similarity when SVM probabilities fail
4. **Enhanced logging**: Now logs SVM prob, decision values, AND cosine similarities

### Expected Behavior:

After restarting the app, you should see logs like:
```
INFO: [Classifier] Best SVM match: 100098104 with confidence 0.0177
INFO: [Classifier] Best cosine match: 100098104 with similarity 0.6234
INFO: [Classifier] Using cosine similarity fallback (SVM prob too low but cosine sim high)
INFO: ✓ RECOGNIZED: Student Name (ID: 100098104) with confidence 0.62
```

### Next Steps:

1. **Restart** `HADIR_web/app.py`
2. **Test recognition** - Should now work with cosine similarity
3. **Check logs** - Verify cosine similarities are reasonable (>0.4 for matches)
4. **Tune threshold** - Adjust `COSINE_THRESHOLD` in code if needed (currently 0.4)

### Alternative Solutions (if needed):

If cosine similarity also fails:
1. Lower cosine threshold to 0.3
2. Use decision function values instead of probabilities
3. Retrain SVM with different parameters (e.g., C=0.1, no probability=True)
4. Use a different classifier (e.g., Random Forest, Neural Network)
