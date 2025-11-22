# Face Similarity Scores - Explanation & Fix

## The Problem

You were getting very high similarity scores (~0.9) even for different faces. This is NOT normal.

## Root Cause

The embeddings were **not L2-normalized** before computing cosine similarity. This is critical for face recognition systems.

## The Fix

Added L2 normalization to face embeddings:

```python
# L2 normalize the embedding (CRITICAL for face recognition)
embedding = torch.nn.functional.normalize(embedding, p=2, dim=1)
```

## Updated Similarity Thresholds

For **L2-normalized embeddings**, use these thresholds:

| Similarity Score | Interpretation              | Decision     |
| ---------------- | --------------------------- | ------------ |
| **> 0.50**       | Very likely the same person | ✓ MATCH      |
| **0.40 - 0.50**  | Possibly the same person    | ❓ MAYBE     |
| **0.30 - 0.40**  | Uncertain                   | ❓ UNCERTAIN |
| **< 0.30**       | Different people            | ✗ DIFFERENT  |

## Why L2 Normalization Matters

### Without L2 Normalization:

- Embeddings have varying magnitudes
- Cosine similarity can be misleadingly high
- Two random vectors can have 0.8+ similarity

### With L2 Normalization:

- All embeddings have unit norm (||e|| = 1.0)
- Cosine similarity = dot product
- More discriminative (better separation)
- Typical same-person scores: 0.5-0.7
- Typical different-person scores: 0.1-0.3

## Diagnostic Output

The script now shows:

1. **L2 Norm** of each embedding (should be ~1.0)
2. **Average similarity** across all faces (warning if > 0.8)
3. **Embedding statistics** (mean, std, min, max)

## Expected Results After Fix

### Same Person (Different Photos):

```
Similarity: 0.55 - 0.75 ✓ SAME PERSON
```

### Different People:

```
Similarity: 0.10 - 0.35 ✗ DIFFERENT PERSON
```

### Identical Photo:

```
Similarity: 1.00 (perfect match)
```

## How to Verify the Fix

Run the script and check:

1. **L2 Norms should be ~1.0:**

   ```
   Face 1: L2 Norm: 1.000000 ✓
   Face 2: L2 Norm: 1.000000 ✓
   ```

2. **Different faces should have lower similarity:**

   - Previously: 0.85-0.95 ❌
   - Now: 0.15-0.35 ✓

3. **Average similarity warning:**
   - If > 0.8: Something is still wrong
   - Should be 0.3-0.5 for different faces

## Common Issues if Still Too High

If similarities are still > 0.8 after normalization:

1. **Model not properly loaded**

   - Check checkpoint path
   - Verify model.eval() is called

2. **Wrong preprocessing**

   - Verify mean/std values match training
   - Check image is RGB not BGR

3. **Face crops too small**

   - Faces should be at least 50x50 pixels
   - Poor quality = poor embeddings

4. **Using same image twice**
   - Identical images will give 1.0 similarity
   - Use different photos of the person

## References

- FaceNet paper: embeddings are L2-normalized before training
- MobileFaceNet: assumes normalized embeddings
- ArcFace loss: operates on normalized features
